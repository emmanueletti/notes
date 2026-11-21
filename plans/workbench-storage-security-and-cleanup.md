# Workbench storage: upload security, cleanup, and migration prep

Started 2026-11-07. Goal: close the anonymous upload hole, shrink the bucket to what we actually use, and be ready to move storage (Render object storage is coming).

## What happened

On 2026-11-05 at 06:46 UTC an automated scanner hit the portal subdomain and used Rails' stock `ActiveStorage::DirectUploadsController` to create blobs without logging in. It uploaded about 150-byte `.msl` (ImageMagick script) and `.eps` (Ghostscript) files named `photo_*`, then requested `/nx_proof.png` and `/nx_rce.png` to see if a payload had run. Those returned 404.

Why it worked:

- The stock controller inherits from `ActiveStorage::BaseController`, not our `ApplicationController`, so it never checks login. CSRF is its only guard, and any page hands out a token.
- `config/routes.rb:36` added the stock route on the portal subdomain, and Rails draws it on the main host too.
- No content type or size limits.
- AppSignal ignored `ActiveStorage::DirectUploadsController#create`, so no traces.

Why it mattered: the prod image installs `libvips42`, Debian's build can hand unknown formats to ImageMagick, and `BlobNormalizer` loaded files with `loader(unlimited: true)`. `NormalizeImagesJob` with no shop sweeps every `image/*` blob, attached or not.

Evidence status:

- Scanner blobs were purged from the prod console on 2026-11-07, so the database rows and bucket objects are gone.
- AppSignal logs for the window still have paths, filenames and checksums: https://appsignal.com/its-us-studio-1/sites/68a6990e319937bc79601a92/logs?from=2026-11-05T06%3A46%3A50Z&timeframe=custom&to=2026-11-05T06%3A47%3A12Z. Export before retention drops it.
- Logged IPs are Cloudflare edges. The real IP is in Cloudflare Security > Events for that window. Capture it.
- [ ] Confirm nothing processed the scanner files (0 means safe):
  `SolidQueue::Job.where(class_name: "NormalizeBlobJob").where(created_at: Time.utc(2026, 11, 5, 6, 46)..).count`
  If not 0, follow ciso `references/incident-response.md`.

## Built, not yet committed

### toolshed (main)

- `feat(studio-rack-attack): resolve remote_ip through Cloudflare edges`. Adds Cloudflare ranges to Rails `trusted_proxies`, so `request.remote_ip` is the real visitor everywhere (sessions, terms signature IPs, `rate_limit`, logs). Blocks and throttles log `client_ip`.
- `feat(studio-monitoring): log the client IP with each request`. `http_request` lines carry `client_ip`.
- Then `bundle update` in workbench (and belly).

### workbench (worktree `~/projects/itsusstudio/wt-workbench-uploads`, branch `secure-direct-uploads`)

Kept off the main checkout because another agent has pending migrations there. Rebase onto main before committing.

- `fix(uploads): require login and a policy for direct uploads`. `DirectUploadsController` subclass with `Authentication`, `rate_limit` 300/hour per team member, `UploadPolicy` + `config/upload_policies.yml` (`job_item_images`, `rich_text_embeds` for Trix). Stock route 404s on every host, portal route removed. AppSignal no longer ignores uploads.
- `fix(images): only normalize files whose bytes are real images`. `BlobNormalizer` sniffs the first 4 KB with Marcel and skips anything not JPEG, PNG, WebP, GIF or HEIC. Prod image sets `VIPS_BLOCK_UNTRUSTED=1`.
- `feat(jobs): purge unattached blobs daily`. `PurgeUnattachedBlobsJob`, as in the Rails guide: unattached, older than 2 days, `purge_later`, daily at 3am.

Full suite in the worktree: 2439 runs, 3 failures in Stripe checkout and SMS tests, unrelated to uploads. Probably missing credentials in the worktree (no master key). Confirm on main.

### jean-claude

- `docs(studio-security): add weekly threat-sweep and run it from weekly-review`. New `threat-sweep` skill: read-only weekly hunt for exploit probes that answered, upload abuse, credential stuffing, token and ID guessing, SMS or email pumping, webhook forgery, scraping and attack tools, defences firing, and 5xx errors started by known attackers. Reports go to `~/notes/security/sweeps/`.

## Plan

### 1. Ship the security fixes

- [x] Commit toolshed, workbench and jean-claude changes above (all pushed by 2026-11-08).
- [x] `bundle update --source toolshed` in workbench, deployed.
- [ ] After deploy, check that a job item photo upload and a Trix image in policies still work.
- [ ] Check that `http_request` logs arrive with `client_ip`. On 2026-11-07, AppSignal only showed Rails' own `action_controller.request_completed` events, so the deployed gem may be older than toolshed main.

### 2. Close remaining upload gaps (plain Rails, no new gem)

Decision: no `active_storage_validations`. It validates at attach time only, so it would not have stopped this attack, and two small validations don't justify a dependency.

- [x] (2026-11-08, `8239eb0c`: bytes checked after attach in VerifyImageBytesJob, not in the request) `JobItem#identify_image` (`job_item.rb:186`) trusts the declared content type for "trusted" types. Always call `blob.identify` and validate `images` against the policy's types. Wait until the other agent's `job_item.rb` changes are committed.
- [x] (2026-11-08, `8239eb0c`: blobs stamped with the uploader's shop) `Dashboard::JobItems::ImagesController` `find_signed!` isn't scoped to the shop. Low risk.
- [x] (2026-11-08, `8239eb0c`) Policy shopping (security review, 2026-11-07): a logged-in user can create a blob under `rich_text_embeds` (25 MB) and attach it as a job item photo (15 MB). Record the policy name in blob metadata (`blob_args` merge) and check at attach time that it matches the record and attachment. Fold this into the `JobItem#images` validation above.
- Cloudflare trust (security review on toolshed `b870557`): any Cloudflare customer can forge `X-Forwarded-For` and `CF-Connecting-IP` through their own zone or Worker. Decided 2026-11-07 not to add an origin-secret header check: it costs a middleware, a credential and a Cloudflare rule per app, and the worst case is a faked IP for rate limits or logs, which rack-attack already accepted. The README says forwarded IPs are hints, not proof. Revisit if an IP ever becomes an access control.

### 3. Trim the bucket

Numbers from prod on 2026-11-07:

| What | Count | Size |
| --- | --- | --- |
| Attached image blobs without the `normalized` flag | 256,339 | (includes the variants below) |
| By type | jpeg 234,861, heic 16,185, png 5,235, webp 56, gif 1, tiff 1 | |
| Over 2.5 MB | 9,070 | 27.2 GB |
| Rails variants (`ActiveStorage::VariantRecord`) | 6,977 | 3.6 GB |
| Previews | 0 | 0 |
| Unattached orphans | 1,172 | 1.13 GB (purged) |

The `normalized` flag is only set by `BlobNormalizer`, never by the browser compression in `normalize_image.js`, so the 256k count overstates the work.

HEIC is not a display problem: every view goes through `generate_image_url` with `format: :jpeg`, and imgproxy v4 converts HEIC.
- [x] Moot: the backfill converted every HEIC to JPEG.

Steps:

- [x] Delete variants, done 2026-11-07 (nothing reads them, since `variant_processor` is `:disabled`):
  `ActiveStorage::VariantRecord.find_each(&:destroy)`
  Check `[ActiveStorage::VariantRecord.count, variants.count]` reaches 0.
- [x] Narrow `NormalizeImagesJob` to attached originals over 2.5 MB or HEIC (about 20k files: all 16,185 HEIC plus JPEG and PNG over 2.5 MB; not 256k), excluding `ActiveStorage::VariantRecord` attachments. Re-encoding already compressed JPEGs would cost quality and hours.
- [x] (finished 2026-11-08, on the dedicated worker with single-thread processes) Run it once, one internal shop first, check a sample of photos, then the rest. Watch in Mission Control. Expect about 18 GB back.
- [x] (2026-11-08, `5c687d26`) Remove the normalizer for good: `BlobNormalizer`, `NormalizeBlobJob`, `NormalizeImagesJob`, the `image_processing` gem, and `libvips42` and `libheif1` from `Dockerfile.production`. Image work then lives only in imgproxy, and the ImageMagick risk leaves the app servers.
- [ ] Compare the bucket against the database. Total in DB:
  `ActiveSupport::NumberHelper.number_to_human_size(ActiveStorage::Blob.sum(:byte_size))`
  If the DO console shows much more, write a read-only script (run by a human with Spaces credentials) that lists the bucket, compares it against `active_storage_blobs.key`, and reports extra keys and their size. Check for a pre-Rails-6.1 `variants/` folder too. Delete only after review.

### 4. Migrate storage (when Render object storage is ready)

Check first:

- [ ] Out of preview, S3-compatible, supports presigned PUT (direct uploads) and CORS.
- [ ] Pricing for storage and transfer against Spaces ($5 for 250 GiB and 1 TiB transfer, then $0.02/GiB stored and $0.01/GiB transfer).

Move with Active Storage's `Mirror` service, no downtime, same keys and signed ids:

1. `storage.yml`: mirror service with DO primary, Render mirror. New uploads write to both.
2. Copy existing files: `ActiveStorage::Blob.find_each(&:mirror_later)`, or a bucket-to-bucket copy since keys match.
3. Point imgproxy (shared-services) at the new bucket: S3 endpoint and allowed sources.
4. Switch primary to Render, then drop DO.

Transfer out of DO is free under the 1 TiB monthly allowance at our size.

### 5. Other apps (from the 2026-11-07 audit)

- [ ] (committed `27cfed7`, not pushed) belly: set `VIPS_BLOCK_UNTRUSTED=1`. Upload policy checks only the declared type, and libvips sniffs the bytes on attach.
- [ ] canvas: close only the stock direct upload route with a 404 and a "never route this" warning, like deja-yum's `5857e9d` (stock route is open, no attachments). Add studio-rack-attack. Don't use `draw_routes = false`: it reads like an invitation to draw the upload route back in by hand.
- [ ] (committed `5857e9d`, not pushed) deja-yum: stock direct upload route answers 404, with a warning comment and a test.
- [ ] trellis template: bake in the closed stock upload route (404 plus warning), the upload policy controller, purge job and `VIPS_BLOCK_UNTRUSTED` so new apps start safe.
- [ ] Move the upload policy and purge job into a toolshed gem only once several apps share the same code.

## Cold storage idea (parked)

Spaces Cold Storage costs $0.007/GiB-month against $0.02 for Standard, has a 30-day minimum and 128 KiB minimum billing, and is a separate bucket type with no lifecycle transitions. Moving old photos would mean an app-level job and "last viewed" tracking. It only pays at several TiB. Not worth it now.
