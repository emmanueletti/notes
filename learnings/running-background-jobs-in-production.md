# Running background jobs in production

What I learned on 2026-11-07, while an image backfill took Workbench down
several times. The incident itself is in
`~/notes/retros/2026-11-07-workbench-backfill-oom.md`.

## How production teams run jobs

The short version: they don't fix it by scaling the app up. They keep heavy
work away from the web app, and they can turn job load down while things are
running, without a deploy. At Shopify, deploys took hours, so a deploy was
never the emergency lever.

1. **Isolation first.** Jobs run on their own worker fleet, never inside the
   web process. Pools are split by workload: fast user-facing jobs, bulk jobs,
   and memory-heavy jobs like media each get their own. A runaway job can only
   crash its own pool. Heavy media work often moves to a separate service
   entirely (imgproxy, an image service).
2. **Controls that work while it's running.** Kill switches, concurrency limits
   and pause flags live in config, env vars, feature flags or the database, not
   in code. Every queue can be paused.
3. **Backfills are a separate, controlled tool.** Shopify built `job-iteration`
   and `maintenance_tasks` for this. A backfill walks rows with a cursor, can be
   interrupted and resumed anywhere, survives deploys, runs from an admin UI
   with pause, resume and cancel, and **throttles itself on health signals**
   (`throttle_on { memory high || DB unhealthy || replica lag }`). It backs off
   before anything falls over.
4. **Scale on the right signal.** Workers autoscale on queue wait time, not CPU
   (Judoscale, HireFire).
5. **Memory guards per process.** A memory killer restarts one fat worker
   cleanly, instead of letting the whole machine run out of memory.
6. **Admin tools live apart from the app,** so they still work when the app
   doesn't.
7. **Scaling up is the emergency lever, not the design.** Bigger instances for
   an hour are fine. They don't replace isolation and limits.

## Before running any production backfill

Write down four numbers and divide:

- how many items
- time per item (measure one)
- memory per item (measure a long run, not one item: see below)
- memory left on the instance after the app itself

Then decide where it runs (never the web process), what the concurrency limit
is, how to turn it down without a deploy, and what the kill switch is if the
app is down.

## Solid Queue specifics

- **Concurrency is the smaller of the job's limit and the worker threads.** The
  thread count is processes × threads × instances. Raising only one does
  nothing.
- **`limits_concurrency` uses a semaphore,** a counter of free places stored in
  `solid_queue_semaphores`. It stores free places, not the limit. Raising or
  lowering the limit doesn't change places already handed out. Running jobs
  pass their place straight to the next blocked job, so the running count
  stays where it was until you reset the counter by hand.
- **`duration`** is how long a job may hold its place. It's what frees a place
  when a job dies holding it, for example on an out-of-memory crash. Set it
  longer than the slowest job, or a slow job lets an extra one start.
- **Mission Control counts:**
  - **Ready**: free to run as soon as a worker picks it up. This is what the
    Queues page counts.
  - **Blocked**: waiting for a concurrency place. Not counted as queued, so
    "queue 0" with thousands blocked is normal.
  - **In progress**: claimed by a worker.
  - **Failed** with `ProcessPrunedError`: the worker process died (often out
    of memory). The code didn't fail, and a retry is usually safe.
- **`queues: "*"` runs every queue in enqueue order on shared threads.** 7k
  housekeeping purges starved the backfill, and the backfill could starve
  emails. Give each workload its own pool with an explicit queue list.
- **A paused queue** holds new and released jobs; running ones finish. It
  survives restarts because it's stored in the database. Pausing is the first
  move in any job incident.
- **Env vars are read when workers boot,** so changing one means a restart
  ("Save and deploy" on Render, no rebuild). A console change never reaches
  the workers.

## Native libraries in threaded workers

- libvips and libheif, used to convert images, leaked or fragmented memory
  when several threads converted in one long-lived process. Measured locally:
  3 threads grew from 1.1 GB to 3.4 GB to 4.2 GB and never gave it back. One
  thread per process stayed flat at about 260 MB after 300 images. Confirmed
  in production the same night: with single-thread processes on a 4 GB
  worker, memory stayed flat.
- One image looked cheap (about 360 MB), but a long run is what matters.
  Measure memory over hundreds of items, not one.
- For native-heavy work, scale with processes of one thread each, not threads.
  A short-lived child process per item is the strongest guarantee, since all
  its memory is freed on exit.
- `VIPS_CONCURRENCY=1` stops libvips starting one thread per CPU per image.

## Bulk operations

- `purge_later` queues one job per file. Deleting 7k files meant 7k jobs and
  about 15k Spaces round trips. For bulk deletes, use the storage's batch API
  (S3 `delete_objects`, up to 1,000 keys a call) and `delete_all` on rows.
- A fan-out job that queues everything up front (20k jobs at once) has no
  brakes. Either cap concurrency hard, or have the job throttle itself.

## Pushing and history while other people work

- A push to main is a production deploy on Render.
- Never rewrite a commit that's already pushed. Add a new one on top.
- When some commits must wait (column changes for zero traffic), order
  history so the deployable ones sit underneath, and push only up to them:
  `git push origin <sha>:main`.
- Pre-push CI tests the checked-out code, not the commit being pushed.
