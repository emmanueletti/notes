# Belly: idiomatic Hotwire Native chrome

Status 2026-11-05 (evening): phases 0-4 built uncommitted in wt-belly, verified on Android and the iPhone/iPad sims. See "Build-out results" below and ~/notes/handoffs/belly-native-chrome-buildout.md.

## Goal

Make the iOS and Android apps look and behave like stock Hotwire Native apps:
native navigation bar, native back, native titles, native bar buttons and
menus, native sheets, platform-owned safe areas. Delete the web-side
workarounds that exist only because the web draws its own app chrome.

Trigger: the iPad recipe page shows a huge empty band above the back/Edit row.
The band is the iPad's top tab bar safe area painted white by
`NATIVE_SHELL_TOP_CLASS`, plus the web header row under it. Patching that one
screen would add another workaround on top of the same root cause.

## Root cause

One path configuration rule: the `.*` catch-all sets `navigation_bar: "hidden"`
on both platforms (`server/app/controllers/hotwire/configurations/ios_controller.rb:10`,
`android_controller.rb:19`).

- Commit deac731 meant to hide the bar only on tab roots, where the web header
  duplicated it. The catch-all spread it to every pushed screen.
- Commit 01da58b copied it to Android for parity.

With the bar hidden, the web has to carry back, titles, actions and top
spacing itself, and the shells fight their own defaults to make room:

iOS
- `contentInsetAdjustmentBehavior = .never` (`AppDelegate.swift:49`)
- `setNavigationBarHidden` per screen (`BellyVisitableViewController.swift:48-50`)
- `SwipeBackGestureDelegate` to bring back the swipe UIKit turns off with the bar hidden (:52, :168-189)
- tab bar overlap math pushed into `--tab-bar-h` with `evaluateJavaScript` (:98-133)

Android
- toolbar hidden plus hand-made status bar padding (`WebFragment.kt:25-34`)
- `hideTopInsetFromPage` so the page doesn't pad twice (`WebDestinationHooks.kt:66-75`)

Server
- `--shell-top`, `NATIVE_SHELL_TOP_CLASS`, `MAIN_EDGES native:pt-[...]` and about 15 files of sticky offsets
- `_page_header` and `back_btn` with `back_recede` / `back_replace` and the `history-back` controller
- separate h1 titles because `<title>` never shows

The second source of workarounds is in-page web `<dialog>` sheets (the
`global_modal` frame). They have no URL, so native can't present them. That's
why the `dismiss` bridge component exists (Android back), part of why
`freshness` exists, and why `modal_turbo_frame_id_unless_native_app` is
everywhere. The TODO in `server/app/views/shared/_modal_dialog.html.erb:2-23`
already plans moving them to URL sheets.

## Target model

The web renders content. Native owns:

- Navigation bar: visible on every screen except immersive ones (auth,
  onboarding, cook mode, source video). Title from `<title>`. Back is the
  native stack's back button.
- Bar actions: bridge components put buttons and menus in the native bar. The
  web keeps a plain HTML control that the component clicks.
- Insets: iOS default content inset adjustment, Android stock AppBarLayout and
  window insets. The web never reads `env(safe-area-inset-top)` in native.
- Presentation: every sheet is a URL with a path configuration modal rule
  (`context: modal`, `modal_style`).
- Tabs: the platform tab bar, with the iPad sidebar style on regular width.

Reference: hotwire-native-demo (Rails, `app/assets/stylesheets/native.css`,
`app/javascript/controllers/bridge/`) and the Demo apps in hotwire-native-ios
1.3.1 / hotwire-native-android 1.3.2 (`Demo/Bridge/{Form,Menu,OverflowMenu}Component`).
Port from those tags; don't invent the API.

## Compatibility with installed app builds

Path configuration and pages come from the server, so old builds would pick up
changes before they update. Two mechanisms keep each build consistent:

1. Versioned path configuration. New builds load
   `/hotwire/configurations/{ios,android}/v2.json` with the bar visible. `v1`
   is frozen for old builds. Remote path configuration URLs are versioned for
   exactly this reason.
2. Capability-gated web chrome. hotwire-native-bridge sets
   `data-bridge-components` on `<html>` from the user agent. Web header
   controls hide only when the matching component is registered, the way the
   demo's `native.css` does it:

   ```css
   [data-bridge-components~="button"] [data-controller~="bridge--button"] { display: none; }
   ```

   Server-side branches (header partial, title h1) check the same list through
   a helper that parses the user agent's `bridge-components: [...]`, never the
   app version.

With both in place, server changes deploy at any time. Old builds keep today's
look, and new builds get the native look the moment they ship.

Cleanup of the old paths waits until old builds stop showing up. One week after
the release, a flag turns on an upgrade nudge for builds without the `button`
component (decision 5).

## Phases

### Phase 0: spike on recipe show

Prove the model end to end on one screen before converting anything.

- iOS: v2 config with the bar visible on `/dashboard/recipes/\d+`, default
  insets on that screen, port an Edit `button` component.
- Android: the same with the stock toolbar.
- Server: hide `page_header` when `button` is registered. Title from
  `content_for :page_title`.
- Check on the iPhone 17 Pro sim, the iPad Pro 11 sim (studio Mac) and the
  Android emulator: title, back, swipe back, Edit, sticky elements, pull to
  refresh, scroll under the bar, hero photo under the bar.
- Measure cold start with stock `HotwireTabBarController` on 1.3.1 against the
  lazy `BellyTabBarController` (the ~1.3s reason is from an older version).

Exit: screenshots of all three form factors, and a decision on the questions
below.

#### Phase 0 results (2026-11-05)

Built uncommitted: v2 endpoints (v1 rules + `NATIVE_BAR_PATTERNS`), the
`native_bar?` / `native_bridge_component?` helpers, `body[data-native-bar]`
zeroing `--shell-top`, `button` component on web/iOS/Android, iOS inset
behaviour per screen in `visitableDidActivateWebView`, bundles regenerated
from v2.

- iPad Pro 11: the gap is gone. Glass back and Edit buttons beside the top tab
  bar, title under it, photo under the bar.
- iPhone 17 Pro: iOS 26 glass bar, edge effect on scroll, Edit opens the form.
- Android: stock toolbar with title, up arrow and EDIT. Works, looks unstyled
  (all caps action, system font, grey bar). Theming is phase 1 work.
- Old builds: v1 untouched, gating is by the `button` component in the UA.

Findings to carry into phase 1:
- Android first launch after update showed the v2 page (no web header) with
  the native bar still hidden: the cached v1 rules won until the remote v2
  loaded. Relaunch fixed it. A user's first screen after updating could have
  no back and no Edit. Fix before release: either the app clears the cached
  config when the URL version changes, or the server gates on the bridge
  component and the native side also forces the bar for the same pages.
- iOS: on first render the content inset only cleared the status bar, so the
  hero sat under the nav bar. Pleasant on a hero page, wrong on text pages.
  Find out why (likely content inset applied after load, so the offset never
  moved) before converting a page without a hero.
- The title duplicates the page h1 on recipe show. Decide per screen: blank
  native title until scrolled, or drop the h1 in native.
- Edit still uses `turbo_action: replace`, so back from edit skips the recipe.
  Goes away when edit becomes a sheet (decision 3).
- Not measured yet: cold start with stock `HotwireTabBarController`.

### Phase 1: native foundations (both apps, one release each)

- Bridge components ported from the demo tags: `button` (text or SF Symbol /
  drawable, primary or plain), `menu` (iOS menu / Android bottom sheet list),
  `form` (submit in the bar, disabled while submitting). Add `haptics` on
  Android or drop the web calls there.
- Nav bar appearance: DM Sans titles, brand tint, light only (matching today).
  iOS large titles on tab roots only if we choose that below.
- iOS: delete `.never`, `setNavigationBarHidden`, `SwipeBackGestureDelegate`
  and the `--tab-bar-h` injection for v2 screens. Keep `navigation_bar` as an
  opt-out for immersive screens only.
- Android: delete the toolbar hide, status bar padding and
  `hideTopInsetFromPage` for v2 screens. Bump Material / AndroidX to the
  demo's versions.
- Point both apps at v2 path configuration. Regenerate the bundled copies.
- Server: `v2` endpoints, a `native_bridge_component?(name)` helper, and
  `native.css` rules for the gated controls.
- Server: upgrade nudge for old builds, behind a Flipper flag that stays off
  until a week after release.
- Both apps: Add as a `+` bar button on the Recipes root (and Plan), opening
  the add chooser sheet.

### Phase 2: convert screens

The work is mostly `_page_header` (13 dashboard callers) plus sticky offsets.
Admin uses its own partial and is out of scope.

Per screen: native title, native back, actions as components, delete web back
and h1 in native, sticky elements at `top: 0` in native.

| Screen | Bar action |
| --- | --- |
| Recipe show | Edit (`button`), owner actions in `menu` |
| Recipe new, manual import, edit (sheet) | Cancel, Save (`form`) |
| Playlist show | overflow `menu` |
| Playlist new/edit (sheet) | Cancel, Save (`form`) |
| Playlists index, shares, shared playlists | none |
| Settings and subpages, tags | none |
| Grocery list | overflow `menu` (when not empty) |
| Party show, edit | `menu`, Save |
| Week plan | groceries action as `button`; week switcher stays a web row under the bar |
| Recipes index | search and control row stay web, sticky at `top: 0` |

Immersive screens keep the bar hidden on purpose: auth, onboarding (6), cook
mode, source video. Their own safe area handling stays.

Party show: transparent native bar over the cover (decision 4).

### Phase 3: web dialogs to URL sheets

Work through the `_modal_dialog.html.erb` TODO list: grocery item edit,
grocery list menu, recipe menu, plan and meal type sheets, playlist choices
and share, party/dish/task menus, week plan day sheets, cook mode step list,
nudges. Menus that are just a list of actions become `menu` components
instead of sheets.

When the list is done, delete in native: `bridge--dismiss` (except the quick
add card if it stays), `modal_turbo_frame_id_unless_native_app`, the
`.native-sheet` header-hiding hooks, and the `freshness` calls that only
covered dialog writes.

### Phase 4: tab bar

Add is out of the tab bar (decision 2), so try the stock controllers:

- Stock `HotwireBottomNavigationController`
  on Android (deletes `MainTabBar`'s copy of the library's private
  `switchTab`, and the selected index in `MainActivityViewModel`), and stock
  `HotwireTabBarController` on iOS if phase 0 shows the cold start is fine
  (deletes `LazyNavigatorViewController`, the manual reselect-to-root and the
  `containing()` casts).
- iPad: `mode = .tabSidebar` on regular width.
- Re-check whether `TabNavigation` (ADR 0004 queue) is still needed once
  dialogs and the hidden-bar plumbing are gone. Keep it unless the races are
  gone.

### Phase 5: iPad layout

Readable content width inside the native chrome, split recipe layout at
regular width, sheets as form sheets. Verify both orientations.

### Phase 6: cleanup after old builds age out

On the trigger above:

- delete the v1 endpoints and the `navigation_bar: hidden` catch-all
- `--shell-top`, `NATIVE_SHELL_TOP_CLASS`, `MAIN_EDGES` native padding,
  `--page-header-h`, the native branches of `back_btn` and `page_title`
- `_page_header` native branch, `history_back_controller` native path
- unused `.toast-region-top`, the unused `browser` variant
- write ADR 0005 recording the model (native owns chrome, web owns content,
  capability-gated controls, versioned config)

## What stays

These have a reason that isn't the hidden bar:

- home tabs (`HomeTabRouteDecisionHandler`, ADR 0004)
- `freshness` for writes the native stack can't see, `TabFreshness`
- `keep_awake`, `tab_bar: hidden` for immersive screens
- share, shared-text, the share extension, staging access
- custom error views, the iOS Close button (iOS 26 `.done` reads as apply)
- separate auth coordinator / `AuthActivity`
- medium sheet detent sync on iOS
- `WebBottomSheetFragment` until sheet pages stop using `100dvh`, then retry
  the stock sheet

## Decisions (2026-11-05)

1. Tab roots get the native bar with a title (iOS large title). Web header
   goes away there too.
2. Add moves out of the tab bar to a `+` bar button, so both apps try the
   stock tab controllers (`HotwireTabBarController`,
   `HotwireBottomNavigationController`). Phase 0 cold start measurement still
   decides whether iOS keeps lazy tabs.
3. All recipe and playlist forms are sheets (`context: modal`, Cancel in the
   bar, Save via `form`): recipe new, manual import, recipe edit, playlist
   new/edit. `MODAL_EXCEPTION_PATTERNS` goes away, and with it the full-screen
   editor `tab_bar: hidden` rules. Saving dismisses the sheet onto the recipe
   page, so the stack never holds a form screen. That removes the confusing
   add, save, edit chain where form screens pile up in back history.
   Recipe edit is long (photos, ingredients, steps), so it uses the large
   detent and must be checked for keyboard and photo picker behaviour in the
   sheet during phase 2.
4. Party cover gets a transparent native bar over the cover (iOS
   `scrollEdgeAppearance` transparent, Android transparent toolbar), so back
   and the menu stay native. It turns opaque on scroll. The web back and menu
   buttons over the cover go away in native.
5. Old builds: one week after the release, flip a flag that shows an upgrade
   nudge to builds without the `button` component. This nudge doesn't exist
   yet. Build it in phase 1 (gated on the bridge component list, flag off),
   linking to the App Store / Play listing. Phase 6 cleanup follows once
   sessions on old builds drop off after the nudge.

## Verification

Every phase, before calling it done:

- iPhone 17 Pro sim, iPad Pro 11 sim (portrait and landscape, studio Mac over
  Tailscale), Android emulator
- the current App Store / Play build against the changed server, to prove old
  builds look unchanged
- path configuration controller tests and the bundled configuration test
- tap targets of any remaining web controls

## Rough size

- Phase 0: about a day
- Phase 1: 2 to 3 days plus one release of each app
- Phase 2: 2 to 3 days
- Phase 3: 3 to 5 days (about 15 sheets)
- Phase 4: 1 to 2 days, depends on decision 2
- Phase 5: 1 to 2 days
- Phase 6: half a day, later

Phases 1 and 2 ship together in the first app release. Phase 3 and later are
server-led and mostly don't need new builds (except new menu uses that need
the `menu` component from phase 1).

## Build-out results (2026-11-05)

Choices made while building, beyond the decisions above:

- Phase 0 issue 1 was misdiagnosed: Hotwire Native caches path config per URL
  (Android SharedPreferences key = full URL, iOS file = last path part), so v1's
  cache can't serve v2. The real risk was two sources of truth: `native_bar?` on
  the server and the app's possibly stale v2. Fix: v2 shows the bar on every
  screen and hides it only on IMMERSIVE_PATTERNS; `native_bar?` = button
  component in the UA + flag + not immersive. A stale config can now only cause
  "both bars" (ugly), never "no back" (stranded). Removing an immersive pattern
  later needs a new config version.
- Kill switch: feature_enable_native_chrome gates `native_bar?` (views only).
  Off = new builds show native bar and web header both. Turn on with the first
  release that loads v2.
- Old builds: every server change branches on `native_bar?`, v1 rules are
  frozen (v1_rules methods; existing legacy-body test). Web dialogs become
  native sheets only under the native bar
  (`modal_turbo_frame_id_unless_native_bar`, NATIVE_SHEET_PATTERNS /
  NATIVE_SHORT_SHEET_PATTERNS in v2 only).
- `data-native-bar` is on body, not html (Turbo keeps html attributes across
  visits); `--sticky-top-zone-bottom` is recomputed there.
- Bridge components: button (title or icon "plus"/"share"), menu (bar overflow:
  iOS UIMenu, Android toolbar overflow; destructive items red), form (ported
  from the demo; follows the submit button's disabled state). No `enabled`
  guard in connect: cold start connects before the adapter.
- iOS large titles dropped (decision 1 amended): with a shared web view the
  large-title collapse left tab roots scrolled 52pt under the bar on first
  render. Inline titles, plus a follow-the-top-inset pin in
  BellyVisitableViewController for bar/no-bar transitions.
- Native title duplicates: kept on hero pages (recipe, party with cover);
  web h1 hidden with `native-bar:hidden` where it only repeats the title.
- Add tab removed on both apps; + bar button on Recipes and Plan roots. Android
  now runs the stock HotwireBottomNavigationController. iOS keeps the lazy
  BellyTabBarController (cold start not measured: Mac offline) with
  mode = .tabSidebar and labels on iPad.
- Recipe edit opened from recipe show carries opened_from=recipe so saving
  dismisses onto the recipe instead of stacking a second copy; import flows
  still push.
- Upgrade nudge for old builds: row on Recipes, flag
  feature_enable_app_upgrade_nudge, copy awaiting approval.
- Not done: decision 4 (transparent bar over party cover: .never insets would
  hide the party's sticky tabs under the bar; needs its own design),
  grocery item edit sheet (stays web dialog), phase 5 beyond what the
  responsive web already does, phase 6 (waits on old builds).
