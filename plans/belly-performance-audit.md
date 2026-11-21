# Belly performance audit

## 2026-11-16 baseline (14 days, PostHog logs + $web_vitals, AppSignal traces)

Server: p50 ~30ms, daily p95 200-300ms. Spikes on Nov 5 and Nov 8 came from the week-plan picker search.
Browser (non-internal): FCP p75 0.3-0.7s on dashboard pages; /login FCP p75 1.24s, p90 2.9s; /dashboard/recipes/url_import/new FCP p75 0.97s. INP p75 under 100ms except /signup and /dashboard/onboarding (~345ms, small n).

Findings
1. Dashboard::WeekPlans::RecipesController#index with q: db p50 2.6s, max 5s (unfiltered: ~30ms). Trace 140ac2c2 (Nov 15): 4 queries carry Recipe.search_name at 600-800ms each (Recipe Count 790, RecipeTag Count 599, Recipe Exists? 699, Recipe Load 698). The same search on Dashboard::RecipesController#index for the same tenant: ~29ms. Mostly tenant 2 (internal), also tenant 7.
   - Suspect: ingredient trigram subquery plan picks a global GIN scan for common words (butter, chicken, spaghetti).
   - Needs EXPLAIN (ANALYZE, BUFFERS) on prod, run by the user.
   - Cheap cuts: `recipes.none?` in _picker.html.erb fires an extra Exists query; tag facet counts rerun the search on every keystroke.
2. Url/Text/ImageImportsController#create: p50 3-4s, p95 6-7s, from the LLM call inline in the request.

## 2026-11-16 follow-up: iPad cook mode, planner and main page slow (user 2)

- Server time is fine for user 2 over 14 days: WeekPlansController#index p50 68ms, RecipesController#index 50ms, CookModesController#show 26ms.
- iPad at 18:42 tonight: main page server 110ms but FCP 3.4s, planner server 69ms but FCP 2.5s. Other iPad loads had FCP 0.45-0.7s. No replay was recorded (replay is gated by the record-session-replay flag).
- Network floor: /up ttfb ~170ms through the Toronto (YYZ) edge to the Ohio origin. Every tap pays that before Ruby runs.
- JavaScript: 91 modulepreloads, ~124KB compressed, Cloudflare HIT with a one-year max-age. Not the cause.
- Cook mode Next/Previous each fetch the step from the server (turbo frame, data-turbo-prefetch="false" in cook_modes/_action_bar.html.erb:5).
- INP on iPhone for user 2 is mostly presentationDelay: ~800ms on planner meal taps, 1-2s per keystroke in week_plans/notes/new and grocery-add-input. Cause not found yet.

## 2026-11-16 ~20:40: slow recipe images (report p95, not averages)

- User 2, 14 days, server p95: recipes#show 248ms, recipes#index 261ms, week_plans#index 346ms, cook_modes#show 237ms.
- User 2 on phone, recipe page LCP p95 2.5s (n=19). The hero photo is the LCP element, so ~2.2s is spent on the image, not the server.
- images.itsusstudio.com (shared imgproxy): 160KB 800x800 JPEG with a one-year immutable max-age.
  - During the slow window, Cloudflare served it from the Newark (EWR) edge: HIT, 1-5.7s total, 0.5-1.5s to first byte.
  - Minutes later it came from Toronto (YYZ): HIT, p95 0.28-0.43s over 20 fetches.
- App assets stayed on YYZ the whole time, at 0.12-0.16s.

## Next
- Get the EXPLAIN from prod, then fix the search plan.
- Re-measure with the same PostHog query (logs, body = 'http_request', controller = Dashboard::WeekPlans::RecipesController, q length >= 3).
