# Retro: Workbench outages from the image backfill

2026-11-07 into 2026-11-08 (UTC). Workbench production.

## What happened

We started a one-time image backfill in production to shrink about 20k
HEIC and oversized photos before a storage migration. The backfill ran
background jobs inside the same Render instance that serves the web app.
Those jobs decoded full-size photos in libvips, ran the 2 GB instance out
of memory, and Workbench returned 502s for every customer. It crashed
repeatedly, because each restart picked the jobs up again.

## Timeline

1. Deleted 6,977 unused variant records in the prod console. Each queued
   its own `ActiveStorage::PurgeJob`, about 7k jobs on `default`.
2. Started `NormalizeImagesJob`. It sat behind the purges, because one
   worker with 3 threads ran every queue (`queues: "*"`) in enqueue order.
   It looked stuck, and the count we watched (`todo.count`) didn't move.
3. Purges cleared, and the backfill fanned out into 20k `NormalizeBlobJob`s.
   Three conversions ran at once on 3 threads, and memory ran out.
   **Outage 1.**
4. Mission Control was down with the app (502), so we couldn't pause the
   queue from the UI. The fix options were the Render shell
   (`SolidQueue::Queue.find_by_name("low").pause`) or `JOB_CONCURRENCY=0`.
5. Shipped a global limit of 2 conversions at once. Jobs picked up before
   the limit took effect didn't count toward it, and the 2 GB instance
   still crashed. **Outages 2 to 4** (process deaths at 00:05:24, 00:05:31,
   00:06:44 and 00:06:54 UTC left 12 `ProcessPrunedError` failures).
6. Upgraded to 2 × 8 GB instances and made the limit an env var. Then
   found the real ceiling was worker threads (2 instances × 3 = 6), not
   the limit.

## What went wrong

- **We ran heavy jobs inside the web process with no memory budget.**
  solid_queue runs in Puma, so a job that uses lots of memory takes the
  web app down with it. Nobody estimated memory per job (about 0.4 to
  0.6 GB for a 48 MP HEIC with `loader(unlimited: true)`) against the
  instance (2 GB, with Puma already using about 1 GB).
- **No concurrency limit on a fan-out job.** The backfill queued 20k jobs
  with nothing capping how many ran at once. The only limit was per blob,
  which prevents duplicates, not load.
- **We didn't size the run before starting.** I said "about 9k files",
  and it was 20k, because every HEIC counted. I estimated hours of
  runtime only after it started. A dry run of `todo.count` plus one timed
  conversion would have caught both.
- **One worker pool for every queue.** `queues: "*"` meant 7k purges
  starved the backfill, and the backfill could starve emails and SMS. The
  studio `background-jobs` skill already says never `"*"` and gives a
  dedicated fast pool. Workbench doesn't follow it.
- **Our admin tool died with the thing it administers.** Mission Control
  runs in the same Puma, so during the outage there was no UI to pause the
  queue.
- **Cleanup by `purge_later` one file at a time.** 7k jobs and about 15k
  Spaces round trips for 3.6 GB, competing with the backfill.
- **Misread signals.** "Queue 0" while blocked jobs grew looked alarming
  but was normal, since blocked jobs aren't counted as queued. We lost
  time on it mid-incident.
- **Process mistakes on my side, not causes of the outage:**
  - I started a push without being told to push. The user stopped it.
  - I rewrote a commit the user had already pushed. I caught it and
    rebuilt the change as a separate commit.
  - I seeded the shared test database (`db:seed:replant` in test), which
    broke later test runs.

## What went right

- The security fixes shipped first and are unaffected.
- The narrowed backfill avoided 256k pointless re-encodes.
- Blobs are rewritten in place, so a crash mid-job leaves a photo that
  still displays (imgproxy reads the file, not the record), and a retry
  repairs it.
- The cursor-and-fan-out design meant pausing one queue stopped
  everything, with nothing lost.
- Coordinating with the other agents kept their commits safe through
  four history rebuilds.

## Lessons

1. **Before any production backfill, write down four numbers:** row
   count, time per item (measure one), memory per item, and memory left
   on the instance. Divide. If the answer is close, it doesn't run in
   Puma.
2. **Every fan-out job gets a global `limits_concurrency`**, with the
   limit from an env var, so it can be turned down without a deploy.
3. **Concurrency is the smaller of the job limit and the worker
   threads** (`processes × threads × instances`). Raise both or neither.
4. **Heavy one-off work runs where it can't take the web app down:** a
   separate worker service, a Render one-off job, or a temporary bigger
   plan scaled before starting, not after the first crash.
5. **Have a kill switch that doesn't need the app:** the Render shell
   command, or `JOB_CONCURRENCY=0`. Write it down before starting. Studio
   convention since 2026-11-08: every long backfill also gets a
   `blackhole_<job>` Flipper flag that drops just that job class.
6. **Bulk deletes use bulk APIs** (S3 `delete_objects`, `delete_all` on
   rows), not one `purge_later` per file.
7. **Know the dashboard's vocabulary:** ready, blocked, in progress,
   failed, and `ProcessPrunedError` means the process died, not the code.

## Action items

| # | Action | Owner |
| --- | --- | --- |
| 1 | Finish the backfill on the 8 GB plan, then reset `JOB_CONCURRENCY` to 1, remove `NORMALIZE_BLOB_CONCURRENCY`, downgrade, and remove the normalizer and libvips | Mackenzie, then Claude |
| 2 | Bring workbench's `config/queue.yml` in line with the `background-jobs` skill: named latency queues, a dedicated fast pool, no `"*"` | Claude, when asked |
| 3 | Add a "Production backfills" section to the `background-jobs` skill covering lessons 1 to 6, and a "Reading Mission Control" note for lesson 7. Partly done 2026-11-08: the blackhole flag convention is in (jean-claude, `docs(studio-developer): require a blackhole flag on long backfills`) | Claude, when asked |
| 4 | Write the kill-switch commands into workbench's ops docs or CLAUDE.md | Claude, when asked |
| 5 | Decide whether one-off heavy work gets a separate worker service or a Render one-off job | Mackenzie |
