# studio-auth: one omakase sign-in and sign-up for every app

Written 2026-11-17. Status: building.
Repo: ~/projects/itsusstudio/toolshed (gems/studio-auth), then workbench and belly.
Supersedes: phase 2 ("unified Continue with email") of the 2026-11-11 version of this plan. Phase 1 shipped: the gem owns the sign-in and code pages, built from Uniform (70b0666 and after).

## Problem

Sign-up is split between the gem and each app, and the split causes real failures. On 2026-11-17 a mistyped email address on Workbench's /login got a sign-up code and the normal "Check your email" page, so it looked like a sign-in. The code never reached the real inbox, three tries were rejected, and it read as a lockout. It took production logs to work out what happened. Each app also carries its own sign-up controller, session hand-off and tests, and they drift: Belly creates the user before the code is checked, Workbench after.

## Who

Every studio app's new users and the studio itself. Workbench (repair studios, the ICP) and Belly move first. Any future app gets sign-up for free.

## Evidence

- 2026-11-17, the founder signing in to Workbench production: a mistyped address looked like a successful request, and three rejected codes followed (Render logs, 18:09 to 18:11 UTC). Single source, but the failure is structural, not a one-off.
- 2026-11-11: one small change (spam hint, resend, autofill) needed edits in the gem, the dummy app, Belly and Workbench. That's why phase 1 happened.
- Code today: Workbench `Public::SignupsController` plus `PendingSignup` (about 100 lines), Belly `Public::SignupsController`, and gem API built only to bridge them (`start_sign_up_for`, `create_account_for`, `verified_email_address`).

## Decisions already made

- The gem owns every auth page: /login, the new-account page, /signup, /verify, invite acceptance and sign out. Same pages in every app. Apps don't override views.
- Sign-up asks only for email address and `full_name`. `full_name` is the studio standard column, so Belly renames `name`.
- A `User` is always complete. A verified sign-up waits in the gem's `studio_auth_pending_sign_ups` table until the app's setup finishes, then the app creates the user and its tenant together. Apps never handle half-made users or null tenant references. This follows Clerk's separate `SignUp` object rather than Devise's unconfirmed users.
- Workbench keeps team members who can't sign in as `User` rows with no email address. Splitting them into a separate table adds no value.
- An email address with no account gets the Amazon-style page ("Looks like you're new to Workbench", "Create an account", "Use a different email address"). We accept that this reveals which email addresses have accounts, as Google, Microsoft and Amazon do.
- The app owns two separate things after that:
  - Setup is everything the app needs to work (a tenant, required settings). It happens before the user exists, so a user can't skip it. A gate is only needed later, if a new required setting is added for existing users.
  - Onboarding is activation: teaching the app and welcoming the user. It's never a gate.
- The gem is tested once, deeply. Apps include the shared `SecurityTests` and test only their own hooks and setup screen.
- Belly's native shells change with Belly's bump. They already treat /signup as an auth path (`path-configuration.json`, `AuthPaths.kt`); check the rest in that slice.
- No passwords, no social sign-in. Google and Microsoft sign-in stay deferred.

## Deliberately out of scope

- Onboarding content for any app. Workbench's lives in `workbench-onboarding-plan.md`.
- Invite-only apps (a "no new accounts" setting). Add it when an app needs it.
- Restyling the mail or the auth shell.
- Account deletion, email address change (Workbench owns that today) and session management pages.

## Approach

Finish the work already in toolshed (uncommitted on 2026-11-17), then move sign-up into the gem and delete the app copies.

Already built, not committed:
- The new-account page for email addresses with no account, kept at /login so native shells need no new path. Apps without sign-up show an error under the field instead.
- "Don't have an account? Create one" under the email field.
- "Send a new code" always mails a fresh code and ends the old one.
- fr and nl copy, README, and the shared security test updated.

From the 2026-11-17 security audit:
- A resend counts only when the email address matches this browser's pending code, so `resend=1` can't skip the account check for any address. Done.
- Dropped: failing closed when the cache rate limit can't be checked. Both apps use `solid_cache_store` in production, so the limit lives in Postgres and can't fail separately from the database.

Then the gem's sign-up:
- `GET /signup` renders the gem's form: full name and email address, prefilled from the new-account page, plus a hidden field with the browser's time zone. `pending_sign_up` and `prepare_new_user` both get it.
- `POST /signup` mails a sign-up code. An address that already has an account gets the normal sign-in code, because signing in is the right outcome.
- On a verified code with no user, the gem writes a pending sign-up (email address, full name, verified at) and a browser cookie for it.
- Apps with setup define `sign_up_setup_path`. The gem sends the person there, and the app's setup screen reads `pending_sign_up`, creates the tenant and the `User` in one transaction and calls `finish_sign_up(user)`. That deletes the pending row and starts the session.
- Apps without setup (Belly) don't define it. The gem creates the user straight away, calling `prepare_new_user(user)` for the app's defaults, then `after_sign_up(user)` for where to go.

When an email address is typed on /login, the gem checks in this order:
1. `users`: a normal sign-in code.
2. `studio_auth_pending_sign_ups`: a code, then straight back to setup ("Finish setting up your account").
3. Neither: the new-account page.

Accepting an invitation deletes any pending sign-up for the same email address, so `finish_sign_up` never collides with a user the invitation created.

## Flow

1. The person types an email address on /login.
2. If it has an account, a code goes out and they land on /verify, as today.
3. If it doesn't, they see the new-account page. "Use a different email address" returns to /login with the typo filled in. "Create an account" opens /signup with the address filled in.
4. On /signup they add their full name and submit. A code goes out.
5. On /verify the code checks out and the gem saves a pending sign-up.
6. The app's setup screen asks what the app needs (Workbench: the studio's name and time zone). On submit the app creates the studio and the user together, and the person is signed in.
7. If they leave during setup, they come back by typing the same email address on /login, on any device, for 30 days.
8. Onboarding starts inside the app.

Deliberately absent: no sign-up through /login, no business fields on the sign-up form, no user row until setup is done.

## Gem API after the change

App hooks, overridden in the app's ApplicationController:
- `sign_up_setup_path` sends a verified sign-up to the app's setup. Leave it undefined to have the gem create the user directly.
- `prepare_new_user(user)` sets the app's defaults before the first save, for apps without setup.
- `after_sign_up(user)` returns a path. It defaults to `after_authentication_path`.
- `after_sign_in(user)`, `after_invitation_accepted(user)` and `can_sign_in?` stay as they are.

Helpers for the app's setup screen: `pending_sign_up` (email address and full name) and `finish_sign_up(user)`.

Removed: `create_account_for`, `start_sign_up_for` as public API, `verified_email_address`, `verified_email_address?` and `new_account_email_address`, because nothing outside the gem needs them now.

Test helpers stay as they are (`sign_in_as`, `sign_out`, `assert_requires_authentication`, `assert_allows_unauthenticated_access`, `SecurityTests`). `assert_requires_staff` moves from Workbench into studio-admin.

## Data and model changes

- Gem: new table `studio_auth_pending_sign_ups`, added by the install generator and an upgrade migration in each app. Columns: `email_address` (unique, normalized, NOT NULL), `full_name` (NOT NULL), `time_zone` (from the browser, NULL if it sent none or sent one Rails doesn't know), `expires_at` (30 days). The browser holds a signed cookie with the row id, like a session cookie, so no token column. Rows only exist once a code checked out, so no `verified_at` either. Identity only: the app's setup answers never go in it. `PurgeExpiredJob` deletes expired rows with the expired codes. The privacy policy mentions the 30 days.
- Belly: rename `users.name` to `users.full_name` (expand and contract per `rails-database-migrations`). `timezone` stays NOT NULL and is set in `prepare_new_user` from `User::DEFAULT_TIMEZONE`, with `timezone_auto` detecting the real one later.
- Workbench: none for sign-up. `users.repair_shop_id` stays NOT NULL.

Cleanup found on 2026-11-17. Columns are not dropped yet: dead ones stay in each model's `ignored_columns` until a later decision.
- Both apps: `studio_auth_login_codes.email_address` becomes NOT NULL. Only codes from before address-keyed codes lack it, and they expired long ago. Delete any such rows first, in a rake task, not the migration.
- Belly: add `user_id` to the gem's `LoginCode` ignore list only if Belly still has the column when commit 3 lands; the foreign key stays.
- Belly: drop the `""` default on `users.email_address`, so a missing address fails instead of saving blank. This changes a default, it doesn't drop a column.
- Already ignored and staying that way: Workbench `users.password_digest`; Belly `admin`, `default_layout`, `first_signed_in_at`, `login_code_attempts`, `login_code_digest`, `login_code_expires_at`.

## Risks

- The setup screen runs before any session exists, so it must work as a public page that reads only `pending_sign_up`. Treat it as untrusted input like any sign-up form.
- Belly's shipped iOS and Android builds can't handle a change to /login or /verify, which is why the new-account page renders at /login. /signup becomes the gem's page, which the shells already treat as an auth screen. Check it on both before release.
- Belly's current sign-up creates the user before the code. Accounts it created but never verified stay valid, so there's nothing to clean up.
- Losing the "hide which email addresses have accounts" property is a decision we made, not an accident. The audit fixes keep lookups rate-limited.

## Rollout

The gem ships through each app's lockfile bump, not a Flipper flag, because the auth pages can't run two versions side by side cleanly. Rollback is reverting the app's bump commit.

1. Workbench first: fewer users, and it's the app where the typo happened.
2. Belly second, with the native check and the `full_name` rename.

## Success metric

Sign-up completion: of people who submit /signup, the share who finish setup within 7 days. Track it in PostHog with two new events, `authentication.sign_up_started` and `authentication.sign_up_completed`, and count abandoned rows in `studio_auth_pending_sign_ups`. Target: 80% or more over the first 30 days after Workbench's release. Stop and rethink if it's under 60% by 2026-12-31.

Secondary, with no threshold: lines of sign-up code in each app, which should drop to the hooks plus the setup screen.

## Commits

Toolshed:
1. `feat(studio-auth): send unknown email addresses to a new-account page`, with the fresh code on resend and the resend audit fix. One commit, because the resend flag is what keeps sign-up resends working once /login needs an account.
Refactors before group 2, no behaviour change, the existing tests unchanged:
- R1. `refactor(studio-auth): keep domain objects in app/models`: move `TypedInput`, `Secrets`, `SessionDevice` and `AppReviewAccounts` out of `lib`. Constant names stay.
- R2. `refactor(studio-auth): move sign-in limits out of LoginCode` into `SignInLimits`, a model that only answers questions (resend window, mail budget, IP limit, lockout).
- R3. `refactor(studio-auth): request and verify codes in services`: `RequestCode` and `VerifyCode` in `app/services` do the writes, locks and mail. `LoginCode` keeps the record, scopes and predicates.
- R4. `refactor(studio-auth): split ForController by job` into authentication, session lifecycle and return path concerns. `ForController` still includes them, and the sign-up bridge stays until commit 3 deletes it.

2. `feat(studio-auth): keep verified sign-ups pending until the app's setup`, adding the table, the generator and upgrade migration, the purge, the lookup order and the invitation rule.
3. `feat(studio-auth): own the sign-up page`, adding the hooks, helpers and time zone field and removing the bridging API.
4. `feat(studio-admin): add assert_requires_staff`.

Workbench:
5. Cleanup: `studio_auth_login_codes.email_address` NOT NULL (rake task, then migration).
6. Bump the gem and add the pending sign-ups migration. Setup screen creates the studio and owner and calls `finish_sign_up`. Delete `Public::SignupsController`, `PendingSignup`, their routes, views and tests, and use the gem's `assert_requires_staff`.

Belly:
7. Cleanup: `studio_auth_login_codes.email_address` NOT NULL and the `""` email default.
8. `users.name` to `users.full_name`, expand step.
9. Bump the gem, which also carries the uncommitted admin redirect test changes from 2026-11-17. Add the pending sign-ups migration and the hooks, delete its signup controller and views, and check the iOS and Android shells.
10. Contract step for `name`, keeping `name` in `ignored_columns` instead of dropping it.

## Progress

Built 2026-11-17, committed in toolshed, not pushed:
- `4146f94` commit 1, the new-account page.
- `5408b84`, `a31e636`, `fd71b2e`, `3f9dd48` R1 to R4.
- `d9082f5` rate limits: 5 codes an hour per address (was 10), and "Send a new code" waits 30 seconds after the last code. Added after the build started.
- `cf87519` commit 2, pending sign-ups.
- `8f27521` commit 3, the gem's sign-up page. The form wraps a hidden `time_zone` field in `<u-time-zone>`, which does nothing until Uniform defines it; until then every sign-up has no time zone.
- `0766181` commit 4, `Studio::Admin::TestHelper#assert_requires_staff(user)`.
- Uniform `479b610`: `<u-time-zone>` and `<u-countdown>`. Toolshed `4f46277`: the code page counts down to the next code, from when the code went out. Each app's bump also takes Uniform `479b610` or later, or the time zone stays blank and there's no countdown.
- `19aa962` security review fixes: `c.sign_up` has no default and boot fails until the app sets it, and the pending sign-up cookie lasts 1 hour (not 30 days) and clears on sign-in and sign-out.

Each app's bump must, in the same commit, delete its own signup routes (the gem now draws `signup`) and set `c.sign_up = true` in its initializer, or the app won't boot.

## Next steps

1. Approved 2026-11-17.
2. Build R1 to R4, then commits 2 to 4, testing each app against the local gem.
3. Workbench commits 5 and 6, release, then watch the completion metric for a week.
4. Belly commits 7 to 10.

## Open questions

- AppSignal received no Workbench logs between 2026-11-16 and 2026-11-17, while Render has them. It's separate from this plan, but it hid this incident. Owner: founder.
