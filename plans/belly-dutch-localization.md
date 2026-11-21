# Belly Dutch localization

Updated: 2026-11-04
Status: proposed, waiting for approval.
Runbook: studio `add-app-language` skill plus Belly `translate-grocery-catalog`. Refine both from what this work teaches (see "Skill learnings" at the bottom).

## Why now

One signed-up Dutch user (223, Goes, browser nl-NL) out of 79 signed-up web users in 90 days. PostHog insight "Signed-up users by browser language" on Belly weekly pulse tracks this. Dutch doubles as the first run of the add-language skill on a second language.

## Decisions

- One locale, `nl`, for the Netherlands and Flanders, falling back to `en`. No `nl-BE` until Flemish users report wording problems.
- Browser `nl`, `nl-NL` and `nl-BE` resolve to `nl` in `Localizable`.
- Informal address: je / jouw, never u / uw.
- Everything in the first release: web app, error pages, catalog and parser, native apps, both store listings with screenshots, marketing site at `/nl/`, Dutch changelog feed.
- Number formatting stays English ("1.5"), same open item as French. Not fixed here.
- Native strings stay native (14 per language: error screens, permission prompts, share label, tab screen-reader labels). Moving tab names into path configuration costs a per-locale bundled config for 5 screen-reader labels.
- Review: agent judges (see below).

## Phases

Each phase is one or more commits, approved one at a time.

1. Register `nl`: `application.rb` locales and fallbacks, `i18n-tasks.yml`, locales README, `Localizable` mapping, `LANGUAGE_NAMES` ("Nederlands"), `locales_test.rb`.
2. App copy: `nl.yml` from `en.yml` (~1,140 lines), one area per commit in the French order (auth, app frame, recipes, cook mode, import, recipe form, grocery list, plan, playlists and sharing, settings, Insiders and billing, flashes and validations, parties).
3. Static error pages: Dutch in the translations hash of the six `public/*.html` pages.
4. Catalog and parser (`translate-grocery-catalog`): `catalog.nl.yml` (~850 items, units, aisles, packages); complete the existing `nl` unit words in `units.yml`; Dutch aliases on catalog items and variants; replay real Dutch grocery lines.
5. Native: Android `values-nl`, iOS `nl` in both String Catalogs and `knownRegions`. Ships with the next app release.
6. Stores: `nl-NL` listings for App Store and Google Play (`app-store-listing`), release notes in nl-NL from then on (update `release-apps-to-store-review`), Dutch screenshots.
7. Marketing: Bridgetown `available_locales` adds `:nl`, `src/_locales/nl.yml` (~200 lines), the six `locale: multi` pages, Dutch hero screenshots, `locale_overrides.nl` on all 19 changelog entries, `app.yml` changelog feed and page URLs for `nl` in every environment, footer language switcher, hreflang.

## Agent judges

Run after each phase that writes Dutch, before asking to commit.

- Fluency judge: reads the Dutch file alone, without the English, as a Dutch copy editor for a consumer app. Flags anything that reads translated, wrong register (u / uw), Flemish-only or Netherlands-only words where a shared word exists, and spelling (Groene Boekje).
- Fidelity judge: reads English and Dutch side by side per key. Flags changed meaning, dropped or added information, broken interpolation variables, and buttons that aren't verbs.
- Catalog judge: for item names and aliases, flags names a Dutch or Flemish shopper would not use in a supermarket (Albert Heijn, Jumbo, Delhaize, Colruyt wording), and aliases that point at a different product.
- Every judge is an expert translator in modern Dutch SaaS copy (tense, je/jouw, point of view, how Dutch apps phrase empty states, confirmations, errors, onboarding, calls to action), not a literal checker.
- Each judge also proposes app changes Dutch SaaS copy needs (string structure, variable placement, labels vs sentences, conventions) and calls out English source strings that aren't modern idiomatic SaaS copy.
- Every judge finding is a proposal: the user sees each per-key fix (before, after, reason), app change and English rewrite, and only approved ones are applied (user rule, 2026-11-04). Earlier rounds in this plan were applied before review; their findings files stay in the scratchpad for audit.
- Judges run on a different model or prompt than the writer, so the review isn't anchored on the translation's own choices.

Real Dutch users replace the judges when available: the user 223 account, and a feedback ask in the app.

## Open questions

- Founder signatures or other gendered copy in the marketing site: check during phase 7 and ask the user.
- Legal language requirements for the Netherlands and Belgium: none expected for a consumer app, flag only if something turns up.

## Skill learnings

Fill in as phases land, then fold into `add-app-language` and `translate-grocery-catalog`.

- Done: native strings inventory and why they stay native, in the studio skill's native step.
- Phase 1: add the new locale to `i18n-tasks.yml` only in the commit that completes the copy; listing it earlier makes `i18n-tasks missing` fail lint on every commit in between. Don't push between phase 1 and the end of phase 2: browsers in the language would get English copy mixed with rails-i18n's translated validation messages and dates.
- Phase 1: the browser mapping was one hardcoded `fr` line; generalized to a language -> full locale table, which also fixed fr-BE / fr-CH browsers getting English.
- Phase 2: four translator subagents in parallel (one quarter of `en.yml` each, ~250 lines), working from a HEAD snapshot in the scratchpad, sharing one brief and glossary (`scratchpad/nl/BRIEF.md`), then a merge script checking key parity and `%{}` variables. Keeps the main context free of 1,100 lines of Dutch.
- Phase 2: onboarding screens and nudges show a per-locale screenshot (`app/assets/images/onboarding/*-<locale>.webp`, path in the locale file). The skill's copy step didn't mention it. Dutch stays on the English images until screenshots are captured in Dutch.
- Phase 2: the studio 1Password hook blocks any shell command containing a standalone "op", which is a common Dutch word. Write Dutch with Write/Edit or a script file, never inline in a shell command.
- Phase 2: never run `i18n-tasks normalize -p`: it moves the catalog keys into `en.yml` / `fr-CA.yml` and deletes the `catalog.*.yml` files. Plain `normalize` is what `bin/style` runs.
- Phase 4: the parser's descriptor lists were English-only, so Dutch prep words up front ("gesnipperde ui") and French ones at the end ("lait tiède") missed. Moved to `config/descriptors.yml` per language (user decision 2026-11-04). Regression replay vs a HEAD worktree: 23 changed lines at HEAD, 11 after, none new.
- Phase 4: aliases are language-blind, so Dutch "paprika" (bell pepper) can't be aliased; needs language-specific aliases later.
- Phase 7: render.yaml carried per-feed cache and CORS headers for /fr/changelog.json; /nl/ needed the same. The marketing agent dropped exclamation points from real testimonials; restored. Quotes keep their punctuation.
- Done: agent judges as the interim review, in the studio skill (decisions, "Agent judges", launch) and the Belly catalog skill's verify step.
