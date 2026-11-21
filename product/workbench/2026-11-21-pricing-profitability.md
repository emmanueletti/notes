# Pricing profitability, 2026-11-21

Unit economics for the proposed plans (`2026-11-21-pricing-strategy.md`): what each plan costs to serve, what it earns, and how much we can spend to win a shop. Figures researched 2026-11-21 from vendor pages and secondary sources; check vendor pages before committing. USD converted at about 1.38 CAD per USD.

## Verdict

- Team and Scale are profitable at the proposed prices: about 79% gross margin for a real Team shop and 91% for our real wholesale shop, with AI intake on Claude Haiku 5.5.
- Real usage (PostHog, 2026-11-07 to 2026-11-20): most shops send no texts, the heaviest about 170 a month; Jewellery Clinic Wholesale takes in about 990 jobs a month. Allowances: Team 250 texts and 150 AI intakes, Scale 500 texts and 1,500 AI intakes.
- Model choice is the biggest cost lever: about C$0.002 a job on Haiku against about C$0.04 on Sonnet. At full Scale use, Sonnet wipes out the margin. Run extraction on Haiku by default and escalate only uncertain jobs.
- Texts are the next biggest cost: about C$0.034 per French text plus a number per shop.
- Email provider cost is trivial either way. Choose Resend or Postmark on deliverability, not price.
- Square's app marketplace takes 20% of app revenue it bills; Shopify takes 0% on the first US$1M lifetime. Bill integrations through our own Stripe where the rules allow.
- At today's C$33 a month with unlimited texts, we can afford about C$320 to win a shop. At the proposed prices, about C$400 for Team and C$900 for a wholesale Scale shop.

## Cost inputs

### Texts (Twilio)

| Item | Price | Source |
| --- | --- | --- |
| US text, per billed part | US$0.0083 | Twilio pricing via sms8.io, getkanal (Nov 2026) |
| US carrier fees, per part | about US$0.0035 to 0.005 | getkanal |
| Canada text, per part | about US$0.0064 to 0.0087 (sources disagree) | getkanal, zavu |
| Phone number | US$1.15 a month per number | sociocs |
| US registration (A2P 10DLC) | Brand US$4.50 to 46 once, campaign vetting US$15 once, campaign US$1.50 to 10 a month | sociocs, telphiconsulting |

Model assumptions: a typical text is 2 billed parts (French accents bill at 70 characters per part). Cost per text about US$0.025, or C$0.034. Per-shop number cost about C$1.60 a month in Canada; up to about C$15 a month for a US shop with its own registered campaign.

### Email

| Provider | Plans | Per 1,000 beyond |
| --- | --- | --- |
| Resend (in use: `config.action_mailer.delivery_method = :resend`) | Free 3,000/mo (100 a day); Pro US$20 for 50,000; Scale from US$90 for 100,000 | about US$0.90 |
| Postmark | Free 100/mo; Basic from US$15 for 10,000 | about US$1.20 to 1.80 |

At Workbench's likely volume for the next few years (under 50,000 emails a month), the difference is US$0 to 40 a month. Per shop, email costs cents.

Decision advice: stay on Resend unless deliverability tests show sign-in codes or customer emails landing in spam. Postmark's reputation is built on transactional deliverability, and it separates transactional and broadcast streams; if inbox placement tests favour it, the extra cost is worth it. Test both with the same messages to Gmail, Outlook and iCloud before deciding.

### AI intake (Anthropic, from the claude-api skill, cached 2026-11-03)

| Model | Input per 1M tokens | Output per 1M tokens | Cost per intake (est.) |
| --- | --- | --- | --- |
| Claude Haiku 5.5 | US$0.10 | US$0.50 | about US$0.0015 (C$0.002) |
| Claude Sonnet 5.5 | US$2 | US$10 | about US$0.027 (C$0.04) |
| Claude Opus 5.5 | US$4 | US$20 | about US$0.055 (C$0.08) |

Intake assumption: 3 photos (a form and 2 of the piece) at about 1,600 tokens each, plus a 1,000-token prompt, about 500 tokens of output and about 1,000 of thinking. Measure real tokens per intake in the first test and replace these estimates.

### Payments and platforms

| Item | Take | Source |
| --- | --- | --- |
| Stripe (our subscriptions), Canada | 2.9% + C$0.30 per charge | stripe.com/ca/pricing |
| Shopify App Store | 0% on first US$1M lifetime app revenue, then 15%; 2.9% processing; US$19 one-time registration | shopify.dev revenue share |
| Square App Marketplace | 20% of app revenue from referred merchants or billed through Square | Square developer agreement |

### Infrastructure (estimate; replace with real bills)

Render web (standard), worker (standard), Postgres (basic-1gb), DigitalOcean Spaces, Resend Pro, AppSignal, domains: roughly US$150 to 170 a month, about C$210 to 235. Per-shop variable hosting and photo storage is cents a month, even at wholesale volume (about 4 GB of photos a month at 1,000 jobs).

## Revenue inputs

| Source | Terms | What it could mean |
| --- | --- | --- |
| Shopify partner referral | 20% recurring of the Shopify subscription for stores we refer (transferred development stores; not Starter or trial stores); Q4 2026 promotion up to US$1,500 on the first referral | A young brand on a US$39 Shopify plan earns us about US$8 a month |
| Square referral | 10% of Square's processing revenue in the referred merchant's first 12 months (marketplace agreement); at least US$1,000 per referral processing US$250k+ a year (referral program) | Rare for small shops; a bonus, not a plan |
| Stripe Connect application fee | Our own fee on payments taken through Workbench, if we build payments | Custom deposits run into the thousands; 0.5% of C$200k a year of shop payments is C$1,000 a year per shop |
| Supplies | At cost by decision | Zero profit, retention benefit only |

Shopify and Square referral terms change often; confirm in each partner dashboard before counting on them.

## Per-shop monthly economics (CAD)

Based on real usage (next section) and the revised allowances: Team 250 texts and 150 AI intakes, Scale 500 texts and 1,500 AI intakes. "Real" assumes every job goes through AI intake once it exists. "Full" uses every allowance.

| | Free | Team, real (100 jobs, 150 texts) | Team, full | Scale, real wholesale (990 jobs, 0 texts) | Scale, full |
| --- | --- | --- | --- | --- | --- |
| Revenue (yearly plan) | 0 | 41.67 | 41.67 | 83.33 | 83.33 |
| Stripe | 0 | 1.26 | 1.26 | 2.50 | 2.50 |
| Texts plus number | 0 | 6.70 | 10.10 | 1.60 | 18.60 |
| AI on Haiku (on Sonnet) | 0.02 (0.40) | 0.20 (4.00) | 0.30 (6.00) | 1.98 (39.60) | 3.00 (60.00) |
| Email, storage | 0.30 | 0.40 | 0.50 | 1.50 | 2.00 |
| Gross profit, Haiku | -0.32 | 33.11 | 29.51 | 75.75 | 57.23 |
| Gross profit, Sonnet | -0.70 | 29.31 | 23.81 | 38.13 | 0.23 |
| Gross margin, Haiku | | 79% | 71% | 91% | 69% |

The last row is the warning: a Scale shop using its full 1,500 AI intakes on Sonnet earns nothing. AI intake must run on Haiku-class models by default (see "Cutting AI cost" below), or Scale moves to C$150 before AI intake ships widely.

US shops add up to about C$13 a month for their registered texting campaign; price US plans or the US texting setup to cover it.

Students cost about C$5 to 7 a month each with no revenue. Fine as a growth cost; cap the number per school.

Today's plan for comparison: C$33.33 a month with unlimited texts. At 100 texts it earns about C$27 gross profit; a heavy texter can push it toward zero.

## Real usage, 2026-11-07 to 2026-11-20

From PostHog events `intake_completed` and `customer_notification_sent`, 14 days, scaled to 30 days (×2.14). Two weeks is a short window; re-run monthly.

| Shop | Jobs a month | Texts a month | Emails a month | Photos per job |
| --- | --- | --- | --- | --- |
| Jewellery Clinic (Wholesale), 8 | about 990 | 0 | 0 | 1.0 |
| Jewellery Clinic Kelowna, 16 | about 190 | 0 | 0 | almost none |
| JEWELLERY CLINIC, 10 | about 185 | about 135 | about 15 | 0.3 |
| C Creations, 54 | about 100 | 0 | 0 | almost none |
| Fort Richmond Jewellers, 29 | about 95 | about 170 | 0 | 0 |
| SarahBijoux, 27 | about 55 | 0 | 0 | 0 |
| Russell Jewellers, 9 | about 28 | about 13 | about 6 | 0.3 |
| Others | under 10 | under 10 | under 5 | |

What it changes:

- **Texts are lower than assumed.** Most shops send none. The heaviest sends about 170 a month. Team's 250 covers every shop today; Scale's 500 leaves wide room. Text costs in the table above are an upper bound.
- **Jewellery Clinic Wholesale is twice the earlier estimate**: about 990 jobs a month (33 a day, including weekends), not 500. Photos already run at one per job there.
- **AI allowances were too low.** Scale's 750 AI intakes wouldn't cover our main wholesale shop. Active independent shops take in 50 to 190 jobs a month, so Team's 100 sits in the middle of real use.
- Revised proposal: Team 150 AI intakes, Scale 1,500, 500 texts on Scale. At 1,000 intakes on Haiku that's about C$2 a month; on Sonnet about C$40, still leaving about C$37 gross profit on a C$100 Scale plan.
- **Time saved at Jewellery Clinic Wholesale is twice as large**: about 90 seconds over about 990 jobs is about 25 hours of staff time a month. That strengthens the case for Scale at C$150 and a wholesale plan.

## Cutting AI cost

How others run AI for cents, and the levers in order. Researched 2026-11-21.

- **Tally** gives its AI form builder to free users. Each call is short text with no images, usage per person is occasional, and AI is treated as an acquisition cost, like the "Made with Tally" badge. Their 767K AI calls in August 2026 at a fraction of a cent each are small next to US$6M a year in revenue. Their MCP server also runs on the user's own ChatGPT or Claude subscription.
- **Duolingo** cut Video Call from about US$0.30 to "well under one cent" per call, "mainly by moving to open source models or open weight models" (CEO, earnings call), and cut text-to-speech cost 40% by caching responses (Duolingo FinOps blog). Self-hosting open models pays only at their scale, but caching and pre-generating content apply to anyone.
- **Belly's Bella costs cents, not dollars.** Measured in production (PostHog, November 2026): 2.5 to 4.7 US cents a plan on Sonnet 5.5 at low effort, with output (thinking plus JSON) 55 to 75% of the cost. Changes on 2026-11-05 brought it down further: fresh builds plan one dish per call on Haiku 5.5 in parallel (about half a cent a plan, 8/8 evals), other runs use Sonnet with thinking off (about 2 cents, 13/13 evals), and the unused prompt cache write was dropped. Every change was checked against an eval set first. That's the template for Workbench's photo intake.

Levers, cheapest first:

1. **Measure cost per finished task**, not per request, with token logging from day one.
2. **Plain code first**: QR scans, customer matching, OCR templates for a store's form. No tokens at all.
3. **Single call, not an agent loop**, wherever the steps are known. Loops resend the growing conversation every turn.
4. **Smallest model that passes an eval**: Haiku for extraction, escalate to a larger model only for low-confidence jobs.
5. **Prompt caching**: the fixed system prompt and instructions cost about 10% of the normal input price on repeat calls.
6. **Low effort and short outputs**: extraction needs little thinking, and output tokens cost 5 times input. Structured output, no prose.
7. **Smaller images**: downscale and crop photos before sending. Image tokens grow with pixels.
8. **Batch API at 50% off** for anything not urgent: morning summaries, nightly checks, pre-written drafts.
9. **Cache and reuse results**: never extract the same form twice.
10. **Caps**: allowance per plan and a hard monthly ceiling per shop.

Applied to Workbench: at about C$0.002 per intake on Haiku, AI intake is already Tally-cheap. Free shops can get a generous taste, and AI is not a reason to raise prices. It's a reason shops pay.

Sources: [Tally, 6 years in](https://blog.tally.so/6-years-in-6-million-far/), [Tally free AI form builder](https://tally.so/help/free-ai-form-builder), [Duolingo FinOps blog](https://blog.duolingo.com/finops), [Duolingo Video Call cost (runtimewire)](https://runtimewire.com/article/duolingo-ai-video-call-cost-open-models), [Duolingo AI and Video Call](https://blog.duolingo.com/ai-and-video-call).

## Fixed costs and break-even

- Fixed infrastructure about C$220 a month: covered by 7 Team shops.
- Paying one founder C$8,000 a month: about 240 Team shops, or about 110 Scale shops like Jewellery Clinic Wholesale, or a mix.
- Payments (Stripe Connect fee) and a Scale price rise are what shorten that path most.

## What each price point lets us spend to win a shop

Rule of thumb for a bootstrapped company: earn back acquisition cost within 12 months of gross profit. With yearly plans paid upfront, cash comes back on day one, which is safer still.

| Price point | Gross profit a month | Can spend per shop (12-month payback) | What that pays for |
| --- | --- | --- | --- |
| Today, C$33 | about C$27 | about C$320 | Founder time and travel for in-person setup in Montreal; referral free months |
| Team, C$50 | about C$33 | about C$400 | Plus a revenue share to referrers (20% of first year is C$100); a supplier or rep commission; modest Google Ads on buying searches |
| Scale, C$100 | about C$57 to 75 | about C$700 to 900 | Plus travel to wholesale shops outside Montreal; paid trade newsletter placements |
| Scale, C$150 (after photo intake) | about C$100 | about C$1,200 | Plus a trade show booth shared across 10 or more shops won |
| Scale or wholesale, C$200 to 400 (after payments and custom projects) | about C$150 to 330 | about C$1,800 to 4,000 | A part-time salesperson or contractor in the field |

Paid ads check: if a niche search click costs C$3 to 6 and 2 to 3% of clicks sign up, a sign-up costs about C$100 to 300. If half of trials pay, a paying shop costs C$200 to 600. That works for Scale, is borderline for Team, and doesn't work today.

## Price trajectory

| Stage | When | Plans | Unlocked by | Existing shops |
| --- | --- | --- | --- | --- |
| 0. Today | Now | One plan, C$400 a year (legacy C$348) | | |
| 1. Three plans | With the 2.0 revamp, early 2027 | Free, Team C$50, Scale C$100 | New site, onboarding that works, setup calls | Keep their price until renewal; legacy shops get a first year at C$400 |
| 2. Scale rises | After photo intake hits its target, about mid-2027 | Scale C$150 for new shops; AI and text packs | Photo intake proven at Jewellery Clinic Wholesale | 12 months' notice, personal note |
| 3. Wholesale and payments | After payments on jobs, custom projects v2, Shopify integration | Scale C$200 to 250; a wholesale plan C$300 to 400 for 500+ jobs a month; a fee on payments | Money moving through Workbench, deep integrations | Same rule |
| 4. Counter sales | Only if shops keep asking | Possibly a point of sale add-on | Payments, then simple counter sales, then inventory | |

Each rise is tied to a proof point, applies to new shops first, and reaches existing shops with notice. Prices stay well under Gem Logic (C$399 and up) at every stage.

## What this request didn't include

- **Founder time per in-person setup.** A Montreal visit (travel plus 2 hours) is a real cost even if unpaid. Track hours per new shop; it's the largest hidden cost today.
- **Trial costs.** Trial shops use texts and AI with no revenue. Give trials the Team allowance, not Scale.
- **Sales tax on our subscriptions.** Canadian SaaS sales may require collecting GST/HST and QST once over the C$30,000 small supplier threshold. Stripe Tax can collect it for a fee. Confirm with an accountant.
- **Currency.** Most costs (Twilio, Anthropic, Render, Resend) are in USD; revenue is in CAD. A weaker Canadian dollar cuts margin. Review prices yearly.
- **Churn and failed payments.** Margin only matters if shops stay. Track yearly renewal rate per plan.
- **Support load.** Scale shops will ask more; budget founder hours.
- **Refunds and chargebacks.** Small, but Stripe charges about C$15 per dispute.

## Open

- Real monthly bills for Render, AppSignal, Resend, Twilio, Google Workspace. Owner: Emmanuel.
- Re-run the real usage query monthly (14 days of data so far). Owner: Emmanuel.
- Tokens per intake, measured in the first photo intake test. Owner: Emmanuel.
- Inbox placement test, Resend against Postmark. Owner: Emmanuel.
- Shopify and Square partner terms, confirmed in their dashboards. Owner: founders.

## Sources

[Twilio SMS pricing (sms8.io)](https://sms8.io/blog/twilio-sms-pricing-2026), [Twilio SMS pricing (getkanal)](https://getkanal.com/blog/twilio-sms-pricing), [Twilio 10DLC (sociocs)](https://www.sociocs.com/post/twilio-10dlc-explained/), [Twilio pricing (zavu)](https://www.zavu.dev/en/blog/twilio-sms-pricing), [Resend pricing (blueyemail)](https://blueyemail.com/compare/resend/pricing), [Resend vs Postmark (coldmailer)](https://coldmailer.ai/blog/resend-vs-postmark-pricing), [Resend vs Postmark (suprsend)](https://www.suprsend.com/post/resend-vs-postmark), [Shopify revenue share](https://shopify.dev/docs/apps/launch/distribution/revenue-share.md), [Shopify partner earnings](https://help.shopify.com/partners/partner-program/how-to-earn), [Shopify Q4 2026 referral offer](https://www.shopify.com/q4-2026-first-merchant-bonus), [Square developer agreement](https://squareup.com/us/en/legal/global-developer-integration-marketing-agreement), [Square referral program](https://squareup.com/ca/en/partnerships/referral-partner), [Stripe Canada pricing](https://stripe.com/ca/pricing).
