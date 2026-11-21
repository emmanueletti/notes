# AI recommendation action plan, 2026-11-21

Every action for getting Workbench recommended by AI assistants and search, from the workbench-4a audit (hand-run through Google AI Mode, Perplexity and ChatGPT on 2026-11-21) plus the Cloudflare finding. Strategy and reasoning: section 3 of `2026-11-21-plg-strategy.md`.

Owner: FOUNDER (writing or ops), CODE (change in `marketing/` or `server/`), OUT (outside listing or outreach). One founder does all three.

## Evidence

- Google AI Mode: Workbench in 0 of 4 buyer prompts. Branded prompts work only with useworkbench.co in the query.
- Perplexity (signed in, Montréal): 2 of 4. Every mention cited useworkbench.co only, no third-party source. It cited us despite PerplexityBot getting 403s, so it used an index or cache.
- ChatGPT: not testable from the founder's account (it knows Workbench is ours).
- Google's sources: Capterra Canada, GetApp Canada, r/jewellerymaking, Shopify App Store, YouTube, SourceForge, competitors' repair pages updated in November 2026.
- Competitors named most: PrismaNote (nearly every answer; closest to us), Gem Logic, Jewel360, wJewel. Also Flawless POS, Luxare, Jewelia, PIRO Retail, Noble (Shopify app), RepairDesk for Shopify (US$19/mo), Hubtiger, Repair Pilot, Datopia Flow, JewelryStudioManager, Lightspeed, RepairShopr, Jobber.
- Facts engines state: signed terms and tone are verified in the app (`CustomerTermsSignatureEvent`, `notification_templates.tone`). The 30-day trial isn't verified in code: check it. No false claims found; the problem is stale positioning.

## Next 30 days (to 2026-12-21)

| # | Action | Impact | Effort | Owner |
| --- | --- | --- | --- | --- |
| A1 | DONE 2026-11-21 (Security, Settings, AI Crawler and Agent access policies: Training and Agents set to Allow; every crawler now gets 200, robots.txt has only the sitemap line). Was: unblock AI crawlers in Cloudflare: allow OAI-SearchBot, ChatGPT-User, PerplexityBot, Perplexity-User, ClaudeBot, Claude-SearchBot, Claude-User, Googlebot, Bingbot (Copilot uses Bing), and the training bots (GPTBot, Google-Extended) too. Add explicit Allow lines to `robots.txt`. Verify: `curl -A "PerplexityBot" https://useworkbench.co/` returns 200. | H | 30 min | FOUNDER, CODE |
| A11 | One Gartner Digital Markets listing (feeds Capterra, GetApp, Software Advice, Canada and US) in "Jewelry Store Management", and "Repair Shop" if allowed. Screenshots, CAD pricing, the descriptor. | H | 2 to 3 h | OUT |
| A12 | 5 to 10 reviews on Capterra and G2 within 60 days. Ask personally, right after a win, with the direct link; start with Jewellery Clinic Wholesale. Use Gartner's own review campaigns, not our incentives. | H | 1 to 2 h a week | FOUNDER |
| A2 | Rewrite `marketing/src/_data/ai_info.yml`: line 3 `last_updated` "2025" to a real date; line 7 tagline to "The back office for independent jewellers that runs itself"; line 8 category to back office software for independent jewellery brands; `target_customer.primary` to independent jewellery brands including makers selling direct; add shipped features (customer self-check-in page, split Jobs list, live updates, assignees); add PrismaNote, Gem Logic, Jewel360, wJewel to comparisons; add a disambiguation field ("not The Workbench London ring-carving kits, not a physical jeweller's bench"). Perplexity quotes this file almost word for word ("repair-led", "less of a complete jewellery ERP"). | H | 2 to 3 h | FOUNDER, CODE |
| A3 | `src/llms.txt.erb` and `/ai-info`: first line "Workbench for jewellers: back office software for independent jewellery brands", a disambiguation line, links to every comparison page and the help centre. | M | 1 h | CODE |
| A4 | Titles and meta: `src/index.md:3` "Jewelry & Watch Repair Shop Software" and comparison titles "for Jewelry & Watch Shops" to the new position, always with "Workbench for jewellers" or "jewellery". Settle "jewelry" vs "jewellery": one in the title, the other in body or meta. | M | 1 to 2 h | FOUNDER, CODE |
| A22 | Use the descriptor everywhere: "Workbench for jewellers" (or "Workbench by ITS US STUDIO") in titles, structured data `alternateName`, `llms.txt`, listings, App Store, social bios, YouTube. | H | in A2 to A5, A11 | all |
| A23 | Trademark check: CIPO, USPTO and UKIPO for "Workbench" in classes 9 and 42, and The Workbench London's marks in class 14. Keep the name with the descriptor unless a software-class conflict turns up; decide before the redesign ships. | H if conflict | 1 to 2 h | FOUNDER |
| A8a | Comparison pages vs PrismaNote and vs Gem Logic (`src/compare/`, partial `_compare_page.erb`). Honest about where they're stronger (point of sale, inventory) and who should pick which. Add to `ai_info.yml`. | H | 3 to 4 h each | FOUNDER, CODE |
| M4 | "How did you hear about us?" at sign-up, with "If you asked ChatGPT or Google, what did you ask?" (also in setup step 3). | H | 2 to 3 h | CODE |
| M5 | PostHog tile for AI referrers: chatgpt.com, perplexity.ai, gemini.google.com, copilot.microsoft.com, claude.ai. | M | 1 h | CODE |
| G1 | Shop interviews on getting customers (section 4 of `customer-interview-script.md`). Start with the owner who said they want more customers. Jewellery Clinic Wholesale's customers are stores. | | 3 to 5 calls | FOUNDER |
| G2 | Run 20 local prompts by hand for 2 shops ("custom jeweller in <city>", "ring resizing near <neighbourhood>", "who repairs gold chains in <city>") and show them the result. Their reaction decides whether "Get found" is worth building. | | 2 h | FOUNDER |
| M3 | First monthly rerun around 2026-12-01: prompts P1 to P12, plus the untested engines. | | 1 h | FOUNDER or agent |

## Days 31 to 90 (to 2027-02-19)

| # | Action | Impact | Effort | Owner |
| --- | --- | --- | --- | --- |
| A5 | JSON-LD: `Organization` (ITS US STUDIO, `sameAs` social, Capterra, App Store) and `SoftwareApplication` (BusinessApplication, Web, offers in CAD, `aggregateRating` once reviews exist), `alternateName` "Workbench for jewellers"; `FAQPage` on comparison and pricing pages from `src/_partials/_faqs.erb` data. Today `_head.erb` only emits meta tags via `seo`. | M | 3 to 4 h | CODE |
| A6 | Answer page "jewellery repair tracking software": what it does (intake photos, tickets, statuses, texts and emails, signed terms, self-check page), price in CAD and USD, who it's for and not, Canada and bilingual up front, FAQ. PrismaNote and Flawless rank with this kind of page. | H | 1 day | FOUNDER, CODE |
| A7 | Answer page "custom jewellery order and commission tracking" (deposits, design rounds, stages). Jewelia, PrismaNote, Jewel360 and wJewel outrank us on custom work. | M | 1 day | FOUNDER, CODE |
| A8b | Comparison pages vs Jewel360 and vs wJewel; later Flawless POS, Jewelia, RepairDesk for Shopify (or update the RepairDesk page). | M | 3 to 4 h each | FOUNDER, CODE |
| A9 | Retire or merge weak comparison pages (Asana, Trello, kanban) unless PostHog shows search traffic. Engines never return generic tools for jewellery prompts. | L | 1 h | FOUNDER |
| A10 | French versions of home, pricing, A6 and top comparison pages; none exist today. Use `add-app-language`, `create-i18n-translation` and a translation-judge pass. | M (H for Quebec) | 2 to 3 days | FOUNDER, CODE |
| A13 | G2 listing, same review push. | M | 1 to 2 h | OUT |
| A14 | SourceForge (cited for "The Edge alternatives"), Crozdesk, Software Suggest, SaaSworthy. | L to M | 2 h total | OUT |
| A16 | Google Business Profile for ITS US STUDIO / Workbench, if not done. | L | 30 min | OUT |
| A17 | Reddit (r/jewellerymaking, r/jewelry, r/Goldsmith, r/smallbusiness): answer threads about repair tracking, job envelopes and custom orders, disclosed as the founder. Google cited an r/jewellerymaking thread (2026-03-14) where a Jewel360 rep answered. | H | 1 h a week | FOUNDER |
| A18 | Ganoksin forum: helpful answer in its "Repair tracking software" thread. | M | 1 h | FOUNDER |
| A19 | 2 to 4 short YouTube demos ("Taking in a ring repair with photos in 60 seconds", "How customers check their own repair status", "Custom order from deposit to pickup"), "Workbench for jewellers" in titles; embed on A6 and A7. | M | 1 day | FOUNDER |
| A20 | Trade press and associations: JCK, National Jeweler, Canadian Jeweller Magazine, Jewellers Vigilance Canada, CJA supplier directory, Bench Jeweler / MJSA. Pitch: Canadian, bootstrapped, bilingual, the self-check page. | M, slow | 1 day | FOUNDER |
| A21 | Ask authors of cited "best jewelry repair software" lists (Zipdo, Gitnux, WifiTalents, Guideflow, FitSmallBusiness) to include us with accurate facts. | M | 2 to 3 h | OUT |
| A15 | Shopify App Store app. Google recommended Noble and RepairDesk for Shopify because they're Shopify apps. See `shopify-integration.md`. | M to H | weeks | CODE |
| A25 | Markdown copies of every page for AI agents: a small Bridgetown build plugin writing `/page.md` next to each page plus `llms-full.txt`, from the pages' own Markdown and YAML sources (or `reverse_markdown`), linked with `<link rel="alternate" type="text/markdown">`. Cloudflare's Markdown for Agents does this at the edge but needs a paid plan. Helps agents doing tasks; little evidence it improves recommendations. | L | half a day | CODE |
| A24 | Rerun the branded test 2 to 4 weeks after A1 to A5 are live. If Google still returns benches, revisit the name. | | 30 min | FOUNDER |
| Sauron | Studio AI visibility tracker V1 (below), after an API cost and fidelity test. | | | CODE |
| G3 | Review ask at pickup, if G1 confirms (below). | H | 2 to 3 days | CODE |
| | Decide on the Shopify app (A15) and "Get found" (G7) from the data. | | | FOUNDER |

## Measurement

Prompts used 2026-11-21, with results:

| # | Prompt | Google AI Mode | Perplexity |
| --- | --- | --- | --- |
| P1 | What is the best software for a small independent jewellery shop to track repair jobs? | No (PrismaNote, Flawless POS, Gem Logic, RepairDesk for Shopify, Jewel360) | No (RepairDesk, Hubtiger, PrismaNote, Gem Logic, RepairShopr) |
| P2 | jewellery repair tracking software for shops in Canada | No (PrismaNote, Gem Logic, Jewel360, Lightspeed, wJewel, RepairDesk) | Yes, #3 (Gem Logic, Luxare, Workbench, wJewel, RepairDesk) |
| P3 | What are good alternatives to The Edge or RepairDesk for a small jeweller who does repairs and custom work? | No (Jewel360, Gem Logic, PIRO, wJewel, PrismaNote) | No (Jewel360, Repair Pilot, RepairShopr, Gem Logic, JewelryStudioManager, Jobber) |
| P4 | Back office software for an independent jewellery brand to manage repairs, custom orders and customer updates | No (Gem Logic, wJewel, Jewel360, Noble, PIRO) | Yes, #5 of 5 (Jewelia, PrismaNote, Jewel360, wJewel, Workbench) |
| P5 | What is Workbench for jewellers? | The physical bench; one line on "a niche software tool" | The software, first |
| P6 | Workbench jewellery software useworkbench.co review | Yes, accurate (Google only) | |

Add from the next run:

- P7 logiciel de suivi des réparations pour bijouterie
- P8 best software for custom jewellery commissions and deposits
- P9 PrismaNote alternatives
- P10 Gem Logic vs Jewel360 vs Workbench
- P11 how do jewellers track repairs digitally
- P12 jewelry repair software that sends text updates to customers

Untested: ChatGPT signed out (private window), Microsoft Copilot, Claude.ai, Gemini app, French prompts, a US location (VPN), Google's classic AI Overviews, local consumer prompts for shops.

Monthly rerun (1st of the month, about 1 hour, founder or an agent with claude-in-chrome): P1 to P12 on Google AI Mode (`google.com/search?udm=50&q=...`), Perplexity, ChatGPT signed out and Copilot. Log date, engine, prompt, named yes or no, position, competitors, cited domains in `aeo-log.md` in this folder.

Target: Workbench named in at least half of category prompts by 2027-06-01 (`2026-11-21-plg-strategy.md`).

## Sauron: studio AI visibility tracker

Internal name only. Draft spec: `~/notes/plans/studio-sauron.md`. Recommendation from the audit: start as a hosted Rails app, extract a gem later.

- V1: Workbench only, 30 to 50 prompts (category, comparison, branded), weekly.
- Engines through official APIs with web search: Perplexity Sonar, Gemini with Google Search grounding, OpenAI Responses with web search, Claude with web search.
- One Claude structured-output call per answer extracts mentions, position, description and citations.
- One dashboard page per product: mention rate per engine over time, competitor ranking, top cited domains and URLs, a gap list (prompts where a competitor is named and we aren't, with the cited pages), annotations for shipped fixes.
- Out of scope: scraping consumer apps, a content engine, alerts, selling it.
- Cost: API credits aren't covered by consumer subscriptions; rough guess US$30 to 150 a month at 3 runs a week. Measure in week 1.
- Prompt sources: drafted from the site and competitors, the sign-up question (M4), engine fan-out queries, variations of gap prompts.
- Metric: mention rate on category and comparison prompts, 2× baseline by 2027-03-01. Stop if fewer than 3 fixes ship from the gap list by then.

## Getting found, for our shops

Core per the founders. The customer-facing name must not be "Sauron" (the Tolkien estate enforces its trademarks).

| # | Action | Impact | Effort | Owner |
| --- | --- | --- | --- | --- |
| G1 | Validate: 3 to 5 shops. How did your last 10 new customers find you? Has anyone mentioned ChatGPT or Google AI? Where do you lose people (unanswered quotes, one-time customers)? What have you paid for marketing? Would you pay to be found more? | | 3 to 5 calls | FOUNDER |
| G2 | 20 local prompts by hand for 2 shops, shown to them. | | 2 h | FOUNDER or agent |
| G3 | Review ask at pickup: when a job is picked up, prompt staff (or text, if the shop opts in) with a direct Google review link. Local AI answers lean on Google reviews. Opt-in and human. | H | 2 to 3 days | CODE |
| G4 | Care reminders from job history (rhodium replating at 12 to 18 months, prong checks, cleaning, watch batteries, resizing follow-ups), shown to staff as nudges to send personally. | M to H | 3 to 5 days | CODE |
| G5 | Quote follow-up nudges for quotes unanswered after N days. | M | 2 days | CODE |
| G6 | Shop services as structured data: a public shop page or widget with `LocalBusiness` / `JewelryStore` JSON-LD, services and the "check your repair" link. Later, product feeds for AI shopping (ChatGPT, Perplexity), tied to the Shopify vision. | M | 1 week | CODE |
| G7 | "Get found" add-on: weekly local visibility check ("named in 3 of 20 local questions, Competitor X in 9"), each gap paired with a fix Workbench does (G3, G6), plus "How did you find us?" at intake to prove the return. About C$20 to 50 a month. Only after G1, G2 and Sauron V1. | | | CODE |
