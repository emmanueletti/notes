# Workbench: job status stages

Date: 2026-11-16. Prerequisite for the new Home (owner and technician views).

## Why

Shops name their own job statuses. Today the code reads meaning from two
places that don't survive that:

- `public_key`, which is generated from the display name and regenerates when
  a shop renames a status.
- `should_track_progress` and `show_in_overview`, two booleans that only say
  "open or closed" and "show on the old Home".

Home needs to know where a job sits in the work: on the bench, waiting on
someone else, ready for pickup, finished. Reports will need it too (turnaround,
finished on time).

## The model

Statuses stay fully custom in name, colour and order. Each one belongs to
exactly one stage, which Workbench owns and never changes. Linear (workflow
state types), Jira (status categories) and ClickUp (status groups) all work
this way.

| Stage | Open | Means | Starter statuses |
|---|---|---|---|
| to_do | yes | Taken in, not started | Draft |
| in_progress | yes | On the bench | In progress |
| waiting | yes | Off the bench until someone else acts: quote, parts, setter | Quote needed |
| ready | yes | Finished, waiting to be collected | Ready for pickup, Pending pickup |
| done | no | Picked up or delivered | Picked up |
| cancelled | no | Closed without finishing | Cancelled |

The reason a job is waiting lives in the status name the shop picks ("Waiting
on parts", "Quote sent"), not in the stage.

What the code reads from it:

- Open: every stage but done and cancelled. Replaces `should_track_progress`.
- On the bench: to_do and in_progress.
- Blocked: waiting.
- Money waiting: ready.
- Finished: entered done. Turnaround and on-time later need the time a job
  entered done (or a status history), not part of this plan.

Rules:

- Every shop keeps at least one status in to_do and one in done.
- New jobs start in the first to_do status by position.
- Statuses are ordered within a stage; the stage order is fixed.
- Status settings group statuses under their stage, and creating a status asks
  for its stage.

## Steps

Each step ships on its own. No data changes inside migrations.

### 1. Export and review (no code)

Run in the production console (read-only), paste the output into a review
sheet:

```ruby
JobItemStatus.includes(:repair_shop).order(:repair_shop_id, :position).map { |s|
  [s.id, s.repair_shop_id, s.repair_shop.name, s.public_key, s.localized_display_names["en"], s.localized_display_names["fr"], s.should_track_progress, s.show_in_overview, s.job_items.count]
}.each { |row| puts row.join(" | ") }
```

Then go through every row together and decide its stage. The result is one
explicit list: status id to stage. Starter statuses that still carry their
original key can be mapped by key; every other status gets decided by hand.

Done 2026-11-17 (export in ~/Downloads/status.csv): 327 statuses, 47 shops.
295 still carry a starter key with the starter name; 32 are custom (435 jobs).

#### Final map

Starter statuses, by `public_key`:

| Key | Stage |
|---|---|
| draft | to_do |
| quote_needed | waiting |
| in_progress | in_progress |
| ready_for_pickup | ready |
| pending_pickup | ready |
| picked_up | done |
| cancelled | cancelled |

Custom statuses, by id:

| id | Shop | Name | Jobs | Stage |
|---|---|---|---|---|
| 119 | Timeless Repairs | Quote sent to client | 3 | waiting |
| 126 | Etti Repair Emporium | Test | 0 | to_do |
| 120 | SarahBijoux | Send estimate to client | 0 | waiting |
| 121 | SarahBijoux | Waiting for client response | 14 | waiting |
| 122 | SarahBijoux | Waiting for payment | 2 | waiting |
| 123 | SarahBijoux | Ready for repair | 16 | to_do |
| 124 | SarahBijoux | Repair in progress | 1 | in_progress |
| 125 | SarahBijoux | Ready for pick up | 8 | ready |
| 133 | SarahBijoux | Done | 306 | done |
| 134 | SarahBijoux | Do not repair | 52 | cancelled |
| 148 | Fort Richmond Jewellers | Waiting For Order | 5 | waiting |
| 149 | Fort Richmond Jewellers | Stock | 1 | to_do |
| 157 | Fort Richmond Jewellers | Waiting For Customer Approval | 0 | waiting |
| 306 | Fort Richmond Jewellers | Lay-away | 1 | ready |
| 237 | Grimson and Sons | Logged & Ready for Work | 3 | to_do |
| 215 | Grimson and Sons | Estimate Requested | 0 | waiting |
| 242 | Grimson and Sons | Estimate Provided | 0 | waiting |
| 236 | Grimson and Sons | Returned - No Work Done | 0 | cancelled |
| 216 | Grimson and Sons | In progress | 1 | in_progress |
| 239 | Grimson and Sons | On Hold - Waiting on Client | 0 | waiting |
| 240 | Grimson and Sons | On Hold - Waiting on Supplier | 0 | waiting |
| 238 | Grimson and Sons | Finished - Ready to Invoice | 0 | ready |
| 241 | Grimson and Sons | Ready for Pickup > Atelier | 0 | ready |
| 235 | Grimson and Sons | Ready for Pickup > Boutique | 0 | ready |
| 278 | Jewelry By Allen Joseph | Received | 0 | to_do |
| 279 | Jewelry By Allen Joseph | At the bench | 0 | in_progress |
| 280 | Jewelry By Allen Joseph | Waiting on parts/approval | 0 | waiting |
| 321 | C Creations (shop 54) | Received | 4 | to_do |
| 328 | C Creations (shop 54) | Pending Approval | 2 | waiting |
| 322 | C Creations (shop 54) | Approved | 14 | to_do |
| 324 | C Creations (shop 54) | Complete | 0 | ready |
| 326 | C Creations (shop 54) | Shipped | 3 | done |
| 327 | C Creations (shop 54) | Return Undone | 0 | cancelled |

Notes:

- Stock (149): read as shop inventory going through the bench. Check the one
  job before the backfill; if it means waiting on stock to arrive, use waiting.
- Lay-away (306): finished piece held until paid off, so ready.
- The backfill maps starter keys first, then the id list. A starter-key status
  created after this export maps by key; any new custom status makes the task
  fail and gets added by hand.

#### Behaviour change: stale Ready for pickup

Early shops used Ready for pickup as a closed status (`should_track_progress`
false). Ready is open, so these jobs come back into Home:

| Shop | Jobs in Ready for pickup |
|---|---|
| JEWELLERY CLINIC (10) | 2,492 |
| Jewellery Clinic Wholesale (8) | 72 |
| Russell Jewellers (9) | 63 |
| Fort Richmond Jewellers (29) | 45 |

Decision: accept it, and the shops move collected jobs to Picked up
themselves. We can't, since we don't know which were collected. A status
change sends no customer message (notifications are manual), only an event and
a new `status_changed_at`. To make the cleanup cheap (lands with step 8):

- Saved view on Jobs: Ready for pickup, unchanged for over 90 days.
- "Select all N matching" for bulk actions, since today bulk only covers the
  rows ticked on screen.
- One-time Home nudge for shops with stale ready jobs, linking to that view.
- The Ready for pickup card shows the age of its oldest job.
- Email the four shops before the new Home ships (needs approval to send).

The bulk move stamps today's `status_changed_at` on old jobs; accepted as
one-time noise in later turnaround reports.

### 2. Add the column (migration, needs approval)

- `job_item_statuses.stage`, string, nullable for now. The allowed values
  live in the model enum only (business values, per the migrations skill), no
  check constraint.
- Model: `enum :stage, {to_do:, in_progress:, waiting:, ready:, done:, cancelled:}`
  backed by strings, with scopes `open`, `on_the_bench`, `closed`.
- Starter statuses (`JobItemStatusDefaults`) get their stage, so new shops are
  complete from day one.
- Creating or editing a status in settings requires a stage from here on.

### 3. Manual backfill

- `backfills:run:job_item_status_stages` in `lib/tasks/backfills.rake`, with
  the reviewed id-to-stage list written into the task.
- It only fills blank stages, so it's safe to run twice.
- It prints every status it couldn't place and exits non-zero if any are
  left, so nothing falls through silently.
- Run it by hand after the deploy (not in the boot entrypoint), then check
  `JobItemStatus.where(stage: nil).count` is 0.

### 4. Make it required (migration, needs approval)

- `stage` becomes NOT NULL.
- Validate the two shop rules (at least one to_do and one done) in the model,
  and block deleting or restaging the last one.

### 5. Move the code onto stages

Replace `should_track_progress`, `tracking_progress`, `show_in_overview` and
meaning read from `public_key`. Files today:

- app/models/job_item_status.rb, job_item.rb, job_ticket.rb, repair_shop.rb, customer.rb
- app/models/concerns/job_item_status_defaults.rb
- app/helpers/job_tickets_helper.rb (saved views: overdue, due this week)
- app/presenters/dashboard/data_tables/job_items_data_table.rb
- app/services/dashboard_overview_service.rb (goes away with the new Home)
- app/controllers/dashboard/settings/job_tickets/job_item_statuses_controller.rb
- app/views/dashboard/settings/job_tickets/job_item_statuses/_status_row.html.erb
- app/views/portal/job_tickets/_card.html.erb, show.html.erb
- app/views/portal/shared_links/job_ticket.html.erb

`public_key` stays where it identifies a status for customer notifications
(`notified_status_public_key`, template rendering, events), since that's a
record of what was sent, not a meaning.

### 6. Status settings by stage

Prototype: https://claude.ai/artifact/ARwZPLGupK3D6xi9NgH4Zq#statuses

- One card, six stage sections in fixed order, each with its stage icon, name
  (meaning in a tooltip) and job total. Replaces the two switches and the
  modal form.
- Row: drag handle on hover, colour dot (8 named colours), inline name, job
  count, "Default" on the first To do status, and a menu with Move up, Move
  down, Move to stage, Delete.
- "+" on a stage adds an empty row in that stage; Escape cancels it.
- Moving a status to another stage happens at once, with an Undo toast.
- Delete: no jobs deletes with Undo; with jobs, a dialog asks where to move
  them (same stage preselected). The last To do and last Done can't be
  deleted or moved out.
- The status picker on a job groups statuses by stage the same way.
- Stage icons go into Uniform from Lucide: circle-dashed, circle-dot,
  circle-pause, circle-check, check-check, a circled X (check the Lucide name),
  plus grip-vertical.
- Status icons (`icon_key`) are gone from defaults and the form in step 2;
  drop the column with step 7.

Translations:

- No per-status language fields. A Translate button in the page header opens
  one table: status names per stage, one column per customer language,
  missing names prefilled with suggestions, and a "N missing" badge on the
  button.
- Only shown when the shop has customers in more than one language.
- Generate everything from the supported language list, not hard-coded en/fr:
  `JobItemStatus::LocalizedDisplayNames` (today `Data.define(:en, :fr)`),
  the form params, and the Translate table's columns. Storage
  (`localized_display_names` jsonb keyed by language code) already allows it.
- Adding a language later (Spanish, say) is then a translation job for the
  customer-facing copy (portal, notifications, emails, sign-in code, see the
  add-app-language skill), plus a shop-level "customer languages" setting.
  Not part of this plan.

Proposed starter statuses for new shops (existing shops keep theirs):
Received (to_do), In progress, Quote needed and Waiting on parts (waiting),
Ready for pickup (ready), Picked up (done), Cancelled. Drops Draft and Pending
pickup. Delete the unused `Enums::JobTickets::Statuses`.

### 7. Drop the old columns (migration, needs approval)

After step 5 has run in production: drop `should_track_progress` and
`show_in_overview`.

### 8. Build Home on stages

- Owner: Late and due today, Stalled, Ready for pickup (with the dollar total),
  Waiting (each row shows its status name), Team load, Due next two weeks.
- Technician: Up next (to_do and in_progress, mine, soonest due), New for you,
  Blocked (mine in waiting).
- New shop: setup checklist from Onboarding::Progress.
- Prototype: https://claude.ai/artifact/ARwZPLGupK3D6xi9NgH4Zq

## Open questions

- Should a status history table (job, from, to, at) land with step 5, so
  turnaround and time-in-stage work for Reports later? It's cheap now and
  impossible to recover later.
