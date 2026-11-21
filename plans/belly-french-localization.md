# Belly French localization

Updated: 2026-10-26
Status: French is on. Phases 1 to 3 and 5 are done (main, unpushed). Left: the end of phase 1, phases 4, 6 and 7, then review.

## Decision

Three locales: `en`, `fr-CA`, `fr-FR`. fr-CA is the full French file. fr-FR holds only the keys where France differs and falls back to fr-CA, then en. The dialects share 90%+ of the copy, so the overrides live in one small file that reads as a diff.

Locale resolution (`Localizable`): saved user locale, then the browser's first language (plain `fr` -> fr-CA), then en. No cookie, session or `?locale=` until something writes it (phase 7 hand-off).

Decided: no per-locale signup defaults for week start or units. Everyone gets Monday and "as written"; add them only if French users ask.

## Phase 1: what's left

- `users.locale` NOT NULL: run `backfills:run:users_locale` in production, then the migration, then drop the `DEFAULT_LOCALE` fallback in `set_locale` and `allow_nil` on the validation.

## Phase 4: catalog, units, parsers

Done: unit, aisle, package and item names in `config/locales/catalog.<locale>.yml` (fr-FR overrides kept); catalog YAML is parse-only; 4,200+ French item aliases; French unit words and "de/d'". Typed French groceries match the catalog (images, aisle, substitutes, units, pack hints). The typed name is user content and always shows as written: the app translates its own text, never user content.

Left:
- Held back on purpose (recipe-import territory, not grocery typing): French serving notes ("au goût", "pour garnir"), "et"/"ou" separators, "heures" in recipe times. Watch "en dés": stripping it breaks "tomates en dés".
- Agent judges' review of the 849 item names (`catalog.fr-CA.yml`, `catalog.fr-FR.yml`) and the agents' flagged doubts.
- The grocery unit field shows the raw code ("cup", "fl_oz"). Showing the label means changing the shared combobox to post a code while displaying a label; several French unit labels are shared (pincée, boîte, portion, filet).
- Number formatting in pack hints and quantities stays English ("1.5", not "1,5").
- Recipes stay in the language they were written in; rebuilt recipe lines keep English units. Translating a recipe comes later with the AI action and `recipes.language`.

## Phase 6: native and stores

Done: both apps translated (en, fr, fr-FR overrides) with icon-only tab bars; tab names stay as screen-reader labels. Android `values-fr` / `values-fr-rFR`; iOS `Localizable.xcstrings` (tabs, error screen) and `InfoPlist.xcstrings` (camera and photo prompts). Native text follows the phone's language, web content follows the account's.

Left:
- Fastlane metadata: `fr-CA` and `fr-FR` for both stores. Listings have no fallback, so both get full copy. Use the `app-store-listing` skill. Screenshots in French per store (`generate-screenshots` with locale).
- French App Store and Google Play badges in the web app (download needs approval).

## Phase 7: marketing site

- Bridgetown locales en, fr-CA, fr-FR. Copy lives in `src/_data/*.yml`, so this needs a per-locale data shape (spike first: Bridgetown's built-in i18n reads `src/_locales`, not `_data`).
- Locale in the URL: `usebelly.app/fr-ca/` and `/fr-fr/`, English at the root.
- hreflang: `fr-CA`, `fr-FR`, and `fr` pointing at fr-CA.
- App links from French pages carry `?locale=fr-CA` / `?locale=fr-FR` (`/signup`, `/login`). This brings back a locale cookie in `Localizable`, ranked after the saved user locale.
- Language switcher in the marketing footer, linking the same page across `/`, `/fr-ca/`, `/fr-fr/`.
- FAQ, privacy, terms in French. Changelog feed entries in French (the in-app changelog reads this feed).

## Before launch

- Quebec's Charter of the French Language (Bill 96) generally requires software and commercial websites offered to Quebec consumers in French, on terms no less favourable. Confirm scope with counsel.

## Open questions

- Who reviews fr-CA and fr-FR copy?
- Later: an AI action to translate a recipe, as a premium paid feature. Before or with it: store `recipes.language` so French, Korean and Spanish recipes show their own unit names ("2 c. à soupe de miel", not "2 tbsp de miel"). Every line with a unit word is rebuilt, scaled or not (TODO in `IngredientLine#quantity_prefix`). It would need `recipes.language` (a migration) so rebuilt lines can use the recipe's own unit names.
