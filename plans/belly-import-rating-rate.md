# Belly: more signal on import quality

Date: 2026-11-05. Status: phases 1 to 3 built 2026-11-06, uncommitted; phase 4 dropped. Built without waiting for the phase 1 readout.

## Why

Since 2026-10-20, 64 of 274 imports were rated (23%). Only 27 of 66 importers
have ever rated. By source: url 23%, photo 35%, text 15%.

The two real problems we found this month (Dutch total time read as prep,
Half Baked Harvest steps packed into one) each came from a single low rating
with typed feedback. Every user who fixed the same thing by hand and didn't
rate told us nothing.

Goal: know how good every import is, not only the rated ones. More star taps
is secondary.

## What the code does today

- Every import ends on the edit form (`_import_redirect.html.erb` visits
  `edit_dashboard_recipe_path`). The rating row sits at the top of that form
  (`_recipe_form.html.erb:35`) and on the show page.
- Pressing Save on that form sends `recipe_saved` with `action: "updated"`
  (`RecipesController#update`). So "updated within 30 min of import" is true for
  267 of 274 imports. It is the confirm step, not a correction, and it can't be
  used as a signal as it stands.
- `recipe_imported` carries no `recipe_id`, so it can't be joined to
  `recipe_saved` by recipe.
- The rating partial asks before the user has read the import. It shows only
  while unrated and within 14 days (`RecipeImportEvent::RATING_WINDOW`).

## Phase 1: record what the user changed on the import

The implicit signal. It needs no UI change, so it ships first.

1. In `RecipesController#update`, assign the params, then work out which parts
   changed before saving:
   - `name`, `serves`, `times` (prep, cook, marinade), from `@recipe.changes`
   - `ingredients` and `steps`: any row new, removed (`marked_for_destruction?`)
     or `changed_for_autosave?`, ignoring the blank rows the form builds
   - `photo`
   Keep the result as a list of part names, e.g. `["times", "steps"]`. It goes
   in a small PORO in `app/models` (`RecipeContentSnapshot`, taken before and after the save) so it can be unit
   tested without the controller.
2. Only the first save after import counts as the review. Add
   `reviewed_at` and `review_changed_parts` (string array) to `recipe_import_events`
   and set them on that first save when the event has no `reviewed_at`. Later
   edits are the user's own cooking notes, not import errors.
3. Add `changed_parts` (array) and `is_import_review` (boolean) to the
   `recipe_saved` properties, and `recipe_id` to `recipe_imported`.
4. Admin import ratings page: show `review_changed_parts` next to each row and
   allow filtering by "changed on review". That gives the unrated corrections
   the same triage view as the low ratings.

Tests: controller tests that round-trip the real edit form (each part detected, blank form rows
ignored, untouched save gives []); one controller test that the first save
sets `review_changed_parts` and the second save leaves it alone.

Migration: two columns, needs approval per the migrations skill. No backfill:
past saves can't be diffed.

Events imported before the deploy may get their review set by a later edit during the first 14 days; read out only events created after the deploy.

Readout after about 2 weeks: share of imports changed on review, by source,
strategy and part. That number decides whether Phase 2 and 3 are worth it.
No UI decisions before then.

## Phase 2: ask when the user is fixing something

Depends on the Phase 1 data showing that corrections happen often enough.

- Move the rating off the top of the edit form. Before review the user hasn't
  read the import yet.
- After the review save:
  - Parts changed and unrated: on the show page, ask "Did the import get
    something wrong?" with the changed parts preselected as chips. One tap
    sends it.
  - Nothing changed and unrated: show the normal rating on the show page,
    once. Dismissing it counts as seen; don't ask again.
- Bulk importers (user 223 did 9 in 15 minutes) see only the inline row, never
  a modal or sheet.

## Phase 3: thumbs and reason chips instead of 5 stars

- Thumbs up or down. Down opens chips: Ingredients, Amounts, Steps, Times,
  Photo, Something else (with the existing free text field).
- Keep the `user_rating` column and its approval logic: up stores 5, down
  stores 1. `APPROVAL_RATING` and `LOW_RATING` keep working, and older ratings
  stay comparable.
- New `feedback_reasons` string array column on `recipe_import_events`, plus a
  `feedback_reasons` property on `recipe_import_rated`.
- Removes the 3-star problem: both 3-star raters were mostly happy, but 3 counts
  as low and unapproves the cached import for everyone.

## Phase 4: dropped

Telling reporters their report led to a fix was dropped on 2026-11-06.

## Not doing

- Rewards, streaks or badges for rating.
- A modal after every import.
- Asking twice on the same import.
- A `rating_viewed` event. Imports are the denominator already.

## Open questions

- Does the review save always come from the import's own edit form, or do some
  users back out and edit later? Phase 1 data will show via `reviewed_at -
  created_at`.
- Should a big change on review (several parts) unapprove the cached import
  the way a low rating does? Not until the Phase 1 data shows how much noise
  there is.
