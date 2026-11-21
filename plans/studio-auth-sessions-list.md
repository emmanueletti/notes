# Sessions list (studio-auth first, then Belly)

Drafted 2026-11-11. Replaces Belly's lone "Log out everywhere" button with a
list of signed-in devices, per-row log out, and "Log out other devices".

## Goal

Settings > Account shows every active session:

```
Sessions

[phone]  Belly for iPhone            This device
[laptop] Chrome on macOS                  Log out
         Active 2 hours ago
[laptop] Safari on macOS                  Log out
         Active 3 weeks ago

            [ Log out other devices ]
```

## Decisions

- No location. Needs a GeoIP database (new dependency) and fights the
  planned IP/UA encryption (see belly-pii-encryption memory).
- No user-agent gem. A small hand mapping in studio-auth covers the browsers
  and OSes we see. Bring in a gem only if the mapping starts growing per bug.
- Bulk action keeps you signed in ("Log out other devices"). The current
  "Log out everywhere" route stays for now; Belly stops linking it. Remove it
  from the gem once no app links it.
- "Active" is coarse: last_seen_at only updates once an hour
  (SESSION_TOUCH_THROTTLE). Under an hour shows "Active in the last hour",
  not "Active now". The current session shows "This device" instead.
- Plumbing lives in studio-auth (routes, controller, model, device naming,
  security tests). The list markup lives in each app, so it follows that
  app's design system.

## Phase 1: studio-auth (toolshed/gems/studio-auth)

Routes, inside the existing `studio_auth` macro:

- `delete "logout/others", to: "sessions#destroy_others", as: :logout_others`
- `delete "logout/sessions/:id", to: "sessions#destroy", as: :logout_session`

New `Studio::Auth::SessionsController < BaseController`:

- `destroy`: `current_user.sessions.find_by(id:)`. Nil or the current session
  is a no-op redirect (gone = already done; the current one has no button and
  logs out via `logout_path`). Otherwise destroy, `disconnect_cable([it])`,
  notify `authentication.session_ended` with actor_id.
- `destroy_others`: delete every session except `current_session`, disconnect
  their sockets, expire live login codes, forget known devices other than
  this browser's (`device_token_digest` from DeviceCookie), notify
  `authentication.other_sessions_ended`.
- Both `redirect_back_or_to main_app.root_path, status: :see_other` with a
  flash. Move the shared session-ending steps out of
  `terminate_all_sessions` into a private helper both paths call.

ForSession additions:

- `scope :ordered_by_last_seen_at_desc` (nulls last).
- `device` returning a `Studio::Auth::SessionDevice` PORO built from
  user_agent: `kind` (:phone, :tablet, :computer) and `name`.

`Studio::Auth::SessionDevice` (lib/, pure):

- Hotwire Native first: "<App> Hotwire Native iOS|Android" in the UA gives
  "<product name> for iPhone|iPad|Android". Product name comes from config
  (add `Auth.config.product_name`, or read it from studio-settings if both
  apps already expose it there; check before adding config).
- Else browser (Edge, Chrome, Firefox, Safari, in that match order) and OS
  (iOS, iPadOS, Android, macOS, Windows, Linux) gives "Chrome on macOS".
- Unknown or blank gives "Unknown device".
- Labels via the gem's i18n (en, fr, nl) for the "on" / "for" joins and
  "Unknown device". Browser and OS names stay untranslated.

Tests (gem):

- SessionDevice unit tests from a fixture list of real UAs (Belly iOS,
  Belly Android, Chrome mac, Safari iPhone, Firefox Windows, Edge, blank).
- Controller: destroy ends only that session and its sockets; another user's
  session id is a no-op and that session survives; current session id is a
  no-op; destroy_others keeps the current session and cookie, ends the rest,
  keeps this browser's known device.
- SecurityTests (shared into apps): add "cannot end another user's session".

Ship flow per toolshed change flow memory: edit toolshed, test in Belly via
Gemfile path swap, commit/push toolshed after approval, restore the git block,
`bundle update studio-auth`. Workbench gets the routes too, unused until it
adds UI.

## Phase 2: Belly UI

- `Dashboard::SettingsController#account` (and the show modal path) loads
  `current_user.sessions.active.ordered_by_last_seen_at_desc`.
- New partial `dashboard/settings/_sessions.html.erb` in the account panel,
  between the account fields and the danger card. 48px rows: Lucide
  `smartphone` / `tablet` / `laptop` icon, name, sub-line (This device or
  Active ...), per-row "Log out" as `button_to logout_session_path(session)`.
- "Log out other devices" button shows only when other sessions exist (keep
  today's `many?` gate). Drop the "Log out everywhere" button.
- Forms target `_top` like today's logout buttons, or answer with a turbo
  stream that removes the row; decide in build (hotwire-conventions: a
  stream removing one row is the nicer fit inside the modal).
- Copy (propose EN first, then fr-CA and nl): "Sessions" heading, "This
  device", "Active in the last hour", "Active %{time} ago", "Log out",
  "Log out other devices", flashes.
- Controller tests: list shows each active session by data-session-id,
  expired sessions left out, current one has no log out button.
- Chrome check at desktop and 390px with the dev account's 4 sessions.

## Open questions

- Single-row log out cannot forget that browser's known device: sessions
  don't record a device token. Fine for now (trust only lets a new code
  request take over a pending one). Revisit if sessions gain a device link.
- Do we still need "Log out everywhere" anywhere (e.g. after a suspected
  breach)? If yes, keep it in the danger card instead of removing it.
