# Donna: workspaces and leads

Goal: make donna a product-agnostic outreach tracker. One workspace per studio
product (Workbench today, Belly next), each holding its own leads.

## What already exists

Donna is already multi-tenant: User -> Membership -> Account -> Project -> Shop.
Every dashboard query goes through `current_project.shops`, and
`Dashboard::CurrentProjectsController#update` switches projects (with a
cross-account 404 test). Nothing in the UI calls it. So the work is a rename, a
generalization of Shop, and UI, not new tenancy.

## Decisions (from the 2026-09-29 conversation)

- Rename Project -> Workspace and Shop -> Lead, in code, tables and routes.
- In-app workspace switcher in the page header plus a "New workspace" form.
- Region tabs are per workspace.

## Data model

Workspace (was projects):
- `name`
- `countries` text array, default `["CA", "US"]`. Drives the pipeline tabs. One
  country means one tab and no country split; empty means one "All" tab.
- Unique index on `[account_id, name]` (missing today, only a model validation).

Lead (was shops). Generic fields that already fit Belly practitioners:
name, contact_name, email, phone, website, city, province_state, country,
language, stage, source, last_touch, needs_follow_up, notes.

Jewelry-specific fields become generic:
- `shop_type` (jewelry/watch/both, check constraint) -> `category`, free text.
  Each workspace keeps its own list, suggested from the values already in use
  (datalist), so Workbench keeps jewelry/watch/both and Belly uses
  nutritionist/dietitian/coach/naturopath without a migration per product.
- `shop_size` -> `size`, same solo/small_team/multi_location values. Belly's
  screening is exactly solo vs clinic, so this carries over as is.
- `crown_jewel` -> `priority` boolean, still shown as a marker next to the name.
  The "tier-1 golden ICP" copy moves to a generic "Priority lead".
- `source`: keep the enum, add `directory` (Belly finds leads in practitioner
  directories). trade_directory stays for Workbench rows.

activity_logs: `shop_id` -> `lead_id`.

## Migrations

No strong_migrations gem, Render free plan, two internal users. Do the renames
in place (`rename_table`, `rename_column`) in one deploy and accept a few
seconds of errors during the deploy instead of a dual-write. Say so in the
commit. Order:

1. `rename_table :projects, :workspaces`; `rename_column :shops, :project_id, :workspace_id`.
2. `rename_table :shops, :leads`; rename `shop_type` -> `category`,
   `shop_size` -> `size`, `crown_jewel` -> `priority`; drop the shop_type check
   constraint; update the source check constraint to include `directory`.
3. `rename_column :activity_logs, :shop_id, :lead_id`.
4. Add `workspaces.countries` (default `["CA", "US"]`) and the unique index.

Generate each with `bin/rails g migration`. No data changes in migrations.
Existing Workbench rows keep their values through the renames, so no backfill.

## App changes

- Models: Workspace, Lead, `Current.workspace`, Tenancy concern
  (`current_workspace`, `current_leads`, `session[:current_workspace_id]`).
- Controllers and routes: `Dashboard::LeadsController`,
  `resources :leads`, `resource :current_workspace`, new
  `resources :workspaces, only: [:new, :create]`. Root stays the pipeline;
  country comes from a `country` param validated against
  `current_workspace.countries` instead of the hardcoded `/` and `/us` routes.
- Views: move `dashboard/shops/*` to `dashboard/leads/*`. Replace hardcoded
  "Workbench" with the workspace name. Replace the jewelry/watch label maps
  with `category` shown as text. Tabs built from `current_workspace.countries`.
- Header: workspace switcher (dropdown of `current_account.workspaces`, each a
  `button_to` PATCH to current_workspace) plus a "New workspace" link.
- CSV import: header becomes `category,size,priority` instead of
  `shop_type,shop_size,crown_jewel`. Accept the old names as aliases so
  existing CSVs still import. Country validated against the workspace's
  countries, not CA/US.
- Analytics: already scoped to the current workspace; just the renames.
- Seeds and `internal:seed`: create both Workbench and Belly workspaces. Belly
  gets `countries: ["CA"]`.
- App module `WorkbenchPipeline` and PWA manifest name -> Donna.

## Tests

- Rename factories and test files (shop -> lead, project -> workspace).
- New: workspaces controller create (valid, duplicate name, other account),
  switcher renders every account workspace, leads never leak across
  workspaces (index, show, import dedupe), tabs follow workspace countries,
  CSV import accepts old and new header names.
- Auth tests for the new workspace routes.

## Outside donna (follow-up, jean-claude)

The studio-sales skills hardcode donna's CSV contract and URL:
`build-donna-shop-csv` header, `research-shop-website` fields and crown rubric,
`import-shops` upload path `/dashboard/shops/import`. They need the new header,
`/dashboard/leads/import`, and a note to pick the workspace before importing.
The import aliases keep them working until then.

## Order of work

1. Migrations + model renames, tests green.
2. Controller, route and view renames, tests green.
3. Generalize fields (category, size, priority, countries, source directory).
4. Workspace switcher + new workspace form.
5. Seeds, internal:seed, copy and branding.
6. Browser check at the local host, then production-review.
7. jean-claude skill updates.
