# Pricing strategy, 2026-11-21

Where pricing landed after one session. Decisions are marked; everything else is a proposal for the founders to settle.

## Verdict

Price on how much of the back office runs itself (`2026-11-21-brand-positioning.md`), not on features or seats. Keep people, jobs and the portal unlimited. Scale the plans by AI intake, texts and integrations, which track both the value a shop gets and our costs. Don't build a point of sale to justify a higher price; integrate deeply with Shopify and Square instead.

## Today

- One plan: C$40 a month or C$400 a year (`config/subscription_plans.yml`). Legacy shops pay C$348 a year.
- Every paying shop is on a yearly plan.
- Everything unlimited, including texts, plus "white glove" help.
- Problems: one price for a solo maker and a 500-jobs-a-month wholesale shop; in-person help that loses money at C$33 a month; no place for AI costs; the price signals "small tool".

## Market, checked 2026-11-21

| Product | Price | Scales by | Texts |
| --- | --- | --- | --- |
| Gem Logic | C$399 or C$949 a month, yearly | Stores (+C$279), users (+C$39) | Feature, no limit shown |
| Jewel360 | About US$199 to 299 a month, possible $750 setup | Quote | Not found |
| The Edge | About US$4,600 upfront plus 20% a year | Workstations | Not found |
| QuantumRepair | C$56, 89 or 114 a month, yearly | Locations, users, texts, AI credits (30 to 175) | 20, 50 or 125 a month |
| RepairShopr, RepairDesk | About US$70 to 140 a month | Users | Not checked |
| FixyFlow | Free (5 jobs), C$25 (50 jobs), C$39 (200 jobs) | Jobs | 20, 200 or 1,000 a month included |

Workbench sits at FixyFlow's price while competing with QuantumRepair and Jewel360. Nobody shows a per-text price; everyone includes a monthly allowance. QuantumRepair already sells AI as monthly credits. Setup is free everywhere.

Sources: [Gem Logic](https://www.gem-logic.com/pricing), [QuantumRepair](https://quantumrepair.app/pricing), [FixyFlow](https://fixyflow.com/pricing), [Jewel360 on The Edge](https://jewel360.com/blog/the-edge), [JMS Dev Lab roundup](https://jmsdevlab.com/blog/best-jewelry-repair-shop-software). Jewel360 and The Edge figures come from vendor comparison posts.

## Decided

- Free plan: free forever, limited so growing shops move to Team.
- Students: Team free for each year they're in school.
- In-person setup: free for now.
- Portal: on every plan.
- Texts: included allowance on Team and Scale, cheap beyond it.
- No point of sale for now. Deep integrations with Shopify (first, most young operators) and Square (light version for SarahBijoux).

## Proposed plans (CAD)

| | Free | Team | Scale |
| --- | --- | --- | --- |
| Price | $0 | $50/mo or $500/yr | $100/mo or $1,000/yr |
| For | Solo jewellers | Independent shops; students free each school year | Busy counters, wholesale |
| People | 1 | Unlimited | Unlimited |
| Jobs, photos, history, portal | Unlimited | Unlimited | Unlimited |
| Client updates | Email only | Email plus 250 texts/mo | Email plus 500 texts/mo |
| AI intake (forms, piece photos, email) | 10 jobs/mo | 150 jobs/mo | 1,500 jobs/mo |
| Integrations | None | Shopify or Square: customers both ways | Plus job to checkout, online orders to jobs, MCP and API |
| "Powered by Workbench" | Always shown | Optional | Optional |
| Locations, roles, audit trail | 1 location | 1 location | Several locations, roles, audit trail |
| Setup | Help centre, chat | Setup call, in person when it makes sense | In person, history brought in for them |

Upgrade triggers: Free to Team when the shop hires, wants to text clients or wants AI intake. Team to Scale at volume, for wholesale, or for deeper integrations.

Beyond the allowance: packs of texts and AI intakes, priced once real cost per job is measured. Most shops should never need one.

## Texts

- Price the allowance to cover per-shop number and US registration (A2P 10DLC) fees, carrier fees, failed texts and support. These are why "slight profit over Twilio" per text is too cheap.
- French texts with accents (é, à, ç) bill at 70 characters per part instead of 160, so a French text is often 2 or 3 parts. Count texts as the shop sees them, priced as if a typical text is 2 parts.
- Extra texts are rare and quiet, in packs. No visible per-text price, matching the market and the private bank tone.

## AI

- Allowance in each plan, packs beyond it, a firm cap. Never lose money on tokens.
- Log token cost per AI intake from day one, then set pack prices well above cost.
- Run AI intake on Claude Haiku 5.5 by default (about C$0.002 a job) and escalate only low-confidence jobs to a larger model. On Sonnet, a Scale shop using its full 1,500 intakes earns nothing. Cost levers: "Cutting AI cost" in `2026-11-21-pricing-profitability.md`.
- Value check: at Jewellery Clinic Wholesale, about 90 seconds saved per job over about 990 jobs a month (PostHog, 2026-11-07 to 2026-11-20) is about 25 hours of staff time a month.

## Students

- Verify enrolment once a year (school email address or instructor).
- At graduation, offer a discounted first year on Team for new grads opening their own studio.

## Raising the ceiling later

Ranked by how much they raise what shops will pay, without a point of sale:

1. AI intake (hands-free, nobody else has it).
2. Payments and deposits on jobs, through Shopify or Square, or Stripe Connect with a small cut of each payment. Custom deposits run into the thousands.
3. Custom projects v2 with appointments.
4. Accounting connection and reports.
5. Several locations, roles and an audit trail.

With 1 to 3 in place, a Scale or wholesale plan at C$200 to 400 a month is believable on time saved alone. A full point of sale stays open (the founders are "extremely open" to it); the path would be payments first, then simple counter sales, then inventory, only if shops keep asking.

## Trajectory and profitability

Price rises, unit economics, cost per text, email, AI and platform, and what each price point lets us spend to win a shop: `2026-11-21-pricing-profitability.md`. It proposes Scale include 500 texts instead of 1,000, and AI intake on Claude Haiku 5.5 first.

## Open decisions

1. Scale at $100, or higher? Proposal: launch at $100, raise for new shops once photo intake is proven.
2. Monthly billing? Proposal: monthly at about 20% more (Team $60, Scale $120) so yearly stays the obvious choice, or yearly only.
3. Allowances. Real usage (PostHog, 2026-11-07 to 2026-11-20): heaviest texter about 170 a month, most shops none; Jewellery Clinic Wholesale about 990 jobs a month, active independents 50 to 190. Proposal: Team 250 texts and 150 AI intakes, Scale 500 texts and 1,500 AI intakes. See `2026-11-21-pricing-profitability.md`.
4. Existing shops: keep each shop's price until renewal, then move them to Team or Scale by usage. Legacy C$348 shops: first year at C$400 with a personal note.
5. Business clients and store reference numbers: every plan, or Scale only?
6. Currency: CAD today. The Shopify app will likely bill in USD through Shopify, and the App Store takes a share of app revenue above a threshold. Settle in the Shopify investigation.
7. Pricing page tone: rewrite the flag emojis and "~30% advantage" pitch for the private bank voice in the 2.0 revamp.

Owner of all: founders.
