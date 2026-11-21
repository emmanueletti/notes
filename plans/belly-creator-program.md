# Belly creator program

Status: direction agreed 2026-10-30, nothing built.

## Why

Belly helps people cook more and feel their best. It started from the old habit of trading recipe cards between friends, but that trade happened after someone paid for the cookbook or magazine. Imports from creator sites cut their ad page views. We don't want to give users what they want at creators' expense. The goal is a fair alternative to ad-heavy recipe sites: users get a clean library, and creators who want to be paid get paid. Musicians moved to merch and direct support after CD sales collapsed. Belly can be the platform that helps food creators do the same.

Rough math: a food blog page view is worth about 2-6 cents in ads, and a saved recipe might replace 3-5 return visits. What one member displaces is small enough to make up directly.

Context: ReciMe published a defence of recipe saving (https://recime.app/help/en/articles/11596213-recipe-saving-on-recime-and-copyright). It rests on four claims: saves are private by default, there's no in-app sharing, there are no bots, and saving is one recipe at a time. Belly has sharing, a shared import cache and a fetcher that impersonates a browser, so ReciMe's defence doesn't cover Belly. People are also vibe-coding aggressive scrapers and open-sourcing them. Extraction is becoming free, so it isn't Belly's edge. Creator consent and a relationship with creators are.

Competitors, researched 2026-10-30 (details and sources in the cofounder doc "What food creators think about recipe apps", https://claude.ai/artifact/TMvmvUz7ckdwptPf4ubowY):

- Spillt (Brooklyn, 2021, no funding listed) is the closest precedent. It's a "Goodreads for recipes" that opens the blog when you tap a saved recipe and syncs reviews back to the creator's site. Bloggers promoted it. Since November 2024, bloggers sell a subscription inside Spillt at their own price; Spillt takes 99¢ per subscriber per month. 200+ blogger plugin installs; no revenue numbers public. It's our phase 4 already built, and it shows creator-first grows slowly. Talk to Ann Baum.
- ReciMe (Melbourne 2021, New York 2024, about $2M raised) went user-first and grew fast: 800,000 users by July 2024 (the "10M+" claim is unconfirmed). They cut everything but the importer, rode TikTok and Instagram recipes, ran their own TikTok accounts, and used a sequenced paywall (7-day trial, then 14 days if you close it), heavy App Store search and paid ads. Social recipes drove the growth and also caused the creator backlash.
- Lesson: user growth comes from ReciMe-style discipline (one core action, paywall sequence, App Store search, short video), which needs no grey-area fetching. The creator program sets Belly apart and protects its reputation, but it isn't a growth engine. Belly's opening is to have both.

Fallback: if this fails, pivot imports to bookmarks only (title, image, link) rather than full imports.

## Principles

- Consent-first saving. Belly doesn't scrape. You save from your browser, creators get credit, and the ones in our program get paid. Every public claim has to be literally true, because creators can check their server logs.
- Prefer what creators publish for machines: schema.org JSON-LD (already read in `RecipeIngest::Sources::Web`). Use the LLM fallback only for pages without it, social posts and cookbook photos.
- Sharing passes a card to a friend, it doesn't republish to the web.
- Creators control how their recipes appear. Belly never charges on a creator's behalf.

## Decisions

- No pooled revenue share. A pro-rata pool sends most of the money to the biggest sites, as Spotify's does to the biggest stars.
- Tips go only to approved creators. Belly never holds money for anyone who hasn't joined, so there are no unclaimed funds.
- No tip-to-share gate (for example, "tip before you can share", or "share with N people per tip"). A required payment is a toll, not a tip. It punishes cooking with friends, lands badly on creators ("I had to pay to send my mom a recipe"), would count as an Apple digital purchase requiring in-app purchase, gets routed around with screenshots, and only works for program creators. Instead, every share is a funnel to the creator. If gating ever happens, the creator sets it (for example, "full method only for supporters").

## Phase 1: hygiene (before any payment story)

Sharing, as of 2026-10-30: `/r/:short_id` shows the full recipe to anyone, with no login and no expiry. No `noindex` exists anywhere and `public/robots.txt` is empty. Shares double as a sign-up funnel (`signup_source`). Copies keep the source credit (`RecipeCopier`). Playlist shares already expire and have claims.

- Add `noindex` to share pages and disallow `/r/` in `robots.txt`. Check party and playlist share pages too.
- Split shares by `user_created`. Own and family recipes share freely. Imported recipes show the creator up top, ingredients, and "Full method at <creator>", or the full recipe only once the recipient signs in.
- Share pages for imported recipes say "<sharer> shared this from <creator>". Once the creator joins the program, show their tip, cookbook and merch buttons.
- Device-side fetch (~/notes/plans/belly-device-page-fetch.md): the user's browser loads the page, not a Belly server. Then retire `CurlImpersonateClient`, the hardest piece to defend publicly. Moved up the priority list for that reason.
- Confirm the fetcher can't get past paywalls in the meantime.
- Add a creator page on the marketing site with a contact address and an opt-out. Opted-out domains are saved as a bookmark only.
- Marketing rule: never frame Belly as a way to skip ads or blog stories. The pitch is "keep the recipes you love, credited".
- Confirm extraction keeps only ingredients and steps, never headnotes or story text.
- Decide whether `cached_recipe_imports` should be shared across users or kept per user.
- Track "cooked" by source domain, so creators can be shown real numbers.

## Phase 2: outreach (no code)

- Pick 5-10 creators we admire, half small and half mid-size, and contact them by hand. Include social-first creators (TikTok, Instagram): they often have no site or structured data, which is where most of the grey area remains, and they'd gain the most from an embed link in their bio.
- Show them the attribution and ask what would make Belly feel fair. Pitch the save button, tips, merch and stats.
- Go/no-go: if fewer than about a third are interested, rethink before building anything.
- Named contacts: Ann and Maddy Baum (Spillt founders), to compare notes or partner rather than compete; Adam Gallagher (Inspired Taste), a vocal, respectful voice on fair traffic.
- Do this outreach before Tastemaker (January 2027). Arriving with 3-5 creators on board and a working embed demo turns the pitch into "here's what creators who joined said".

Where creators gather (checked 2026-10-30):

- Tastemaker Conference, January 8-9, 2027, San Antonio. About 600 food creators plus brands, so exhibiting or sponsoring is possible. Probably too late to sponsor for 2027; attending is doable. https://tastemakerconference.com/events/tastemaker-conference-2027/
- Tastemaker Collaborative (online community) and the Tastemaker Talk podcast, run by the same organizers. https://tastemaker-conference-collaborative.mn.co/
- Flavor Media Summit, April 20-21, 2027, Nashville. Capped at 50 experienced food bloggers, by application, about $2,600. Good for deep conversations; expect the hardest questions there, since these bloggers live on ad revenue. https://flavormediasummit.net/apply/
- Byte of Texas, Austin, regional. No 2027 date confirmed. https://austinfoodbloggers.org/conference/
- International Food Blogger Conference: the longest-running one, but nothing found after 2022. https://foodbloggerconference.org/about/
- Canada: Food Bloggers of Canada ran national conferences 2013-2017 and looks quiet since (https://www.foodbloggersofcanada.com/about-fbc/). The Canadian West Coast Food Blogger Retreat ran October 15-18, 2026; watch for the next one (https://sabrinacurrie.com/connect-canadian-west-coast-food-blogger-retreat/).
- Not checked yet, from memory: Food Blogger Pro (the Pinch of Yum team's paid community and podcast); the Mediavine and Raptive creator communities (expect them to be sceptical of anything that reduces page views, which makes them a useful place to test the pitch); IACP (cookbook authors and food writers, a fit for the cookbook side).

## Phase 3: creator program, approved creators only

- Approval is manual. The creator proves they own the domain (an email from it, a meta tag or a DNS record). An admin links their domains and social handles to a creator record. No self-serve sign-up until manual approval becomes the bottleneck.
- One embed for creator sites and link-in-bio pages: "Save to Belly" plus support buttons (tip, cookbook, merch). A save that starts on the creator's page carries their consent, credit and stats, and needs no fetching. Pinterest's Save button is the model: creators add it because saves mean distribution.
- Support covers tips plus links out to the creator's cookbook and merch (their shop, or Bookshop.org for books). Belly handles no fulfilment and no inventory.
- Payouts run on Stripe Connect Express, which handles identity checks, bank details and tax forms.
- A recipe whose `source_url` domain belongs to an approved creator shows the support buttons and the creator's name. Other recipes keep the plain credit and link.
- Creators set their share policy for their own recipes.
- Belly's fee: lean 0%. Stripe's ~2.9% + 30¢ eats small tips, so offer fixed amounts with a minimum of about $3.
- Creators get a dashboard with aggregate saves and cooks, never who.
- App stores: run `appstore-review` before anything native. Apple likely wants in-app purchase for creator tips, which would break the 100% story. Start with web-only tipping and link out where the rules allow (the US after the Epic ruling).
- Tax: check GST/QST treatment of pass-through tips with the accountant once.

## Phase 4: creators publish into Belly (later)

Creators sell collections or a subscription inside Belly, and buyers can share cards with a few friends. This rebuilds the cookbook-and-trading model. It's a real two-sided marketplace, so only start once phase 3 has creators on board.

## Open questions

- Should Belly send users to the source the first time they cook an imported recipe, as Spillt does? Creators measure fairness in clicks; users love the clean in-app view.
- Should tipping be web only, or also in the app wherever the stores allow it?
- Do we confirm a 0% Belly fee?
- For imported recipes, should shares show ingredients plus a link, or the full recipe behind sign-in?
- One-hour review with a Canadian IP lawyer on imports, the shared cache and share pages.
