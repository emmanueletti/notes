# Handoff: Belly native chrome, phases 1-5 build-out

2026-11-05, session native-app-refactor. Plan: ~/notes/plans/belly-native-chrome.md.

## State
- All uncommitted in /home/emmanueletti/projects/itsusstudio/wt-belly (branch wt-belly, base main e9887ae). ~134 files. Nothing staged, committed or pushed.
- Server on 3001 runs wt-belly; dev DB belly_party_development migrated (4 main migrations; origin backfill run by hand, same logic as the deleted task).
- Flags in dev: feature_enable_native_chrome ON. feature_enable_app_upgrade_nudge registered, off.
- Android: latest build installed on emulator-5584, adb reverse 3000->3001. Verified by hand.
- iOS: verified on iPhone 17 Pro and iPad Pro 11 sims (studio Mac, portrait only). iOS lint and unit tests pass. Mac checkout reverted and clean (main a5153067); both sims booted with the build installed, logged in as clanker.

## Open
- iPad landscape and the recipe split layout not checked (idb can't rotate). Cold start of stock HotwireTabBarController not measured; kept the lazy controller.
- Large titles dropped on iOS (their collapse fought the web view scroll and left tab roots scrolled under the bar). Decision 1 said large titles; inline titles now.
- iPad sidebar shows UIKit's Edit (tab customization); consider turning it off.
- Nudge copy (EN draft) needs approval, then fr-CA/nl (lint fails on 4 missing keys until then).
- Decision 4 (transparent bar over party cover) not built.
- grocery_items#show stays a web dialog (needs refresh-on-dismiss natively).
- Lefthook partial staging trap when committing: see memory.

## Review feedback, 2026-11-05 evening

- Reversed decision 2: the middle Add tab is back on both apps (HEAD's tab code restored), glyph now Lucide `plus` (iOS `plus.imageset`, Android `ic_tab_add.xml`); `plus_circle.imageset` deleted. The `+` bar button on Recipes and Plan is gone (`_native_bar_add_button` partial deleted). Button/menu/form bridge components stay; nothing sends `plus` to ButtonComponent now.
- New v2 path property `navigation_title: "hidden"` (`TITLE_HIDDEN_PATTERNS` in base_controller): iOS clears `navigationItem.title` in `visitableDidRender`, Android `WebFragment.shouldObserveTitleChanges()` returns false. Hotwire Native has no built-in for this; a blank `<title>` makes Android show the URL. Currently: recipes index, recipe show, plan index. User will name more pages.
- Bar hidden on the Recipes and Plan roots (`BAR_HIDDEN_ROOT_PATTERNS`, `NAVIGATION_BAR_HIDDEN_PATTERNS` = immersive + roots, `navigation_bar_hidden_rule`). `native_bar?` split: `native_chrome?` (v2 build + flag) decides link targets, `native_bar?` (chrome and bar showing) decides layout. `modal_turbo_frame_id_unless_native_chrome` (renamed) returns `_top` in v2: nil left the recipe-grid card ••• loading into the grid frame ("Content missing"). TITLE_HIDDEN_PATTERNS now only recipe show.
- Transparent bar (decision 4, extended to recipe show): `navigation_bar: "transparent"` on TRANSPARENT_BAR_PATTERNS (recipe show, party show). Web: `native_bar_transparent?` → `body[data-native-bar-transparent]` sets `--shell-top: env(safe-area-inset-top)`; hero `-mt-[var(--shell-top)]` (recipe max-lg, party max-md); NATIVE_SHELL_TOP_CLASS shield hidden there (it was the white band). iOS: `.never` inset + transparent navigationItem appearance; iOS 26 top edge effect kept (fades scrolled content, status bar auto-light over photo). Android: toolbar drawn over page (constraint to parent top, bringToFront), page top inset = app bar height, white→transparent fade at rest, solid surface once scrolled. Party show not visually verified.
- Cook mode follow-up idea: native full-screen modal (X leading, contents list as bar button) instead of immersive.
