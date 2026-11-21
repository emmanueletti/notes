# Workbench pulse

The north star and the few numbers that matter, checked weekly. Written so an agent can run it: queries, sources, and the report format.

## North star

**Weekly active shops**: paying or trial shops (not internal) that took in at least 3 jobs that week.

Why: a shop that takes in jobs every week depends on Workbench, keeps paying and tells others. Every strategy (onboarding, photo intake, referrals, search, Shopify) should move this number.

Baseline: week of 2026-11-09, 10 shops took in at least 1 job (379 jobs); week of 2026-11-16, 10 shops (374 jobs). These include internal tenants; the query below excludes them.

## Pulse (weekly)

| # | Metric | Why | Source |
| --- | --- | --- | --- |
| 1 | Weekly active shops (north star) | Shops that depend on Workbench | PostHog `intake_completed` |
| 2 | Jobs taken in | Volume through Workbench; grows with each shop's own business | PostHog `intake_completed` |
| 3 | New shops | Is distribution working | PostHog `shop_signed_up` |
| 4 | Started within 7 days | Is onboarding working (the quarter's metric, target 3 of 4) | PostHog `shop_signed_up` then `intake_completed` |
| 5 | Renewals due in 30 days | Revenue at risk, check in before each | Admin (`/admin`), `Subscription.renewing_soon` |
| 6 | Demos booked | Is the site converting buyers | PostHog `demo_booked` (not built yet) |

Monthly, not weekly: AI recommendation score (prompt set in `2026-11-21-plg-strategy.md`), cost per AI intake (once photo intake ships, PostHog `$ai_generation`), real usage per shop (texts, jobs) for pricing allowances.

## Internal tenants to exclude

32 (IT'S US STUDIO). Check 7 (Timeless Repairs) and 14 (Etti Repair Emporium), both created 2026-11-17 with almost no activity; exclude them if they're test or demo shops. Keep this list current as new internal tenants appear.

## Queries (PostHog, project 718224, HogQL)

Set `{week_start}` to the Monday of the week being reported, in America/Toronto. Each query runs against `events` with a timestamp window.

1 and 2. Active shops and jobs:

```sql
SELECT
  countIf(jobs >= 3) AS weekly_active_shops,
  sum(jobs) AS jobs_taken_in
FROM (
  SELECT properties.tenant_id AS tenant, count() AS jobs
  FROM events
  WHERE event = 'intake_completed'
    AND timestamp >= toDateTime('{week_start} 00:00:00', 'America/Toronto')
    AND timestamp < toDateTime('{week_start} 00:00:00', 'America/Toronto') + INTERVAL 7 DAY
    AND properties.tenant_id NOT IN (32)
  GROUP BY tenant
)
```

3. New shops:

```sql
SELECT count() AS new_shops
FROM events
WHERE event = 'shop_signed_up'
  AND timestamp >= toDateTime('{week_start} 00:00:00', 'America/Toronto')
  AND timestamp < toDateTime('{week_start} 00:00:00', 'America/Toronto') + INTERVAL 7 DAY
  AND properties.tenant_id NOT IN (32)
```

4. Started within 7 days, for shops that signed up 7 to 14 days before `{week_start}` (so each has had a full 7 days):

```sql
SELECT
  count() AS cohort,
  countIf(first_job IS NOT NULL AND first_job <= signed_up + INTERVAL 7 DAY) AS started_within_7_days
FROM (
  SELECT
    s.tenant AS tenant,
    s.signed_up AS signed_up,
    (SELECT min(timestamp) FROM events
      WHERE event = 'intake_completed'
        AND properties.tenant_id = s.tenant
        AND timestamp >= s.signed_up
        AND timestamp < s.signed_up + INTERVAL 8 DAY) AS first_job
  FROM (
    SELECT properties.tenant_id AS tenant, min(timestamp) AS signed_up
    FROM events
    WHERE event = 'shop_signed_up'
      AND timestamp >= toDateTime('{week_start} 00:00:00', 'America/Toronto') - INTERVAL 14 DAY
      AND timestamp < toDateTime('{week_start} 00:00:00', 'America/Toronto') - INTERVAL 7 DAY
      AND properties.tenant_id NOT IN (32)
    GROUP BY tenant
  ) AS s
)
```

If the correlated subquery is rejected, run the cohort list first, then one `intake_completed` lookup per shop.

5. Renewals: read the admin dashboard, or ask the founder. No agent access to production data.

6. Demos booked: `count()` of `demo_booked` in the week, once the event exists.

## Report format

Post weekly, Monday morning, to `~/notes/product/workbench/pulse-log.md` (append, newest first):

```
## Week of 2026-11-23

- Weekly active shops: 9 (last week 9)
- Jobs taken in: 370 (last week 374)
- New shops: 1
- Started within 7 days: 1 of 1
- Renewals due in 30 days: [from admin]
- Demos booked: not tracked yet

One line on what moved and why, if anything did.
```

Numbers only, plus one line of interpretation. No charts, no commentary beyond that line.

## Rules

- Exclude internal tenants every time.
- Compare with last week, not with targets, in the log. Targets live in `2026-11-21-90-day-priorities.md`.
- Two weeks of data is noise; call a trend only after 4 weeks.
- If an event is missing or renamed, say so in the report instead of guessing.
