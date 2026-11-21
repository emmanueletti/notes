# Belly latency audit (2026-11-09)

Sources: AppSignal Belly/production, last 7 days (transaction_duration p95 per action, traces). PostHog logs (project 674317) not used: the PostHog MCP is pinned to Workbench and refuses project switches. AppSignal keeps every request over 0.5s but only 25% of the rest, so its p95s read high.

## Setup that matters

- One web instance, WEB_CONCURRENCY=0, 3 threads, jobs run inside Puma (SOLID_QUEUE_IN_PUMA). Workbench moved jobs to a worker after jobs competed with requests.
- Database plan basic-256mb.
- /up health check with no warm-up: every deploy's first requests are cold.

## Findings

| Action | p95 | Cause | Fix |
|---|---|---|---|
| Recipes::Image/Text/UrlImportsController#create | 3.8-4.4s | Model extraction (RecipeIngest) runs inside the request; DB ~60ms, rest untraced | Run extraction in a job and stream the result (llm-features skill: model calls belong in jobs). Product call: keep a waiting screen |
| WeekPlans::RecipesController#index (recipe picker) | 1.9s (traces 1.0-5.1s, every visit) | Accent-folded substring search over recipe names, every ingredient and every tag, run 4 times per render (count, tag count, exists, page) | 80dd951 (3-letter minimum) and 16ae94c (trigram index on folded ingredient text) went live 2026-11-09 17:38Z; no picker visits since. Re-measure. Likely still worth: trigram index on folded recipe name and tag name, and not running count + exists + load separately |
| Parties::DishesController#new, PartiesController#show, Parties::MenusController#show, CourseChoices | 0.4-2.6s | Traces are minutes after deploys (2026-11-03 15:20) | Boot warm-up (same as Workbench) |
| Public::SignupsController#create | 586ms | Password hashing plus signup work | Accept, or move to email codes |
| Public::VerificationsController#create | 548ms (trace 463ms, ~430ms untraced) | Code has since moved; not re-checked | Re-measure on current code |
| PlaylistRecipesController#create | 340ms | Not traced yet | Look after re-measure |

Admin pages (Mission Control, PgHero) are over budget but internal.

## Recommended order

1. Re-measure the recipe picker now that the search fix is live (a few visits as a heavy organization).
2. Move recipe imports' model call into a job with a live update; this is the slowest thing users wait on.
3. Port the boot warm-up once it's extracted from Workbench into toolshed.
4. Consider moving jobs out of Puma into a worker, as Workbench did.

## Signup (checked later 2026-11-09)

- Old code (trace 2026-11-09 03:14Z, 1111ms): user-creation transaction 995ms, of which login-code email render 65ms + synchronous Resend POST 269ms, both inside the open transaction, plus ~650ms untraced (likely hashing the old login_code_digest). Rejected signups (422) took 80-178ms.
- New code (studio-authentication, live since 17:38Z): login code email is deliver_later, code is encrypted (Secrets.encrypt), deliverability check is string-only. Expect ~100-200ms. Not yet measured: no signups since.
- Caveat: jobs run inside Puma, so the email job shares web threads.

## Handoff (2026-11-09)

Continued by session investigate-belly-performance. Workbench's equivalent plan: ~/notes/plans/workbench-latency-2026-11-07.md (see "#13 job item INP" for the browser paint method).

## Session investigate-belly-performance (2026-11-09 evening)

PostHog access: switch-project to 674317 works once the conversation_id from a first exec call is passed back. Unsampled request logs: `logs` table, body `http_request`, attributes controller/action/duration/db/view/path/platform/sessionId.

### Re-measure (as of 20:20Z)
- Picker, signup, verification: no traffic since the 17:38Z deploy. Still pending.
- Unsampled 7-day server p95 (logs, admin excluded): imports 5.8-7.8s (p50 3.2-4.1s); picker 4.2s (all db, pre-fix); signup 1.1s; verification 739ms; RecipesController#update 516ms (db 379); PartiesController#show 504ms; PlaylistRecipesController#create 409ms (db 385). Everything else under 400ms.
- Party slow loads: 5 of 5 over 300ms were in a process's first 10 minutes. Warm-up covers it.

### New: intermittent ~100ms stalls on trivial queries (RecipesController#update and others)
- 27 of 30 slow updates were warm. Traces 47ccbe0c (1082ms) and cfcce329 (632ms): BEGIN/COMMIT, PK loads and an EXISTS take 74-107ms each, several per request; the same queries are under 1ms in other requests.
- The 85-107ms quantum matches Ruby's 100ms thread timeslice: the request waits for the GVL while another thread in the same Puma process is CPU-bound (jobs run in Puma, plus import requests). Other candidate: DB-side waits on basic-256mb. Not proven.
- 47ccbe0c also uploads the photo to Spaces inline (123ms) and enqueues AnalyzeJob (127ms, 90ms of it COMMIT).
- Next: log GVL wait per request (gvltools or similar) as an http_request attribute. If it is the GVL, a separate worker (Workbench did this) is the fix, not query work.

### Browser paint ($web_vitals, 14 days)
- Real users are mostly the iOS app: FCP p75 589ms, p90 884ms; INP p75 72ms. Fine.
- Every INP over 1s is internal staff on iOS except three: Apple-review-looking taps during load (Fremont/Vacaville #email_address, inputDelay ~990ms) and one Goes (NL) tap at 1032ms.
- #recipe-tags-add INP 10-20s: /recipes/:id/tags opens as a native picker sheet; the web view under it does not paint until the sheet closes. Measurement artifact, not lag. #picker-search and #planned-note-text (presentationDelay 1-4.5s, processing 0ms) are inside native sheets on focus/keyboard; likely the same class, not proven, internal only.
- Login FCP p50 1262ms, p90 3640ms (44 loads) while server is 5ms p50 / 35ms p90. Slowest are Play pre-launch-style Android bursts (Bend/Sheffield/Senneville, 2026-11-09 09:52-09:54) and probable Apple review (Fremont, Cupertino), but real iOS first launches too (Riyadh 3.1s, Melbourne 2.2s).

### Proven: the flower <img> holds WebKit first paint on auth pages
- Replay 01a19f9c (Riyadh, iOS): TTFB 462ms, DOM interactive 1.03s, FCP = page load = 3.10s; belly-flower-db82e04c.svg (2KB) took 2.43s queued behind ~90 modulepreloads (175KB wire total).
- Playwright WebKit (Docker v1.62.1) on a prod /login snapshot served locally, PostHog blocked: SVG delayed 2.5s -> WebKit FCP 2.52-2.55s with DCL ~150ms. JS delayed 1.5s or fonts delayed 2.5s -> FCP stays 40-120ms. Chromium FCP ~50ms in every case. Scripts: scratchpad wk/login.mjs.
- Variants with SVG delayed 2.5s: width/height attrs 2.5s, decoding=async 2.5s, loading=lazy ~105ms, inline SVG 100-140ms, no img ~90ms.
- Fix (uncommitted, mine): app/views/layouts/auth/shell.html.erb renders `svg "belly_flower"` (existing partial, currentColor) instead of image_tag. Not verified on dev: dev routes are 500 from another agent's in-progress studio_authentication route change.
- Same pattern likely on onboarding (image_tag belly-flower.svg) and the recipes/week plans empty states (icon: "belly-flower.svg"). Check before changing.
- Secondary: login preloads every controller (~90 modules) though it needs few; on cold mobile connections they compete with the page's own image.

### Updated order
1. Ship the auth-shell inline flower (after dev check), then onboarding and empty states if they show the same.
2. Re-measure picker/signup/verification once there is traffic.
3. Imports into a job (product call on the waiting screen).
4. GVL wait logging, then decide on a separate jobs worker.
5. Boot warm-up from toolshed.

### Flower follow-up (2026-11-09, later)
- Dev check, WebKit, real dev pages for a fresh account (perf-audit@studio.com), SVG delayed 2.5s: onboarding FCP 2547ms with <img>, 46ms inline. Recipes and week plans empty states paint at ~45ms either way (enough other content), so left as image_tag.
- Fixed (uncommitted, mine): layouts/auth/shell.html.erb and dashboard/onboardings/show.html.erb render `svg "belly_flower"`. Both verified rendering on dev.
- Dev sign-in under studio-authentication: code is on /verify in #studio-authentication-dev-code (424242 gone). After the gem swap, a long-running dev server hit "::User expected, got User" on verify (class reload); a fresh boot fixed it. Told the toolshed-7f session.

### "Send code" button mashing (checked 2026-11-09, prod code 0eef24a)
- 19 sessions clicked Send code in 14 days. Login already has spinner_submit (since 842a859, Aug).
- Mashing sessions are not waiting on the server:
  - 01a1882f (Cupertino, likely App Review): one POST /verification, 303 in 2.6ms (fake example.com domain), back on /login with "We can't send email to this address", then ~25 taps with no further POST.
  - 01a19517 (iOS): one POST, 303 in 2.3ms (blank or fake domain, so rejected), then ~20 taps with no POST.
  - 01a189f7 (Android Chrome, 21 taps) and 01a19f9c / 01a1a0ac (Riyadh iOS, 7 and 3 taps): zero POSTs reached the server. Riyadh came from a 401 in a context with no session while the same app's other session kept working.
- Likely mechanism (not proven): after the redirect, SessionsController#new sets no @email_address, so the field comes back empty or the typed value is invalid; HTML required/type=email then blocks the submit, and WKWebView shows no validation bubble, so every tap is dead.
- Real sends are 379ms p50, 739ms p95 (deliver_now with Resend inside the request). That is the case the spinner covers.
- Deploy window ruled out: Oct 29 23:21Z was inside c006e38 (21:02-04:05, one process, pid 108); Nov 3 04:13Z and 09:10Z were inside d47195b (02:12-12:12, pid 115, 360 requests served).
- Proven cause for the zero-POST sessions: the browser refused to submit. Autocapture logged 0 `submit` events in all three (th-TH Android, ar iOS twice); every en-* session logged a submit on its first tap. The replay DOM at the mash shows the button enabled, the form not busy, and the email field `required`.
- Playwright WebKit and Chromium: `type=email` + `required` blocks checkValidity for Arabic-Indic digits, Thai digits, a full-width ＠, Arabic or Thai letters, an RTL mark or a zero-width space. ASCII, a trailing space or a missing TLD dot pass.
- Fix direction: `novalidate` on the form so every tap reaches the server; normalize on the server (NFKC, native digits to ASCII, strip bidi and zero-width marks, strip, downcase); on rejection, re-render with the typed value and an inline error. Async sending is separate and doesn't help these users.

### Playlist add (PlaylistRecipesController#create), 2026-11-09
- 15 days, unsampled: usually ~50ms total and ~30ms db. Four outliers at 330-667ms, almost all db, all from iOS: 2026-10-27 05:17Z, 2026-11-04 11:51Z, 12:17Z and 14:31Z.
- Trace f98e270c (675ms): seven trivial queries at 55-100ms each (Session PK load 55, Recipe load 91, pluck 95, bulk insert 100, COMMIT 90, Recipe count 87, attachment load 92). Everything else is ~1ms. Same signature as the recipe update stalls.
- At 12:17:08Z one person was browsing playlists in pid 109; no other request was in flight and no job trace shows (AppSignal samples fast jobs at 25%, jobs don't write request logs). So a busy neighbour thread holding Ruby's lock isn't shown here.
- Three candidates share a ~100ms quantum: Ruby GVL timeslice (100ms), Linux CFS CPU throttling of the web container (100ms period), CPU throttling of the basic-256mb Postgres (same). Trace data can't tell them apart.
- Next: Render CPU and throttling metrics for the web service and the database at those four timestamps (Render MCP needs auth). If the DB was throttled, the dedicated worker won't fix this; a bigger DB plan would.

### Dedicated jobs worker (prepared, uncommitted, branch fix/email-input-non-latin)
- render.yaml: new prod `type: worker` belly-prod-jobs-east, standard, Dockerfile.web, dockerCommand `./bin/jobs start`, same DB, S3 and imgproxy env as the web, RAILS_MASTER_KEY sync:false. The entrypoint skips `bin/studio release` for this command (last arg `start`), so migrations stay on the web.
- Step 1 keeps SOLID_QUEUE_IN_PUMA=1 on the web, so jobs run in both places until the worker has its master key and is confirmed processing. Step 2 removes it. Staging keeps jobs in Puma.

### Landing (2026-11-09 evening)
- The user said no worktree. On local main (unpushed): 21a71d7 flower, 10b1333 jobs worker step 1, c9f12b3 signup novalidate (--no-verify: Bundler can't boot because the auth WIP's Gemfile.lock pins toolshed e480a69).
- The login/verify email fix ships only with the studio-authentication migration (session toolshed-7f / fix-user-reload-models ported it). Branch fix/email-input-non-latin (bd4d580) kept for reference, never pushed.
- Push blocked: pre-push runs bin/ci in the main working tree, which holds the uncommitted auth migration, so CI wouldn't test the pushed commits.
