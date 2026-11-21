# Handoff: Belly native chrome refactor, after phase 0

2026-11-05, from session recipe-page-native-spike.

## Where things are

- Plan, decisions and phase 0 findings: ~/notes/plans/belly-native-chrome.md. Read it first.
- Code: worktree /home/emmanueletti/projects/itsusstudio/wt-belly, branch wt-belly, rebased onto main e9887ae. Phase 0 is 21 uncommitted files there (git status shows exactly these). Nothing committed, nothing pushed.
- Main's working tree (/home/emmanueletti/projects/itsusstudio/belly) holds another session's recipe ingest work. Not ours; leave it.

## What phase 0 built

- Server: v2 path configuration endpoints (v1 rules unchanged + `NATIVE_BAR_PATTERNS` rule, recipe show only). `native_bar?` in ApplicationHelper matches the same patterns and requires the `button` bridge component in the user agent, so old builds keep the web header. `body[data-native-bar]` zeroes `--shell-top`. `_page_header` draws nothing under the native bar but keeps the action in a hidden div for the bridge to click. `bridge/button_controller.js`.
- iOS: `ButtonComponent`, v2 config URL, `contentInsetAdjustmentBehavior` per screen in `visitableDidActivateWebView` (automatic under the bar, never otherwise).
- Android: `ButtonComponent` (toolbar menu item), v2 config URL.
- Bundled configs regenerated from v2; bundled test points at v2.
- Tests: helper + path config tests pass (70). Lint not run yet.

Verified: iPhone 17 Pro and iPad Pro 11 sims (studio Mac, remote) and Android emulator. iPad gap gone.

## Open before phase 1 / before any release

1. Android first launch after update: cached v1 rules beat the remote v2 until it loads, so the page drops its header while the bar is still hidden (no back, no Edit). Must fix.
2. iOS first render: content inset only clears the status bar, hero sits under the nav bar. Find the cause before converting pages without a hero.
3. Native title duplicates the recipe h1. Decide per screen.
4. Edit uses turbo_action replace, so back from edit skips the recipe. Goes away with edit as a sheet (decision 3).
5. Cold start with stock HotwireTabBarController not measured.

## Rules that bite

- No commit without the user's explicit approval, per commit. Explicit paths only (`git commit -- <paths>`), no AI attribution.
- Lint (bin/style, bin/lint) once at the end, not per edit. Full test suite only when the user asks.
- Testing needs a server from wt-belly (main's server has no v2.json). Installed spike builds: emulator-5584 and both sims on studio-macmini.
- Studio Mac checkout was patched and reverted; it's clean. Follow drive-ios-simulator-remotely, revert patches after.
- Follow the Hotwire Native demo at the pinned tags (iOS 1.3.1, Android 1.3.2), don't improvise APIs.
