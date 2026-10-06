# Belly: simpler recipe import

Goal: a recipe import anyone can read top to bottom in one sitting, that
answers one question: can we import this, and if not, why. About 12 files with
plain names instead of 26 with invented ones.

Started 2026-10-01 from a failed imports pass. The RECIPE_ELSEWHERE change
(new code, paste-sheet banner, `missing_recipe_reason` on the request classes)
lands first, before any of this.

## Rules

- No new words where a plain one exists. No Strategy, Adapter, Reading,
  Unreadable, verdict.
- No base class until two concrete classes share real code, and even then a
  small module of helpers before a template method.
- No class that only calls another class.
- One file per thing someone would search for: "how does Instagram import
  work" opens `sources/instagram.rb` and finds all of it, oEmbed included.
- Hashes and constants over registries and catalogs.
- File count is a symptom, not the target. Merge only where it removes a
  concept.

## Target shape

| Today | Target |
|---|---|
| `RecipeIngest` + `Pipeline` | `RecipeIngest.call(url)`: fetch, read, follow one link, return a `Result` |
| `Fetcher` + impersonation step in `Pipeline` | `PageFetcher` owns the fallback; `CurlImpersonateClient` (was `ImpersonatingFetcher`) stays its own file (curl process plumbing). Done. |
| `SourceAdapters` + `Base` + `REGISTRY` | `sources/<name>.rb`, each with `read(page)`; a plain `SOURCES` array picks one by host |
| `InstagramOembed`, `TiktokOembed` | inside `sources/instagram.rb` and `sources/tiktok.rb` |
| `Reading` / `Redirect` / `Unreadable` | `RecipeIngest::ExtractedRecipe`, `RecipeIngest::FollowLink`, and the existing `RecipeIngest::Failure`. Done. |
| `LlmStrategy`, `JsonLdStrategy` | methods on `sources/web.rb`; JSON-LD parsing moves to a pure model if it stays big |
| `ExtractionRequest` + text, url, caption, video caption, photo requests + `LlmExtraction` | one `RecipeExtraction`, prompt picked from a hash by source (`:web`, `:caption`, `:video`, `:text`, `:photo`) |
| `IngredientGrouper` + `IngredientGrouperRequest` | one file |
| `PageMeta` + `PageText` | one `Page` model in `app/models/recipe_ingest/page.rb`. Done. |
| reason knowledge in five places | a `REASONS` hash in one file: code to referral |

Shared bits the sources really do share (link finding with the shopfront
deny-list, json string unescape, cover and author) go in one small helper
module, not a base class. Today they are copied between YouTube and Facebook,
and Facebook reaches into `Youtube::ELSEWHERE`.

Namespace stays `RecipeIngest` (39 files reference it). Renaming it is churn
with no reader benefit.

## What an import answers

The model observes, code decides. Haiku flips compound judgments on prompt
wording (the bare-title caption did all session), so the model never picks the
reason. It extracts whatever ingredients and steps are there and answers one
yes/no: do the caption's own words send the reader somewhere to get the
recipe.

One method on `RecipeExtraction`, about ten lines, picks the outcome. For a
social post:

1. Ingredients and steps: import.
2. Ingredients only: INGREDIENTS_WITHOUT_METHOD.
3. A url written in the caption: follow it, one hop (regex, not the model;
   TikTok already does this).
4. Words point elsewhere: RECIPE_GATED.
5. Otherwise: the recipe is in the post's video or images.

Step 5 is a best-effort deduction, not something the model judges. The user
pressing import is the evidence there is a recipe. Video or images comes from
the url: `/reel/`, `/tv/`, TikTok `/video/` and YouTube are video, TikTok
`/photo/` is images, Instagram `/p/` is either.

Web pages keep NOT_A_RECIPE: no media to fall back on.

## Reasons

| Code | Meaning | User sees |
|---|---|---|
| NOT_A_RECIPE | web page with no recipe | paste sheet, "no recipe" banner |
| INGREDIENTS_WITHOUT_METHOD | ingredients, no steps | paste the method |
| RECIPE_GATED | DM, comment keyword, subscription, bio | "somewhere we can't reach" banner |
| RECIPE_IN_VIDEO | by elimination, video url | paste; counts video demand |
| RECIPE_IN_IMAGES | by elimination, image url | screenshot into photo import |

RECIPE_ELSEWHERE (shipping now) becomes RECIPE_GATED once caption urls are
followed. POTENTIALLY_VIDEO_ONLY_RECIPE becomes RECIPE_IN_VIDEO. Stored codes
rename with a backfill in `lib/tasks/backfills.rake`, or the digest's video
demand count splits.

Every stored reason becomes a code. Today the `reason` column mixes codes with
prose ("instagram would not show us this post"); the prose moves to the log
line.

Not the model's job: fetch and access failures (blocked, signed out, private),
PROVIDER_FAILED, INVALID_PAYLOAD.

Known cost: video demand gets noisier (multi-dish reels count). Fine for a
best-effort signal.

No event processor or subscribers. Following a link happens inside the import
before the failure is final; banners, recording and the digest only read the
`REASONS` hash. Revisit only when a consumer lives outside the request (async
notification, analytics export, re-import job).

## Bugs to fix along the way

- Web pages lose their LLM reason. `LlmStrategy#call` returns `.data`, so a
  page the model calls NOT_A_RECIPE is recorded as "no strategy could read the
  page" and gets the wrong banner.
- `VideoCaptionRequest#kind` says "caption", so logs can't tell which prompt
  ran.
- Sources disagree on links: TikTok checks before the model, YouTube and
  Facebook only after it fails, Instagram never.
- `Pipeline`'s `else adapter_failure("nothing could read the page")` is
  unreachable.

## Names that must not survive

These are poor names left in place on purpose because a later step deletes or
folds them. Renaming them early is wasted work; leaving them after the
flattening is a miss. Whoever finishes step 3 checks every row is gone
(`grep -rn` over `server/app server/test`).

| Name | Why it is poor | Removed by |
|---|---|---|
| `Pipeline` | a class whose only job is `RecipeIngest.call` | step 3, fold into `RecipeIngest.call` |
| `SourceAdapters`, `SourceAdapters::Base`, `REGISTRY`, `FALLBACK` | invented vocabulary, registry | step 3, `sources/<name>.rb` + a plain `SOURCES` array |
| `Reading`, `Redirect`, `Unreadable` | invented result types | done: `ExtractedRecipe`, `FollowLink`, and the existing `Failure` (user chose named structs over `Result` with `follow:`) |
| `LlmStrategy` | 20-line pass-through, "strategy" says nothing | step 3, a method on `sources/web.rb` |
| `JsonLdStrategy` | "strategy" | step 3, method on Web or a pure model |
| `ExtractionRequest` + `TextRequest`, `UrlRequest`, `CaptionRequest`, `VideoCaptionRequest`, `PhotoRequest`, `LlmExtraction` | six classes for one prompt with variations | step 3, one `RecipeExtraction` |
| `missing_recipe_reason` on the request classes | lives on classes being deleted | step 3, moves into `RecipeExtraction`; step 6 replaces it with the outcome method |
| `RecipePageDetector` "verdict" | "verdict" is jargon for score + signals | Web step of 3; rename the value, keep the class |
| `InstagramOembed`, `TiktokOembed` | separate files for single-caller clients | step 3, inside their source file |
| `IngredientGrouperRequest` | separate file for one caller | step 3, inside `IngredientGrouper` |
| `IngredientGrouper#reject` | logs and returns the payload ungrouped; nothing is rejected | grouper step; rename to what it does, e.g. `log_and_keep_ungrouped` |

## Sequencing

Note (2026-10-06): main was rebased and pushed by someone else after step 3,
so the commit hashes below are stale. Match by commit subject. Everything up to
"name JsonLdRecipeParser's helpers" is on origin/main; step 6 is local.

Flatten first with behaviour unchanged, then redesign inside the simpler code.
Never both in one step. Suite green after every step; one source at a time.

1. Done (`f83160f`). Commit RECIPE_ELSEWHERE (green, evals 25/25 x3).
2. Done (`82c8e64`, `8548eac`). Fix the web reason bug and `kind`.
3. Flatten, no behaviour change:
   - Done (`f7b2c2f`). `Page` (meta + text), `PageFetcher` absorbs the
     impersonation fallback, `Fetcher` renamed `PageFetcher`,
     `ImpersonatingFetcher` renamed `CurlImpersonateClient`, private methods
     renamed (`fetch_with_user_agents`, `user_agents`, `read_response`,
     `meta_tags`, `tag_value`, `absolute_url`), constants renamed
     (`*_TAGS`, `TEXT_BLOCKS`, `USER_AGENTS`, `USER_AGENT_NAMES`),
     `@refused_with` removed.
   - Done (`e9a48a0`, own commit, a behaviour change): dropped the browser
     `User-Agent` rung. See "Fetch: one agent".
   - Done (see git log). One `RecipeExtraction` replaces the request classes
     and `LlmExtraction`. Called as `RecipeExtraction.call(kind, text:, images:,
     source_url:)`; kinds `:url`, `:text`, `:photo`, `:caption`,
     `:video_caption`; one `KINDS` hash (prompt, lead, tool per kind) that also
     validates the kind in the initializer. Verified
     byte-identical to the old classes (prompt, tool, content, model, tokens,
     event, kind for all 6 variants); evals 24/25 then 25/25 (the miss was the
     known-flaky `caption_multi_part_recipe`). `missing_recipe_reason` is now a
     3-line private method. `LlmGate` stringifies `kind` for logs and metrics.
     Follow-ups done: constants and helpers renamed for what they hold and do
     (`136af94`; `reject` is `log_and_fail`), placeholder regex replaced by
     `PLACEHOLDER_VALUES = ["<unknown>", "unknown"]` (`320f431`; measured: the
     only placeholder in 3,175 values across 42 extractions). Add a value to the
     list only when evals or the digest show a new one.
   - Done (`3fcc5e5` class << self in touched files, `db82a3c` result types,
     `27908fd` literal method names: `claims_host?`, `fill_missing_images_and_source_name`,
     `build_extracted_recipe`, `log_and_fail_signed_out`, `registered_adapter_for`
     replacing `identify` + private `adapter_for`, `failure_result`, and the rest).
     Every source returns `ExtractedRecipe`, `FollowLink`
     or `Failure(stage: "adapter")`, swapped in one mechanical commit so the
     import code never handles two shapes. Base's `reject` is `log_and_fail`;
     the unreachable `else` in `Pipeline` is gone (an unmatched return now
     raises `NoMatchingPatternError`, a programming error).
   - Pipeline folded (`c28a7dd`): `RecipeIngest.call(url)` does fetch, read
     and the one hop itself (`MAX_HOPS` on `RecipeIngest`); the registry lives
     in `sources.rb` (`Sources::REGISTERED`, `Sources::FALLBACK`,
     `source_for_url_or_web`, `registered_source_for`, `canonical_url`).
     `Pipeline`, `SourceAdapters` and `Base` deleted. Live through
     `RecipeIngest.call`: hummus (json_ld), a YouTube sourdough (llm), the
     report's TikTok (RECIPE_ELSEWHERE) and cookies reel
     (POTENTIALLY_VIDEO_ONLY_RECIPE). Names check: everything gone except
     `IngredientGrouperRequest`, `IngredientGrouper#reject` and the detector's
     `verdict` / `Verdict`, still open.
   - Web done (`70415a9`): `Sources::Web` (`FALLBACK`), `LlmStrategy` folded
     in as `extract_with_llm` (the "no strategy could read the page" string
     kept as `NO_READABLE_TEXT`), `JsonLdStrategy` is now the pure model
     `JsonLdRecipeParser` (`.new(page).parse`), strategy names are
     `RecipeIngest::LLM_STRATEGY` / `JSON_LD_STRATEGY`. Live: hummus via
     JSON-LD (9 ingredients); Chicken Chasseur with JSON-LD stripped via the
     LLM (17 ingredients, 9 steps, against 19 in its JSON-LD: a data point for
     the page-text eval). `JsonLdRecipeParser`'s private method names (`build`,
     `named`, `list`, `text`, ...) are still prose-like; rename in their own
     commit.
   - Facebook done (`dd83f2a`): `Sources::Facebook`, `canonical_url` builds
     on `UrlNormalizer.normalize` instead of `super`; `SIGNED_OUT` referral key
     moved with it. No live check (no public Facebook recipe post to hand);
     covered by the moved tests.
   - YouTube done (`0455d66`): `Sources::Youtube` (`video_id` now a private
     class method). Link finding moved into `Sources::Helpers`:
     `SHOPFRONT_AND_SOCIAL_HOSTS` (was `Youtube::ELSEWHERE`),
     `first_recipe_link(text, link_pattern:, trailing_punctuation:)`,
     `shopfront_or_social_link?`, `parse_json_string`. Facebook's copies
     deleted (it gets them through `Base`). Each source keeps its own link
     regex: YouTube's and Facebook's differ, and TikTok's skips the shopfront
     filter; unifying them is a behaviour change for step 6. Live: a real
     YouTube video imported ("Your First Sourdough", Brian Lagerstrom, 8
     ingredients).
   - Instagram done (`0346499`): `Sources::Instagram` with oEmbed folded in the same way;
     `SIGNED_OUT` moved with it. Tests stub the oEmbed URL; the default stub
     answers an empty caption so fallback tests skip the retry wait. Live: the
     cookies reel is POTENTIALLY_VIDEO_ONLY_RECIPE; the whipped feta carousel
     ("Save the recipe to your belly at usebelly.app") is RECIPE_ELSEWHERE,
     though its recipe is on the slides. Add that caption as a fixture in step
     5 (should become RECIPE_IN_IMAGES).
   - TikTok done (`b1512ea`): `Sources::Tiktok` with the oEmbed client folded
     in as private methods (`fetch_oembed_post` and friends, `OEMBED_*`
     constants, `OembedPost`). Tests stub TikTok's oEmbed endpoint with WebMock
     instead of stubbing a class. Live check on the report's TikTok:
     RECIPE_ELSEWHERE (substack caption), as expected.
   - Pinterest done (`5bd2306`): `Sources::Pinterest` (no base class, no
     forwarding `self.call`), shared pieces in `Sources::Helpers`
     (`fill_missing_images_and_source_name`, `log_and_fail`; `Base` includes it
     too) and `RecipeIngest::UrlNormalizer.normalize` (pure model in
     `app/models`; `Base.canonical_url` delegates to it). `Pipeline` builds
     every source with `.new(page).call`, so old adapters and new sources mix
     in `REGISTRY` with no special case.
   - Sources one at a time into `sources/<name>.rb`, no forwarding
     `self.call`, class methods in `class << self` (never `def self.`): Pinterest, TikTok (+ oEmbed), Instagram (+ oEmbed), YouTube,
     Facebook, Web (+ strategies). The page-text eval in "Web page text" is not
     needed to move Web (the move changes no behaviour); run it before anyone
     changes how `Page#text` finds the recipe.
   - Fold `Pipeline` into `RecipeIngest.call`; delete `SourceAdapters`, `Base`.
     (Done, see above.)
   - Done: `IngredientGrouperRequest` folded into `IngredientGrouper` (`c11e955`,
     `reject` is `log_and_keep_ungrouped`, prompt/tool/content verified
     byte-identical); detector's `Verdict` is `RecipeSignalScore` with
     `recipe_likely?` / `recipe_possible?` (`5f83f9c`); `JsonLdRecipeParser`
     helpers renamed (`31c709d`).
   - STEP 3 COMPLETE (2026-10-03). "Names that must not survive" all gone.
     Pipeline commits after `c28a7dd` (fold) are on main, unpushed.
4. Eval spike: measure extraction and `points_elsewhere` accuracy across about
   5 runs per fixture. Under about 95% is not ready.
   DONE 2026-10-04 (28 cases x 5 runs: 25 fixtures + pizza beans, pasta
   fagioli, whipped feta from the 2026-10-01 report). Experimental prompt: no
   is_recipe gate, "copy whatever recipe the source holds", points_elsewhere
   always asked; outcome decided in code.
   - has_ingredients 140/140 (100%); invented ingredients on bare titles,
     promises, pins: 0. The main risk of dropping the gate did not happen.
   - has_steps 138/140 (99%); misses are the marinade-only caption (flaky
     under today's prompt too).
   - points_elsewhere 67/75 (89%), 67/70 (96%) without whipped feta. Feta 0/5:
     "Save the recipe to your belly at usebelly.app" does point at an app,
     ours. Product rule needed: a pointer to Belly is not elsewhere. Other
     misses: 2 pins and 1 bare title called GATED instead of IN_MEDIA (both
     route to paste; banner wording differs).
   - Final outcome 130/140 (93%); today's prompt 135/135 against today's
     coarser codes.
   - Not measured: web pages (no web fixtures), steps without ingredients.
   Spike script and its fixtures live in `~/notes/plans/belly-import-redesign/`
   until step 6 brings them into the repo with the code.
5. Fixtures for every reason, including guards against invented ingredients
   once `is_recipe: false, set nothing else` goes away.
   Additions from the spike: whipped feta expecting RECIPE_IN_MEDIA (with a
   Belly-is-not-elsewhere rule, prompt first, code rule if the prompt misses),
   a steps-without-ingredients case, a caption with a written-out URL
   (FOLLOW_LINK), and web page fixtures (shared with the page-text eval).
   Re-run the spike; points_elsewhere must reach 95% before step 6 ships.
6. DONE 2026-10-06 (see git log). Decisions (user): method-only captions
   import with the ingredients the method names; one RECIPE_IN_MEDIA code;
   RECIPE_GATED replaces RECIPE_ELSEWHERE; order is import, follow a written
   link, INGREDIENTS_WITHOUT_METHOD, RECIPE_GATED, RECIPE_IN_MEDIA (pasted text,
   web pages, photos: NOT_A_RECIPE instead of the last two). Built: no
   is_recipe gate, kinds caption / pin_blurb / text / url / photo
   (video_caption gone), `missing_recipe_reason(payload, answers)`,
   `follow_written_link_or_log_and_fail` shared by every caption source
   (TikTok lost its link-first shortcut; Instagram gained link following; the
   shopfront filter applies everywhere), referral `recipe_gated`, 29 redesign
   fixtures in the repo. Steps with zero ingredients cannot save
   (RecipeSchema minItems) and fall through the order like nothing extracted.
   RECIPE_IN_MEDIA referral `recipe_in_media`, banner copy A (approved): "This
   post keeps its recipe in the video or photos, and we can only read the
   caption. If you can see the recipe, type or paste it below." Evals after a
   method-only rule tweak: 143/145 over 5 runs (method-only 4/5, one
   INVALID_PAYLOAD flake).
   Outcome method, prompt change, caption urls followed on every source.
   Evals stable across several runs. Split `NO_INGREDIENTS_OR_STEPS`, which
   today covers two cases because ingredients are checked first: nothing
   extracted (the model contradicted its own is_recipe; treat as is_recipe
   false and fall through the normal order) and steps without ingredients (its
   own reason, `STEPS_WITHOUT_INGREDIENTS`, pairing with
   `INGREDIENTS_WITHOUT_METHOD`).
7. `REASONS` hash; controllers and the paste sheet read it.
8. DONE (committed, unpushed): `backfills:run:failed_import_reasons` renames
   POTENTIALLY_VIDEO_ONLY_RECIPE to RECIPE_IN_MEDIA and RECIPE_ELSEWHERE to
   RECIPE_GATED in failed_recipe_imports. NO_INGREDIENTS_OR_STEPS and old social
   NOT_A_RECIPE rows are left: their meaning cannot be recovered per row.
   Human runs it on production after step 6 deploys, then deletes the task.

## Fetch: one agent

Measured 2026-10-01. Ruby's Net::HTTP with each `User-Agent`, from a dev box:

| Site | BellyBot | Browser UA |
|---|---|---|
| simplyrecipes.com | 200 | 402 |
| allrecipes.com | 200 | 402 |
| seriouseats.com | 200 | 402 |
| foodnetwork.com | 200 | 403 |
| budgetbytes.com | 200 | 403 |
| bonappetit, NYT Cooking, recipetineats | 200 | 200 |

A Chrome `User-Agent` on Ruby's TLS fingerprint reads as a bot posing as a
browser, which is what walls block. curl-impersonate works because it fakes
the header and the TLS fingerprint together. In production, the ladder climbed
once in four days (simplyrecipes, 2026-09-30): 403 on every agent, then
curl-impersonate. The browser rung saved nothing.

Caveats: measured from a dev IP, not Render's. Production was behind main at
the time (still logging a `crawler` agent that `45610d7` removed).

Change: the fetch becomes BellyBot, then curl-impersonate on a refusal.
Removes:

- `BROWSER_USER_AGENT`, `USER_AGENTS`, `USER_AGENT_NAMES`, `user_agents`,
  `user_agent_name`, and the loop in `fetch_with_user_agents` (it collapses
  into a single `get`).
- `PRICED_ACCESS`, `RETRYABLE_REFUSALS`, `announce_retry`, and the claimed-host
  rule that kept Instagram off the browser header.
- The `recipe_fetch_retrying` log event and the `agent` property on
  `recipe_fetch_failed`.
- The close-import-failures skill's "403 to BellyBot, 200 to the browser
  agent" row and its `PageFetcher#user_agents` note, updated in the same
  change.

After deploy: check `recipe_fetch_impersonating` logs that curl-impersonate
still recovers walled sites.

## Web page text

`Page#text` sends at most 12,000 characters, cut from the top, and only for web
pages with no JSON-LD recipe. On a long blog post the story can fill the window
and push the recipe past the cut. `RECIPE_CONTAINERS` (schema.org microdata
plus seven WordPress plugin classes: WPRM, Tasty, Mediavine Create, EasyRecipe,
Simple Recipe Pro, Cooked, ZipList) exists to start at the recipe instead.

Do not grow the plugin list. WPRM, Tasty and Mediavine all write JSON-LD, so
their pages almost never reach the model. The pages that do (custom themes,
hand-written blogs, broken JSON-LD) are the ones no plugin class matches.

Options:

1. Recommended: start at the recipe, not at a plugin class. The detector
   already finds the "Ingredients" heading and quantity lines. Start the
   12,000-character window just before that heading. Works on any site, no
   list to maintain. Microdata can stay as a first choice (a standard, not a
   plugin).
2. Drop the containers and raise the cap (about 40,000 characters, roughly
   10,000 Haiku tokens, about a cent per web import without JSON-LD). Least
   code; more noise, so more risk of the model taking a "you might also like"
   recipe, and very long pages can still be cut.

Eval first. There are no web page fixtures yet, only captions. Collect 10 to 15
real recipe pages with no JSON-LD (long story above the recipe, custom themes,
microdata-only), save their html as fixtures, and score current vs option 1 vs
option 2 on whether the right recipe comes out whole. Choose on the numbers.

The detector's own use of the plugin list (3 points of recipe signal) is
separate; keep or drop it with the Web step.

## Keep

- Log event names (`recipe_extraction_rejected`, `instagram_caption_missing`,
  ...). The close-import-failures skill and AppSignal searches depend on them.
  Rename only all at once, with the skill updated in the same change.
- `CurlImpersonateClient` separate from `PageFetcher`: two transports.
- `CachedRecipeImport`, `RecipeSchema`, `RecipeBuilder`, `RecipePageDetector`:
  each already one plain thing.

## Open questions

- Several dishes ("3 ways to"): own reason, or let it fall to media.
- Steps with no ingredients: rare; fold into NOT_A_RECIPE or name it.
- Instagram `/p/`: one RECIPE_IN_MEDIA code with media type beside it, or two
  codes.
- Dropping `is_recipe: false, set nothing else` risks invented ingredients from
  a bare title. The spike decides whether a lighter guard stays.

## After this plan: remove forwarding `self.call`

Not a codebase convention, and unwanted: a class method whose whole body is
`new(...).call` only exists to skip writing `.new`. It spread because agents
copied it. A class-level builder earns its place when it does real work
(chooses a class, normalizes input, caches); a pure forwarder to a fresh
instance does not. Callers write `Thing.new(...).call`; tests stub
`Thing.any_instance.stubs(:call)` or inject the instance.

Do it app-wide in one change, not piecemeal, so the codebase never shows both
shapes for long. Classes in `app/` and `lib/` with a forwarding `self.call` as
of 2026-10-01 (from `grep -rnE "^\s+new\([^)]*\)\.call\s*$" app lib`):

- `app/services/catalog_miss_healer.rb`
- `app/services/grocery_item_adder.rb`
- `app/services/ingredient_parser.rb`
- `app/services/login_code_delivery.rb`
- `app/services/login_code_request.rb`
- `app/services/recipe_copier.rb`
- `app/services/recipe_ingest/curl_impersonate_client.rb`
- `app/services/recipe_ingest/ingredient_grouper.rb`
- `app/services/recipe_ingest/instagram_oembed.rb`
- `app/services/recipe_ingest/json_ld_strategy.rb`
- `app/services/recipe_ingest/llm_strategy.rb`
- `app/services/recipe_ingest/page_fetcher.rb`
- `app/services/recipe_ingest/pipeline.rb`
- `app/services/recipe_ingest/recipe_builder.rb`
- `app/services/recipe_ingest/recipe_extraction.rb`
- `app/services/recipe_ingest/recipe_page_detector.rb`
- `app/services/recipe_ingest/source_adapters/base.rb`
- `app/services/recipe_ingest/tiktok_oembed.rb`
- `app/services/recipe_keeper_importer.rb`

Files this plan creates from scratch (`sources/<name>.rb`) are written without
it. Existing classes, `RecipeExtraction` included, keep it until the sweep.

## After this plan: `def self.` to `class << self`

House style: class methods live in a `class << self` block, with `private`
inside it for class-level helpers, never as `def self.method`. As of
2026-10-01 there are 86 `def self.` methods in 53 files under `app/` and
`lib/`, 33 of them in 17 recipe ingest files (`grep -rn "def self\." app lib`).

- New files this plan creates (`sources/<name>.rb`, anything else written from
  scratch) use `class << self` from the start.
- Existing classes convert in one app-wide sweep, together with the forwarding
  `self.call` removal above: 19 of the 86 are forwarders that get deleted rather
  than moved, so do that sweep first and convert what is left.
- Keep it mechanical: move each method into the block unchanged, keep public
  and private as they were, suite green, no other edits in the same commit.

