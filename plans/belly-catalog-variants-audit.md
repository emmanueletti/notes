# Belly catalog variants: phase 5 audit proposal

Status: applied 2026-11-01 (uncommitted), suite green. Policy answers: P1 yes, P2 NO (plant milks and dairy_free_milk stay items), P3-P8 yes.

Applied: every row below except plant milks and these (?) rows, skipped as not passing P4/P7: colby_jack, dinner_roll, vanilla_sugar, cinnamon_sugar, pearl_couscous, currants, sweet_potato_noodles, chickpea_pasta, moong_dal, popcorn_kernels, almond_paste, kashmiri_chili_powder, natural_peanut_butter, reduced_sugar_ketchup, champagne_vinegar, green/black olives, ancho_chili_powder, canned_tomatoes split, smoked_sausage, honeycrisp_apple. Added orange_bell_pepper next to yellow. Every variant's display names are also aliases (skill rule); "sucre semoule" stays on sugar (France: granulated), "mélasse noire" stays on black_treacle, fr-FR light_cream name dropped (crème légère is half_and_half). Dev backfill moved 13 ingredients.

Follow-ups: kosher_salt and greek_yogurt need their own sourced density (find-ingredient-densities); French names on the 75 new variants want a native review; the cleanup section at the bottom is untouched.

Each line: `code` variant_of `base`. (?) marks a judgment call. Proposed English names in quotes; French after approval.

## Policy questions

P1. Vegan, plant-based and dairy-free versions are variants of the thing they replace (vegan_butter of butter, vegan_mayonnaise of mayonnaise), like dairy_free_yogurt. Proposed: yes.

P2. Plant milks (almond, oat, soy, rice, coconut carton) are variants of milk, not items. Proposed: yes (?). Canned coconut_milk stays an item.

P3. Cuts are items, never variants of the animal (chicken_thigh, ground_beef, steak). Variants live inside a cut: boneless vs bone-in, lean grade. Proposed: yes. Keeps vegan_ground_beef variant_of ground_beef legal.

P4. Varieties and kinds are variants when someone sent for the base would accept them: red onion, basmati rice, balsamic vinegar, cherry tomato, chicken stock. A different species or thing stays an item: enoki, napa cabbage, almond flour, sweet potato, peanut butter. Proposed: yes.

P5. Fat level is a variant everywhere, not only yogurt: low_fat_milk, and also low-fat cottage cheese, cream cheese, sour cream, part-skim mozzarella. Proposed: milk yes; the others stay aliases unless you want strict consistency (?).

P6. Whole vs ground spices (cinnamon sticks, cumin seeds, peppercorns) and dried vs fresh herbs (dried dill, sage, thyme). Proposed: leave as aliases for now; a separate catalog-wide decision.

P7. Brands or flavours where recipes ask for them by name and the shelf splits (kewpie mayonnaise, italian breadcrumbs, vanilla sugar, natural peanut butter). Proposed: variants only where the shelf truly splits; otherwise aliases. Each marked (?).

P8. When a base effectively means one variant already (yellow_onion is what "onion" means in North America, button_mushroom is what "mushrooms" means), merge into the base as aliases instead of a variant. Proposed: keep as variants for now so stored codes stay valid (?).

## Dairy, frozen, bakery

Convert existing items
- `unsalted_butter`, `vegan_butter` variant_of `butter`
- `vegan_cream` variant_of `cream`
- `vegan_sour_cream` variant_of `sour_cream`
- `vegan_parmesan_cheese` variant_of `parmesan`
- `vegan_cheese` variant_of `cheese` (?)
- `dairy_free_milk` variant_of `milk`
- `almond_milk`, `oat_milk`, `soy_milk`, `rice_milk`, `coconut_milk_beverage` variant_of `milk` (P2)
- `plant_based_egg` variant_of `egg` (? P1)
- `pepper_jack` variant_of `monterey_jack`
- `half_and_half` variant_of `cream` (?)
- `petit_pois` variant_of `peas`, keeps `aisle: frozen`
- `corn_tortilla`, `flour_tortilla` (?) variant_of `tortilla`
- `wholegrain_bread` variant_of `bread`

New variants from aliases
- `low_fat_milk` ("Low-Fat Milk") of `milk`: skim, nonfat, fat free, 2%, semi-skimmed, lait écrémé, demi-écrémé (P5)
- `light_cream` ("Light Cream") of `cream`: single cream, crème à cuisson (?)
- `fresh_mozzarella` ("Fresh Mozzarella") of `mozzarella`: fresh mozzarella, mozzarella balls, boules de mozzarella
- `colby_jack` ("Colby Jack") of `monterey_jack` (?)
- `coconut_whipped_cream` ("Coconut Whipped Cream") of `whipped_cream` (?)
- `hot_dog_bun` ("Hot Dog Bun") of `bun`
- `dinner_roll` ("Dinner Roll") of `bun` (?)
- `stir_fry_vegetables` ("Stir-Fry Vegetables") of `mixed_vegetables`
- `peas_and_carrots` ("Peas and Carrots") of `mixed_vegetables`
- `shelled_edamame` ("Shelled Edamame") of `edamame` (?)
- `wonton_wrapper` ("Wonton Wrapper") of `dumpling_wrapper` (?)

Kept as items: cottage_cheese, cream_cheese, goat_cheese, swiss_cheese, sour_cream, whipped_cream (?), ice_cream, vegan_chicken (?), naan_bread, pita_bread, rye_bread (?)

## Baking, grains, snacks

Convert existing items
- `brown_sugar`, `powdered_sugar`, `sanding_sugar` variant_of `sugar`
- `vanilla_sugar`, `cinnamon_sugar` variant_of `sugar` (? P7, decide together)
- `cake_flour`, `whole_wheat_flour`, `self_raising_flour` variant_of `flour`
- `gluten_free_flour` variant_of `flour` (?)
- `dairy_free_chocolate_chips` variant_of `chocolate_chips`
- `black_sesame_seeds` variant_of `sesame_seeds`
- `ground_flax_seeds` variant_of `flax_seeds` (?)
- `sliced_almonds` variant_of `almonds` (?)
- `basmati_rice`, `jasmine_rice`, `arborio_rice`, `sushi_rice`, `brown_rice` variant_of `rice`
- `green_lentils`, `red_lentils` variant_of `lentils`
- `whole_wheat_pasta` variant_of `pasta`
- `pearl_couscous` variant_of `couscous` (?)
- `currants` variant_of `raisins` (?)

New variants from aliases
- `bread_flour` ("Bread Flour") of `flour`
- `tipo_00_flour` ("00 Flour") of `flour` (?)
- `caster_sugar` ("Caster Sugar") of `sugar`
- `raw_sugar` ("Raw Sugar") of `sugar`: turbinado, demerara
- `dutch_process_cocoa` ("Dutch-Process Cocoa") of `cocoa_powder` (?)
- `instant_yeast` ("Instant Yeast") of `yeast` (?)
- `gelatin_sheets` ("Gelatin Sheets") of `gelatin`
- `panko` ("Panko") of `breadcrumbs`
- `italian_breadcrumbs` ("Italian Breadcrumbs") of `breadcrumbs` (? P7)
- `gluten_free_breadcrumbs` ("Gluten-Free Breadcrumbs") of `breadcrumbs` (?)
- `dark_corn_syrup` ("Dark Corn Syrup") of `corn_syrup` (?)
- `milk_chocolate_chips` ("Milk Chocolate Chips") of `chocolate_chips` (?)
- `glutinous_rice` ("Glutinous Rice") of `rice`
- `instant_rice` ("Instant Rice") of `rice` (?)
- `glutinous_rice_flour` ("Glutinous Rice Flour") of `rice_flour`
- `rice_vermicelli` ("Rice Vermicelli") of `rice_noodles`
- `sweet_potato_noodles` ("Sweet Potato Glass Noodles") of `bean_thread_noodles` (?)
- `black_lentils` ("Black Lentils") of `lentils`; also "french lentils" moves to green_lentils
- `chickpea_pasta` ("Chickpea Pasta") of `pasta` (?)
- `oven_ready_lasagna` ("Oven-Ready Lasagna Noodles") of `lasagna` (?)
- `quick_oats` ("Quick Oats") of `oats` (?)
- `moong_dal` ("Moong Dal") of `mung_beans` (?)
- `medjool_dates` ("Medjool Dates") of `dates` (?)
- `mini_marshmallows` ("Mini Marshmallows") of `marshmallows` (?)
- `popcorn_kernels` ("Popcorn Kernels") of `popcorn` (?)
- `almond_paste` ("Almond Paste") of `marzipan` (?)

Kept as items: non-wheat flours (almond, coconut, oat, millet, sorghum, buckwheat, cassava, chickpea, corn, rice, rye), spelt and kamut flour (?), coconut_sugar and palm_sugar (?), nutritional_yeast, rose_water, orange_blossom_water, glace_cherry, nut_butter, sunflower_seed_butter, egg_noodles (?), rice_noodles, bean_thread_noodles, puffed_quinoa, wild_rice (?), split_peas, dried_mango, goji_berries

## Condiments, oils and vinegars, spices, canned, beverages

Convert existing items
- `dark_soy_sauce`, `tamari` (?) variant_of `soy_sauce`
- `dijon_mustard`, `whole_grain_mustard`, `yellow_mustard` variant_of `mustard`
- `green_curry_paste`, `red_curry_paste`, `yellow_curry_paste`, `massaman_curry_paste`, `panang_curry_paste` variant_of `curry_paste`
- `madras_paste` variant_of `curry_paste` (? moves it from spices to condiments aisle)
- `vegan_mayonnaise` variant_of `mayonnaise`; `vegan_pesto` of `pesto`; `vegan_worcestershire_sauce` of `worcestershire_sauce`
- `white_miso` variant_of `miso`
- `apple_cider_vinegar`, `balsamic_vinegar`, `black_vinegar`, `malt_vinegar`, `red_wine_vinegar`, `rice_vinegar`, `sherry_vinegar`, `white_wine_vinegar` variant_of `vinegar`
- `extra_virgin_olive_oil` variant_of `olive_oil`
- `smoked_paprika` variant_of `paprika`
- `kashmiri_chili_powder` variant_of `chili_powder` (?)
- `chicken_stock`, `beef_stock`, `vegetable_stock`, `fish_stock`, `lamb_stock`, `vegan_chicken_bouillon` variant_of `stock`
- `kalamata_olives` variant_of `olives`
- `cannellini_beans`, `great_northern_beans`, `navy_beans` variant_of `white_beans`
- `dark_beer` variant_of `beer`; `red_wine`, `white_wine` variant_of `wine`

New variants from aliases
- `low_sodium_soy_sauce` ("Low Sodium Soy Sauce") of `soy_sauce`; "light soy sauce" stays on soy_sauce (Chinese light soy is regular)
- `light_mayonnaise` ("Light Mayonnaise") of `mayonnaise`
- `kewpie_mayonnaise` ("Kewpie Mayonnaise") of `mayonnaise` (? P7)
- `red_pesto` ("Red Pesto") of `pesto`
- `vegetarian_oyster_sauce` ("Vegetarian Oyster Sauce") of `oyster_sauce`
- `vegan_caesar_dressing` ("Vegan Caesar Dressing") of `caesar_dressing` (?)
- `spicy_brown_mustard` ("Spicy Brown Mustard") of `mustard` (?); "moutarde forte" moves to dijon_mustard
- `blackstrap_molasses` ("Blackstrap Molasses") of `molasses` (?)
- `crunchy_peanut_butter` ("Crunchy Peanut Butter") of `peanut_butter`
- `natural_peanut_butter` ("Natural Peanut Butter") of `peanut_butter` (? P7)
- `reduced_sugar_ketchup` ("Reduced Sugar Ketchup") of `ketchup` (?)
- `seasoned_rice_vinegar` ("Seasoned Rice Vinegar") of `vinegar`
- `champagne_vinegar` ("Champagne Vinegar") of `vinegar` (?)
- `light_coconut_milk` ("Light Coconut Milk") of `coconut_milk`
- `castelvetrano_olives` ("Castelvetrano Olives") of `olives`
- `green_olives`, `black_olives` of `olives` (?)
- `kosher_salt` ("Kosher Salt") of `salt`, with its own density (salt's density is wrong for kosher today)
- `flaky_sea_salt` ("Flaky Sea Salt") of `salt`; fleur de sel (?)
- `chipotles_in_adobo` ("Chipotles in Adobo") of `chipotle`, aisle canned; `chipotle_powder` ("Chipotle Powder") of `chipotle` (? which is the base)
- `ancho_chili_powder` ("Ancho Chili Powder") of `ancho_chili` (?)
- `mexican_oregano` ("Mexican Oregano") of `oregano` (?)
- `jamaican_curry_powder` ("Jamaican Curry Powder") of `curry_powder` (?)
- `jerk_paste` ("Jerk Paste") of `jerk_seasoning` (?)
- `anchovy_paste` ("Anchovy Paste") of `anchovy`
- `pasta_sauce` ("Pasta Sauce") of `tomato_sauce`: marinara, bolognese
- `pizza_sauce` ("Pizza Sauce") of `tomato_sauce`
- `passata` ("Passata") of `tomato_sauce`; takes "strained tomatoes" from canned_tomatoes (collision today)
- `canned_tomatoes` split into crushed, diced, fire-roasted, rotel (?)
- `instant_coffee` ("Instant Coffee") of `coffee`
- `dark_rum` ("Dark Rum") of `rum` (?)
- `bread_and_butter_pickles` ("Bread and Butter Pickles") of `pickle` (?)

Kept as items: apple/almond/cashew/peanut butter, date and pomegranate molasses, ginger_garlic_paste, shaoxing_wine, fried_garlic, celery/onion/seasoned salt, juniper_berries, coconut_milk, coconut_cream, condensed and evaporated milk, black_eyed_peas, fermented_black_beans, corned_beef, pickled_ginger, coconut_water, soda_water

## Produce, meat and seafood

Convert existing items
- `red_onion`, `white_onion`, `sweet_onion`, `yellow_onion` (? P8) variant_of `onion`
- `red_bell_pepper`, `green_bell_pepper` variant_of `bell_pepper`
- `cherry_tomato` variant_of `tomato`
- `baby_pak_choi` variant_of `bok_choy`
- `cremini`, `button_mushroom` (? P8) variant_of `mushroom`
- `romaine`, `iceberg` variant_of `lettuce` (?)
- `breakfast_sausage`, `chicken_sausage`, `turkey_sausage`, `vegan_sausage` variant_of `sausage`
- `vegan_ground_beef` variant_of `ground_beef` (P3)

New variants from aliases
- `baby_spinach` ("Baby Spinach") of `spinach`
- `lean_ground_beef` ("Lean Ground Beef") of `ground_beef`: 90%+ lean, extra-lean
- `boneless_chicken_thigh` ("Boneless Chicken Thighs") of `chicken_thigh`
- `bone_in_chicken_breast` ("Bone-In Chicken Breast") of `chicken_breast` (base stays the product most people buy)
- `italian_sausage` ("Italian Sausage") of `sausage`
- `smoked_sausage` ("Smoked Sausage") of `sausage` (? or onto kielbasa)
- `pearl_onion` ("Pearl Onions") of `onion`
- `red_cabbage` ("Red Cabbage") of `cabbage`; `savoy_cabbage` (?)
- `yellow_bell_pepper` ("Yellow Bell Pepper") of `bell_pepper` (? orange too)
- `roma_tomato` ("Roma Tomatoes") of `tomato`
- `russet_potato`, `yukon_gold_potato`, `red_potato`, `baby_potato` of `potato`
- `granny_smith_apple` ("Granny Smith Apples") of `apple`; `honeycrisp_apple` (?)
- `lacinato_kale` ("Lacinato Kale") of `kale` (?)
- `silken_tofu` ("Silken Tofu") of `tofu`; `extra_firm_tofu`, `smoked_tofu` (?)
- `thai_basil` ("Thai Basil") of `basil`
- `sour_cherry` ("Sour Cherries") of `cherry` (?)
- `green_papaya` ("Green Papaya") of `papaya` (?)
- `chinese_eggplant` ("Chinese Eggplant") of `eggplant` (?)
- `white_asparagus` ("White Asparagus") of `asparagus` (?)

Kept as items: shirataki_noodles, cauliflower_rice, zucchini_noodles, sweet_potato, garlic_chives, wild_garlic, napa_cabbage, beech/enoki/oyster/wood ear mushrooms, snow_peas and sugar_snap_peas (?), ground_beef/chicken/pork, rotisserie_chicken, smoked_salmon, chinese_sausage, chilean_sea_bass, chicken_thigh/breast/tenders

## Not variants: misfiled aliases and bugs (separate cleanup)

Bug
- `sea_bass` alias "filet de " is truncated (config/catalog/meat_seafood.yml:601)

Should be new items
- tortilla_chips (from tortilla), cheese_curds (from cheese), cheese sauce ("liquid cheese" on cheese), almond_extract (from vanilla_extract), tapioca_starch (from tapioca + "tapioca flour" on cassava_flour), tempura flour (from flour), pistachio paste (from pistachio), black cardamom (from cardamom)
- turkey: ground turkey, turkey breast, turkey neck, turkey ham are each their own item (P3)
- chicken wings/drumsticks/legs, pork belly/loin, king oyster mushroom (P3/P4)
- made-from products aliased on fresh: salt cod, smoked haddock, smoked mackerel, pickled herring, canned pumpkin, creamed corn, beet greens, dried figs, dried mushrooms

On the wrong entry
- "blue cheese" on stilton (generic under a specific); "caramelized sugar sauce" and "sugar syrup" on sugar; "linguine pasta" on pasta; "dried fruit" on raisins; "soy chunks" on soy_curls; "garlic sauce" on hot_sauce; "gherkin relish" on pickle; "french dressing" on vinaigrette; "apple cider" on cider; "english mustard" on mustard_powder; "beef cutlet" on veal; "chestnut mushroom" on mushroom (belongs on cremini); "green garlic"/"garlic shoots" on scallion; "whitefish"/"white fish" on tilapia/cod; "mutton" on lamb (?); "farmers cheese" on cottage_cheese

Duplicates and collisions
- "short-grain rice" on rice vs "short grain rice" on sushi_rice
- "hoagie buns" on bun vs "hoagie rolls" on bolillo
- sweet_paprika_powder duplicates "sweet paprika" on paprika
- canola oil on vegetable_oil vs rapeseed_oil
- pie_crust vs shortcrust_pastry both carry pâte brisée
- tabasco is a brand item; README says alias on hot_sauce

State words filed as aliases: "chilled butter", "beurre froid" on butter; "toast" on bread

Inconsistencies
- chili_pepper holds habanero, padron, banana pepper while jalapeno, serrano, poblano are items
- winter_squash holds spaghetti squash while butternut, acorn, kabocha are items
- steak lumps ribeye, sirloin, flank, skirt, tenderloin
- chili_powder mixes the US blend with Indian ground red chilli

## Follow-up round, 2026-11-01

Done (uncommitted, suite green):
- Converted items that had no density on purpose kept none: explicit empty `density:` on sanding_sugar, vegan_mayonnaise, vegan_pesto, white_miso, vegan_butter, vegan_cheese, vegan_parmesan_cheese, vegan_sour_cream, smoked_paprika, navy_beans, kalamata_olives, baby_pak_choi, sweet_onion. README documents the empty `density:`.
- Alias moves: caramelized sugar sauce -> caramel, linguine pasta -> linguine, soy/soya chunks -> tvp, english mustard -> mustard, beef cutlet -> beef, short-grain rice -> sushi_rice, hoagie buns -> bolillo, sweet paprika and paprika doux -> sweet_paprika_powder.
- sweet_paprika_powder variant_of paprika; tabasco variant_of hot_sauce (P7).
- Truncated sea_bass alias "filet de" removed.
- Kept on purpose after checking: green garlic on scallion (pinned by a parser test since 37974b7), canola oil on vegetable_oil (rapeseed_oil shows "Huile de colza" to Quebec), apple cider on cider (apple_juice would rename it), state-word aliases (chilled butter, beurre froid, toast) since they map to what you buy.

### Densities: awaiting go-ahead (find-ingredient-densities step 5)

| code | source | id | description | portion | grams | density |
|---|---|---|---|---|---|---|
| greek_yogurt | FNDDS 2024-10-31 | 2705421 | Yogurt, Greek, NS as to type of milk, plain | 1 cup | 245.0 | 1.04 |
| instant_rice | SR Legacy | 169709 | Rice, white, long-grain, precooked or instant, enriched, dry | 1 cup | 95.0 | 0.40 |
| dark_corn_syrup | SR Legacy | 168836 | Syrups, corn, dark | 1 cup | 328.0 | 1.39 |
| light_mayonnaise | SR Legacy | 168094 | Mayonnaise, reduced-calorie or diet, cholesterol-free | 1 cup | 231.0 | 0.98 |

Same as the inherited value, nothing to write: raw_sugar (SR 170674 turbinado, 202 g/cup, 0.85), glutinous_rice (SR 168883, 185 g, 0.78), quick_oats (SR 173904, 81 g, 0.34), mini_marshmallows (SR 167995 miniature, 50 g, 0.21), milk_chocolate_chips (SR 167587, 168 g, 0.71), baby_spinach (SR 168462, 30 g, 0.13), lacinato_kale (SR 168421, 21 g, 0.09).

SKIP:
- kosher_salt: no open source (skill list); stays without one, as salt does.
- panko: no panko entry; SR "soft bread crumbs" (0.19) is fresh crumbs, a different form. Propose pinning an empty `density:` since it inherits breadcrumbs' 0.45 (prior behavior for these lines).
- fresh_mozzarella: SR has only shredded/diced; propose pinning empty for the same reason.
- crunchy_peanut_butter: SR chunky 1.09 vs item 1.05; the item's own source is unclear, difference small, left inheriting.

### New catalog items: awaiting approval (close-catalog-gaps "New catalog entries")

Misfiled aliases that each need a complete new entry (units, aisle, packages, density per find-ingredient-densities, image prompt per add-catalog-images, en/fr-CA names). The alias moves off the wrong item in the same change.

- Snacks/baking/pantry: tortilla_chips (from tortilla), almond_extract (from vanilla_extract), tapioca_starch (from tapioca; + "tapioca flour" from cassava_flour), tempura_flour (from flour), pistachio_paste (from pistachio), simple_syrup ("sugar syrup" from sugar), relish ("gherkin relish" from pickle), french_dressing (from vinaigrette), toum ("garlic sauce" from hot_sauce), dried_fruit (from raisins)
- Dairy: cheese_curds, cheese_sauce ("liquid cheese") from cheese; farmers_cheese from cottage_cheese; blue_cheese item with stilton as its variant
- Spices: black_cardamom (from cardamom)
- Meat (P3 cuts are items): ground_turkey, turkey_breast, turkey_neck (from turkey; turkey ham -> ham alias), chicken_wings, chicken_drumsticks, chicken_legs (from chicken), pork_belly, pork_loin (from pork), mutton (from lamb)
- Seafood: salt_cod (from cod), smoked_haddock, smoked_mackerel, pickled_herring, whitefish (from tilapia/cod)
- Produce: king_oyster_mushroom (from oyster_mushroom), beet_greens (from beet), dried_mushrooms (from mushroom), dried_figs (from figs), spaghetti_squash (from winter_squash)
- Canned: pumpkin_puree (canned pumpkin, from pumpkin), creamed_corn (from corn)

Consistency splits, same approval:
- chili_pepper: habanero, padron, banana pepper, hungarian wax become variants of chili_pepper; jalapeno, serrano, poblano (items today) become variants too (P4).
- steak: ribeye, sirloin, flank, skirt, tenderloin each become items (P3 cuts), steak stays the generic.
- chili_powder: split the Indian ground red chilli wordings into their own item; the US blend stays.

Cost: about 35 new images at the add-catalog-images default (gpt-image-1.5, low). Estimate from that skill before generating.

### Applied 2026-11-01 (uncommitted, suite green)
- Densities written: greek_yogurt 1.04, instant_rice 0.40, dark_corn_syrup 1.39, light_mayonnaise 0.98 (re-read against raw USDA rows); panko and fresh_mozzarella pinned empty.
- 41 new items + 4 chili variants written with aliases moved off the wrong items, en/fr-CA (fr-FR where different) names, image prompts. Sourced densities: blue_cheese 0.57 (SR 172175, 1 cup crumbled not packed, 135 g), relish 1.04 (SR 168561, 1 cup, 245 g), beet_greens 0.16 (SR 170375, 1 cup, 38 g), dried_figs 0.63 (SR 174665, 1 cup, 149 g), pumpkin_puree 1.04 (SR 168450, 1 cup, 245 g), creamed_corn 1.08 (SR 169215, 1 cup, 256 g). tapioca_starch skipped (SR only has pearl tapioca).
- Converted: jalapeno, serrano, poblano variant_of chili_pepper; stilton variant_of blue_cheese. "red/hot chilli powder" moved to cayenne; "turkey ham" to ham.
- New backfill backfills:run:catalog_split_items moves stored ingredients onto the split-out items (dev: 4).
- Images not generated yet: needs the cost approval.
