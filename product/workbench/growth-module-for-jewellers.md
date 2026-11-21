# Growth module for jewellers

Written 2026-11-21. Idea stage, not decided.

Workbench could add a growth module that tells each shop how often Google and AI assistants recommend it, does most of the work to improve that, and proves the result in new customers and job revenue. "Get found" is the working name. It runs on Sauron, the studio's internal AI visibility tracker (spec: `~/notes/plans/studio-sauron.md`), which we use on Workbench itself first.

## Why

- A jewellery owner, asked how Workbench could help most, said they ultimately want more customers (2026-11-21, relayed by the founders). That's one source and the answer most owners give, so it shows interest in growth, not demand for this module.
- It moves Workbench from "saves you time" to "brings you customers". That's an easier sale and harder to cancel. It also fits the long-term vision of the Shopify for independent jewellery brands: Workbench wins when its shops make money.
- No shop has told us AI search doesn't recommend them yet. Validate before building (see Next steps).

## What we learned from Gauge

Gauge (withgauge.com) sells AI visibility tracking to developer tools companies such as PostHog, Braintrust and Clerk, at US$599 a month. The founders report it as a team of 6 from YC near US$6M ARR, which we haven't verified. Its case studies are written by Gauge and self-reported.

How it works:

- It asks about 600 buyer questions every day across ChatGPT, Google AI Mode and Copilot, and records whether the brand is named, where, how it's described and which pages are cited.
- It shows the gaps: questions where a competitor is named and the brand isn't, with the pages the engine cited.
- Its content engine drafts an article for each gap, then it reruns the questions to see whether anything moved.

Why customers pay:

- It turns an invisible worry into a number a marketer can report upward.
- The gap list tells them exactly what to do next.
- The team works closely with customers and ships what they ask for.
- Its customers are developer tools companies, where AI search is the main channel and marketing budgets are big.

What carries over to us:

- The loop: ask the same questions on a schedule, show the gaps, fix them, measure again.

What doesn't carry over:

- Gauge's customers have growth teams that do the work. Our shops don't, so the value has to be in fixes Workbench does for them.

How it handles selling to competitors (our reasoning; Gauge doesn't address it publicly):

- The answers it measures are public, and each customer sees only its own questions.
- SEO tools such as Ahrefs and Semrush have sold to direct competitors for 20 years.
- The target keeps moving, but that doesn't make it meaningless:
  - AI answers name several options, so more than one brand can win a question.
  - The fixes (reviews, listings, good pages) build up and are hard to copy.
  - Most customers never act on the report.
  - Once everyone measures, standing still means falling behind.

## SEO tracking compared with AEO tracking

Both check the same searches regularly and watch what changes. The difference is that Google shares real data about your own site for free, while AI engines share nothing, so AEO has to sample answers.

Classic SEO tracking has five parts:

1. **Rank tracking:** a tool searches Google daily for chosen keywords and records your position. This is the direct cousin of AEO.
2. **Google Search Console:** free, Google's own data. It gives impressions, clicks and average position for the real searches that showed your site, including ones you never thought to track.
3. **Traffic analytics:** visits from search and whether they convert (PostHog).
4. **Backlinks:** who links to you and to competitors. Links matter to SEO roughly the way citations matter to AI answers.
5. **Technical audits:** broken pages, speed, titles, blocked bots.

| | SEO | AEO |
|---|---|---|
| Result | A ranked list of 10 links, fairly stable | A written answer that changes every time |
| What you track | Position 1 to 100 | Whether you're named, where, how, and which pages are cited |
| Data from the engine | Search Console, free | None, so you sample |
| Ranking signals | Links, content, speed | Citations, reviews, listings, Reddit, content |

For shops, the local version of Search Console exists: Google Business Profile performance data, free through its API. It shows the searches that found the shop, calls, direction requests and website clicks. So the module can pair real Google numbers with sampled AI answers.

## What the shop sees

A "Get found" page in Workbench:

```
You're recommended in 4 of 20 local questions  (up from 2 last month)

Who gets recommended instead
  Maison Doré        11 of 20
  Bijouterie Lavoie   7 of 20

Questions you're missing
  "custom engagement rings Plateau"   → Maison Doré, 38 Google reviews
  "who fixes broken chains near me"   → Lavoie, lists "chain repair" on Google

From Google this month: 312 searches showed you, 14 calls, 9 direction requests
This month: 6 new customers found you online, $2,340 in jobs
```

- **Questions:** about 20 local questions written from the shop's own data (city, neighbourhood, services, specialties), such as "ring resizing in Surrey" or "custom engagement rings Mile End". The shop can edit them.
- **Runs:** weekly, asked as if from the shop's area, because local answers change by location.
- **Competitors:** the shops named instead, ranked.
- **Gaps:** each missed question, why the winner was chosen (reviews, a listed service, a page) and the fix that closes it.
- **Google numbers:** real searches, calls and direction requests from the shop's Google Business Profile.

## What Workbench does for the shop

Owners have no time to act on a report, so most fixes are done for them or take one tap.

1. **Review requests at pickup.** When a job is marked picked up, staff get a nudge with a ready review link to send. The jeweller sends it, so it stays personal, because boutique shops dislike anything that sounds automated.
2. **Google Business Profile sync.** Workbench already knows what the shop does. It keeps the profile's services, hours and photos complete and current. Local AI answers lean heavily on this profile and on reviews.
3. **A public shop page** with the shop's services, area, structured data and a "check your repair" link, so AI engines can read and cite it.
4. **Repeat business:** care reminders from job history (rhodium replating, prong checks, cleaning, watch batteries) and follow-ups on unanswered quotes, shown as nudges the jeweller sends personally.

## Proof

- At intake, Workbench asks the customer how they found the shop: Google, ChatGPT or another AI, Instagram, a friend, walking by.
- Workbench also knows each job's value, so it can say "Google and AI brought you $2,340 in jobs this month".
- Gauge can only show traffic. Tying discovery to job revenue is something only the back office can do. It's also the measure that holds up when rankings shift, and it's what makes a monthly fee easy to keep paying.

A weekly email sums it up in a few lines: "You moved up on 'ring resizing Mile End'. 2 new reviews came in. The question to win next: chain repair."

## Pricing

Fits the principle in `2026-11-21-pricing-strategy.md`: price on how much of the back office runs itself.

- **Free plan:** the score and the "How did you find us?" question. The score is the hook and gives us data.
- **Scale, or an add-on at about C$20 to 40 a month:** the full question set, competitors, gaps, fixes, Google profile sync and the weekly email. Included or sold separately is open.
- **Later, done for you, about C$100 a month:** someone (or an agent) writes the shop's Google posts, replies to reviews and builds its pages, like Gauge's managed services.

## How we build it, and what it costs

- **Sauron first.** We track Workbench's own AI visibility before offering the module to shops, so we learn the loop on ourselves.
- **Free version:**
  - Run it as a recurring job inside the Workbench app, so there's no new Render service.
  - Use the Gemini API free tier with Google Search grounding (closest to Google AI Mode), plus Perplexity Sonar if the Pro plan's API credit applies.
  - Find mentions with plain string matching against shop and competitor names. Cited URLs come back structured from the APIs.
  - ChatGPT and Copilot get checked by hand once a month.
- **At scale:**
  - About 20 questions a week per shop is roughly 80 engine calls a month.
  - Free tiers cover the studio and a handful of shops, not 100. The module's price pays for the calls, which come to cents or a few dollars per shop.
- **Rules:**
  - Use official APIs only. Automating the consumer ChatGPT or Perplexity apps breaks their terms and keeps breaking.
  - Sauron stays an internal name, because the Tolkien estate enforces its trademarks.

## Risks

- **No promised rankings:** sell tracking, fixes and proof, never a position.
- **Shops on the same street:** two Workbench shops in one neighbourhood will compete for the same questions.
  - No exclusivity. Shopify doesn't offer it either.
  - Never show one shop another shop's Workbench data.
  - Most competitors won't be on Workbench, so "Workbench shops get found more" becomes a reason to join.
- **Google access:** profile sync needs each owner's permission and Google API approval.
- **Customer messages stay human and opt-in.** Review asks and reminders are nudges the jeweller sends.
- **Wholesale is different:** Jewellery Clinic Wholesale's customers are stores, so local consumer questions don't apply.

## Next steps

1. Interview 3 to 5 shops with section 4 of `customer-interview-script.md`, starting with the owner who said they want more customers. Owner: founder.
2. Run 20 local questions by hand for 2 shops, show them the mock-up above, and ask what they'd pay. About an afternoon. Owner: founder, with an agent drafting the questions.
3. Set up Google Search Console for useworkbench.co if it isn't already, so we see the searches that find us. Owner: founder.
4. If steps 1 and 2 are positive, ship the cheapest pieces first:
   - the "How did you find us?" question at intake
   - the review request at pickup (G3 in `aeo-action-plan.md`)
5. Build the weekly check on Sauron once it works for Workbench itself (G7 in `aeo-action-plan.md`).

## Open

- Name: "Get found" is a placeholder.
- Included in Scale or sold as an add-on.
- Whether Google Business Profile sync is worth the API approval work before there's demand.
