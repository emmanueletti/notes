# belly: fetch refused recipe pages on the device

Status: proposed, 2026-10-17. Not started.

## Problem

Some recipe sites refuse production's fetch with a 403 even after curl-impersonate
retries as Chrome. thekitchn.com (16 Oct) refused both fetches from production
but served the page to BellyBot from a home connection. The block is on our
address (Render runs on a cloud provider's IP ranges, which bot protection
flags wholesale), not on how we ask. Today the user lands on the "blocked"
referral and has to paste the recipe by hand.

A server-side headless browser (FlareSolverr, Byparr, Scrapling) does not help
here: it solves JavaScript challenges, but still leaves from Render's address.
Residential proxies would help but are out: they exist to evade detection, and
many networks route through other people's devices.

## Step 0: measure first (shipped with this plan)

`recipe_fetch_failed` and `recipe_impersonated_fetch_failed` now log the
refusing site's `server`, `cf_mitigated`, and `challenge` (cloudflare,
datadome, imperva, human, aws_waf, from `RecipeIngest::RefusedResponse`).

Read after 2 to 4 weeks of logs (AppSignal, one query per day):

- Mostly no `challenge` on impersonated failures: address blocks. Build the
  device fetch below.
- Mostly `challenge: cloudflare` or another vendor: a browser challenge. A
  Byparr sidecar (FlareSolverr API, Camoufox) might win these from the server
  and needs no app release. Weigh its memory (a Chromium container, about 1 GB)
  against the count.
- A handful a month: neither is worth it; the paste referral stays.

Trigger to start building: refusals that survive impersonation reach a few a
week, or keep landing on sites people import from often.

## Step 0b: record the platform on every failure (not built yet)

Logs carry `hotwire_native: true/false` on every line, but they expire after
about a week, and "not native" lumps phone browsers in with desktop ones. The
permanent `failed_recipe_imports` table (admin page and digest) stores no
platform at all.

- Add `platform` to `failed_recipe_imports`: `ios`, `android`, `mobile_web`,
  `desktop_web`. Schema-only migration, no `default:`; enum in the model.
- Apps are told apart by their user agent (what `hotwire_native_app?` reads).
  In a browser, `Mobi` in the user agent means mobile_web, else desktop_web.
  Rough, but enough for this decision.
- The import controllers pass it to `FailedRecipeImport.record`; the digest
  and `/admin/failed_recipe_imports` show it.
- Existing rows stay blank; the logs that could fill them have expired.

This is what decides the web work below: once the device fetch ships,
remaining refusals mostly `desktop_web` means build the extension; mostly
`mobile_web` means the bookmarklet or a nudge into the app.

## Design: the phone fetches, the server reads

When the server's fetch is refused, the app loads the page itself, on the
user's phone, network and real browser engine, and sends the HTML to the
server. The server runs the existing pipeline unchanged:
`RecipeIngest::Page.new(url:, html:)` then `Sources.source_for_url_or_web`.

This is the user viewing the page they asked to save, which is how Paprika
(in-app browser) and Mealie's Mini Mealie extension ("HTML mode") work.

### Flow (Hotwire Native bridge)

1. `UrlImportsController#create` gets a refusal. Today it renders the "blocked"
   referral. In the apps (`hotwire_native_app?`) it renders a "Trying on your
   phone" state instead, carrying a bridge component `page-fetch` with the url.
2. Native `PageFetchComponent` (iOS and Android) loads the url in an offscreen
   web view, waits for load plus a short settle (JS challenges redirect once),
   with a hard timeout (15s).
3. Native runs a small script in the page: clone the document, drop `script`
   (except `application/ld+json`), `style`, `svg`, `iframe`, `noscript`, then
   return `outerHTML`. This keeps the payload to tens or hundreds of KB.
4. Native replies over the bridge with `{html, final_url}` or `{error}`.
5. The Stimulus controller puts the html into a hidden field and submits the
   form (Turbo form submission; Stimulus never fetches) to a new
   `Dashboard::Recipes::DevicePageImportsController#create`.
6. That controller builds a `Page` from the posted html and runs the source
   step only (no fetch). On failure it falls back to the existing referrals.

On the web the flow is unchanged: browsers block cross-site reads, so web users
keep the paste field.

### Server work

- New route `resource :device_page_import, only: [:create]` under
  `dashboard/recipes`, with auth tests (new dashboard routes need them).
- Treat posted html as untrusted input: size cap (1 MB after stripping),
  `final_url` must be http(s) and share the registrable domain of the url the
  user entered (so a page cannot claim to be another site's recipe in the
  cache), and never fetch anything the html points at except the hero image
  through the existing guarded image path.
- `RecipeIngest` grows an entry point that takes a `Page` instead of a url,
  sharing everything after fetch. No second resolution path.
- Rate limit it like url imports (`rails-rate-limiting`).
- Do not write the device-fetched page into `CachedRecipeImport` for other
  users without the same checks a server fetch passes; simplest is to cache it
  exactly like a server fetch once the domain check passes.
- Log `recipe_device_fetch_succeeded` / `_failed` with host, so the step 0
  numbers can be compared after.

### iOS work

- `PageFetchComponent` (BridgeComponent) owning an offscreen `WKWebView`
  with the default (shared) data store, so a site the user is signed into
  works. Keep it out of the view hierarchy, or attach it hidden; some pages
  wait for visibility, so test both.
- Timeout, single in-flight fetch, cancel on disconnect.
- Register the component; tests in `bellyTests/Components`.

Later, optional: the Share Extension can add
`NSExtensionActivationSupportsWebPageWithMaxCount` and a JavaScript
preprocessing file, so a share from Safari carries the page Safari already
loaded. That skips the offscreen load entirely for Safari shares, but not for
shares from other apps, so it is a follow-up, not the core.

### Android work

- Same component with an offscreen `WebView`, `evaluateJavascript`, the same
  script and timeout. Tests in `components/`.

### Web

The web app cannot do the device fetch itself. A page on our origin cannot
read another site's response unless that site opts in with
`Access-Control-Allow-Origin`, which recipe sites do not; a cross-origin
iframe is unreadable too, and many sites refuse framing. Our server cannot
borrow the visitor's address either. The apps escape this because they own
their web view.

What does work, in order of cost:

1. Bookmarklet ("Save to belly"). It runs inside the recipe page, so it can
   read it. It opens belly in a new window and hands the html over with
   `postMessage`; our page checks the message origin and submits a same-origin
   form to the same device page import endpoint. A direct cross-site form POST
   would not work: SameSite=Lax keeps our session cookie off it. About a day of
   work on top of the endpoint. Clunky on phones (iOS Safari bookmarklets), so
   link it from the "blocked" referral on desktop only.
2. Browser extension (the Mini Mealie model). One click, can read any page the
   user opens. Separate build plus Chrome and Firefox store reviews; a Safari
   extension ships inside the iOS/Mac app. Only when step 0b shows desktop
   refusals are a real share.

Android's browser "share to belly" only passes the link, not the page, so it
does not help here.

### Release

Needs a new build for both apps. The server change can ship first: without the
native component registered, the bridge component never connects and the page
shows the existing "blocked" referral, so old builds keep today's behaviour.

## Stopgap: a home proxy over Tailscale

If step 0 shows address blocks piling up before the device fetch ships, one
always-on machine on a home or studio connection can be a third fetch attempt.
The studio Mac mini is already always on and on the tailnet; if it sits on a
business line, the ISP terms concern below mostly goes away.

- A SOCKS5 proxy (`microsocks` or `dante`) bound to the machine's tailnet
  address only. Production joins the tailnet (userspace Tailscale in the Render
  container); a tailnet ACL lets only production reach the proxy port.
- After curl-impersonate is refused, retry once through
  `--proxy socks5://<host>:1080`, behind a setting that turns it off at once.
  Plain `socks5`, not `socks5h`, so production still resolves the host and
  `SsrfGuard` keeps validating the address.

Risks, worst first:

1. Home network exposure. The fetcher takes user-typed urls; any guard bypass
   would reach the router admin page, a NAS, other devices. Put the machine on
   a guest network or VLAN and firewall its egress off private ranges, as a
   second guard behind production's.
2. The household's address takes the reputation hit: captchas or blocks on
   the family's own browsing, abuse complaints to us.
3. Most residential ISP terms forbid servers or commercial traffic.
4. Home power, internet and a changing address: best effort only, never a
   dependency.
5. It deliberately routes around a site's block on cloud traffic. Defensible
   at one page per user request; not if it ever becomes bulk crawling.

Two or three home addresses look like two or three heavy users and can be
blocked in turn, so this does not scale. It buys time; the device fetch is the
answer.

## Rejected: proxy and volunteer node networks

- Paid bandwidth-sharing apps (Honeygain, Pawns.app, PacketStream, EarnApp,
  Repocket, Traffmonetizer, Grass) and SDK networks bundled in free apps
  (Bright Data, Infatica) are the supply behind residential proxies. Consent
  is the problem: Hola VPN's free users were sold through Luminati without
  most understanding it, and several networks have been tied to malware.
- Volunteer projects do not fit: ArchiveTeam Warrior archives sites for the
  Internet Archive; Tor exits are blocked harder than cloud addresses;
  Snowflake helps censored users reach Tor.
- Asking belly users to fetch for other users would put strangers' requests
  behind their home address, and likely breaks App Store guideline 2.4.2
  (no unrelated background processes).

The device fetch is the consented version of the same idea: each phone fetches
only the page its own user asked for.

(Product names from memory, 2026-10-17; verify before citing anywhere public.)

## Out of scope

- Residential proxies and CAPTCHA solvers.
- A server-side headless browser, unless step 0 shows challenges dominate.
- Claiming to be another company's crawler (standing rule).

## Open questions

- Does the offscreen web view pass Cloudflare's managed challenge without
  being on screen? Test against a known challenge site before building the
  rest.
- Copy for the "trying on your phone" state (ui-microcopy).
- Do we show the page to the user when the offscreen fetch hits a human check
  (a captcha), so they can solve it themselves? Probably yes, as a sheet with a
  Done button, which is still the user browsing.

## References

- Mealie: proxy plus FlareSolverr options, and the Mini Mealie HTML mode
  extension: https://github.com/mealie-recipes/mealie/discussions/5315,
  https://addons.mozilla.org/firefox/addon/mini-mealie/
- Byparr / Scrapling / FlareSolverr overview (vendor blog, unverified claims):
  https://godberrystudios.com/posts/byparr-scrapling-flaresolverr-cloudflare-bypass-2026/
- Paprika in-app browser import: https://paprikaapp.com/sites
- iOS share extension page preprocessing:
  https://bipsync.com/blog/three-top-tips-for-building-an-ios-share-extension-for-web-pages/
