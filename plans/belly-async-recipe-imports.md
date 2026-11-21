# Belly: recipe imports in a background job (plan, 2026-11-09)

Why: URL, image and text imports take 3-8s in the request (p50 3.2-4.1s), almost all of it the model call. Holds a web thread for the whole wait. Investigation by session investigate-belly-performance; file:line detail in that session's subagent report, summarised here.

## Today
- Routes config/routes.rb:56-60. UrlImportsController#create -> RecipeIngest (PageFetcher 10s, Sources::*, RecipeExtraction -> LlmGate -> AnthropicClient 60s) -> RecipeBuilder -> attach_photo / CacheImportPhotoJob -> RecipeImportEvent.record! -> log_outcome.
- Image: RecipeExtraction(:photo) on in-memory bytes; text: RecipeExtraction(:text). Rate limits 100/10/100 per day.
- Success: turbo_stream close_modal + visit edit. Referral (URL only): visit import_fallback. Other failure: 422 re-render with the unreadable copy + support prompt.
- Waiting UI: import-loading Stimulus panel on turbo:submit-start/end. Native: medium sheets (MEDIUM_SHEET_PATTERNS), text_import full modal; the edit page is pushed (MODAL_EXCEPTION_PATTERNS). Stale comment at hotwire/configurations/base_controller.rb:96-98.
- Share: iOS extension and Android intent (URL or text only, no images) open url_import/new or text_import/new with via=share; the user still taps Add.
- Not affected: approved cache hits, onboarding starter recipes, grocery imports, bulk import (already a job).

## Design
- New RecipeImport row: status, source, input (text, or blob ids uploaded to private_uploads first), platform, via, user_id, recipe_id, error_code, referral. Not LlmGeneration (subject_id NOT NULL).
- create stays synchronous for validation, rate limits and approved cache hits. Otherwise: create the row, enqueue RecipeImportJob, reply with a turbo_stream that swaps the sheet body for the same loading panel plus turbo_stream_from @import. No navigation, so native sheets stay put.
- The job does today's work and broadcasts today's exact payloads to @import: success close_modal + visit edit; referral visit import_fallback; failure replaces the sheet body with the current error markup.
- Safety net: a small Stimulus controller on the waiting panel GETs recipe_imports/:id (turbo_stream) on cable connect, on visibilitychange to visible, and every ~5s. It returns nothing while pending, else the final payload. Covers a job that beats the subscription and broadcasts missed while the app was backgrounded.
- The job needs explicit context: user_id for LlmGate, actor for analytics, platform, via, locale (I18n.with_locale like BulkImportJob), duration measured from the request.
- Idempotent (one Recipe per import row), limits_concurrency by import id, stale sweep like FailStalePartyPlansJob with a window above 60s model timeout + fetch.
- Runs on the dedicated worker (render.yaml step 1/2). Consider its own queue so 3 concurrent imports don't starve photo and Bella jobs.
- ApplicationCable::Connection auths via Session.from_cookie: re-check after the studio-authentication migration lands.

## Riskiest surface
iOS (then Android) share from Instagram/TikTok, user switches back mid-import: the socket suspends, the broadcast is lost, TabFreshness reloads the tab, not the sheet. The client re-check is what saves it; test on a real device. Also cold launch from a share, where the subscription lags a fast job.

## Test matrix
Surfaces: desktop web, mobile web, iOS app, Android app, iOS share, Android share.
Types: URL (model), URL (cache hit, sync), image (sheets only), text (sheet and share).
Outcomes: success to edit with live photo; referral to fallback (URL); unreadable error; model timeout/provider error; rate limited (sync 429); validation (sync); backgrounded <30s and >30s; job finishes before subscribe; job dies (stale sweep).
Server tests: job tests per type x outcome with assert_turbo_stream_broadcasts; controller tests for enqueue, sync paths, status endpoint; one system test for the URL green path (Mocha-stub the service). Rewrite 67 controller tests (url 33, image 19, text 15). Native backgrounding and cold-launch cases by hand in simulator and emulator.
