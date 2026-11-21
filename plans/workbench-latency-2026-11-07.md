# Workbench latency plan

Started 2026-11-07. Goal: 300ms p95 per web action, for customers across Canada (Vancouver is the worst case). Measured as AppSignal transaction_duration p95 per action; Vancouver users see about 65ms on top.

## Budget

- App and Postgres stay in Render Ohio. Oregon was ruled out: Montreal would go from ~20ms to ~70ms RTT.
- Vancouver to Ohio RTT is ~65-70ms (direct_uploads TTFB 90-132ms in a browser test). Montreal ~20ms.
- Target is server p95 under 300ms per action. Aim for ~230ms where Vancouver matters, so the full trip stays near 300ms.
- Photo uploads: ImagesController#create counts toward the target, the browser PUT to Spaces does not. A 1-2MB PUT to NYC3 took 470-830ms on its own.

## Baseline (AppSignal, 2026-11-07 00:00-18:16 UTC)

- ~330 web requests, mean 124ms. 46 background jobs, mean 145ms.
- p95 offenders: Public::SignupsController#create 748ms, ImagesController#create 369ms, DetailsStepsController#show 330ms, JobTicketsController#index 178ms (one 548ms, one 1031ms cold).
- Go port ruled out: most slow time is network, SQL or bcrypt, which Go would not change. Rendering is the only CPU-bound part.

## Done

- [x] Identify photo before the row lock (d6fcc98c, deployed in 61212ac at 18:28). Verified on the demo account: 3 parallel uploads overlapped, 182-322ms each in the browser, no queueing. A real upload trace (de49d3c6) shows the Spaces fetch (265ms) outside the transaction.
- [x] Skip the Spaces fetch for declared image types (uncommitted). `JobItem#add_image` marks jpeg/png/webp/gif/heic/heif blobs identified without downloading; other types still go through `identify`. The client already re-encodes photos to JPEG (`normalize_image.js`), so the declared type comes from the browser's own encoder. Security review: not exploitable (Spaces object keeps the browser's declared type either way, Rails nosniff and inline allowlist defaults, photos served through imgproxy, uploads are authenticated). Saves ~200-470ms per upload.

- [x] Asset cache-control header in production.rb (uncommitted). Still needs Render Edge Caching turned on in the dashboard.
- [x] Signup: `disposable_domain: true` (no DNS), probe TeamMember gets the digest so bcrypt runs once, password length and not_pwned now on Registration (shared `Unpwnable::NOT_PWNED_OPTIONS`), registration not_pwned message added to en and fr (uncommitted). Tests: breach, hashes once, no DNS lookup.

- [x] Render Edge Caching on (common static files). Asset went MISS then HIT, TTFB 293ms to ~92ms. Default 2h TTL until the cache-control header deploys.
- [x] Cloudflare cache rule "Cache imgproxy images" on the itsusstudio.com zone: hostname equals images.itsusstudio.com, eligible for cache, edge TTL uses cache-control if present and bypasses if not. Photo went MISS then HIT, TTFB 271ms to ~95ms. Error responses (403) BYPASS. Shared with Belly.

- [x] Fingerprinted icons (uncommitted). public/favicon/* moved to app/assets/images/favicon/, head links use image_path, manifest served by Rails 8 rails/pwa#manifest from app/views/pwa/manifest.json.erb. Root fallbacks (/favicon.ico, /apple-touch-icon*.png) stay plain files in public/, the Rails default: browsers only fetch them when a page declares no icons, and favicon caches are sticky regardless of headers. A 302-redirect version was built and dropped as non-idiomatic.

- [x] Committed 8851e856 (photo skip), 4d19425d (asset header), b8e5a6b1 (signup), 263bfe92 (icons + manifest); jean-claude 1ea1cd8 (dependency-update Rails section). Not pushed: waiting on workbench-1a's "49 committed" so bin/ci runs on a clean tree.
- [x] Trigram indexes (uncommitted, migrated on dev). Migration 20261107193815 adds `lower(description) gin_trgm_ops` on job_items and `phone_number gin_trgm_ops` on customers, both concurrently. `JobItemsSearch` description branch now compares `lower(description) LIKE`. Dev plan confirms both indexes are usable; dev data is too small for the planner to prefer them, so verify the shop 8 search time in AppSignal after deploy.

- [x] Trace tags (toolshed, uncommitted): studio-monitoring `Current` setters for actor_id, tenant_id and a new locale attribute call `Tags.apply`, which adds AppSignal transaction tags and attributes on the request's root OTel span (PostHog APM), or the current span in jobs. `default_properties` prefers `Current.locale`, because the around_action has already reverted I18n.locale when the http_request line is written. 131 gem tests pass. Workbench half (one line in `Localizable#switch_locale` + test) saved as a patch in the session scratchpad: apply only after toolshed is pushed and `bundle update studio-monitoring --conservative` runs, or every request raises NoMethodError (this happened once in dev and was reverted at once).
- [x] Row prefetch (uncommitted): `data_table_row_link(href)` + `inline_td(link: true)` put a full-cell overlay `<a data-turbo-frame="_top" tabindex=-1 aria-hidden>` in each content cell; checkbox and actions cells opt out. Stretched link over `<tr>` ruled out: WebKit bug 240961 (fixed only in trunk, April 2026), and the iOS app is WebKit. Verified in Chrome: hover sends one `X-Sec-Purpose: prefetch` request with no frame header, the click reuses it (2 Turbo fetch events, 1 network request), full-page visit. Jobs and customers lists. Keyboard reachability unchanged (rows still not focusable).
- [x] Cold start (uncommitted): `config.active_record.check_schema_cache_dump_version = false`. bin/studio release already dumps the schema cache before every boot (the agent's "no schema cache" was wrong), but with the version check on, Rails defines attribute methods lazily on first use, the 13-23ms single-row instantiations in the cold trace. Signed-in warm-up page not done: needs a real session at boot.
- [x] N+1s (uncommitted): team member checkboxes `.load` (no EXISTS then load), jobs index preloads `customer: :repair_shop`, `form_fields_from_stored_values` preloads definitions (5 queries to 2 with 4 values, test added).

- [x] Committed locally: toolshed 81ec57b (trace tags); workbench 7d286a17 (row prefetch), 148b4f60 (attribute methods at boot), 8154ed11 (N+1s), 012ee04c (comment trim). Not pushed (user pushes). Next after the toolshed push: apply the scratchpad patch, `bundle update studio-monitoring --conservative`, one workbench commit for the locale tag.

- [x] Health check noise owned by the gem (toolshed, uncommitted): `Configuration::HEALTH_CHECK_PATH = "/up"`; RequestSampling always drops it from AppSignal (even when an app assigns `appsignal_ignored_paths =`), lograge skips it by path (`ignore_custom`), OTel uses the constant, and a railtie initializer defaults `silence_healthcheck_path` to it. 134 gem tests pass. App cleanups saved as scratchpad patches, apply only after the gem bump: workbench (4 health entries in appsignal.rb, portal entry in unlogged_actions) and Belly (2 appsignal entries, silence lines in production and staging).
- [x] Committed toolshed 090169f (health check filtering). Not pushed. After the user pushes toolshed: in workbench `bundle update studio-monitoring --conservative`, apply both scratchpad patches (locale tag, health check cleanup), one commit; Belly applies its patch after its own bump.
- [x] Workbench d4c6d5b3: gem bumped to 090169f (bump made by workbench-50 on the user's instruction), locale tag in Localizable, health check ignores removed from appsignal.rb and monitoring.rb, stale ignore_actions test removed. Dev verified: /up silent in the log on both hosts. Not pushed. Belly still to bump and apply belly-health-check-cleanup.patch (scratchpad).
- Skipped `attributes_for_inspect = [:id]`: hides record attributes in the production console; little privacy gain since Ruby 3.4+ keeps inspect out of error messages.

- [x] 43197926: prefetch for the portal job list and the exact-ID match row (render_td gets the overlay too). Houston and the unused linkable_tr helpers skipped.
- [x] Belly health check patch sent to belly-49, applied there, awaiting the user's commit approval. belly-49 flagged Belly's own lib/middleware/silence_health_check.rb as redundant with Rails' SilenceRequest.
- [x] Image format comparison (dev imgproxy, 6 jewellery photos at 800px, scored against lossless references). Decision: keep JPEG.
  - WebP q80: about half the bytes, visible smoothing on skin and metal texture at zoom, and a poor ring render (SSIM 0.948 vs 0.989) for 13% saving. WebP q90 matches JPEG quality at the same size.
  - AVIF q60: about half the bytes with quality close to JPEG on photos, but weaker on the render, needs iOS 16+ (older shop iPads would show broken images without a picture fallback), and the saving is about 17KB per 800px photo, a few ms on a normal connection. Not worth a picture element at 8 call sites for the latency goal.
- Pending: keyboard access on rows, waiting for the job_item_status rename session to commit (it is editing en.yml and fr.yml).

- [x] After-deploy numbers (PostHog http_request logs, warm traffic = more than 10 min after each deploy; 012ee04c live since 15:00, demo-account traffic generated through Chrome: about 136 page loads plus 3 photo uploads, deleted after):
  - Overall warm p95: 352ms (61212ac, 275 requests, 8 shops, 18 over 300ms) to 143ms (012ee04c, 180 requests, 2 shops, 0 over 300ms).
  - ImagesController#create p95 727 to 60ms (p50 214 to 55). Per-photo work, so it holds for any shop size.
  - JobTicketsController#index p95 357 to 112, JobItems#show 204 to 141, #edit 286 to 194, Customers#show 316 to 75.
  - Caveat: most after-traffic is the demo shop (2 jobs, 2 customers); the before set includes larger shops such as shop 8. List-page gains are partly shop size. Rerun on real traffic over a day before calling the target met.
  - Cold first requests after the 15:00 deploy still ran 300 to 490ms (show 391, index 423, edit 488): attribute methods are fixed, first template compile is not.
- [x] Dead code (uncommitted): render_tr, render_linkable_tr, inline_linkable_tr and their _tr / _linkable_tr partials had no callers.

- Dropped: further boot and cold-start work (template precompiling via actionview_precompiler, signed-in warm-up, YJIT warm-up traffic). Decided 2026-11-07: too much complexity for a gain limited to the first requests after a deploy. Already in place: YJIT, jemalloc, bootsnap, eager load, schema cache trusted at boot.
- Dropped: jobs list composite index. Rolled-back dev experiment with a 6,022-item shop in a 36k-item table: count 4.3ms, first page 6.3ms with today's indexes (Postgres walks index_job_items_on_job_ticket_id backwards and stops at 15); job_items (repair_shop_id, job_ticket_id DESC, id) only took the page to 3.4ms. The 35-83ms prod counts were cold starts and contention, not the plan.
- Connection pooling: no change needed. Active Record pools Postgres (first query about 1ms, no reconnects); an external pooler like PgBouncer would break prepared statements and advisory locks for no gain on one process. The AWS SDK pools Spaces connections, and Spaces is off the request path since the photo skip.

- [x] Real traffic check, 2026-11-07 17:25 (PostHog http_request, warm only, demo shop 32 excluded). Before 61212ac: 262 requests, 7 shops, p50 70, p95 374, p99 729, 6.9% over 300ms. After 012ee04c: 834 requests, 5 shops (8, 10, 16, 27, 54), p50 54, p95 130, p99 215, 1 request over 300ms (0.1%). Every route under 300ms p95; slowest is CustomersController#create at 290 (8 requests). Target met on this sample. Recheck on a weekday with more shops.

## Next: investigate Dashboard::CustomersController#create

- Slowest route after the deploy: p95 290ms, max 400ms (8 warm requests, 012ee04c). Before: p95 513ms, max 575ms (4 requests). Only route near the 300ms line; Vancouver adds about 65ms on top.
- Plan: pull the slow traces (AppSignal keeps every request over 0.5s, PostHog http_request has every request), break down where the time goes (validations, phone parsing, uniqueness checks, callbacks, mailers or jobs enqueued inline, the redirect target), read the create path, find the cause, fix, measure again.

### Findings so far (2026-11-07)

- Cause found in the slowest trace (f677ce66, 582ms, 61212ac): SendEmailConsentConfirmationService sends CustomersMailer#email_consent_confirmation with deliver_now during the request. Building the email took 42ms and the Resend API call 175ms, about 217ms total, only when staff tick email consent. That explains why create is usually 57-94ms but sometimes 290-580ms. Also in that trace: three consent transactions about 40ms, the assign_to_new_job turbo stream 36ms (32ms in _choose_customer_dropdown), and about 250ms unattributed (Ruby, GC, contention; pre-deploy).
- Same service runs from ApplyCustomerConsentChangesService, called by Dashboard::CustomersController#create, Dashboard::Customers::NotificationSettingsController and Portal::SettingsController, so all three pay it.
- Fix option: move the send to a job like CustomerNotificationEmailDeliveryJob, record CONFIRMATION_SENT only after a successful send. Cost: staff lose the immediate "Email confirmation could not be sent" warning; failures go to retries and monitoring instead. Decision pending.

### Plan: consent email in a job, with a live broadcast for the result

- Move SendEmailConsentConfirmationService's send into a job (pattern: CustomerNotificationEmailDeliveryJob). The request returns straight away; the job sends, retries on Resend errors, and writes CONFIRMATION_SENT only after a successful send.
- Replace the lost on-screen warning with a Turbo Stream broadcast from the job: on success or final failure, push a toast (or update a consent status badge) to the customer page and the staff member who triggered it. Covers all three callers: dashboard customer create, notification settings, portal settings (portal: probably just the customer's own page, decide whether customers should see delivery failures at all).
- Action Cable is not production-ready today. config/cable.yml uses the redis adapter with REDIS_URL, which render.yaml never sets, so production would fall back to redis://localhost:6379 and fail. No turbo_stream_from or broadcasts exist anywhere in the app yet. Options:
  - solid_cable (Rails 8 default, Postgres-backed, matches solid_queue and solid_cache already in use, no new Render service). Likely choice.
  - Redis: the only Render Key Value is the free rack-attack cache with allkeys-lru; pub/sub would work but mixes concerns and the free plan has no persistence guarantees.
- Also check: WebSocket support through Render's edge and Cloudflare (should work), Hotwire Native app behaviour on reconnect, the hotwire-conventions skill's rules for broadcasts and refreshes, and scoping stream names per shop and per team member so one shop never receives another's events.

#### Reference: Belly's Action Cable setup (copy this)

Belly runs Action Cable in production on solid_cable, no Redis.

- Gem: `gem "solid_cable"` (4.1.0 in Belly's lockfile).
- config/cable.yml: `adapter: solid_cable`, `connects_to: {database: {writing: cable}}`, `polling_interval: 0.1.seconds`, `message_retention: 1.day` in development, production and staging; `adapter: test` in test.
- config/database.yml: a `cable` entry under each environment (`<<: *primary_production`, `min_connections: 0`, `migrations_paths: db/cable_migrate`). In production it has no database name of its own, so the table lives in the primary database; development uses a separate `<app>_development_cable` database. Workbench's queue uses a separate production database (workbench_production_queue), so decide which pattern to follow.
- Schema: db/cable_migrate/20260425000003_create_solid_cable_messages.rb and db/cable_schema.rb.
- config/routes.rb: `mount ActionCable.server => "/cable"`.
- app/channels/application_cable/connection.rb: `identified_by :current_user`, `find_verified_user` reads the session cookie (`Session.from_cookie(cookies)`) and calls `reject_unauthorized_connection` when there is none. Workbench needs the same for team members, plus a separate path for portal customers if the portal gets broadcasts.
- Development: development.rb wraps ActionCable.server.config.logger in SilenceHotwireSparkCableLogger to keep cable chatter out of the log.
- Subscribing: `turbo_stream_from record` or `turbo_stream_from [current_space, :grocery_list]` (scoped to the tenant). Workbench equivalent: `[current_repair_shop, ...]` or the customer record.
- Broadcasting from a job: app/jobs/concerns/broadcasts_recipe_hero.rb calls `recipe.broadcast_replace_to(recipe, target: dom_id(recipe, :hero), partial: ..., locals: ...)`, sets `ActiveStorage::Current.url_options` from AppSettings because jobs have no request, and rescues any broadcast error into a `Studio::Monitoring::Events.warn("..._broadcast_failed")` so a failed broadcast never fails the job. bulk_import_job.rb does the same with `broadcast_replace_to(bulk_import, partial: ...)`.
- Broadcasting from a controller: `Turbo::StreamsChannel.broadcast_refresh_later_to(current_space, :grocery_list)` for page refreshes across a tenant's open tabs.
- For the consent email: the job broadcasts a replace of a consent status target (for example `dom_id(customer, :email_consent)`) on the customer stream, rescued the same way.
- Done locally (uncommitted, 2026-11-07): solid_cable 4.1.0, cable.yml solid_cable in dev and prod, separate cable database like queue and cache (workbench_development_cable, workbench_production_cable, created by db:prepare in bin/studio release), db/cable_schema.rb, ApplicationCable::Connection identifies current_team_member from the session cookie and rejects missing or expired sessions. Portal customers have no cable connection yet. /cable is auto-mounted by Rails.
- Decided (2026-11-07): follow the Rails default and do not close cable connections when a session ends (no remote_connections disconnect on logout). The connection checks the session only at connect; open sockets drop on every deploy and re-auth then. Learnings from Belly to apply with the first broadcast: AppSignal ignore_actions for Turbo::StreamsChannel#subscribed/#unsubscribed, ApplicationCable::Connection#connect/#disconnect and Turbo::Streams::BroadcastStreamJob#perform; wrap model broadcasts in ActiveRecord.after_all_transactions_commit; optionally silence hotwire-spark cable chatter in dev.
- This would be the app's first broadcast, so it sets the pattern for later live updates (for example job status changes across team members).

### Built (2026-11-07, uncommitted): consent email job and live badge

- EmailConsentConfirmationDeliveryJob replaces SendEmailConsentConfirmationService. ApplyCustomerConsentChangesService enqueues it; the request no longer pays the ~217ms. Retries 5 times (polynomial); on final failure records a new confirmation_failed consent event. limits_concurrency per customer, discard on conflict. Skips revoked consent and already-sent.
- Staff see a status line under the notification pills on the customer details card: "Confirmation email sent" or "Couldn't send the confirmation email", drawn from the latest confirmation outcome event, updated live over turbo_stream_from [customer, :email_confirmation_status]. Portal customers no longer see a delivery failure.
- AppSignal ignores cable subscribe/unsubscribe/connect/disconnect.
- Trap: solid_cable 4.1 writes broadcasts from a background thread; a one-off `bin/rails runner` exits before flushing. Long-running job workers are fine. Dev bin/jobs must be restarted after adding the gem.
- Ships after the held group (needs solid_cable).

### Investigate later: why the consent email was built synchronous

- Added in d6cf869e (2026-05-02, "customer consent: send email confirmation on grant and add public unsubscribe link"). The commit says the service "delivers via CustomersMailer inline" and the feature "mirrors the SMS confirmation flow", but gives no reason for inline delivery.
- It is the only customer-facing email sent with deliver_now. Every other app email uses deliver_later or a delivery job: email verification, password resets, team invitations, portal magic links, email address changes, new-registration reports, customer notifications (CustomerNotificationEmailDeliveryJob), intake summaries (IntakeSummaryEmailDeliveryJob), SMS (SmsDeliveryJob).
- The other deliver_now calls are internal only: Houston magic link (Houston::SessionsController) and InternalStaffUser#report_new_internal_staff_user.
- Questions: was the synchronous Failure result (shown to staff as a warning) the reason, or was it copied from an early prototype? Does anything rely on CONFIRMATION_SENT being written in the same request? Should the studio background-jobs convention say customer-facing mail never sends inline?

## Measurement caveat

AppSignal keeps only 25% of fast requests: RequestSampling moves anything under 0.5s that isn't an error into the ignored `sampled_out` namespace. Slow requests are always kept, so AppSignal's per-action p95 and counts are biased high and low respectively. For the 300ms p95 target, measure from PostHog `http_request` logs (every request, `duration` attribute), not AppSignal.

## Rails template drift

On Rails 8.1.4.1 with `load_defaults 8.1`, so framework defaults are current. Generated files never get updated by load_defaults. Diff against a fresh 8.1 app:

- production.rb lacked `public_file_server.headers` (fixed above).
- Missing `config.silence_healthcheck_path = "/up"` (Render health checks fill the logs).
- Missing `config.active_record.attributes_for_inspect = [:id]` (keeps record attributes out of inspect output in production logs and errors).
- Development lacks `query_log_tags_enabled`, `verbose_enqueue_logs`, `verbose_redirect_logs` (dev ergonomics only).
- Missing `bin/rubocop` binstub (repo uses standardrb, ignore).
- Fresh template ships `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]`; ours always runs it in production. Same behaviour, noted for the contention item.

## Infra

1. Asset caching
   - Fingerprinted assets go out with no `cache-control` header. `config/environments/production.rb` predates the Rails default `config.public_file_server.headers`.
   - Fix: add `{"cache-control" => "public, max-age=#{1.year.to_i}, immutable"}`. Tradeoff: favicon, apple-touch icons and robots.txt get the same 1-year header.
   - Then turn on Render Edge Caching (service Settings, "common static files"). Free on paid plans, purges on every deploy. `app.useworkbench.ca` is a DNS-only CNAME to Render, so Render's edge is what serves users.
2. Image CDN
   - imgproxy at `images.itsusstudio.com` (shared studio service, proxied by our Cloudflare zone) already sends `cache-control: max-age=31536000, public`, but Cloudflare answers `DYNAMIC`. URLs end in `@jpeg`, not a cacheable extension.
   - Fix: Cloudflare Cache Rule on `images.itsusstudio.com`, eligible for cache, respect origin TTL. Free plan. Safe: URLs are signed and name their format. Belly benefits too.
   - Later: try `@webp` (about 30% smaller), check jewellery photo quality first.
3. Cold starts after deploys
   - First request per page after a deploy is 2-5x slower (1031ms jobs index, 556ms details step). No `db/schema_cache.yml`, SCHEMA queries at request time, boot warm-up in `config/puma.rb` only hits `/login`.
   - Fix: ship a schema cache dump in the image, warm one signed-in dashboard page at boot. Measure before and after.
4. Contention
   - One Puma process (`WEB_CONCURRENCY: 0`), 3 threads, solid_queue plugin on the same box. Small spans inflate about 10x in some traces (cache_increment 16ms against ~1ms).
   - Watch after the other fixes. If it persists, consider moving solid_queue to its own worker (costs money, so only if needed).
5. Ruled out: Render Oregon, Spaces SFO3 (both hurt Montreal), Cloudflare Argo (paid).

## Server

1. Signup (600-1200ms)
   - Two bcrypt hashes per signup: `Registration` has_secure_password, then `validate_as_prospective_team_member` (`app/models/registration.rb:58`) builds a TeamMember with `password:`. ~225ms each on Render (152ms locally).
   - `valid_email_2` `disposable: true` on TeamMember does a DNS MX lookup (5s timeout) inside the save transaction.
   - Fix: `disposable_domain: true` (list only, no DNS). Hash once by giving the probe TeamMember the digest and keeping password rules (length, not_pwned) on Registration.
   - Expected ~250-300ms after. Do not lower bcrypt cost.
2. Jobs index search
   - `app/queries/job_items_search.rb:72` description branch is a plain ILIKE with no trigram index. The phone branch has none either. The 4-way UNION runs twice per request (count and load). Shop 8 search: ~190ms of SQL for 1 row.
   - Fix: GIN `lower(description) gin_trgm_ops` index (concurrently) and switch the branch to `lower().matches`, like the name and identifier branches. Optional phone index. Needs a migration, so approval.
   - Unverified without a prod plan. Trigram does not help patterns under 3 characters.
3. Jobs index default sort
   - `ordered_by_newest_ticket` filters on job_items.repair_shop_id and sorts on job_tickets.id, so Postgres sorts the whole shop. Candidate composite index on job_tickets (repair_shop_id, id) or job_items (repair_shop_id, job_ticket_id).
   - Needs a plan on realistic data first. Dev has ~22 items per shop.
4. N+1 cleanups (5-15ms total)
   - `_multi_team_member_checkboxes`: `.empty?` on an unloaded relation runs EXISTS then load. Pass the controller's `@active_team_members`.
   - Jobs index: preload `job_ticket: [{customer: :repair_shop}, :job_items]` to clear the per-row RepairShop lookups.
   - `JobItem#form_fields_from_stored_values` -> `typed_value` loads each form_field_definition separately. Preload or assign the known definition.
5. Not doing: row fragment or collection caching. Rows depend on Date.current, user timezone, locale and associations with no touch chain, and house rules require Studio::Cache with a killswitch. Moving `identify` to a job: would attach photos with an unchecked type.

## Frontend

1. Turbo prefetch on job rows
   - Turbo 8.0.23 prefetches links on hover by default, but job rows navigate with `Turbo.visit` from a `<tr>` click (`app/javascript/controllers/data_table/filters_controller.js:31`). The main list-to-item click never prefetches and rows are not keyboard reachable.
   - Fix: a real `<a>` stretched over each row, checkbox and actions menu layered above. Confirm the job item show page has no side effects on GET first.
2. Upload round trips: skip. Folding the attach into the direct upload saves ~65ms of ~700ms and risks attachments pointing at missing objects.

## Follow-ups

- AppSignal traces lost the repair shop, team member and locale tags since the 12:11 deploy (b427409). Fix so slow requests can be traced to a shop again.
- Unexplained ~140ms inside the photo attach lock in trace de49d3c6 (only ~25ms of it is SQL). Watch once the skip is deployed.
- Re-measure ImagesController#create p95 after the skip ships.

## Order

1. Asset header + Render edge caching
2. Signup fixes
3. Cloudflare image cache rule
4. Description and phone trigram indexes (approval)
5. Schema cache + warm-up
6. Row links for prefetch
7. N+1 cleanups
8. Trace tags

## Next stream (2026-11-08): what the user waits for, not just server time

Measured after everything shipped:
- Server p95 is in budget: 144ms on a2cdface (513 requests), p99 420ms. Demo shop 32 (bigger data) jobs index: 230ms warm, 492ms first after deploy (view 136-307ms).
- Real users (PostHog $web_vitals, 7 days, full page loads only): FCP p75 Surrey 960ms, Kelowna 674ms, Montreal 924ms, Richmond 660ms, Burnaby 276ms. Intake additional_items_step FCP 2976ms. Job item page INP max 7136ms, Montreal INP p75 5472ms.
- Network floor from Ontario: /up ttfb 115-145ms on a warm connection (TLS ~30ms, then ~70-90ms through Cloudflare YUL -> Render Ohio for a 1ms endpoint).
- Browser: every page preloads 95 importmap modules, ~9MB decoded JS. heic-to 6.3MB, Chart.bundle 840KB, zxcvbn 800KB, trix 514KB, sortable 117KB, plus js.stripe.com 1.1MB on every page because checkout_controller imports @stripe/stripe-js (side-effect script injection) and controllers are eager-loaded. application.js imports chartkick, Chart.bundle, trix and actiontext globally.

Work, in order:
1. JS payload: preload: false on heavy pins; dynamic import() for heic-to + browser-image-compression (normalize_image), zxcvbn, Chart/chartkick, sortable; stripe via dynamic import or @stripe/stripe-js/pure only in checkout; trix/actiontext only where an editor renders. Consider lazyLoadControllersFrom. Measure FCP before/after with $web_vitals.
2. INP on job item page: HEIC conversion likely runs on the main thread (heic-to) during photo add. Move to a Web Worker or yield; confirm with a replay.
3. Jobs index for bigger shops: view render 136-307ms on demo shop; profile the row partials.
4. Network overhead (~70-90ms edge->origin for a trivial request): check Thruster/Render proxy, keep-alive, Early Hints; mostly fixed cost of Ohio.

## Slow pages to investigate, one by one (list started 2026-11-08)

Source: PostHog request logs. "Real shops" = since a2cdface (2026-11-07 20:08), demo shop 32 excluded. "Demo shop" = shop 32, last 7 days; it has more data than any customer, so it shows where bigger shops are heading, but its numbers include cold first requests after deploys and our own test traffic. Columns: p95 total, then the p95 split where it points somewhere.

| # | Page | Real shops p95 | Demo shop p95 | First lead | Status |
|---|---|---|---|---|---|
| 1 | Public::SignupsController#create | 740ms | - | Traces: warm signup 280ms = bcrypt ~228ms + HIBP 17ms + SQL; the 834ms one was the first signup after a deploy, 579ms loading valid_email2's 178,700-domain disposable list on first use (121ms locally). Fix: removed valid_email2 entirely (only use was the disposable-domain check on signup; the list is 15MB per web process; email codes will prove the address anyway; watch signup domains for trial abuse). bcrypt cost left at the default on purpose. | fixed, 5f306fc8 (unpushed) |
| 2 | Dashboard::CustomersController#show | 108ms | 745ms | The 745ms was the OOM night (trace 80e792a9: a PK lookup 100ms, Redis 94ms). After 2026-11-08 01:30 the demo shop is 104ms p95. | closed, incident noise |
| 3 | Dashboard::OverviewController#index | 145ms | 760ms | view 170ms, db 102ms on demo data: chart and counter queries over all tickets | open |
| 4 | Dashboard::CustomersController#index | 135ms | 576ms | view 410ms on demo data: row rendering | open |
| 5 | Dashboard::JobTicketsController#index | 172ms | 445ms | stackprof (15 rows, test env): PhoneNumber.parse via Phonelib was 22% of the request, re-parsing each row's customer phone. Fix: per-process memo in PhoneNumber.parse (Concurrent::Map, 2,000 entries, cleared when full). 41ms -> 27ms locally (60f543fe, unpushed). Not via studio-cache: Rails.cache is Solid Cache in Postgres, a lookup costs as much as the parse. Re-measure in prod; customers list should gain too (phone on every row). | fixed, 60f543fe (unpushed) |
| 6 | Portal::SharedLinksController#show | 289ms | - | Slow views were each the first portal link view after a deploy (cold template, ~215ms view); warm 30-90ms. Warm-up now visits the staff shop's newest active shared link. | fixed, warm-up |
| 7 | Dashboard::CombinedPrintOutsController#new | 381ms (7-day) | - | ~160ms Ruby was mostly the portal QR as a ChunkyPNG PNG; slowest trace was a post-deploy cold start. Fixed b7fe4666 (SVG, level M, path): local ~100->75ms. Paginator cost is the needed items preload. Re-measure after push. | fixed, b7fe4666 |
| 8 | Dashboard::CustomerPrintOutsController#new | 278ms (7-day) | - | mixed | open |
| 9 | Dashboard::JobItems::ImagesController#destroy | 204ms | 204ms | db 166ms: purge or reorder queries | open |
| 10 | Dashboard::JobTicketsController#show | 182ms | - | other 75ms, view 71ms | open |
| 11 | Dashboard::CustomersController#create | 452ms (7-day) | - | consent email moved to a job in 5b0acfce/07c3665b; re-measure before touching | re-measure |
| 12 | Dashboard::JobItems::ImagesController#create | 417ms (7-day) | 151ms | identify skip shipped; VerifyImageBytesJob added after attach; re-measure | re-measure |
| 13 | Dashboard job item page, interaction delay | - | - | Worst INP was the internal staff shop (terms editor save). The one real case (Surrey, Safari Mac) was a tap during a full load where Safari spent ~4s processing a 75KB page with everything cached; not server, network, deploy or Fernand. Device-side, cause unknown; asking the shop about Mac/extensions. See #13 section. | closed, watch INP chart |

Method per page: pull the slowest traces, reproduce in dev on demo-sized data (DemoAccountSeeder), split SQL/view/other, fix, re-measure with the same query.

## Frontend weight, round 2 (2026-11-08, committed d01cc8f2, 787305a8)

- Brotli is already served on HTML and assets (edge compression, about the same size as gzip). Fingerprinted assets carry `max-age=1 year, immutable`.
- heic-to is now a lazy fallback (d01cc8f2, 787305a8): upload input accepts `image/*` so iOS hands over JPEG and Safari decodes HEIC itself; only when compression fails on a HEIC (Chrome, Edge, Firefox) does heic-to load, from jsdelivr's 3.2MB dist build (was a 6.4MB jspm copy). Verified in Chrome: 5MB HEIC -> 164KB JPEG. Needs a real iPad camera check after deploy.
- zxcvbn (820KB, 397KB gz) replaced by @zxcvbn-ts/core + language-common (493KB, ~240KB gz). zxcvbn's English-only warning text is gone from the hint; bars, label, user-input warning and length hint stay. TODO in Authentication: move to 6-digit email codes as the studio pattern.
- Vendored minified builds: Chart.js 4.6.1 UMD min + date-fns adapter (260KB vs 860KB Chart.bundle), Trix 2.1.19 esm min (208KB vs 526KB), Sortable +esm (46KB vs 119KB from jsdelivr at runtime), Popper +esm (21KB, was a multi-file waterfall from ga.jspm.io on every page).
- Removed the unused stimulus-dropdown pin (preloaded from ga.jspm.io on every page, imported nowhere). Every page now loads JavaScript from our own origin only.
- Speculation Rules: skipped for now (user decision).

## Cache taxonomy and studio-cache stores (done 2026-11-09: toolshed 171b5c9 pushed, Workbench 60f543fe, Belly f38d330, jean-claude 26ccd13 + 7f16412)

Rule: cache only where a lookup costs much less than the work, and pick the layer whose wipe rule matches how stale the value can be.

Name layers by where the value lives:

| Layer | Today | Shared by | Wiped by | Lookup cost |
|---|---|---|---|---|
| object | `@ivar \|\|=` | one object | object discarded (end of request) | ns |
| request | `Current.*`, Rails per-request local cache | one request | end of request | ns |
| process | `Concurrent::Map` constant, `MemoryStore` | one Puma process | deploy or restart | µs |
| rails_cache | `Rails.cache` (Solid Cache in Postgres in Workbench, Redis elsewhere) | all processes and servers | expiry, delete, version bump | ~1-2ms round trip |
| edge | `Cache-Control` + Cloudflare / Render edge | everyone near that edge location | expiry, purge, deploy | near the user |
| browser | `Cache-Control: immutable` on fingerprinted assets | one person's browser | digest change | none |
| next_click | Turbo hover prefetch | one tab | the click, or ~10s | none on click |

studio-cache todo (toolshed, gems/studio-cache):
- Add `store :process | :rails_cache | :process_then_rails_cache` (default `:rails_cache`, today's behaviour). `:process` is a per-class `ActiveSupport::Cache::MemoryStore` (LRU by `size:`, thread-safe, supports `expires_in`/`skip_nil`); `:process_then_rails_cache` reads memory first with its own short `memory_expires_in`.
- Memory stores reuse the killswitch result for ~30s per process, otherwise every fetch does a Flipper lookup (one per table row; no memoizer in jobs).
- README: `delete` on a `:process` store clears only the current process; use it for values that can't go stale or have a short expiry. State the cost rule above.
- Tests per store: hit, miss, expiry, killed, tenant keys apart.
- Someone had uncommitted edits in toolshed `gems/studio-cache/lib/studio/cache.rb` on 2026-11-09; find the owner first.
- Then in Workbench: add `gem "studio-cache"`, `app/caches/phone_number_parse_cache.rb` with `store :process`, flag `killswitch_phone_number_parse_cache`, replace the memo in `PhoneNumber.parse`, re-run the jobs index profile (expect ~27ms).
- Caching skill (jean-claude studio-developer/caching): open with the layer table and the cost rule.

Examples from this session: phone memo = process; asset cache-control = browser (+ edge once Render caches); imgproxy behind the Cloudflare cache rule = edge; jobs and customers row prefetch = next_click.

## Boot warm-up (2026-11-09, committed 81ef4257, 0cd333ea, fcf11676)

- Old `after_booted` hit /login only, and /up answered 200 before it ran, so Render routed users to a cold process anyway.
- New: `BootWarmup` runs from `Rails.application.server` (before Puma binds). /up answers 503 until it finishes, capped at 90s. It renders login, portal login, overview, job tickets, customers, newest job item and customer, 3 threads x 3 rounds, signed in as the internal staff shop owner through a real Session row created at boot and deleted after (normal signed-cookie path; Authentication untouched, per review: an env-key sign-in was a backdoor-shaped surface). No writes, no analytics identify, dropped from AppSignal and request logs.
- Logs `boot_warmup` with `first_round_max_ms` vs `last_round_max_ms` per deploy.
- Dropped `RUBY_YJIT_ENABLE` (Rails 8.1 enables YJIT after boot).
- `min_connections` = RAILS_MAX_THREADS: idle connections otherwise close after 5 min. Required renaming `pool:` to `max_connections:` (Rails 8.1 refuses both).
- Lives in lib/boot_warmup.rb (infra, not domain); added config.autoload_lib.
- Measure: PostHog insight BzpBIW4n "Cold start after each deploy" on dashboard 2318869 (first 10 requests p95 per boot vs warm-up rounds). Baseline 460-950ms cold, 96-146ms warm.
- Local test (2026-11-09, dev env with YJIT, fresh process each run, two runs each): first signed-in request without warm-up: overview 552-633ms, job tickets 240-275ms, job item 261-264ms. After warm-up (about 5s): overview 52-61ms, job tickets 54-55ms, job item 63-143ms. Local dev is slower than prod overall; the gap is the point.
- Bug found by the local test: Rack::MockRequest.env_for doesn't set HTTP_HOST, so any app with config.hosts set got 403 on every warm-up request. Fixed by setting HTTP_HOST from the URL. Tests missed it because the test env has no host list.

## #13 job item INP (2026-11-09)

- Worst INP (7.1s, 5.5s) is tenant 32, the internal staff shop: Save on the terms editor (#edit_policy), handler 8ms, next paint 5.4s. Internal, low priority.
- Real customer (tenant 10, Surrey, Safari Mac): INP 3.6s was a tap while the page was still loading (inputDelay 3.5s). That session's full loads painted at 3-4.3s while the server answered in ~88ms. Safari FCP p90 3.0s vs other browsers 1.2s (web vitals only exist since 2026-11-07).
- Fernand theory tested and NOT the cause: Playwright WebKit (Docker image mcr.microsoft.com/playwright:v1.62.1-noble) on the real dev job item page with Fernand's onload.min.css delayed 3s: FCP 241-519ms, same as with Fernand blocked. WebKit only holds first paint for a script-inserted stylesheet when it is inserted before first paint (synthetic page: 3007ms); Fernand's deferred script runs after.
- Still unknown what the 3-4s is. Next: that session's replay network timings.
- Replay network waterfall (session 01a1c127, 12:17:08 load of /dashboard/job_items/62938, Safari Mac): first byte 183ms, response 1ms, every JS/CSS from browser cache (0-1ms), then "document processing" 5.63s; DOM interactive 4.21s. HTML is only ~75KB and ~470 elements (checked on prod demo). The same page in Playwright WebKit reaches DCL in 250-530ms. So the 4s is that customer's browser main thread on some full loads, not our server, network, assets or Fernand. No app-side fix identified; leave #13 as watch-only on the INP chart unless more shops show it.

## Boot warm-up in prod (2026-11-09 14:01 deploy a165a70)

- Ran: 63 requests in 4.3s, slowest page 735ms first round -> 260ms last round.
- Bug: it picked shop 14's owner (staff plan, ends_at in the past), so the 5 signed-in pages rendered the subscription wall and logged 45 subscription_ended_redirect warns, firing the PostHog "Warning spike" alert. Fix (uncommitted): RepairShop.with_active_staff_subscription (ends_at in the future) and boot_warmup success/failures now count anything but 200.
- Post-deploy round trips from Chrome on the prod demo: overview 156-212ms, job tickets 131-168ms, job item 120-136ms (network included); full load TTFB 86ms, FCP 564ms.
- #7 combined print-out: ~160ms of non-SQL, non-view time in the action. Portal QR is a 480px PNG via ChunkyPNG: 26ms locally vs 12ms for SVG; not the whole gap, keep digging.
- #7 fix (uncommitted 2026-11-09): portal QR drawn as SVG through QrCode (was a 480px ChunkyPNG data URI, 28ms), QrCode uses level M and one SVG path (68KB -> 2KB per code). Local warm combined print-out median ~100ms -> ~75ms; QR share 26% -> 11%. Both codes decoded with jsQR. Next lever: CustomerPrintOut::Paginator ~12%.

## Status 2026-11-09 evening

- Unpushed: 0cd333ea (warm-up picks an active staff shop), b7fe4666 (tracking QR as SVG), fcf11676 (warm-up visits the portal shared link).
- Re-measure tomorrow (2026-11-10), after a day of warm-up: #11 customer create (p95 356, p50 75), #12 photo upload (p95 378, p50 61), #7 combined print-out, #8 customer print-out (278), #6 shared link. Use the "Cold start after each deploy" chart and the slowest-routes query.
- Next: #9 photo delete (db 166ms).
- #9 photo delete: slow trace was the first job enqueue after a deploy (queue DB connect + Solid Queue schema, 227ms). Warm-up now loads every model's schema (54894819). Footguns listed at the top of lib/boot_warmup.rb; test fails on any warm-up write but its session (guard proven to catch a GET write).
- Later: extract the generic warm-up into a toolshed gem and adopt in Belly (same single-instance Render + /up setup), after the 2026-11-10 re-measure.
