# What social apps actually send to a share target

Measured 2026-09-18 on Android 36 emulator (`share_probe` AVD), belly debug
build, probe at `features/share/ShareProbe.kt`. Neither platform documents what
a source app puts in a share payload, so this was measured rather than looked
up. Expect it to rot; re-run the probe before trusting it.

## Results

| Source | action | type | EXTRA_TEXT | EXTRA_SUBJECT | Caption included? |
|---|---|---|---|---|---|
| TikTok | SEND | text/plain | `https://www.tiktok.com/t/ZTUv9hKJg/` | absent | no |
| Instagram | SEND | text/plain | `https://www.instagram.com/p/DdWXqKyDqlZ/?img_index=1&stkn=MXdjdjY0eDQ0Nmlqdg==` | absent | no |
| Pinterest | SEND | text/plain | `Take a look! 📌 https://pin.it/jveDMtBqS` | `Take a look! 📌` | no |

clipData mirrored EXTRA_TEXT in all three. No EXTRA_STREAM, no attachments.

Headline: no source sends the caption. `SharedImport.sharedRecipeUrl` discards
nothing of value, and Pinterest's leading text is boilerplate, not the pin title.

## Reaching belly at all

None of the three list belly in their own share UI. Each requires a second step
into the Android sheet:

- TikTok: custom sheet, scroll the first row right, tap **More**
- Instagram: DM sheet, bottom row, tap **Share**
- Pinterest: "Share Pin link" sheet, tap **More** (legacy chooser)

Onboarding needs to say this. Users will not find it alone. ReciMe's help doc
gives the same instruction for TikTok.

## Shortlink resolution

- `tiktok.com/t/ZTUv9hKJg/` -> `/@ashley_recipes/photo/7682049568975932702?_r=1&_t=...`
- `pin.it/jveDMtBqS` -> `ca.pinterest.com/pin/908953137979946616/sent/?invite_code=...&sender=...&sfo=1`

## Findings that change the code

1. **Pinterest cache never hits.** `Base.canonical_url` downcases host and
   chomps a trailing slash only; it does not touch the query. Pinterest has no
   override, so `invite_code`/`sender` (unique per share) ride into the cache
   key and every share re-runs the pipeline. The sharer's Pinterest sender id
   also gets persisted in `source_url`. Needs a Pinterest `canonical_url`:
   strip query, strip the `/sent` path segment, normalise country subdomains
   (`ca.` vs `www.`).

2. **TikTok photo posts.** Recipe carousels resolve to `/photo/<id>`, not
   `/video/<id>`. oEmbed rejects `/photo/` with HTTP 400 but accepts the same
   id under `/video/`. Rewrite the path before calling oEmbed.

3. **TikTok oEmbed returns the whole recipe.** 1935 chars for the test post:
   grouped ingredients, five numbered steps, hashtags. Public endpoint, no
   auth, no scraping. Feeds `CaptionRequest` directly at ~500 tokens.

4. **Instagram is already correct.** Its `canonical_url` reduces to the
   shortcode, so `img_index` and the per-share `stkn` token are both dropped.

## Still unmeasured

- iOS. No simulator on this box. Open question: belly's activation rule declares
  only `NSExtensionActivationSupportsWebURLWithMaxCount`, and unspecified types
  default to zero, so if a source attaches plain text alongside the URL belly
  may not appear in the sheet at all.
- Whether a TikTok video post (rather than photo) carries `claInfo.captionInfos`
  with a fetchable subtitle track.

## TikTok video post vs photo post (2026-09-18)

Measured a second TikTok post, this time a real video (`/video/`, 62s,
narrated-style with on-screen text), to see whether the share payload differs
from a photo carousel. It does not.

    EXTRA_TEXT = https://www.tiktok.com/t/ZTUvQs8A3/   (35 chars, no caption)

Same `/t/` shortlink shape, same length, no EXTRA_SUBJECT. Video and photo
posts are indistinguishable at the share boundary; the post type only shows up
after resolving.

Resolved to `@cristiiicarrillo/video/7638304516588195103`.

- oEmbed returned the full recipe again: 664 chars, ingredients and method.
- The handle in the url is ignored. oEmbed accepted `@cristicarrillo` (one `i`)
  for a video that lives under `@cristiiicarrillo` (three). Only the numeric id
  matters, so canonicalisation can drop the handle entirely.
- `video.claInfo` was `{hasOriginalAudio: true, enableAutoCaption: true,
  captionInfos: [], noCaptionReason: 3}` and `subtitleInfos` empty. Second
  sample in a row with no fetchable subtitle track. This post is music plus
  on-screen text, so there may be no speech to caption; not proof the field
  never populates, but rung 5 remains unverified after two tries.
- Video page still readable from a residential IP: 429KB, no WAF challenge.

Takeaway: on both samples oEmbed alone was sufficient. Recipe creators write
the recipe into the caption because TikTok search rewards it. Build rungs 0-3
and measure the miss rate before spending anything on transcript or frames.
