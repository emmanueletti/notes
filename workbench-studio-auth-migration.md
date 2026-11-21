# Workbench: move to studio-auth

Status: sketch, 2026-11-10. Precedent: Belly 50043d1 (rename to email_address), 5159dda (swap to studio-auth), c9bb384, a47128a.

## What the gem fixes in place

- Model names: `::User`, `::Session belongs_to :user`, `users` table, `Current.session`, `current_user`.
- Sign-in: passwordless 6-digit code at `/login` and `/verify`, `DELETE /logout` and `/logout/everywhere`.
- Staff: `users.staff` plus an `@itsusstudio.com` address. Admin lives at `/admin` through `studio_admin(tools: [:jobs, :flipper, :pghero])`.
- Rate limits and lockouts are the gem's, on a shared cache. Workbench already runs `solid_cache_store`.

Workbench differs on every one of these: `TeamMember`, passwords, a separate `InternalStaffUser`, and `/houston`.

## Phases (each one a deploy)

### 1. Rename TeamMember to User (done: e9ec7d90, full rename incl. routes)

- Table `team_members` becomes `users`. `team_member_id` becomes `user_id` on sessions, customer_consent_events, customer_terms_signature_events, job_item_assignments, notes and project_assignments.
- Rename the model, factory, policies, `current_team_member` to `current_user` and `pundit_user`. About 258 files.
- Rename the analytics and monitoring event names that say team_member, or keep them deliberately.
- Workbench runs one instance, so renames use `safety_assured`, the same as Belly.
- Risk: invite, verification and reset links in flight when it deploys stop working, because the token purpose is tied to the old class. They expire within 48h; deploy at a quiet time.
- Decision: keep "team member" as the UI word (recommended), with `User` as the model name only.

### 2. Fold Houston into /admin with staff users

- Staff become `User` rows with `staff: true` and an `@itsusstudio.com` address. Users need a `repair_shop_id`, so staff belong to the internal studio shop (`RepairShop#internal_staff?`).
- Rename namespace `houston` to `admin`. `Houston::HoustonBaseController` becomes `Admin::BaseController` with `Studio::Auth::ForStaffController`.
- Swap the HoustonMountConstraints mounts for `studio_admin(tools: [:jobs, :flipper, :pghero])`.
- Point MissionControl `base_controller_class` at the admin base controller.
- Delete InternalStaffUser, InternalStaffSession, the houston sessions controller, the magic link mailer and `dev_login`. Drop their tables in a later deploy.
- Backfill: a `users_staff` rake task creates or marks staff users from `internal_staff_users`, then remove it once it has run (Belly a47128a).
- Houston actions now emit the gem's `authentication.admin_action` audit events.

Phases 2 and 3 can ship together, since the staff checks need the gem's `Session`.

### 3. Install the gem and drop passwords

Install:

- Add `gem "studio-auth"` to the toolshed block.
- Run `bin/rails generate studio:auth:install`. The migration adds `sessions.last_seen_at` (already there), `users.staff`, and the login code and known device tables.
- Initializer settings:
  - `app_name "Workbench"`, `mail_from`, support email, mail logo, terms and privacy URLs.
  - `session_idle_timeout 30.days` and `session_absolute_timeout 90.days`, which keep today's timeouts.
  - The two staff max ages.
- Include `ForUser` in `User`, `ForSession` in `Session`, and `ForController` in `ApplicationController` and `DirectUploadsController`.
- `Current`: keep `attribute :session`, drop `internal_staff_session`, and keep the monitoring tenant hook.
- `User#can_sign_in?` returns `loginable?` (not placeholder, not archived). That also skips the gem's deliverability check for placeholder and archived addresses.
- Restyle the generated `/login` and `/verify` views to match the current public auth layout. Gem copy ships in en and fr.

Delete:

- The `Authentication` concern. `current_repair_shop` and `identify_in_analytics` move into `ApplicationController` on top of `current_user`.
- The public sessions and passwords controllers, `PasswordsMailer`, the dashboard settings password controller and the profile password form.
- The password strength helper, its JS controller and `_new_password_field`.
- `Unpwnable`, the `pwned` gem and the HIBP counters.
- `has_secure_password` and the `:password_reset` token.
- The `Session` model's own expiry code. The gem's `PurgeExpiredJob` replaces `Session.reapable` in `config/recurring.yml`.

Rework:

- Signup: `Registration` loses `password_digest`. After `complete!`, `start_sign_in_for(owner)` mails a code, and entering it proves the address. In `after_sign_in`, mark an `unverified` owner as verified. The welcome-by-link verification on first signup goes away.
- Invitation acceptance (security: `create` today trusts the posted email, so anyone who knows a pending invitee's address can take the invite; fix here): `accept_invitation(full_name:, email_address:)` without a password. The invite link already proves the inbox, so `create` re-checks the token (it doesn't today) and starts the session directly.
- Archive and unarchive: drop the random password. Unarchive sends nothing, or a "you can sign in again" mail, instead of `PasswordsMailer.reset`.
- Email address change: keep the `unverified_email_address` link flow (`EmailVerificationService`). The gem only signs in to the current address.
- Houston demo accounts: create an owner without a password; staff then sign in by code.
- Rack::Attack: remove the `credentials/ip` and `password_reset/email` rules and the dead `/passwords` and `/session` paths. Keep `token_verify/ip` for the email verification, invitation and portal magic link URLs.
- Sign-out buttons use `logout_path` with `button_to` and DELETE. Login links use `login_path`.
- Existing sessions survive. The cookie is the same signed `:session_id`, and the gem's `active` scope accepts rows with `last_seen_at`.
- App review accounts: none, since Workbench has no native shells.

### 4. Cleanup (later deploy)

- Drop `users.password_digest`, `registrations.password_digest`, and the `internal_staff_users` and `internal_staff_sessions` tables.
- Drop the unused `customers.portal_confirmation_token` and `portal_confirmation_token_expires_at` columns, if you want to while you're there.
- Update `docs/arch/004-rate-limiting.md` and `docs/playbooks/rate-limiting.md`, and the security notes if any.

## Out of scope: the customer portal

The gem covers one user model per app. Portal customers are per-shop records with a 2-week magic link and their own cookie (`:customer_portal_session_id`). That keeps working unchanged under `allow_unauthenticated_access`. A shared customer-auth gem would be a separate standard.

## Tests

- `Studio::Auth::TestHelper` gives `sign_in_as(user)`, `sign_out` and `assert_requires_authentication`. Keep `sign_in_as_new_owner` as a wrapper.
- Add an `AuthenticationSecurityTest` with `Studio::Auth::SecurityTests`.
- Replace `sign_in_as_internal_staff` and `assert_requires_houston_auth` (about 15 uses in 9 files) with staff sign-in and the gem's 404 checks.
- Delete the password tests (17 files touch passwords) and the pwned doubles.
- The system auth helper keeps working because the cookie name is unchanged.

## Open decisions

- Which shop do staff users belong to (internal studio shop or a new one)?
- Do placeholder members get a nullable path, or stay `can_sign_in? false`?
- How do we tell shops that sign-in changes (in-app notice or changelog entry)?

## Follow-ups

- Delete `app/models/team_member.rb` (`TeamMember = User` alias) after 2026-11-18.

## After studio-auth: studio-tenancy (separate project)

- RepairShop splits into Organization (subscription, billing) and Workspace (data).
- users.repair_shop_id, role and status move to OrganizationMembership / WorkspaceMembership (owner, admin, member, guest). Placeholder and invited people become memberships, not fake users.
- repair_shop_id becomes workspace_id on every tenant table; current_repair_shop (about 164 uses) becomes current_workspace, plans via current_organization.
- Plan it on its own once studio-auth has shipped.

## Status (2026-11-11)

- Committed on main (not pushed): `e55cb471 chore(houston): remove demo accounts`.
- Built and passing but uncommitted in the working tree: phase 3 (studio-auth) and phase 2 (Houston to /admin on studio-admin, toolshed 349753a). 2,389 tests, system tests, lint and the production boot all pass; checked in the browser.
- Blocked: the toolshed agent is building standard auth pages for every app. Hold the auth commit until that lands, then:
  - bump toolshed conservatively (only toolshed gems move; plain `bundle update --source toolshed` also bumps aws-sdk, pagy, positioning and i18n-tasks)
  - delete Workbench's overrides if the gem pages fit: `app/views/studio/auth/sign_ins/new.html.erb`, `sign_in_codes/new.html.erb`, `layouts/studio/auth/base.html.erb`
  - rerun `test/integration/authentication_security_test.rb` and the full suite
- Then commit `feat(auth): ...` and `feat(admin): ...` (admin depends on auth; they share Gemfile, lockfile, routes, Current, rack_attack, session_test_helper).
- Fixed along the way: the role enum's `staff` value overrode the gem's `staff?` and `User.staff` (any shop user with the staff role passed the admin check). The role enum now uses `prefix: true` (`role_owner?`, `role_manager?`).
- Decided: staff users live in an internal "Itsus Studio" shop on the staff plan (`users.repair_shop_id` stays required). Placeholders go away with tenancy.
- After deploy: production console sets `staff: true` for `InternalStaffUser.active` addresses (define a stub `InternalStaffUser` model first, since the model is deleted). Then a cleanup deploy drops `internal_staff_users`, `internal_staff_sessions` and both `password_digest` columns.
- Next after that: invitation flow (invite email, then sign in with a code; drop the acceptance token page), and moving the AppSignal config defaults into studio-monitoring.
- 2026-11-11: instead of waiting, ported the toolshed agent's in-progress auth page improvements into Workbench's own copies (`app/views/studio/auth/sign_ins/new.html.erb`, `sign_in_codes/new.html.erb`): spam hint, "Send a new code" with a 60s countdown (`auth--resend-cooldown`), auto-submit at 6 digits (`auth--code-autosubmit`), copy button on the dev code, `autocomplete="username"`, autofocus. New keys in `config/locales/studio_auth.{en,fr}.yml`. Migrate later: once studio-auth ships its standard pages, delete these two views, `layouts/studio/auth/base.html.erb`, `app/javascript/controllers/auth/` and the extra locale keys, and use the gem's. The auth commit no longer waits on toolshed.
- 2026-11-11 later: auth pages restyled on Belly's shell (black panel left, form right, Belly-style floating labels via CSS-only `.field-float` with placeholder=" "), code page ported to toolshed's simpler version ("Check your inbox", address + pencil edit link, resend countdown only), and errors moved inline (`shared/flashes/inline`; field errors under fields). When migrating to the gem's pages, also delete `shared/svg/_pencil`, `controllers/auth/resend_delay_controller.js` and `code_autosubmit_controller.js`.
- Sign-in page prefills the address from the pending code in the session (same as toolshed's uncommitted SignInsController#new). Upcoming gem renames `@email_address_error` to `@field_error`; if Workbench's override views are still around when toolshed is bumped, update them or just delete them for the gem's pages.
- Ported toolshed's later page notes: sign-in errors (including flash alerts: rate limit, expired, too many attempts) now show under the email field. Not ported, waiting on the gem: prefilling the address after expired / too-many-attempts (gem passes flash[:studio_auth_email_address]), (the "Signed out." notice is gone: toolshed bumped to ecf64ab). Workbench already has `yield :head` for the gem stylesheet.
- Signup is one page now (full name, email address, business name, time zone detected from the browser). `Registration` model and its hourly cleanup job are gone; the `registrations` table stays until a cleanup migration drops it (needs approval), alongside the internal staff tables and password_digest.
