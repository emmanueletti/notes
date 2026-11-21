# Belly: link-only recipes

Started 2026-11-02, from a close-import-failures pass.

Goal: an import we can't read never ends in a dead end. The user keeps the
recipe anyway, as a link-only recipe, or brings it in another way (screenshot,
paste). When video import ships, link-only recipes fill in on their own.

## Why

- 139 failed imports logged. In 30 days, 17 of 30 native users who imported a
  recipe hit at least one failure.
- Since Oct 6, about 18 failures were the recipe inside a video or images
  (Instagram reels ~9, TikTok videos ~6, Facebook reel 1, Instagram post 1,
  Pinterest image 1), plus ~11 DM-gated posts. Carousels are almost absent, so
  a carousel-image path is not worth building.
- Today every failure lands on the paste sheet with a reason banner. No
  screenshot option, no way to keep the link.
- A saved link sends people back to the creator's post: the most
  creator-friendly thing we can store (see belly-creator-program.md).

## Flow

The failure sheet (`text_imports/_sheet.html.erb`, reached through
`referral_for`) becomes a choice of three, for these referrals:
`recipe_in_media`, `no_method`, `recipe_gated`, `blocked`, `private`.
Not for `no_recipe` (a ChatGPT link, a settings page): nothing to keep.

1. Save the link (first, least effort)
2. Add a screenshot: hands off to the existing image import
3. Paste the text: the current sheet

Mobile first: three 48px+ rows, one line of reason above them.

## Model

- A status on `Recipe`, not a new table: one model keeps search, plans and the
  later fill-in. Name to settle (see Naming); name: `kind`, values "complete" and "bookmark" (decided 2026-11-02).
- `at_least_one_ingredient` and `at_least_one_step` skip for link-only.
  Needs `source_url` and `name`.
- Defaults live in the model (no `default:` in the migration).

## What gets stored

The adapters already hold this when they fail; today they drop it.

- Title, cover image, author, source url: from the page (og tags, TikTok
  rehydration, Instagram oEmbed).
- `INGREDIENTS_WITHOUT_METHOD`: the ingredients the model already extracted.
  Those link-only recipes work for groceries right away.
- Plumbing: `RecipeIngest::Failure` gains an optional preview (title, image,
  author, ingredients) the adapter fills before failing. The failure row and
  the referral carry an id the "save the link" action can read back, never
  the data in the url.
- No title at all: fall back to "<author>'s video" or the domain.

## Search and filters

- Title and author: free, step one.
- Tags (meal, cuisine) from the caption with one cheap model call: step two,
  only if search on link-only recipes turns out to be used. LLM feature
  rules apply (eval before shipping a prompt).

## Plans and groceries

- A link-only recipe can go on the meal plan. It shows the cover and opens the
  post.
- Groceries: adds its ingredients when it has some, otherwise nothing, with no
  error.

## Fill in later

When video import ships (user-shared video files, transcribed; no scraping),
re-run import on every link-only recipe, upgrade the ones that read, and tell
the user once: "12 saved links are now full recipes." The link-only list is
the backlog and the demand count for video import.

## Analytics

- Track which choice the user picks on the failure sheet. Event names to pick
  from the allowed verbs, e.g. `recipe_link_only_created` with `reason` and
  `source_site`; screenshot and paste choices as a `recipe_import_recovery_clicked`
  style event with a `choice` property. Check names against the rules in
  server/CLAUDE.md before shipping.
- Weekly: link-only recipes created, by reason. That is video demand.

## Naming

- Not "saved" (`recipe_saved` exists) and not "bookmark" (reads as a separate
  feature). One name for the code and the UI.
- Candidates: `link_only` (code) / "Link only" (UI label). Decide before the
  migration.

## Copy (English, proposed, not written)

Reason line, one per referral:
- recipe_in_media, no_method: "We can't read recipes inside videos yet."
- recipe_gated: "The creator keeps this recipe somewhere we can't reach."
- blocked: "This site doesn't let us read its recipes."
- private: "This post is private, so we can't read it."

Choices:
- "Save the link" / hint: "Keep it with your recipes and add the details later."
  - no_method hint instead: "We'll keep the ingredients. The steps stay in the video."
- "Add a screenshot" / hint: "A screenshot of the recipe works."
- "Paste the text"

After saving (toast): "Link saved to your recipes."
Recipe card label: "Link only"
Recipe page banner: "The full recipe is in the video." with "Open video"
and "Add steps".
Fill-in notice: "%{count} saved links are now full recipes." (count: form)

Translate after approval (fr-CA, fr-FR).

## Steps

1. Naming decision and copy approval.
2. Migration: status column on recipes (schema only).
3. Failure preview plumbing in the adapters (Instagram, TikTok, Facebook,
   YouTube, Pinterest, Web), with tests per source.
4. Save-the-link action and the three-choice failure sheet; screenshot hands
   off to image import.
5. Link-only recipe card and page; meal plan and groceries behaviour.
6. Analytics events.
7. Native: check the sheet in both shells (path configuration, `invalidates`
   for the recipes tab).

## Open questions

- Does a link-only recipe count for onboarding milestones
  (`first_recipe_added_at`)?
- Does it show in shared recipe lists and party plans, or only to the owner?
- Upgrade on fill-in: replace in place (keeps plans and tags) or create new?
  In place is the working assumption.

## Status 2026-11-02

Built, uncommitted, awaiting review. Recipe#kind complete/bookmark; failure sheet
(save the link / screenshot / paste) for blocked, private, gated, in-media and
no-method failures; bookmark read from preview tags with no model call; notice
on the recipe page; card badge; Cook and Shop hidden without steps/ingredients.
Not built: keeping the ingredients of a no-method import (the failure does not
carry the extracted payload; needs a transient store), tags from the caption,
fill-in on video import. Prod order: deploy, backfills:run:recipes_kind, then a
null: false migration.
