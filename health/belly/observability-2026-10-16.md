# Belly observability audit, 2026-10-09 16:00Z to 2026-10-16 16:00Z (vs 2026-10-02 to 2026-10-09)

First run of observability-audit (trial). Logs covered only 2026-10-15 16:27Z to 2026-10-16 16:27Z (24h log window).

## response_status (web), window vs previous
200: 148640 vs 147264
-1: 1828 vs 870
204: 24 vs 1
301: 18 vs 27
302: 253 vs 262
303: 224 vs 188
304: 446 vs 319
401: 37 vs 233
404: 885 vs 829 (only 1 404 line in 24h of request logs: unrouted 404s not logged)
406: 118 vs 354 (allow_browser: /login, /signup, /r/<share>, /.well-known/assetlinks.json)
422: 9 vs 10
429: 1 vs 0
500: 0 vs 6

## transaction_duration p95 by namespace
web: 374.5 ms vs 462.1
background: 355.0 vs 428.4
action_cable: 0.63 vs 0.57

## transaction_queue_duration p95 (window)
web 5.7 ms, background 152.8 ms

## Slowest Dashboard actions, p95 (window)
ImageImportsController#create 9504 ms
TextImportsController#create 7470
UrlImportsController#create 4398
PlanWeekImportsController#create 3017
PlanDayImportsController#create 1453
GroceryListsController#clear_completed 420
WeekPlans::RecipesController#index 407

## Exceptions
#299 ReparseIngredientsJob StatementInvalid: open, 3 occurrences, last 12:48 PM Oct 16 (fix deployed since)
#238 RecordNotFound WeekPlans::DaysController#show: closed, 3 in window, still recurring

## Alerting
1 trigger: Exception count >= 1, namespace=*, notifiers PagerDuty + Slack
Anomaly incident #247 open since 2026-08-31, unassigned
Uptime monitors: 0
Web vitals: metrics exist, no data in window
