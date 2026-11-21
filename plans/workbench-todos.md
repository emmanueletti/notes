# Workbench TODO backlog

Status 2026-11-07 (later): Small tier committed (1218b711, 2bb7cc42, 61bed72f, 971ad0a4; data checks in prod all 0). Medium items 21, 25, 29, 31, 34 committed (d9f43300 to 96c96a81). Custom projects flag off, removal (46) waits until 2026-11-14. Nothing pushed yet. Status 2026-11-06: Quick tier worked (uncommitted at time of writing): items 1, 2, 4, 5, 6, 8, 9 done; 3 moved to Medium; 7 waits on a design decision. 38 inline TODO comments (all in `server/`) and the open items from `server/TODO.md`, `docs/todo/french-internationaliztion.md` and `marketing/todo.md`, ordered simple to complex. Sizes come from grepping the blast radius on 2026-11-06. Paths are from the repo root.

Tiers:

- Quick: one or two files, under an hour, no deploy ordering.
- Small: a few files or one migration, about half a day.
- Medium: many files, a data migration, or a deploy sequence; a day or two.
- Large: a feature, a design decision, or a cross-cutting refactor; multi-day.

Gated items say what they wait on.

## Quick

1. Done: status row toggles are now monoform `.switch` checkboxes with Belly's `debounced-submit` controller; the uniform toggle partial, helper and controller are deleted. Also fixed: the old controller only updated `show_in_overview`, so a quick double click on "Counts as in-progress" could save the wrong value.
2. Done: `BlobNormalizer.call(blob)`.
3. Moved to Medium (see 34a).
4. Done: `errors_in_full_sentence` was dead code and is deleted. `full_name_initials` stays on the model: `DashboardOverviewService` uses it, and it's a pure function of the name.
5. Done: the job ticket item card thumbnail goes through imgproxy; `JobItem#first_image` is deleted.
6. Done: the mailer and portal sign-in already linked; the portal shared-link footer now does too. The print-out stays text (paper).
7. Needs a decision: status icons are a whole feature (shops pick `icon_key` in status settings, the job items filter tabs show them). Removing them from the pill alone leaves the picker half used. Decide together with 32 (pill redesign): drop icons everywhere, or keep them. Deferred 2026-11-08: user will decide later.
8. Done: a gate already existed at line 90 / branch 75; raised to 95 / 81 (Rails tests measured 96.06 / 82.44 on 2026-11-06). Raise it as coverage grows.
9. Done: templates live in `config/templates/customer_notifications/`.

## Small

10. Done: `public_number` columns dropped (migration `20261107122744`), `ignored_columns` lines and `.database_consistency.yml` entries removed.
11. Done: `job_ticket_id` reference dropped from signature events (migration `20261107122747`, also drops its unique index and FK); ignore line and override removed.
12. Done: `Dashboard::JobTickets::TermsSignaturesController` and `Dashboard::Projects::DesignRounds::ProposalsController`; route names and paths unchanged. (The proposals move is moot if 46 lands.)
13. Done: `EmailVerificationService.request_verification!(team_member)`.
14. Done: `RepairShop#ordered_job_ticket_statuses`, `#tracked_job_ticket_status_ids/keys`, `#job_ticket_status_overview_counts`, `#reorder_job_ticket_statuses!`, `#reassign_job_ticket_status!`; `JobTicketStatus#other_statuses_in_repair_shop`.
15. Done: `PwnedTestHelper`, `CacheTestHelper`, `TwilioTestHelper` in `test/test_helpers/`.
16. Done: only caller is the overview controller (Timezonable), and the rest of that service already used `Time.zone.today`, so the count now uses the same zone as the chart beside it.
17. Done: alias dropped, plain-class enums renamed `def all` to `def values`, `.values.include?` became `.include?` (Performance/InefficientHashSearch).
18. Done already: the customer print-out carries the shared-link tracking QR (`customer_print_outs/_tracking`).
19. Done: `new_customer_portal_magic_link_path` opens a preview modal. The preview link points at the shop's portal login, never a working magic link.
20. Dropped 2026-11-08 by the user (French reviewer pass on attribute names).

## Medium

21. Done, and went further: the three caches were all off in production, so they were removed (15b2de7f). `Cache::Store` stays on the killswitch API (`killswitch:`, `killswitch_<name>_cache`, on kills) for the next cache; `Cache::Keys` still holds the three dead key methods, delete them with `app/utils/cache/` if no cache appears. After deploy, drop the Workbench note from jean-claude's studio-ops `killswitches` skill.
22. Done (14d45145): constraints on JobItem#estimate_cents, FormTemplate#version, JobItemReminder#days_after; checker re-enabled. Original: `server/.database_consistency.yml:6`: Postgres CHECK constraints for 11 numericality validators. Wait for 46: 9 of the 11 are project models (ProjectMaterial, Project, Payment, MaterialOrder, InvoiceLineItem); only JobItem#estimate_cents and FormTemplate#version remain after it. Check existing rows first; add constraints `NOT VALID`, then validate.
23. Done (f12e9bfd): production connect 2s, checkout 5s, statement 5s, lock 10s. AppSignal before: AR p95 4ms, slowest SQL ~270ms. Watch for ActiveRecord::QueryCanceled after deploy.
24. Done 2026-11-08: render.yaml keeps only RAILS_MASTER_KEY as sync: false (b1232efd); imgproxy key and salt confirmed in production credentials, dashboard copies removed by the user.
25. Done (115e5c3d): outside projects only the portal status and sign-in link controllers used `find`; both redirect with "Customer not found" now. The project controllers' `find` calls go with 46.
26. Done (0e23e8df).
27. Done (f93e23cb).
28. Done (a8b6a3a9): topics renamed to `job_item_updated_*`; prod backfill ran 2026-11-07 (122,864 events); task removed.
29. Done (d9f43300).
30. Done (ea80d705): notification settings modal refreshes the page; `@job_item`, `scoped_job_item`, hidden `job_item_id` gone.
31. Done (7a747d49): new concern tests for Eventable and SoftDeletable; the rest are covered by model tests or are thin pass-throughs.
32. `server/TODO.md`: simplify the status pills to match the portal's. Design pass.
33. Done (b74b7920): filter tabs, status list, ticket item cards, portal overview cards and the data table rows use collection rendering (rows use record_counter). Kept as loops: form template field rows (partial also rendered alone by new_field), print-out items (page-break logic), sidebar saved views (helper). TODO removed.
34a. Done (22960987): `public_number` alias removed; callers use `tenant_sequence` (44 files). Token stays `{{job_ticket.number}}`.
34. Done (66eab62d): 33 files nested; all namespaces are modules. Project files left collapsed for 46.

48. Done (a5ba3b19): name and identifier search branches now compare lower(column) LIKE, so the lower() trigram indexes are used (EXPLAIN confirmed). Description has no trigram index; add one if job search gets slow.
49. Done: write actions (cc75d43d) and read actions (ed59e191) are resource controllers; no custom actions remain in config/routes.rb.

50. Done: explicit Stripe (2s open, 10s read and write) and Twilio (10s, client built per send) timeouts. Resend has no official timeout option, so left alone by decision.

## Large

35. Done; see item 4 in the pending list below.
36. Done (112d7911, a5ba3b19): no 'query engine' exists in the ADR or Belly; DataTableQuery is the intended engine. Inline joins/where/order moved into named scopes on JobItem and Customer; search objects kept as query objects.
37. Done: one CustomerNotificationEmailDeliveryJob (5c238793, shipped 2026-11-08). The legacy stub and old job args are removed in the writing-queue-design-convention session's notification fixes batch, which is awaiting the user's review.
38. Done (7546c0c5): sends no longer write events; timeline reads customer_notifications, plus legacy notification events before 2026-03-30. Duplicate events after the cutoff deleted in prod 2026-11-08; the cutoff filter in Event can now go.
39. Dropped 2026-11-08 (audit_events table): built, then discarded. Revisit when a customer asks for it in a security review, roles can change other accounts, or a support case needs history the logs lack.
40. Done (900d9f1b refactor, 7faace30 fix): Pundit policies for shop settings, billing, team members and customer delete; fixed staff archiving teammates and opening billing. Open product question: staff can still edit notification templates, form templates, statuses and reminders (UI never restricted them).
41. Done (df46a8a5 table and class, b5b111b4 FK columns). Only the stored job_ticket_status_update notification type keeps the old name, on purpose.
42. Scoped 2026-11-07: events and customer_notifications stay polymorphic (two real owners). Notes, shared links, terms signatures get real FKs. Deploy 1 committed (7d9b1660): new columns + dual write + backfills:run:owner_foreign_keys. Shipped; backfill ran in prod 2026-11-08 (2403 notes, 2056 shared links, 306 signatures filled; 4 Project notes deleted). Deploy 2 committed (8ee5e191, not yet pushed): reads new FKs, NOT NULL on them, old polymorphic columns made nullable and ignored, signable unique index dropped. Ship off-hours with a DB backup. Deploy 3 after 2026-11-14: drop the old columns and remove the ignored_columns TODOs.
43. Dropped 2026-11-08 by the user (signature by link).
44. Dropped 2026-11-08 by the user (consultation form, quoting, deposits).
45. `server/app/models/customer.rb:1`: per-shop SMS sending numbers with A2P 10DLC registration, shaped like Jobber (see `workbench-sms-subaccounts.md`).

47. Done (ea80d705, d73a1077, f180e645). Adopt Turbo morph like Belly (`belly/server/app/views/shared/_head.html.erb:18`). Plan was in `server/app/views/layouts/application.html.erb`, deleted in 79634275 (`git show 79634275`): add refresh-method morph + scroll preserve meta, `data-turbo-permanent` on the global modal dialog, `#flash_toasts`, sidebar state and client-only Stimulus DOM (dropzone, darkroom, email-preview); stable ids on toggled roots (Belly 19d0e3f); turn `terms_signatures#create` refresh into a real morph; move global-modal controllers from hand-written streams to redirect-and-morph where simpler; retire the image uploader's `_top` frame exception. Unblocks 30.
    Progress 2026-11-07 (ea80d705, notes fix 2804b64e): morph + scroll preserve on; `close_modal_and_refresh` (close_modal + `refresh_keeping_edits`, which keeps edited fields on the page underneath); customer contact/address/notification modals converted, `customers/update.turbo_stream.erb` deleted; `#flash_toasts` swapped whole on morph; note edit/delete now redirect and morph (fixed stale note after delete, edit form not closing). Battle-tested in Chrome. Left: optionally convert team member, invitation, summary email, duplicate customer and assign-to-new-job streams; image uploader `_top` exception works as is.
    Follow-up: team member create, invitation create/update and intake summary email moved to close_modal_and_refresh; 4 stream templates deleted. duplicate_confirmation (swaps modal content) and assign_to_new_job (injects into an unsaved form) stay streams on purpose. 47 done.
    Found while testing, fixed: phone validated only on change (2859a15d), team_members routes trimmed (f624c0ec), seeded joined members get verified_at (c9ea5dc0). Prod check: count customers with unparseable phones.
    Production review 2026-11-07 fixes: note lookup scoped to shop (7ff89552, was a cross-shop hole), note maxlength (0d25d051), uploader and team picker survive morphs (d73a1077), bare US/CA numbers try the neighbour region (19495bd3). PostHog snippet token-URL and PII fixes landed (toolshed bdfb1ce, Workbench 383a796d).

46. Code removed 2026-11-07 (ec1632a9; tables kept, dated TODO in server/TODO.md). Remaining: drop tables on or after 2026-11-14 after Micah/shop 7. Known gap until then: deleting a customer or shop with a project that has invoices, material orders, assignments or materials raises a FK error (user accepts it for the test rows at shops 25 and 7). Before the drop migration, run the cleanup parked in ~/notes/plans/snippets/delete_custom_projects_backfills.rake (+ _test.rb): deletes the 10 tables in FK order, events and notes owned by Project, and attachments for Project, ProjectReference, DesignRendering, MaterialOrder. Original: rip out the custom projects feature (`Project`, design rounds and renderings, references, materials, material orders, invoices, line items, payments; behind `feature_enable_custom_projects`; about 170 files in `server/app`). Steps:
    1. Prove it's unused. Check which shops have `feature_enable_custom_projects` on in production Flipper. Pull AppSignal request logs and traces for 30+ days on `/dashboard/projects*`, the portal project and invoice routes, and the design round mailers and jobs; expect zero hits outside internal shops. Have the human count production rows in `projects`, `invoices` and `payments` (PgHero in Houston). Stop if any real shop has data or traffic.
    2. Remove the code: routes, controllers, views, models, jobs, mailers, presenters, locale keys (EN and FR), factories, tests, Lookbook previews, the sidebar Customs section, the flag in `feature_flags.yml` and the test flags file, and `.database_consistency.yml` entries for the removed models.
    3. Deploy, then drop the tables in a follow-up migration (FK order: payments, invoice_line_items, invoices, material_orders, project_materials, design_renderings, design_rounds, references, projects) and delete stored Active Storage attachments for the removed records.
    2026-11-07 check: NOT unused. AppSignal, 2026-08-07 to 2026-11-07: Dashboard::ProjectsController#index 139 requests, #new 12, Portal::ProjectsController#index 10. Sampled traces are almost all Fort Richmond Jewellers (shop 29, team member 84), regularly up to 2026-11-03; also Jewellery Clinic Kelowna (shop 16) and IT'S US STUDIO (32, internal). Stopped here; talk to those shops (or confirm they only clicked the sidebar) before removing.
    Production data, 2026-11-07: flag on for shops 16, 24, 25, 29. Projects: shop 7 = 5 (flag off), 25 (Micah Jakob Private Jeweller) = 3, 29 (Fort Richmond) = 1 stuck in quote since 2026-07-25. Zero design rounds, invoices, payments for flagged shops. Fort Richmond's 139 index views are page opens, not work. Micah is the shop item 44 was written for, so removal is a product call with Micah, not a cleanup.
    Decision 2026-11-07: flag turned off for all shops (sidebar Customs section hidden; routes still reachable by direct URL). If no shop complains by 2026-11-14, do steps 2 and 3. TODO comment on the flag in `server/config/feature_flags.yml`. Before deleting, export or tell Micah about shop 25's 3 projects, and find out who shop 7 is (5 projects).
    Overlaps 44 (consultation and quoting) and the `custom_projects` branch in 43: decide whether either survives before deleting.

## Pending, simple to complex (2026-11-07)

Now means I can do it without you; the others say what they wait on. Production-sensitive items (DB timeouts, notification events) sit at the bottom on purpose.

1. Done (0e23e8df): 26, English says "client portal" everywhere; French already did.
3. Done (e0e460b7): 20 leftover, user-facing validation messages are activerecord.errors keys in EN and FR; internal invariant messages left as literals.
4. Done (7f1eedb9, c7ac1bae, c69e0ce8): 35, one-off Prosopite raise in test found the real read N+1s, now fixed (Houston shop owners via loaded team_members, job items bulk update preloads plus status resolved once through current_repair_shop, which also stops a foreign shop's status id being saved, Eventable passes the loaded repair_shop). Seeding, reorder, assignment and the field-values check were then redesigned to set-based queries; the remaining write loops and demo seeding are allowlisted in `config/initializers/prosopite.rb` for the development raise. No test gate by choice; development catches new N+1s. Stale Bullet TODOs removed.
5. Done (f93e23cb): 27, 43 keys for generic labels now point at common.*; domain phrases, titles and project keys stay per screen.
7. Done: 28, topic rename and prod backfill.
8. Needs you for secrets: 24, Render `sync: false` env vars into credentials.
9. 46: code removed; on or after 2026-11-14 drop the tables (Micah's 3 projects and shop 7 first). Unblocks 22, 33, 41, 42, 49 now.
10. After 46: 22, CHECK constraints (2 left: JobItem#estimate_cents, FormTemplate#version).
11. Done: 33, collection rendering.
12. Needs a design call: 7 and 32, status pill icons and pill redesign.
13. Done: 47 and 30, Turbo morph.
14. Gated on a third bespoke mailer: 37.
15. Needs a spec: 39, `audit_events` table.
16. Done: 40, Pundit.
17. Done: 36, scopes.
18. Large: 41, rename JobTicketStatus to JobItemStatus (551 refs; pairs with 28 and 29).
19. Large: 42, move Eventable off polymorphic tables.
20. Features: 43 signatures, 44 consultation and quoting (both tied to the 46 decision), 45 per-shop SMS numbers with A2P 10DLC.
22. Sensitive, watched deploy: 23, production connect, checkout and statement timeouts.
23. Sensitive, product call: 38, stop writing notification events; the ticket timeline reads `customer_notifications`.

## Overlaps

- Production timeouts: 23 covers both `database.yml` and `server/TODO.md`.
- Bullet: 35 covers `test_helper.rb` and both `server/TODO.md` entries; `docs/playbooks/performance-optimization.md:68` points at it.
- Renames 28, 29 and 41 are all leftovers of the job ticket to job item move and could ship as one effort.
