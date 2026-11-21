# Belly catalog localization

Updated: 2026-11-04 Status: approved 2026-11-04; phase 1 in progress. Why: good
translations are a core feature, and the grocery catalog is where Dutch (and
French) users notice wrong words, wrong packs and wrong units first. Found by
the Dutch domain judge during the Dutch localization
(`belly-dutch-localization.md`).

## What's wrong today

1. Aliases are language-blind (`Catalog::Items::BY_ALIAS`). A word that means
   different products in two languages can only point at one: Dutch "paprika" is
   bell pepper, English paprika is the spice; Dutch "asperges" are white
   asparagus, French "asperge" is green.
2. Pack sizes are North American. Butter is a 454 g brick; a Dutch or French
   shelf has 250 g. "Koop 1 × 454 g" names a pack nobody sells.
3. Unit and pack nouns are translated once per unit, not per item. Dutch "head"
   is krop for lettuce but bol for garlic and stuk for broccoli; butter comes in
   a "pakje", not a "pak".
4. Missing staples Dutch and Flemish shoppers buy weekly.

Recipe imports are mostly safe from 1: extraction writes item names in English.
It hits lines people type: grocery items and manual recipe entry.

## Proposal

### 1. Language-scoped aliases

- Catalog YAML keeps `aliases:` (every language, as today) and gains an optional
  `aliases_by_language:` map, e.g. on bell_pepper `{nl: [paprika, paprika's]}`.
- `Catalog::Items.resolve(text, language: nil)` checks the language's own map
  first, then the shared one. Without a language it behaves exactly as today.
- `IngredientParser.new(text, language:)` passes it through. Typed lines get the
  typing user's language: `GroceryItemAdder` and manual ingredient saves pass
  `current_user` locale's language (`nl`, `fr`). Imports, healers and admin keep
  nil (English names from extraction).
- `items_test` gains: a language alias may shadow a shared alias only in its own
  language, and must resolve to its own item through the parser with that
  language.
- First entries: paprika, paprika's -> bell_pepper (nl); asperge, asperges ->
  white_asparagus (nl, new variant of asparagus).
- Status 2026-11-04: built (Catalog::Item#aliases_by_language,
  Catalog::Items.resolve(language:), IngredientParser language:, manual recipe
  rows pass the viewer's language, nl paprika on bell_pepper, tests). Left:
  wire GroceryItemAdder and GroceryItem's item_code lookup once the paused
  grocery session commits (both files hold its work); asperges waits for the
  white_asparagus variant in phase 4.

### 2. Pack sizes by market

- Market comes from the user's timezone region, which is set automatically from
  the browser: `Europe/*` -> `eu`, everything else -> `na` (today's sizes). Not
  from language: a Dutch speaker in Toronto shops Canadian packs.
- Catalog YAML gains an optional `packages_by_market:` per item, e.g. butter
  `{eu: {standard_package_size: 250, package_unit: g, package_label: brick}}`.
  Missing market falls back to today's fields.
- `Grocery::PackageCalculator` takes the market. Start with the 30 or so items
  whose EU pack differs (butter, cream, canned tomatoes and beans, stock, sugar,
  flour, milk, cheese blocks, yogurt tubs), researched against AH / Jumbo /
  Carrefour shelves the way `find-ingredient-densities` sources densities.
- Status 2026-11-04: built. 72 EU packs approved and applied (research table
  in the session scratchpad, sources AH/Jumbo/REWE/Carrefour; 7 inferred).
  Item pack readers take market:, PackageCalculator takes market: and now
  bridges a volume need to a weight pack through density when there is no
  grocery_unit, User#package_market from timezone. Densities added (approved):
  jelly, mustard, salsa, canned tomatoes, tomato paste, tomato sauce. Left:
  pass current_user.package_market in grocery_items/_item.html.erb and
  GroceryItem#package_calculator once the grocery session commits.

### 3. Per-item unit and pack nouns

- Locale files gain optional per-item overrides:
  `catalog_item_units.<code>.<unit>` and
  `catalog_item_package_labels.<code>.<label>`, each with one/other.
  `Catalog::Unit#label` and `PackageCalculator#package_noun` check the item
  override first, then today's shared key.
- First entries (nl): garlic head -> bol/bollen, broccoli and cauliflower head
  -> stuk/stuks, butter brick -> pakje/pakjes. French and English get overrides
  only where a judge or user finds one.
- Status 2026-11-04: built. Catalog::Unit#label(count, item_code:),
  Quantity#item_code (ingredients and grocery rows pass it),
  PackageCalculator#package_noun per item; nl overrides for garlic (bol),
  broccoli, cauliflower, bok choy (stuk), butter and unsalted butter
  (pakje); tests.

### 4. New items and variants

- Items: half-om-half gehakt (mixed beef and pork mince; bare "gehakt" moves
  onto it), witlof (witloof, Belgian endive), andijvie, bruine bonen,
  kapucijners, zilveruitjes, hagelslag, beschuit, ontbijtkoek, parelsuiker,
  verse gist, glucosestroop, appelstroop, fritessaus, maatjesharing, Hollandse
  garnalen.
- Variants: rookworst (of sausage), amandelspijs (of marzipan), white_asparagus
  (of asparagus), magere kwark (of quark).
- Each new entry complete per `config/catalog/README.md`, with names in en,
  fr-CA and nl, density via `find-ingredient-densities`, and a thumbnail via
  `add-catalog-images` (image generation costs money: one cost estimate,
  approved before running).

### 5. Later, not in this plan

- nl-NL vs nl-BE words that name different products (patat, karbonade): needs
  region-specific aliases, same mechanism as 1 keyed by region. Revisit when
  Flemish users show up.
- A market setting the user can change, if timezone guesses wrong.

## Order

1 (language aliases), then 3 (per-item nouns), then 2 (markets), then 4 (new
items). Each phase: tests, catalog replay vs HEAD worktree
(`translate-grocery-catalog` verify step), domain judge with findings shown to
the user before applying.

## Decisions

- Market from the user timezone (approved 2026-11-04).
- Thumbnails: prompts via add-catalog-images, one cost estimate, run only after approval.
