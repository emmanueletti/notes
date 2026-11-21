# Marketing site and SEO: report and action plan

Written 2026-11-21. Status: draft. Repo: `workbench/marketing` (Bridgetown 2, Tailwind 4, Render static site).
Supersedes: `2026-11-21-seo-audit.md` (folded in here). Builds on `2026-11-21-plg-strategy.md` sections 1 and 2, `2026-11-21-brand-positioning.md`, bet 4 in `2026-11-21-90-day-priorities.md` and the redesign foundations in `~/notes/workbench-redesign/foundations.md`.

## Verdict

Google indexes the site, but Workbench isn't on page 1 for any buyer search we tried, so search brings almost nobody (1 Google visitor from 2026-11-10 to 2026-11-21). The site ranks only for its own name because every page points at the homepage, nothing targets a specific search, and we're absent from the directories that fill page 1. The site is about to be rewritten and redesigned, so its bugs become requirements for the new site rather than fixes now. The rewrite should be built around a keyword map: one page per search a jeweller actually types, in English and French, with the new positioning and design. Expect results in 3 to 6 months, so founder-led sales stay the main channel meanwhile.

## Report

### Where we stand

- **Traffic:** about 20 visitors in 11 days (PostHog), 1 from Google. No sign-up has a recorded source yet.
- **Indexing:** about 20 pages indexed, including all 9 comparison pages. Indexing isn't the problem.
- **Search Console:** verified 2026-11-21 for the `useworkbench.co` domain. Data from about 2026-11-25.
- **Pages:** homepage, features, pricing, 9 comparison pages, 5 help articles, 4 blog posts, changelog, about, security, legal pages, `/ai-info`, `llms.txt`.

### Rankings, 2026-11-21

Google from Canada, personalisation off. The US results still need their own baseline (1.6).

| Search | Workbench | Page 1 instead |
|---|---|---|
| jewelry repair software | Not on page 1 | RepairDesk, PrismaNote, Gem Logic, Luxare, Reshyne, RepairTrax, Capterra |
| jewelry repair tracking software | Not on page 1 | RepairDesk, Gem Logic, Reddit r/jewellerymaking, Luxare, PrismaNote, wJewel videos, Repair Pilot |
| jewellery repair software canada | Not on page 1 | QuantumRepair (Montreal, C$129/mo), RepairDesk, Capterra, JewelSteps, Gem Logic |
| watch repair software | Not on page 1 | RepairDesk, WatchSheet, Watchmaker App videos, OpenRMA |
| logiciel réparation bijouterie | Not on page 1 | GetApp, Capterra, Gem Logic's French pages, RepairDesk |
| the edge jewelry software alternative | Not on page 1 | Capterra, G2, Software Advice, small competitors' blog posts |
| workbench jewelry software | 1st | BenchWorks, a "Workbench Ring Builder" news story, Ruby Kinglet |

AI Overviews top most of these and name PrismaNote, Gem Logic, Luxare and RepairDesk, never Workbench (same as the AEO audit in `aeo-action-plan.md`).

### What the winners do

- **A page per search.** `prismanote.com/jewellery-repair-software`, `gem-logic.com/repair-management`, `repairdesk.co/jewelry-repair-shop-software`, `repairdesk.co/watch-repair-shop-software`, `luxare.com/jewelry-repair`. Title, H1 and URL all carry the search term.
- **Directory listings.** Capterra, GetApp, G2 and Software Advice appear on most results pages, and "alternatives to The Edge" is almost all directories.
- **Both spellings.** PrismaNote targets "jewellery", RepairDesk "jewelry".
- **French pages.** Gem Logic has French repair pages and owns the French results almost alone.
- **Video.** wJewel and Watchmaker App rank with short YouTube demos.
- **Reddit.** A thread asking what software jewellers use for custom work (r/jewellerymaking, March 2026) ranks on page 1.

### Broken today

1. **Every help link is a 404.** Pages link to `/help/getting-started/...`, but articles build at `/help/category_slug/...` because Bridgetown doesn't fill the `:category_slug` placeholder in `bridgetown.config.yml`. Seven distinct links break, which probably explains much of the 172 crawler 404s.
2. **Hidden help articles are live.** Articles with `publish: false` are still built, indexed and in the sitemap, although `plugins/site_builder.rb` rejects them in `post_read`.
3. **useworkbench.ca serves the full site with a 200** instead of a 301 to .co. Canonicals point at .co, which limits the damage, but a redirect consolidates links and removes the duplicate.
4. **The sitemap lists `/404`, `/500`, `/bridgetown_quick_search/index.json` and `/llms.txt`.** The error pages have a canonical and no `noindex`.
5. **Three pages are titled "Blog | Workbench"** (`/blog/`, `/blog/business/`, `/blog/product/`), and Google indexed a category page as a near copy of a post.

### Weak today

- **Homepage H1** is the eyebrow "For modern watch and jewelry brands", not the product or the search term.
- **No structured data** on any page.
- **Social tags:** `og:type` is `article` on the homepage, `og:locale` is `en_US`, `twitter:card` is `summary`, and `og-image.png` weighs 1 MB.
- **Blog titles** run 61 to 89 characters in Title Case, so Google cuts them off.
- **Internal links** drop the trailing slash (`/pricing`), so they don't match the canonical (`/pricing/`).
- **Stale copy:** the pricing description and `ai_info.yml` still say $40 CAD, the tagline predates the new positioning, and `last_updated` reads "2025".
- **No French pages**, although the app ships in French and Quebec is the next market.
- **Brand clash:** "workbench" alone means the physical bench, and a ring builder called Workbench got trade press in August 2026.

### Not checked

- Page speed and Core Web Vitals. The homepage loads 2 Wistia scripts.
- Backlinks. Needs a paid tool, or Search Console's Links report once data arrives.
- Real search terms. Search Console, from about 2026-11-25.

## What the new site has to do

1. **Rank** for the searches on the keyword map, in English and French.
2. **Win both markets:** the US is the bigger market and Canada is home. One English site in US spelling serves both, because Canadian brands such as SarahBijoux write "jewelry" too and in our searches Google matched both spellings anyway. Canada gets its own page and the French site on top.
3. **Say the new position:** "the back office for independent jewellers that runs itself". Lead with speed, taste and the Shopify fit until photo intake is proven at Jewellery Clinic Wholesale, then switch the headline to "never type" (per `2026-11-21-brand-positioning.md`).
4. **Convert** to a self-serve sign-up or a booked demo.
5. **Feed AI answers:** clear facts, structured data, pages assistants can cite.

## Site map

URLs we keep stay exactly as they are, because changing them loses what little ranking we have. Every moved URL gets a 301.

| URL | Search it targets | Change |
|---|---|---|
| `/` | workbench for jewellers, jewelry business software | Rewrite: new message, H1 names the product |
| `/jewelry-repair-software/` | jewelry repair software | New |
| `/jewelry-repair-tracking/` | jewelry repair tracking software | New, or merged with the page above if the keyword map says they're one search |
| `/custom-jewelry-orders/` | custom jewelry order software, commission tracking | New. Our strongest feature, with almost no competition |
| `/watch-repair-software/` | watch repair software | New |
| `/canada/` | jewelry repair software Canada | New: CAD pricing, bilingual app and notifications, Canadian data and support, PIPEDA and CASL. Links to `/fr/` |
| `/for/wholesale-trade-shops/`, `/for/studios/`, `/for/engagement-rings/` | pages by kind of customer (plg section 2.3) | New, after the keyword pages |
| `/shopify/` | jewelry repair app for Shopify | New once the Shopify integration ships |
| `/features/`, `/pricing/` | brand and bottom of funnel | Rewrite copy, keep URLs |
| `/compare/*` | "X alternative" | Keep, refresh copy and prices, add "best jewelry repair software" |
| `/help/<category>/<article>/` | how-to questions | Fix the URLs, grow to full coverage |
| `/tools/*` | templates and calculators (plg section 2.2) | New, the 3 the keyword map picks |
| `/blog/*` | only searches on the keyword map | Keep the 4 posts, `noindex` category pages until they hold 5 posts |
| `/fr/...` | French versions of the above | New |

## Rules for every page

- One search per page, from the keyword map.
- Title under 60 characters, sentence case, search term first ("Jewelry repair software for independent shops | Workbench").
- One H1 with the search term, and a first paragraph that answers the search directly.
- Real screenshots or a short video, never stock images.
- An FAQ from real questions ("People also ask", Reddit, shop calls), marked up as `FAQPage`.
- JSON-LD: `Organization` and `SoftwareApplication` site-wide, `BreadcrumbList`, `FAQPage` where there's an FAQ (A5 in `aeo-action-plan.md`).
- 3 or more internal links to related pages, with trailing slashes.
- One call to action: start free or book a demo.
- US spelling everywhere (jewelry, jeweler), per `marketing/CLAUDE.md`. "Jewellery" appears only in names, such as Jewellery Clinic Wholesale.
- Prices shown in the visitor's currency once that's decided (see Decisions needed).
- No thin pages written only to rank, and no mass-generated city pages. Google penalises them.

## Design

The rebuild uses the studio foundations in `~/notes/workbench-redesign/foundations.md` and Uniform on Tailwind 4, which the marketing site already runs. Every SEO rule above holds inside the new design: real text instead of text in images, fast pages, and one H1 per page. Check page speed with Lighthouse before launch and keep the homepage's largest image and video loading lazily.

## Off-site

Already planned in `aeo-action-plan.md`, and it does double duty for SEO:

- A11 to A13: Capterra, GetApp, Software Advice and G2 listings, with 5 to 10 reviews in 60 days.
- A20: trade press and associations, which are the best backlinks available to us.
- Reddit: honest answers in threads that already rank, saying who you are.
- YouTube: a 3-minute demo per keyword page. Competitors rank with exactly this.

## Success metric

Clicks from non-branded searches in Search Console, which excludes any search containing "workbench".

- Baseline: the first 4 weeks of Search Console data, December 2026.
- Target: on page 1 for 3 of the 7 searches in the rankings table, and 100 non-branded clicks a month, by 2027-05-01.
- Stop: if by 2027-05-01 no keyword page reaches page 1 in either language, stop writing new pages and put the time into directories, reviews and sales.

## Action plan

Effort assumes one founder working with agents.

### Phase 0: outside the site, this week

The marketing site is about to be rewritten and redesigned, so nothing is fixed in the current code. Its bugs become requirements for the new site (next section). Only work that lives outside the site happens now.

| # | Action | Effort | Owner |
|---|---|---|---|
| 0.1 | 301 useworkbench.ca to .co, path for path, on the apex and `www` only. Keep `iris.useworkbench.ca` (the PostHog proxy) and the .ca email addresses (`hello@`, `support@`) working until they move to .co | 30 min | Founder |
| 0.2 | Find the crawler 404 paths in Cloudflare AI Crawl Control and list them, so the new site redirects each | 1 h | Founder |
| 0.3 | With the app's move to app.useworkbench.co (Cloudflare now lets AI crawlers in on the whole .co zone): keep the app's `robots.txt` open, because a `Disallow` hides noindex tags from crawlers. Keep `/login` indexable with the title "Sign in to Workbench", so "Workbench login" searches and AI assistants find it. `noindex` everything else the app and portal serve without sign-in (`/find-your-shop`, sign-up steps, error pages). The portal and print layouts already have it. Point the marketing site's sign-in link at app.useworkbench.co/login. Checked 2026-11-21: pages behind sign-in redirect crawlers to /login, `/login` and `/find-your-shop` have no robots meta | 1 h | Build agent |

### Requirements for the rewritten site

Found in the 2026-11-21 audit. Each is a bug in the current site that the rewrite must not carry over. Check every item before launch.

1. **Help URLs resolve.** Bridgetown doesn't fill a front matter placeholder such as `:category_slug` in a collection permalink unless it's registered with `Bridgetown::Resource::PermalinkProcessor.register_placeholder`. Today every article builds at `/help/category_slug/<slug>/`, and every help link 404s.
2. **Hidden content isn't built.** `plugins/site_builder.rb` filters `publish: false` inside a `:site, :post_read` hook registered from `build`, which runs after the read has finished, so the filter never runs. All 5 help articles are marked hidden yet are live, indexed and in the sitemap, and the help index lists none of them. Decide which articles are real, publish those, and make sure hidden ones never reach `output/`.
3. **Sitemap holds only real pages.** Today it lists `/404`, `/500`, `/bridgetown_quick_search/index.json` and `/llms.txt`. Use `sitemap: false` on those.
4. **Error pages and thin pages carry `noindex`.** The 404 and 500 pages today, and the blog category pages until they hold 5 posts.
5. **Unique title and description on every page.** Today `/blog/`, `/blog/business/` and `/blog/product/` share "Blog | Workbench".
6. **No broken links.** Today `/contact` (security page) and the footer's help link 404. Run a link check on the build before launch.
7. **Internal links match canonicals,** trailing slash included.
8. **Correct social tags.** bridgetown-seo-tag writes `og:type` `article` whenever a page has a date, and today the homepage does. Use `summary_large_image` for Twitter. Keep `og:locale` `en_US`.
9. **A new OG image** under 200 KB. Today's is 1 MB and shows "useworkbench.ca" and "jewellery", both now outdated.
10. **No .ca anywhere:** not in copy, the OG image, email addresses or the PostHog proxy host, once those move.
11. **JSON-LD** per the page rules above.
12. **Every URL that exists today either survives or 301s,** including the old `/help/category_slug/...` paths that Google has indexed.

### Phase 1: research and foundations, weeks 1 to 2

| # | Action | Effort | Owner |
|---|---|---|---|
| 1.1 | Keyword map (plg section 1): Keyword Planner, autocomplete, "People also ask", Reddit and Ganoksin wording, the customer who found us on Google. Output: query, intent, page | 1 day | Founder with an agent |
| 1.2 | JSON-LD in `_head.erb`: `Organization`, `SoftwareApplication`, `BreadcrumbList`, `FAQPage` (A5) | 3 to 4 h | Build agent |
| 1.3 | Refresh facts: pricing, tagline and `last_updated` in `ai_info.yml`, the pricing page description | 1 h | Founder |
| 1.4 | Gartner listing (Capterra, GetApp, Software Advice) and start the review asks (A11, A12) | 2 to 3 h | Founder |
| 1.5 | Lighthouse on the homepage, pricing and one comparison page, written down as the speed baseline | 1 h | Build agent |
| 1.6 | US baseline: rerun the 7 searches from the US (`gl=us`) and add a US column to the rankings table. Use Keyword Planner's US and Canada volumes for the keyword map | 1 h | Agent |
| 1.7 | US directories and associations: Jewelers of America, MJSA, JCK, the Polygon network, alongside A20's Canadian list | 2 h, then ongoing | Founder |

### Phase 2: rewrite and redesign the site, weeks 3 to 6

Built to the requirements above and the rules for every page.

| # | Action | Effort | Owner |
|---|---|---|---|
| 2.1 | New homepage in the new design and message, H1 naming the product | 3 to 4 days | Founder with an agent |
| 2.2 | The 4 keyword pages (repair software, repair tracking, custom orders, watch repair), each with screenshots, FAQ and a short video | A page a day | Founder with an agent |
| 2.3 | Rewrite features and pricing in the new design, URLs unchanged | 2 days | Founder with an agent |
| 2.4 | Refresh the 9 comparison pages and add "best jewelry repair software" | 2 days | Agent drafts, founder checks facts |
| 2.5 | Help centre to full task coverage, one question per article (plg section 2.1) | Ongoing, 2 a week | Agent drafts, founder checks |
| 2.6 | "Book a demo" on every page (bet 4) | 2 h | Build agent |

### Phase 3: Canada, French and tools, weeks 6 to 10

| # | Action | Effort | Owner |
|---|---|---|---|
| 3.0 | The `/canada/` page | 1 day | Founder with an agent |
| 3.1 | French homepage and the 4 keyword pages under `/fr/`, with `hreflang` both ways and in the sitemap | 1 week | Agent translates, friend audits |
| 3.2 | The 3 free tools the keyword map picks (plg section 2.2), in both languages | 1 to 2 days each | Build agent |
| 3.3 | Pages by kind of customer, starting with wholesale trade shops (Jewellery Clinic Wholesale's numbers, with consent) | 1 day each | Founder |

### Phase 4: keep it going, from week 10

- Weekly: read Search Console, note new searches, fix coverage errors.
- Monthly: rerun the 7 searches above, add the results to this note, and add any search we're close on (positions 11 to 20) to the next page to improve.
- Quarterly: redo the keyword map (plg section 1).
- Blog: only posts that answer a query on the map. Cut `marketing/todo.md` down to those.

## Risks

- **The redesign drops rankings.** Keep every URL that exists, 301 anything that moves, and compare Search Console the week after launch.
- **Founder time.** Phase 2 is the bulk of it. If time runs short, launch the keyword pages before the remaining pages and design polish, because they're what ranks.
- **Copy drifts from the product.** `marketing/CLAUDE.md` says to check the app before any feature claim. Keep that rule for agents drafting pages.
- **US texting.** US shops need A2P 10DLC registration before Workbench can text their customers. Finish it before the site promises texts to US shops, or say plainly that US texting is coming.
- **"Built in Canada, priced in CAD" puts off US buyers.** It's a strength in Canada and a question mark in the US ("what's that in dollars?"). Keep it on `/canada/` and decide the currency before the new pricing page ships.
- **Slow payoff.** SEO compounds over 6 to 12 months. Directories and reviews (1.4) pay back sooner and help both Google and AI answers.

## Decisions needed

1. **Help URLs:** keep the category in the URL (`/help/getting-started/...`) as the links expect, or flatten to `/help/<article>/`? Either works, but decide before the help centre grows. Owner: founder.
2. **Keyword pages before or with the redesign?** Recommendation: ship them before if the redesign isn't ready by week 4. Owner: founder.
3. **Currency for US visitors:** show USD prices to US visitors (Stripe supports a price per currency), or CAD for everyone with a USD estimate. Recommendation: real USD prices, because a US buyer comparing RepairDesk at US$99 needs a number in their own money. Ties to decision 6 in `2026-11-21-pricing-strategy.md`. Owner: founder.

## Decided

- 2026-11-21: target the US and Canada with one English site in US spelling (jewelry, jeweler). Canadian brands such as SarahBijoux use US spelling too. Canada gets `/canada/` and the French site.
- 2026-11-21: useworkbench.ca is deprecated. It stays registered only as a permanent (301) redirect to useworkbench.co, path for path (0.1).
