# Move belly onto studio-tenancy

Status: deploys 1 and 2 shipped 2026-11-11. Deploy 3 built and staged; the owner-only Insiders gate waits for the first paid feature.

## Goal

Belly uses the studio-tenancy gem like every other studio app:

```
Organization          billing (Insiders), owned through organization memberships
  └─ Workspace        recipes, plans, groceries; shared through workspace memberships
```

Today's belly `Organization` is what the gem calls a `Workspace`. So the work
is a rename, a new organization layer on top, then billing moving from the
user to the organization. Shared spaces with invitations come after, with the
workbench port.

## Ground rules

- Simple migrations over zero-downtime ones. Brief 404s and errors while a
  deploy swaps are accepted (decided 2026-11-10), so renames are plain
  `rename_table` and `rename_column` in `safety_assured`.
- No data in migrations. Backfills go in `lib/tasks/backfills.rake` and run
  right after the deploy.
- Each deploy below is one commit, or a few, and ships alone.
- Jobs queued with an `Organization` GlobalID fail after deploy 1. Check
  Mission Control is empty first, and discard any failures after.

## Today

| belly | gem |
| --- | --- |
| `organizations` (name, kind personal/shared) | `workspaces` |
| `memberships` (role, is_default) | `workspace_memberships` |
| `organization_id` on recipes, tags, playlists, planned_meals, planned_notes, grocery_items, bulk_imports | `workspace_id` |
| roles owner, member | owner, admin, member, guest |
| `billing_subscriptions` and `billing_grants` owned by a `User` (polymorphic `owner`) | owned by the `Organization` |
| none | `organizations`, `organization_memberships` |

About 205 files mention organization, most of them `current_organization`,
`Current.organization` and factories.

## Before deploy 1

Run in the production console and confirm:

```ruby
Organization.where.missing(:memberships).count       # 0: every space has a member
Membership.owner.group(:organization_id).having("count(*) > 1").count  # {}: one owner each
SolidQueue::Job.where(finished_at: nil).count         # 0, or wait
```

## Deploy 1: rename to workspaces and add organizations

Migrations:

1. Rename, in one migration with `safety_assured`:
   - `rename_table :organizations, :workspaces`
   - `rename_table :memberships, :workspace_memberships`
   - `rename_column :workspace_memberships, :organization_id, :workspace_id`
   - `rename_column <table>, :organization_id, :workspace_id` on the 7 tables
   - `remove_column :workspaces, :kind` (shared is unused; personal is now "the
     workspace you own")

   Rails renames the conventionally named indexes, and Postgres keeps the
   foreign keys.
2. The gem's install migration, trimmed to what's missing: `organizations`,
   `organization_memberships`, and `add_reference :workspaces, :organization,
   foreign_key: true` (nullable until the backfill).

Code:

- Install the gem: `gem "studio-tenancy"` in the toolshed block, then
  `bundle update --source toolshed`.
- Models: `Organization`, `OrganizationMembership`, `Workspace`,
  `WorkspaceMembership`, each including its `Studio::Tenancy::For*` concern.
  Belly's own associations (recipes, tags, ...) move from `Organization` to
  `Workspace`.
- `User` includes `Studio::Tenancy::ForUser`. Delete `create_personal_organization`,
  `personal_organization`, `default_organization`, `destroy_owned_organizations`,
  `Enums::Organizations::Kinds` and `Enums::Memberships::Roles`.
- `ApplicationController` includes `Studio::Tenancy::ForController`.
  `current_organization` in data code becomes `current_workspace`.
  `Current.organization` becomes `Current.workspace`.
- `belongs_to :organization` becomes `belongs_to :workspace` on the 7 models.
  Broadcast streams follow (`[recipe.workspace, :recipes]`), and open pages
  pick them up on reload.
- Display name: the gem names a new workspace after the user. Keep belly's
  "Emma's space" wording in i18n, from `workspace.name`.
- Admin views and `dev_seed.rake` follow the rename.
- Tests and factories: `:organization` becomes `:workspace`, `:membership`
  becomes `:workspace_membership`.
- `Studio::Monitoring::Current.tenant_id` becomes `current_organization.id`
  (decision 3). Its ids are new, so PostHog groups restart.

Backfill `tenancy_organizations`, run right after the deploy:

```ruby
User.find_each do |user|
  next if user.organization_memberships.owner.exists?
  organization = Organization.create!(name: user.name)
  user.organization_memberships.create!(organization:, role: :owner)
  Workspace.where(id: user.workspace_memberships.owner.select(:workspace_id), organization_id: nil)
    .update_all(organization_id: organization.id)
end
```

Between the deploy and the backfill, `current_organization` is nil for
existing users. Billing still reads the user in this deploy, so nothing
visible breaks.

## Deploy 2: require the organization

- Check `Workspace.where(organization_id: nil).count` is 0.
- Migration: `change_column_null :workspaces, :organization_id, false`.
- Delete the `tenancy_organizations` backfill.

## Deploy 3: billing on the organization

Code:

- `Organization has_many :billing_subscriptions, :billing_grants, as: :owner`.
  `entitled_plan_codes` and `insiders?` move from `User` to `Organization`.
  A user gets Insiders features only where they own the organization
  (decision 2), so the app's check becomes one helper, e.g.
  `insiders_features?` = `current_organization&.insiders? &&
  current_organization.owner == current_user`.
- Checkout (`checkouts_controller.rb:21`) puts `organization_id` in the
  subscription metadata, next to `user_id`.
- `Billing::SubscriptionReconciler` (`subscription_reconciler.rb:63`) finds
  the owner by `organization_id`. Without it, which is every subscription made
  before this deploy, it falls back to the user's owned organization.
- `stripe_customer_id` and the customer portal move to the organization.
- Staff grant forms in `/admin` grant to the organization.

Backfill `billing_owner_organizations`:

```ruby
[Billing::Subscription, Billing::Grant].each do |model|
  model.where(owner_type: "User").find_each do |row|
    organization = Organization.joins(:organization_memberships)
      .find_by!(organization_memberships: {user_id: row.owner_id, role: "owner"})
    row.update_columns(owner_type: "Organization", owner_id: organization.id)
  end
end
```

Until it runs, Insiders members lose their features for a minute.

## Later

- A week after deploy 3: delete the billing backfill. Stop writing `user_id`
  into Stripe metadata, or keep it for support.
- Shared spaces: create another workspace, invite a partner (member or guest),
  switch between workspaces. Invitations land in the gem with the workbench
  port.

## Decisions (2026-11-10)

1. Everything moves in this effort, billing included.
2. Insiders features go to the organization's owners only. Someone invited
   into a workspace (member or guest) doesn't get them, even in a paid
   organization's workspace. The check is `current_organization.insiders?`
   and the user owning that organization.
3. The organization is the tenant everywhere: `Studio::Monitoring::Current.tenant_id`,
   the PostHog group, billing. The workspace is only a data layer.
4. No shared spaces exist; the feature was never built. `kind` drops with no
   data to move.
