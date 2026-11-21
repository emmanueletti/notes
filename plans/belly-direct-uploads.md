# Belly direct uploads engine

Status 2026-10-29: hotfix 6adf1b1 and rename 58c6f85 (wallpaper -> cover) pushed. Engine slice 1 (party cover) built, uncommitted, verified in Chrome against dev MinIO.

## Decisions

- Built in Belly first, kept extractable (engine has no Belly deps beyond utils/logger). Extract to a studio gem when a second app needs it.
- Upload on submit, not on pick.
- JS talking to the server is fine; the "Stimulus never fetches" rule was loosened.
- First slice: party cover only. Party mode already sits behind feature_enable_parties, so no new flag.
- Naming: cover is the umbrella (image or preset), cover_image is the file, cover_preset the colour or gradient.

## Built (slice 1)

- `UploadPolicy` (app/models): name, record, attachment, content types, max bytes, service from the attachment's `service:`.
- `DirectUploadsController`: login required, rate limited, rejects off-policy blobs with 422, also shadows the stock `/rails/active_storage/direct_uploads` (404).
- `utils/direct_upload.js` (FileUpload: state, progress, abort) and `direct-upload` Stimulus controller (submit intercept, signed id swap, data-upload-state, --upload-progress, direct-upload:* events, required values throw on connect).
- Cover form wired: label dims while uploading, progress bar, inline error.

## Before shipping slice 1

- CORS on staging and prod Spaces buckets (AllowedOrigins app hosts, PUT, AllowedHeaders *). Without it every cover upload fails in prod.
- Verify a PUT to Spaces from the iOS and Android shells.
- Not built, with triggers: unattached blob purge job (when abandoned uploads show up in Spaces), turbo visit / beforeunload guard (first multi-file caller), concurrency cap and retry (image import).

## Why

- Cover upload broke in prod (2026-10-29): `photo-normalize` on the cover form had no `max-bytes` value, Stimulus defaulted it to 0, every file was dropped, form posted empty, 400 `ParameterMissing`. Silent to the user.
- Every upload today is a multipart post through Puma: slow on phones, holds a web thread, no progress, no retry.
- Each upload site wires its own normalize + preview + validation. Limits are duplicated between model constants and data attributes.

Ship the one-line cover fix now, independent of this plan.

## Goal

One engine that uploads straight to Spaces, and any UI element can plug into it: a button, a dropzone, a cover tile, a list of previews, a progress ring. The engine owns no markup.

## Shape

Four layers, each usable without the ones above it.

1. Engine: `app/javascript/utils/direct_upload/engine.js`
   - No DOM. An `EventTarget` queue of upload objects.
   - Per file: `queued -> preparing -> uploading(progress) -> uploaded(signedId) | failed(error) | cancelled`.
   - Pipeline per file: `prepare` (optional, for example `normalizeImage`), `validate` (type, size from server policy), `DirectUpload` with `directUploadWillStoreFileWithXHR` for progress and abort.
   - API: `add(files)`, `cancel(id)`, `retry(id)`, `remove(id)`, `settled()` promise, `busy`, `signedIds`.
   - Concurrency cap (2), so a batch of 10 photos on a phone does not stall.
   - Errors reported to the logger once, in the engine.

2. Binding: `direct-upload` Stimulus controller
   - Wraps a form or any container. Builds one engine from server-rendered values: `url`, `attachment`, `field`, `accept`, `max-bytes`, `max-files`, `prepare`. All required, none defaulted. A missing value throws on connect, so the 0-byte bug cannot repeat.
   - Sources: any `fileInput` target, drop on any `dropzone` target, paste on the element.
   - Sink: hidden inputs named `field` holding signed ids, kept in sync with the queue. The picked files are cleared from the file input, so nothing big rides along.
   - Submit: a normal form submit, so the server answers with Turbo Streams like every other form. While busy it holds the submit and fires it once settled. `auto-submit` value for pickers that save on pick (the cover).
   - Turbo visit and `beforeunload` are blocked while uploading.

3. UI contract: how any element connects
   - State as attributes on the controller element: `data-upload-state="idle|uploading|failed|done"`, `data-upload-count`, and `--upload-progress` as a CSS variable. A CSS-only UI (button spinner, disabled submit, progress bar) needs no JS.
   - Events with a fixed `detail` (`{ upload }` with id, file, state, progress, error, previewUrl): `direct-upload:added`, `:progress`, `:uploaded`, `:failed`, `:removed`, `:settled`. Richer UIs are small controllers listening to these: `upload-previews` (replaces `photo-previews`), `upload-progress`.
   - Commands as Stimulus actions: `direct-upload#pick`, `#remove`, `#retry`, `#cancel`, so a button anywhere inside can drive it.

4. Server
   - `DirectUploadsController < ActiveStorage::DirectUploadsController`, routed over the default path. The stock one has no auth: require a signed-in user, rate limit, graceful JSON on CSRF failure.
   - Per-attachment policy in the model, the single source for limits: `Party::WALLPAPER_UPLOAD = {content_types:, max_bytes:}`. The controller rejects blob creation that breaks it (422 JSON the engine shows). The view renders the same policy into the binding's values. The model validation still runs on attach.
   - `attachment_name` on the blob request (Rails 8.1 supports it) picks the service, so `RecipeImportEvent#uploaded_photos` lands on `private_uploads`.
   - Controllers accept signed ids where they accept files today. `@party.update(wallpaper: signed_id)` already works.
   - Recurring job purging unattached blobs older than a day (abandoned uploads).

## Storage and platform

- CORS on the prod Spaces bucket, plus staging and minio in dev. Commands for the human, same as workbench `docs/wiki/s3-cors.md`.
- CSP is off today, no `connect-src` change needed. Note it if CSP is turned on.
- Hotwire Native: file inputs and XHR work in the web view. Verify a PUT to Spaces from iOS and Android before rolling past the cover.
- Imgproxy and variants unchanged, they read the blob after attach.

## Rollout

Behind a Flipper flag in the views only (UI-only flag rule): the flagged view renders the binding, the unflagged view keeps today's multipart form. Controllers accept either.

1. Server endpoint + policy + CORS + engine + binding. Party cover first.
2. Recipe cover photo.
3. Image import (multiple, private service, previews).
4. Settings bulk import file (non-image, no prepare step).
5. Remove the flag and the multipart paths, retire `photo-normalize` and `photo-previews`.

## Tests

- Controller tests: endpoint auth, policy rejection, private service selection.
- Controller tests per caller accepting signed ids.
- One system test for the cover green path, only if approved.
- JS engine has no test runner in Belly; verify in Chrome and both native shells.

## Open questions

- Hotwire-first exception: the engine has to talk to the blob endpoint and Spaces from JS (ActiveStorage `DirectUpload`). Attach still goes through a normal form submit.
- Upload on pick or on submit.
- Which callers in the first slice.
