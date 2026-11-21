# Sauron: AI visibility tracking for the studio, then for Workbench shops

Written 2026-11-21. Status: draft.
Repos: new `sauron` app, new `studio-sauron` gem in toolshed, later `workbench`.

## Problem

When someone asks ChatGPT, Perplexity or Google AI Mode which software to buy, Workbench rarely comes up, and we only know because we checked by hand once. We have no number for it, no trend and no list of what to fix. Our jewellery shops have the same problem one level down: they want more customers, and more and more of their customers ask an AI where to get a ring resized or a custom piece made.

## Who

- Phase 1: the studio. Workbench first, then Belly, Canvas and Deja Yum.
- Phase 2: Workbench shops, independent jewellery brands, as a paid add-on. This is the ICP, and it fits the vision of Workbench as the Shopify for independent jewellery brands, where we win when our shops make money.

## Evidence

AI audit, 2026-11-21, run by hand on 4 buyer prompts and 2 branded prompts:

- Google AI Mode named Workbench in 0 of 4 buyer prompts. For "What is Workbench for jewellers?" it described the physical bench and listed benches for sale.
- Perplexity (signed in, Montréal) named Workbench in 2 of 4: top 3 for the Canada prompt and 5th of 5 for the back office prompt. It personalises by location, so buyers elsewhere probably see us less.
- ChatGPT couldn't be measured, because even a temporary chat knew Workbench was the user's product.
- PrismaNote, Gem Logic, Jewel360 and wJewel came up in nearly every answer.

From shops:

- One jewellery owner, asked how Workbench could help him most, said he ultimately wants more customers (2026-11-21, paraphrased by the user, owner not named). That is a single source and the most common answer any owner gives, so it shows interest in growth, not demand for AI visibility tools.
- No shop has told us that AI search doesn't recommend them. Phase 2 needs that check before any build.

From the market:

- Gauge (withgauge.com) sells this exact tracker to developer tools companies for $599/mo. Its customers include PostHog, Braintrust and Clerk. The user reports it is a team of 6 from YC and close to $6M ARR, which we haven't verified.
- Gauge's case studies are self-reported. Its core is a loop, and that loop is what we're copying:
  1. Ask the same questions every day.
  2. Show the gaps where a competitor appears and you don't.
  3. Show which pages the AI cited to answer them.
  4. Draft a fix.
  5. Measure again.

## Deliberately out of scope

- Automating the consumer ChatGPT, Perplexity or Google apps. Their terms forbid it, and it would break whenever their pages change. We use the official APIs and spot-check the consumer apps by hand each month.
- A content engine that writes and publishes articles. Phase 1 lists the gaps and a person decides what to write. We add drafting only if the gap list proves useful and writing becomes the bottleneck.
- Agent experience testing, Gauge's second product, which checks whether coding agents can use a developer tool. None of our products are developer tools.
- Selling Sauron as a standalone product to outside companies. Gauge, Profound and Peec already own that market. Sauron is studio tooling and a Workbench feature.
- Using the name Sauron in front of customers. The Tolkien estate enforces its trademarks. Internally it stays Sauron, and the Workbench feature gets its own plain name, such as "Get found".
- Phase 2 build work before the shop interviews in Next steps.

## Approach

Build the tracker loop for one product, Workbench, as small as possible, and use it ourselves for 8 weeks before offering it to shops.

Code lives where it does in the rest of the studio:

- `studio-sauron` gem (toolshed) owns the server logic:
  - engine clients
  - the prompt runner
  - parsing answers into mentions and citations
  - scoring

  Both the Sauron app and Workbench use it, so Phase 2 doesn't mean a rewrite.
- `sauron` app (Rails 8 on Render, the studio stack) is the studio dashboard. It's internal and only for us.
- Workbench later adds its own shop-facing screens on top of the gem, built with Uniform.

How Phase 1 works:

- **Engines:** the official APIs with web search turned on: OpenAI (Responses API, web search tool), Perplexity Sonar, Gemini (Google Search grounding) and Claude (web search tool). These come closest to what people see in the apps.
- **Prompts:**
  - 30 to 50 per product, in three groups: category ("best jewellery repair tracking software"), comparison ("alternatives to The Edge") and branded ("what is Workbench for jewellers").
  - Start from the 6 prompts in the 2026-11-21 audit.
  - Add new prompts as Workbench learns them. For example, add a "How did you hear about us?" question at Workbench sign-up, the same way PostHog collects its prompts.
- **Schedule:** run every prompt on every engine 3 times a week. Answers vary from run to run, so we only trust the trend over several runs.
- **Parsing:** one Claude call per answer, with structured output, returns:
  - every product named, and its position
  - whether our product was named and how it was described
  - every cited URL

  The prompt and model follow `llm-features`, with an eval set of hand-labelled answers.
- **Dashboard** (one page per product):
  - mention rate per engine over time
  - competitors ranked by mention rate
  - most-cited domains and URLs
  - the gap list: prompts where a competitor appears and we don't, with the pages the engine cited

## Flow

Phase 1, studio:

1. In the Sauron app, add a product: name, domain, the descriptor ("Workbench for jewellers") and known competitors.
2. Add prompts, or pick them from the suggested starter set.
3. The recurring job runs the prompts and stores the raw answers, then parses them.
4. Open the product page to see the mention rate, competitors, cited sources and gaps.
5. Pick a gap and fix it outside Sauron: a compare page, a directory listing, a Reddit answer. Note the fix in Sauron as an annotation on the chart.
6. Check the trend after the next few runs.

Absent on purpose: alerts, content drafting, team accounts, billing.

Phase 2, shops (a separate spec after the interviews), sketched to test fit:

1. The shop turns on "Get found" in Workbench.
2. Workbench builds local prompts from the shop's data: city, services, specialties ("ring resizing in Surrey", "custom engagement rings Surrey").
3. Each week the shop sees "You show up in 3 of 20 questions. [Competitor] shows up in 9."
4. Each gap comes with a fix Workbench can mostly do for the shop:
   - ask for a review at pickup
   - publish its services as structured data
   - suggest one page to write
5. At intake, Workbench asks new customers how they found the shop, so the shop can see which customers came from AI.

## Data and model changes

All tables live in the gem with a `sauron_` prefix. Migrations follow `rails-database-migrations`.

- `sauron_subjects`: the product or shop being tracked. Name, domain, descriptor, owner (polymorphic, so Workbench can point it at a shop).
- `sauron_competitors`: subject, name, domain, aliases.
- `sauron_prompts`: subject, text, group (category, comparison, branded), active.
- `sauron_runs`: one per prompt × engine × time. Engine, model, status, cost, raw answer text, raw citations.
- `sauron_mentions`: run, name matched (subject or competitor), position, description excerpt.
- `sauron_citations`: run, URL, domain.
- `sauron_annotations`: subject, date, note ("Capterra listing live").

Jobs:

- a recurring `Sauron::ScheduleRunsJob` in `config/recurring.yml` (per `background-jobs`)
- one `Sauron::RunPromptJob` per run, and one `Sauron::ParseAnswerJob` per answer

Engine calls follow `external-services` and `timeouts`.

## Risks

- **Product:** API answers differ from what people see in the apps, because the apps add personalisation, location and memory. The trend still holds if we measure the same way every time. Spot-check the apps by hand each month and note the differences.
- **Product:** the numbers move too slowly to act on, so nobody opens the dashboard. Check this after 8 weeks against the success metric.
- **Cost:** 4 engines × 50 prompts × 3 runs a week, plus parsing, all with web search on. Measure the real cost per run in week 1 before scheduling anything. If it's too high, cut runs, not engines.
- **Technical:** engine APIs and their search tools change often. Keep each engine client small and behind one interface.
- **Phase 2 trust:** a shop that pays and doesn't move up will feel cheated. Sell it as tracking plus concrete fixes, never as a promised ranking.
- **Phase 2 local data:** local questions depend on Google Business Profile and reviews more than on websites. The fixes there are reviews and profile completeness, which Workbench can only partly influence.

## Rollout

- Phase 1: the Sauron app is internal, behind studio-auth, for studio staff only. No flag needed.
- Phase 2: in Workbench behind the Flipper flag `get_found`. Turn it on for 3 to 5 interviewed shops first. Roll back by turning the flag off. Per `feature-flags`, the flag hides the entry point in views.

## Success metric

Phase 1, studio: Workbench mention rate, meaning the share of category and comparison prompt runs across all 4 engines that name Workbench, averaged over the last 2 weeks.

- Baseline: measured in the first 2 weeks of runs. The hand audit suggests 0% on Google and about 50% on Perplexity for 4 prompts.
- Target: double the baseline by 2027-03-01, from fixes chosen off the gap list.
- Stop: if by 2027-03-01 the gap list hasn't led to at least 3 shipped fixes, the dashboard isn't driving action, so stop building and keep the runs only as a monthly check.

Phase 2 gets its own metric in its own spec.

## Next steps

1. Run the 2026-11-21 prompt set once through each engine API by script, to see whether API answers resemble the apps and what a run costs. Owner: build agent. About half a day.
2. Interview 3 to 5 shops, starting with the owner who asked for more customers. Ask how their last 10 new customers found them, whether any mentioned ChatGPT or Google AI, and whether they'd pay to be found there. Owner: the user.
3. For 2 of those shops, run 20 local prompts by hand and show them the result. Their reaction answers whether Phase 2 is worth building. Owner: the user, with a prompt list from an agent.
4. If step 1 is usable, approve this spec and build Phase 1 with `build-spec`, Workbench only.
5. After 8 weeks of Phase 1 use, write the Phase 2 spec with the interview findings.

## Decisions already made

- Internal name Sauron. Customer-facing name different (see out of scope).
- Studio first, Workbench shops second. We learn the loop on our own product before charging shops for it.
- Official APIs, not automation of the consumer apps.
- A gem for logic and a thin app for the dashboard, matching how the studio splits gems and apps.
- Growth tools for shops are in scope for Workbench (the user's Shopify vision, 2026-11-21).

## Open questions

- Which engines matter most to jewellery customers? Google AI Mode probably leads, but its API equivalent (Gemini with grounding) may not match it. Owner: build agent, from next step 1.
- Should the Sauron app live on its own or inside hq tooling? Owner: the user.
- Phase 2 price: a paid add-on at roughly $20 to $50/mo, or included in a higher plan? Owner: the user, after the interviews.
- Should the "How did you find us?" question at Workbench sign-up ship now, separately? It's cheap and feeds Phase 1 prompts either way. Owner: the user.
