# Belly grocery list UX overhaul

Status (2026-11-04): all original complaints fixed and committed on main (unpushed). Founder approved the direction (floating add card). Fix 9 parked, fix 10 dropped; native sheets left. Demo reel in ~/Downloads/belly-grocery-add-options/.

## Done

Commits on main, oldest first (none pushed):

| Commit | What |
| --- | --- |
| 163aec9 | grocery_item_sources.origin (manual, recipe, plan_day, plan_week) + undo one manual add by source id; a row leaves the list when its last source goes |
| 754f01c | Catalog suggestions in the user's locale (GET /dashboard/grocery_catalog) + add a tapped suggestion by catalog code |
| 8ddfa3c | Android back closes web sheets (dismiss bridge component); TODO in shared/_modal_dialog for native sheets |
| 11067f8 | Floating add card: bottom "Add items" pill, card pinned near the top, suggestion chips with "On your list · qty", added list with x to undo, reveal + flash on close, haptics, is_suggestion analytics |
| 8d309ba | (Dutch session) catalog endpoint revalidates per deploy instead of max-age |
| cf0af81 | Undo clearing: grocery_items.deleted_at + SoftDeletable; Done and Clear completed soft-delete with an undo toast; daily purge; failed check-off reverts with an error toast |
| 446b841 | Swipe right = green "Got it", left = red "Remove" (35% threshold, haptic tick, slide off); DELETE /grocery_items/:id with "Removed X · Undo"; "Remove from list" in the edit sheet; undo toasts 8s / 10s, timers pause on touch/hover/focus |
| 03fabf9 | Tests + fr-CA for the undo-clearing batch |
| bffbfd9 | Grocery toasts opt into the top (toast-region-top) as a dark pill that flicks away upwards; other toasts unchanged |
| dfa732b | Shared remembered_open(cookie) helper for <details> open state (party prep plan + groceries) |
| 887464f | Check off in place: rows settle 400 ms then move together; Completed folds into a counted section, open state in a cookie; thin outline checks |
| 8184902 | Letter placeholder for rows without a photo; plain "1" hidden |

Verified on the iPhone and iPad sims, the Android emulator, and web at 390 / 820 / desktop. Tests cover each server-side change; the client-only behaviours (settle delay, check pop, swipe gestures) were checked by hand.

Copy: en + fr-CA committed (fr-FR inherits). Dutch keys for every batch live in the Dutch session's uncommitted config/locales/nl.yml and ride in with its commit.

Decisions:
- Add card over 4 other options (demo + reel): the iOS web view can't keep anything on the keyboard edge, so the card is pinned at the top.
- Undo is by exact source id with a stored origin, not "latest manual source" (that undid the wrong add on merged rows).
- Clearing and removing soft-delete (studio SoftDeletable convention) so undo can restore.
- Swipe directions follow the list/dating-app convention (right = positive); "Remove" over "Delete" (reversible).
- Settle delay 400 ms (tried 1.5 s, 1 s, 300 ms).
- Toast position is opt-in per toast so the rest of the app is untouched.
- Fix 9 (hide the iOS keyboard accessory bar) parked, see below.

## Open

- [ ] Push (12 grocery commits + rails 8.1.4.1 bump; two migrations: grocery_item_sources.origin, grocery_items.deleted_at)
- [ ] After deploy: run backfills:run:grocery_item_source_origin in production, then a migration making origin NOT NULL, then delete the backfill task
- [ ] Android release for the back-button fix (8ddfa3c) to reach users
- [ ] Native sheets: present global_modal web sheets natively via path-configuration modal rules + modal_page, then drop bridge--dismiss from shared/_modal_dialog (TODO there lists the sheets). Trade-off: the grocery item sheet would refresh the list on close instead of updating it live
- VoiceOver: dropped 2026-11-04. Card keeps aria-modal only; an inert trap was tried and removed (each add morphs #grocery-list and strips inert, and few screen-reader users). Trigger to revisit: a user report, a review rejection, or an accessibility audit.
- [x] Told the Dutch session (2026-11-04): its nl.yml carries our keys (add_bar moved to floating_actions + quick_add_card); _insiders_invitation now uses link_interpolations (helper in application_helper.rb, uncommitted); its "via Belly" copy broke playlist_shares_controller_test; its screenshots rake task wiped the dev grocery list mid-test

Ideas, not building:
- History icon with undo/redo. Trigger: shared household lists or users reporting lost items. Cheaper first step: a "Recently removed" section (soft-deleted rows are kept a day).
- Android CookieManager.flush() on background, so remembered open states survive an instant force-stop.

Watch list:
- Once, a tap meant for x seemed to land on the row behind the card (PATCH status, no DELETE). Not reproduced since.

## Why

User feedback after a real shopping trip on iOS. The list felt amateurish: the page jumps on add, there's a big gap under the field, the toast covers the input, adding gives no useful feedback, single items can't be removed, swipes don't say what they do and look muddy, and checking off moves rows abruptly.

Reproduced on the iPhone 17 Pro sim (iOS 26.3, studio-macmini, Debug build against local dev):

- Focusing the add field floats the bar to mid-screen. List rows show through the gap and behind the keyboard, and the page scrolls under the status bar.
- The "Item added." toast sits on top of the input and is still there after 3s.
- The new item lands at the bottom under Other, off-screen. The toast is the only signal.
- The edit sheet has name, qty, unit and Done. No delete.
- Swiping right and left does the same thing (check off). Behind the row is a flat dark brown fill with no icon. The row then vanishes to Completed and the rows below jump up.
- Completed rows are faded and stacked with heavy filled black circles.
- Not reproduced: the jump between adds. My list was long; on a short list the page grows under the focused field. Re-check with a short list after fix 1.

## Root causes

- `_add_bar.html.erb` sticks the bar to the bottom. The iOS keyboard covers the page instead of resizing it, so iOS scrolls the page to show the focused field. On each add, `create.turbo_stream.erb` morphs the whole list and `inline_add_controller#clear` refocuses the field, so iOS scrolls again.
- The toast (`toast.css`, `--overlay-bottom`) sits at the bottom of the screen and doesn't account for the keyboard.
- `swipe_toggle_controller.js` uses `Math.abs(dx)`, so both directions toggle. `--swipe-progress` mixes `--oat-100` toward `--ink-950`.
- `grocery_list_controller#move` moves the row to its new section the moment it's checked.
- Routes: grocery_items only have `show/create/update` (+ reset, status). No destroy.

## Fixes

### Chosen direction for batch A: floating add card (option 5)

Five options were built in a throwaway demo and tried in the iOS sim:

1. Pill + top field: works; cheapest. While typing, new rows can't be shown (any scroll with the keyboard up drags the sticky field off-screen in WKWebView), so feedback is a status line only.
2. Pill + bottom sheet: works, but sits on the keyboard edge, so it has the see-through strip and is fragile.
3. Bottom dock: fails. Doesn't follow the keyboard in WKWebView and gets stuck mid-screen.
4. Composer + suggestions: Todoist feel; on the keyboard edge, so iOS 26's floating accessory bar shows list rows through. Needs native work (hide the accessory bar, or a native composer) to look right.
5. Floating card: a bottom pill opens a card pinned near the top, clear of the keyboard. Field, suggestion chips, and a list of what you added.

Why 5: the iOS web view can't keep anything attached to the keyboard; 2, 3 and 4 depend on that, 5 avoids it entirely. Thumb-reach first tap, nothing scrolls while open, the in-card list replaces the toast as feedback, web-only (no app release), same on Android, iPad and desktop. Earlier "cons" didn't hold up: you don't need the main list while adding (the card shows what you added), closing costs one action in every option, and one quick add costs the same taps everywhere. What's left is build work, not design.

Card design:
- "On list" hint on a suggestion already in the list, and an "already on your list" line on an exact typed match.
- x on each row of the added list to undo that add without leaving the card.
- Catalog chips: tap adds the catalog item (right name, aisle, photo); thumbnails; filter client-side from names sent with the page (~1000 items, ~30 KB). `Catalog::Items.suggest` exists (~18 ms server-side) as the fallback.
- Suggestions must match the user's locale (en / fr-CA / fr-FR); `suggest` currently returns English display names.
- Done closes card and keyboard together; on close, scroll to and flash the added rows.

Constraints learned:
- WKWebView with the keyboard up: any scroll pans the visual viewport and drags sticky/fixed top chrome off-screen.
- Fixed elements get clipped at the top of iOS 26's floating accessory bar, so CSS can't paint under it; scroll content shows through.

### 1. Add field at the top on mobile (superseded by option 5)
Put the add field under the title on mobile, stuck to the top as the page scrolls. Desktop already does this (`md:order-2 md:top-15`), so this mostly means dropping the mobile bottom placement. The keyboard can't cover or move it any more.
Solves: the gap, the jump, content under the status bar.

### 2. Show added items in the list (done, via the add card)
- No toast on add.
- The new row scrolls into view and fades from a soft highlight (~1s), while the field keeps focus.
- A light haptic on each add (`bridge--haptics`).
- A failed add shows its error inline under the field.
- Toasts stay for errors and undo only.
Solves: toast covering the input, no feedback on add.

### 3. Swipe directions that say what they do (done, 446b841)
- Right = check off: green fill (`--success` / brand) with a check icon that grows as you drag.
- Left = remove: `--danger` fill with a trash icon.
- Commit at ~35% of row width (now 50%), with a haptic tick when you cross it.
- On commit, slide the row off-screen instead of snapping back.
- Drop the ink fill.
Solves: confusing swipes, muddy colours.

### 4. Remove a single item (done, 446b841)
- `destroy` route and action on grocery_items.
- Swipe left removes and shows an undo toast ("Removed kiei", Undo). No confirm dialog.
- A quiet "Remove from list" button in the edit sheet.
Solves: no way to delete.

### 5. Check off in place, then move (done, 887464f)
- Strike through and fill the circle where the row is.
- Move checked rows to Completed after ~1.5s. Restart the timer on each new check so quick checks move together (Reminders / AnyList pattern).
- Small scale pop on the check mark.
Solves: the row vanishing and the list shifting under your finger.

### 6. Calmer Completed section (done, 887464f)
- Lightly faded rows, with a thin outline check instead of a filled black circle.
- Collapse the section to one tappable "8 completed" line that expands.

### 7. Safety (done, cf0af81)
- "Done" (`_done_button.html.erb` → `grocery_lists#reset`, `grocery_lists_controller.rb:8`) deletes the whole list with no confirm and no undo. It also appears beside the input and makes it narrower. Change it to clear completed items with an undo toast; the full reset stays in the ••• menu behind its confirm.
- `swipe_toggle#write` ignores the false from `submitInBackground`, so failed saves are silent. Revert the row and show an error toast.

### 8. Row polish (done, bffbfd9 + 8184902)
- Rows without a photo get a placeholder (oat circle with the first letter) so names line up.
- Hide the quantity when it's a plain default 1 with no unit.
- Toast restyle: a compact dark pill near the top, matching the page action pills. It no longer collides with the keyboard.

### 9. Native polish (iOS shell, needs an app release) — PARKED 2026-11-04
Parked: with the add card pinned at the top the bar no longer sits by a gap, its ✓ is the only keyboard-dismiss in textareas, and hiding it needs a private-class override plus an app release. Trigger to revisit: users say the app feels like a website, or a design puts UI on the keyboard edge again.

Hide WKWebView's ^ v ✓ form accessory bar on this screen (override `inputAccessoryView`).


## Batches

- A: option 5 floating card (replaces 1 + 2). Done.
- D: 7. Done.
- B: 3 + 4. Done.
- C: 5 + 6. Done.
- E: 8 done, 9 parked, 10 dropped.

Verify each batch in the iOS sim (drive-ios-simulator-remotely) and on Android before calling it done.
