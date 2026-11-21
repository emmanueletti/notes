# Belly: move to the studio domain model

Goal: belly matches the studio tenant standard (jean-claude
`plugins/studio-developer/conventions.md`, "Domain model") and signs in through
studio-authentication. Written 2026-11-09. Delete this file once every box is
ticked.

## Where belly is

- `User` is done: `users.email` became `email_address` in 50043d1 (deployed).
- `Organization` is done: renamed from `Space` in 7a30db4, 6efc73f and 91c0262,
  deployed 2026-11-09.
- Before the rename: `Space` (`name`, `space_type` personal/shared) was the tenant. `Membership`
  (`user_id`, `space_id`, `role` owner/member, `is_default`) joined them, already
  the standard's shape.
- 8 tables carry `space_id`: bulk_imports, grocery_items, memberships,
  planned_meals, planned_notes, playlists, recipes, tags.
- Code: `current_space` (about 140 uses in 57 files), `personal_space` (about
  180 in 67), `default_space` (14 in 9), `Current.space` (4 in 2), `Space` (22
  in 14).
- Only personal spaces exist; nothing creates a shared one, and there is no
  Invitation model.
- Billing belongs to the user (`owner` polymorphic, only `User` in dev). Fine
  for a consumer app.
- Sign-in is belly's own (`AuthCode`, `LoginCodeRequest`, `LoginCodeDelivery`,
  `PendingVerification`, public sessions, verifications and signups
  controllers). The first studio-authentication attempt is in `git stash`
  ("studio-authentication first pass").

## Decisions to make first

- [x] Personal flag: kept the enum as `kind` (personal/shared),
      `Enums::Organizations::Kinds`.
- [x] Roles: `admin` waits for shared organizations.

## 1. Rename Space to Organization

One migration, one commit, `safety_assured` like the email rename. Belly runs
one instance, so old code errors only while a deploy swaps processes.

- [x] Check production for stored class names first:
      `Billing::Subscription`/`Billing::Grant` `owner_type` and `LlmGeneration`
      `subject_type` must have no `"Space"` rows. If any do, add a backfill task
      before the rename.
- [x] Migration: `rename_table :spaces, :organizations`,
      `rename_column :organizations, :space_type, :kind`, and `space_id` →
      `organization_id` on the 8 tables. Ids stay the same, so PostHog `tenant`
      groups and AppSignal history carry over.
- [x] Code: `Space` → `Organization`, `Enums::Spaces` → `Enums::Organizations`,
      `current_space` → `current_organization`, `personal_space` →
      `personal_organization`, `default_space` → `default_organization`,
      `Current.space` → `Current.organization`, `space:` associations and
      factories, the admin `admin/spaces/:id` route.
- [x] The word "space" in Tailwind classes (`space-y-4`) and copy is not the
      model; rename only Ruby and ERB references to the model.
- [x] UI stays "Space": `display_name` and the signup name keep "'s space"
      (hardcoded English, not i18n yet). Skipped `activerecord.models.organization`:
      nothing calls the model's human name.
- [x] Commit: 7a30db4 `refactor(organizations): rename Space to Organization`,
      6efc73f for two test names, 91c0262 for seeds and lint config.
- [x] Full `bin/ci` green, deployed 2026-11-09.
- [x] Docs: the CLAUDE.md rewrite landed with no stale `space` model refs.
- [x] Deployed. (A `ReparseIngredientsJob` queued with scope `"space"`
      before the deploy would fan out to every organization; admin-only, low
      risk.)

## 2. Adopt studio-authentication

Needs the gem committed and pushed in toolshed first.

- [ ] Credentials (human): add `studio_authentication.review_accounts` with at
      most 2 entries (one Apple, one Google), 6-digit codes, in development,
      staging and production. Remove the old `app_review` key. Production needs
      the human's key: `bin/studio credentials-edit production`.
- [ ] Check each review account is an isolated demo account: its own personal
      organization, demo data, no admin, no shared organizations. Insider access
      through a free grant only if review needs it.
- [ ] Gemfile: add `studio-authentication` to the toolshed block,
      `bundle update --source toolshed`.
- [ ] `bin/rails g studio:authentication:install`: creates `studio_authentication_login_challenges`
      and `studio_authentication_known_devices`, adds `last_seen_at` and `authenticated_at` to
      sessions. Existing sessions keep working.
- [ ] Initializer: `app_name`, `mail_from`, `support_email`.
- [ ] Models: `include Studio::Authentication::User` and `Session`; drop belly's
      own sessions association, email validation and normalization, and the
      `login_link` token.
- [ ] Controllers: `include Studio::Authentication::Controller`. Keep belly's
      `after_sign_in_path` (`activate!`, dashboard) by overriding
      `after_authentication_path`. The Hotwire Native 401 is built in.
- [ ] Signup: after saving the user and personal organization, call
      `start_sign_in_for(user)`.
- [ ] Delete `AuthCode`, `LoginCodeRequest`, `LoginCodeDelivery`,
      `PendingVerification`, `SessionsMailer`, the public sessions and
      verifications controllers and views, and their tests. Remove the code-send
      and code-verify rules from `config/initializers/rack_attack.rb` (the gem
      rate limits). Drop the `bcrypt` gem.
- [ ] `ApplicationMailer`'s review-account skip reads
      `Studio::Authentication::ReviewAccounts.include?`.
- [ ] Pages: `bin/rails g studio:authentication:views`, then restyle with
      belly's auth shell layout. Paths stay `/login` and `/verify`, so shipped
      native apps keep working. `/login-link` goes away; drop it from
      `AUTH_PATTERNS`.
- [ ] Add a "Sign out everywhere" button in settings (`logout_everywhere_path`).
- [ ] Schedule `Studio::Authentication::PurgeExpiredJob` in
      `config/recurring.yml`.
- [ ] Tests: add `AuthenticationSecurityTest` with
      `Studio::Authentication::SecurityTests`. Belly's test cache is
      `memory_store`, so clear `Rails.cache` between auth tests or the gem's
      rate limits fire.
- [ ] Check every email at `/rails/mailers/studio/authentication/mailer`, in
      each locale.
- [ ] Deploy notes: codes and links sent just before the deploy stop working;
      the old `users.login_code_*` columns are dropped in a follow-up migration
      once this is live.

## 3. Toolshed gems

Checked every gem for tenant concepts. Only studio-authentication (done),
studio-monitoring and studio-flags touch them; studio-cache's `actor:` only
passes through to Flipper, and the rest have none.

- [ ] studio-monitoring: no API change. `actor_id` and `tenant_id` are already
      generic, and the PostHog group type stays `"tenant"` (renaming a group
      type loses its history). Update the README examples from `user.space_id`
      and `space.id` to `organization.id`.
- [ ] studio-monitoring README: add the standard `identify_tenant` properties
      so every app's PostHog groups line up: `name`, `kind`, `member_count`,
      `plan`, `created_at`. Workbench sends plan and size today; belly sends
      none.
- [ ] studio-flags README: gate per organization in B2B apps
      (`Flipper.enabled?(flag, current_organization)`) and per user in consumer
      apps. Active Record models already have `flipper_id`, so `Organization`
      works as an actor with no code.
- [ ] Later, not now: each app registers its own Flipper groups (belly
      `:admins`, workbench `:internal_staff` and `:internal_repair_shops`). Once
      workbench is on the standard too, move the shared ones (`:admins` on
      `User#admin?`, an internal-organization group) into studio-flags. Same rule
      as the models: extract after two apps match.

## 4. Later, when shared organizations ship

- [ ] `Invitation` per the standard. Accept pending invitations in
      `after_sign_in(user)`.
- [ ] Organization switcher and `Current.membership`.
- [ ] `Current`: `attribute :organization` with `Current.organization=` setting
      `Studio::Monitoring::Current.tenant_id`, set from the chosen membership.
      Today `Current#organization` derives it from the user (default, else
      personal), which is enough while every user has one organization.
