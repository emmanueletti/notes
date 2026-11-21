# Workbench team members: drop placeholders, add invitations

Written 2026-11-16. Status: proposed, not started.

## Why

A User row has to look like a login account even when the person never logs in. That one choice causes most of the pain around team members:

- Placeholders carry a fake email (`uuid_placeholder@email.com`) to satisfy NOT NULL and uniqueness. Code checks `LIKE '%placeholder@email.com'`.
- Archiving rewrites data: the name becomes "Ana (ARCHIVED)", the email `uuid_archived_ana@…`. Unarchiving guesses the old state from those strings (`formerly_placeholder?`, `formerly_invited?`, `formerly_joined?`).
- `status` mixes three questions: who the person is, whether they can sign in, whether they're archived (unverified, joined, placeholder, invited, archived).
- `unverified_email_address` does three jobs: the invite address, a pending email change, and (until 2026-11-16) the signup address. `verification_sent_at` doubles as "invited at".
- An invite is a long signed user token. No inviter on record, no revoke, no list of pending invites.

## What production says (2026-11-16)

- Placeholder-email users: 54 placeholder, 1 invited, 14 archived, across 14 shops. Newest created 2026-11-12.
- 34,681 job item assignments point at them, 3,207 in the last 90 days, the latest today.
- 3 project_assignments rows (table has no model). No notes, notifications, signature or consent events, events or sessions.

So "people you assign work to who never log in" is a real, daily need. Keep the person; drop the fake login. This matches Square, Shopify POS, Toast, Jobber and ServiceTitan: a team member exists without access, and access is a setting.

## Target

User is a team member: a person with a name and role who can be assigned work.

| Column | Meaning |
| --- | --- |
| `email_address` | Nullable. Blank means no login. Unique when present: partial unique index on `lower(email_address) WHERE email_address IS NOT NULL` |
| `archived_at` | Nullable timestamp. Replaces the archived status. Name and email untouched |
| `verified_at` | When the address was proven (code or invite) |
| `pending_email_address` | Only a pending email change. Replaces `unverified_email_address` |

Derived, never stored:

- Can sign in: email present and not archived (studio-auth's `can_sign_in?`).
- Invited: has a pending Invitation.
- No access: no email, no pending invitation.

Invitation is its own record:

| Column | Meaning |
| --- | --- |
| `repair_shop_id` | Tenant |
| `user_id` | The team member being given a login |
| `invited_by_id` | Who sent it (User) |
| `email_address` | Where it went |
| `token_digest` | SHA-256 of a random token; unique |
| `expires_at` | 7 days |
| `accepted_at`, `revoked_at` | Nullable |

- Link: `/invites/:token` with a short random token (22 chars), stored hashed.
- One pending invitation per team member (partial unique index on `user_id WHERE accepted_at IS NULL AND revoked_at IS NULL`). Resend replaces it.
- Accept: the link proves the inbox. Ask for the name (prefilled from the team member), then set `email_address` and `verified_at`, mark `accepted_at`, sign in.
- Signed in as someone else: sign out first, as today. Signed in as the invited address already: just join.
- Team settings lists pending invites with Resend and Revoke.

UI words: "No access", "Invited", "Can sign in". Never "placeholder".

## studio-auth change

`ForUser` validates `email_address` presence on every user. Make it conditional, for example `validates :email_address, presence: true, if: :requires_email_address?` with a default of `true`, and Workbench overrides it to "has a login". Lookups by email already skip NULLs. One small gem release before phase 3.

## Phases

Each phase is its own deploy and passes on its own.

### 1. Add the new shape (no behaviour change)

Migrations (one statement each, no loops, strong_migrations rules):

- `add_column :users, :archived_at, :datetime`
- `add_column :users, :pending_email_address, :string`
- `change_column_null :users, :email_address, true`
- Partial unique index on `lower(email_address) WHERE email_address IS NOT NULL`, concurrently. Drop the old unique index in phase 4.
- `create_table :team_invitations` with the columns above, indexes on `token_digest` (unique), `user_id` pending (partial unique), `repair_shop_id`, foreign keys.
- Invitation model, unused for now.

### 2. Backfill (rake, `lib/tasks/backfills.rake`)

`backfills:run:team_members`, idempotent, in batches, with a dry-run count first:

- Placeholder users: `email_address` to NULL.
- Archived users: `archived_at` from `updated_at`; restore the name (strip " (ARCHIVED)") and the email (part after `_archived_`). A restored placeholder email becomes NULL. If the restored email now clashes with a live user, keep it NULL and log it.
- Users with a pending email change (joined, `unverified_email_address` differs from `email_address`): copy to `pending_email_address`.
- Invited users (1 today): no Invitation can carry their old signed token. Leave them; phase 3 shows them as "No access" with an Invite button, and the owner re-sends. Tell that shop, or resend for them.
- Test file: `test/tasks/backfills_test.rb`.

### 3. Switch reads and writes

Rough file list (from grep, 2026-11-16):

- Models: `user.rb` (enum, scopes `active`/`archived`, owner status validations, tokens), `concerns/team_invitable.rb` (rewrite: create member without login, invite, accept, archive, unarchive), new `team_invitation.rb`, `repair_shop.rb`.
- Controllers: `dashboard/users_controller.rb`, `dashboard/users/invitations_controller.rb`, `dashboard/users/archives_controller.rb`, `dashboard/settings/teams_controller.rb`, `dashboard/settings/email_addresses_controller.rb`, `dashboard/settings/email_verifications_controller.rb`, `public/user_invitation_acceptances_controller.rb` (becomes `InvitationsController#show/update` at `/invites/:token`), `public/email_verifications_controller.rb` (drop the dead "first" branch), `admin/dashboard_controller.rb`, `admin/repair_shops_controller.rb`, `portal/shared_links_controller.rb` (check what it reads).
- Services and queries: `email_verification_service.rb`, `dashboard_overview_service.rb`, `queries/data_table_query.rb`.
- Helpers and views: `users_helper.rb`, `settings/teams/_users_panel`, `_user_actions_dropdown`, `shared/_multi_user_checkboxes`, `users/archives/create.turbo_stream`, `users/invitations/*`, `settings/profiles/show`, `admin/repair_shops/index` and `show`, data table filters.
- Mailer: `users_mailer#user_invitation` takes an Invitation; add the short-link fallback back to the Uniform invite pattern if wanted.
- Factories and tests: `factories/users.rb` traits (`:placeholder`, `:invited`, `:unverified`, `:archived`), user, team_invitable, controllers, overview service.
- Analytics events keep their names.

### 4. Drop the old shape (later deploy)

- `ignored_columns` for `status`, `unverified_email_address`, `verification_sent_at` first, deployed.
- Then remove the columns and the old email unique index (needs `safety_assured`, ask first).
- Remove `Enums::UserStatuses`, the `UNVERIFIED` legacy-session guard in ApplicationController, and `after_sign_in` verification once no unverified rows remain (check in console).

## Also worth folding in

- Email change by code instead of link: same six-digit code as sign-in, sent to the new address. Then `Public::EmailVerificationsController` and the 48-hour link token go away.
- `project_assignments` has a table and no model; confirm it's dead and drop it.

## Open questions

- Can an owner be a team member without access? No; owners always sign in. Keep that validation.
- Re-inviting an archived member: unarchive first, or allow invite to unarchive?
- Email uniqueness across shops: today one address is one login across all shops. Keep that (one person, one shop) unless multi-shop membership is on the roadmap.

## Checks before each deploy

- Console counts: placeholder emails remaining, users with NULL email and a session (must be 0), pending invitations.
- Full suite, `bin/ci` with approval.
- Phase 4 only after phase 3 has run a week in production.
