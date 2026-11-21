# Belly catalog variants

Status (2026-11-01): phases 1-5 built, uncommitted, suite green (2709 runs). Phase 5 first pass applied across all aisles per belly-catalog-variants-audit.md. Ship everything together; nothing goes out half done.

Rollout after deploy, in production: `bin/rails backfills:run:catalog_variant_codes`, then `bin/rails backfills:run:catalog_split_items` (both idempotent; the split task is temporary, delete after it runs). Do not use the admin re-parse: the dev replay showed it rewrites unrelated codes for the worse (apple -> "crisp apples").

## Why

User 62 (2026-11-01): adding a recipe to the grocery list turned "Low Fat Yogurt" into "Yogurt".

The catalog has two ways to describe a thing, and neither fits a variant:

- New item (the old `greek_yogurt`): duplicates aisle, image, density and package, and loses the link to yogurt.
- Alias (today): says greek yogurt is the same as yogurt. `yogurt` carries 39 aliases, many of them other products: greek, coconut, dairy free, vanilla, fat-free greek.

The parser makes it worse. `LEADING_DESCRIPTORS` lists "low", "fat", "organic", "unsalted" as words "that don't change what a shopper buys", so "low fat yogurt" strips down to `yogurt`. That list exists for catalog matching, and it is the wrong place to decide what a shopper buys.

## The model

- Item: a distinct thing. `yogurt`.
- Alias: another way to say the exact same item or variant. yoghurt, yaourt.
- Variant: a different form of an item, one you pick a different product off the shelf for. low fat yogurt, greek yogurt.

A variant belongs to one item, inherits everything from it, and overrides only what differs.

## Design

### Catalog schema

A variant is a row in the same YAML file, right after its item, with `variant_of`:

    - code: yogurt
      aliases: [yogurt, yoghurt, plain yogurt, yogourt, yaourt, ...]
      aisle: dairy_eggs
      density: 1.03
      ...
    - code: low_fat_yogurt
      variant_of: yogurt
      aliases: [low fat yogurt, low-fat yogurt, yogourt faible en gras, ...]
    - code: greek_yogurt
      variant_of: yogurt
      aliases: [greek yogurt, greek-style yogurt, strained yoghurt, yogourt grec, ...]
      density: 1.1

- Its own code, so everything keyed on `item_code` keeps working untouched: `ingredients.item_code`, `grocery_items.item_code`, the merge key, locales, `catalog_images.yml`.
- `Catalog::Item` reads aisle, units, grocery_unit, density, package fields, substitutions, shoppable and image_* from the item when the variant leaves them blank. New `#item` (itself for an item, its parent for a variant) and `#variant?`.
- Display name: its own `catalog_items.<code>` key in catalog.en.yml and catalog.fr-CA.yml. fr-FR falls back as today.
- Image: `catalog_image_path` falls back to the item's webp. A variant gets its own image only when it looks different on the shelf.
- One level only. A variant of a variant is a load error.

Why a flat code rather than `yogurt/low_fat`: no consumer has to learn to split a code, and the 30-odd places in the consumer map stay as they are. "Is this yogurt?" becomes `catalog_item.item.code`, not a prefix check.

### Parser

No vocabulary change needed. Variant aliases go into the flat `BY_ALIAS`, and `descriptor_candidates` tries the whole phrase first, so "low fat yogurt" hits `low_fat_yogurt` before any word is stripped. Descriptor stripping only runs when no variant matches, and then it falls back to the item, as today.

One change, for gap capture (phase 4): `resolve_one` returns the words it skipped as well as the item. The skipped words that are not in `PREPARATIONS` ("low fat", "organic") are a candidate variant the catalog does not have yet.

### Grocery list

- Name: the catalog display name of the matched entry. With variants, a recipe line "1 cup low fat yogurt" shows "low fat yogurt". Unmatched lines keep their own words, as today.
- Merge: distinct codes, so `low_fat_yogurt` and `yogurt` stay separate rows by default.
- Aisle, image, packages, density: inherited, so they need no change.

### Other consumers

- StepMentions: a variant ingredient also highlights the item's aliases, so "stir in the yogurt" still lights up for "low fat yogurt".
- Recipe facets and filter (`recipe_facet/ingredients.rb`, `recipe.rb:117`): roll variants up to their item, so filtering by yogurt finds greek yogurt recipes.
- Admin catalog pages: list variants under their item.
- CatalogMiss and the healer: unchanged. A new variant alias heals old misses the usual way.

## Decisions

1. Definition rule. Proposed: a variant is something you'd pick a different product off the shelf for (low fat, greek, unsalted, boneless, whole wheat). Preparation and state stay with the parser and never become variants (cooked, grated, warm, fresh). Brands and flavours are out unless the shelf truly splits.
2. Combinations. Proposed: one variant per real product, no stacking. "low fat greek yogurt" is its own variant if shoppers buy it, otherwise an alias of the closest one.
3. Gaps. Proposed: a line that matched the item by skipping non-preparation words records a `variant` CatalogMiss, which shows up in the weekly digest and is closed in close-catalog-gaps. Until then the list shows the item name.
4. Storage: flat code plus `variant_of` (above), or a compound code. Proposed: flat.
5. Merging across variants. Proposed: separate rows. Revisit only if users ask.
6. Filters roll up to the item. Proposed: yes.
7. Work already done for this bug:
   - 0b7b849 (committed, not pushed): the importer names items from the parser's `item_text`, which leaks preparation words ("cooked short-grain rice", "grated parmesan", "lait tiède"). The `original_name` column and the add-bar fix in it stay. Proposed: hold the push until phase 3 replaces the naming, or revert just the importer naming.
   - Uncommitted: the `ingredients.item_text` column, its backfill and the reparser hook become unnecessary once names come from the catalog. Proposed: drop them. Keep the `GroceryItemAdder` fix (typed "low fat yogurt" got no catalog code at all).

## Phases

1. Schema. `variant_of` and inheritance in `Catalog::Item`, `#item`, `#variant?`, image fallback, load errors (unknown parent, nested variant). Tests next to `test/models/catalog/items_test.rb`; the alias-uniqueness test already covers variant aliases. README and admin pages.
2. Yogurt first. `low_fat_yogurt`, `greek_yogurt`, and whichever of coconut and dairy-free pass decision 1. Move their aliases out of `yogurt`, add locale names, set the greek density. Re-code existing ingredients with `IngredientLineReparser` scoped to lines that mention yogurt. Check user 62's case end to end.
3. Grocery naming and consumers. The importer names from the catalog display name again. StepMentions picks up item aliases for variants. Facets roll up. Drop the `item_text` work.
4. Gap capture. The parser returns skipped words, a `variant` miss kind, digest and admin display, then update the close-catalog-gaps skill with the variant rule (decision 1) and when to add an alias, a variant or an item.
5. Alias audit. Sweep all 849 items and 7622 aliases for variants filed as aliases, propose moves in batches by aisle, and apply them after approval through close-catalog-gaps. Dairy first, then meat, then baking.

## Verification

- Every phase: replay every existing ingredient line through the parser and diff item codes. The only changes allowed are lines moving from an item to one of its new variants.
- The alias-integrity and items tests from the catalog workflow.
- Phase 2 and 3: add a recipe with low fat yogurt, greek yogurt and plain yogurt to a list in Chrome on the dev host, and check the names, rows, images and aisle.

## Skills to update

- close-catalog-gaps: variant rule, variant miss kind, alias vs variant vs item.
- add-catalog-images: a variant uses its item's image unless it looks different.
- find-ingredient-densities: a variant inherits density unless it differs.
