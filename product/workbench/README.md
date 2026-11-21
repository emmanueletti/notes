# Workbench product notes

Strategy for Workbench, written 2026-11-21. Notes only, never committed to the repo. Durable decisions graduate to the repo's `docs/adr`.

## Start here

1. `2026-11-21-90-day-priorities.md`: what happens now, next and not this quarter. Read first.
2. `pulse.md`: the north star (weekly active shops) and the weekly numbers. An agent runs it into `pulse-log.md`.
3. `2026-11-21-brand-positioning.md`: who we are and how we say it.

## Strategy

| Note | What it decides |
| --- | --- |
| `2026-11-21-brand-positioning.md` | Public line "the back office that runs itself"; long-term vision the Shopify for independent jewellery brands; private bank feel; ethical and sustainable; the magazine |
| `2026-11-21-go-to-market.md` | Sales: plug the onboarding leak first, help by shop value, growing with no budget, partners, keeping shops, printed material, email, Flux and Stone |
| `2026-11-21-plg-strategy.md` | Self-serve growth: search research, help centre, AI recommendations (incl. 2026-11-21 audit), loops, book a demo, stories and editorial, getting found for our shops |
| `2026-11-21-machine-automation-strategy.md` | "Never type": photo intake first, the agent ladder from MCP to background agents |
| `2026-11-21-pricing-strategy.md` | Free, Team C$50, Scale C$100; allowances; integrations over a point of sale |
| `2026-11-21-pricing-profitability.md` | Unit economics, real usage, cost per text, email, AI and platform, what each price lets us spend to win a shop, price trajectory, cutting AI cost |
| `2026-11-21-supply-store-strategy.md` | QR labels, envelopes and bags at cost; full catalogue with recommendations |
| `shopify-integration.md` | Best-in-class Shopify integration: zero data entry, POS-native intake, payments through Shopify, phases |
| `growth-module-for-jewellers.md` | Idea: "Get found" growth module for shops: lessons from Gauge, SEO vs AEO tracking, local AI visibility score, fixes Workbench does (reviews at pickup, Google profile, shop page), revenue proof from "How did you find us?", pricing, free build |
| `sarahbijoux.md` | Landing SarahBijoux (Quebec): custom work, speed, Hotwire with optimistic updates, full email thread |

## Working tools

| Note | Use |
| --- | --- |
| `aeo-action-plan.md` | Every AI recommendation action (A1 to A24, measurement, Sauron, getting found G1 to G7) with impact, effort, owner, 30 and 90 day order |
| `2026-11-21-marketing-site-and-seo-plan.md` | Site rebuild and Google search: audit (rankings for 7 searches, broken help links, .ca duplicate), site map, page rules, phased action plan, success metric |
| `customer-interview-script.md` | One 20-minute interview that answers every "validate first" question. Log answers in `customer-interviews.md`. |
| `pulse.md` | Weekly metrics, queries and report format |

## Decided 2026-11-21

- Positioning: public "back office that runs itself"; long term the Shopify for independent jewellery brands, with growth tools for shops in scope.
- Fix self-serve onboarding before pushing channels.
- Photo intake at Jewellery Clinic Wholesale is the first automation bet; AI on Haiku by default.
- Speed: performance-tuned Hotwire with optimistic updates; Vue only where measured short.
- No point of sale for now; deep Shopify integration first, light Square for SarahBijoux.
- Free tier free forever but limited; students get Team per school year; in-person setup free; portal on every plan.
- Supplies sold by us at full cost, starting very small.
- Customer stories and a magazine with a Montreal filmmaker in 2027.
- Everything in French, with a friend audit.

## Open

- Pricing decisions 1, 2, 4 to 7 (`2026-11-21-pricing-strategy.md`).
- Done 2026-11-21: AI crawlers unblocked on useworkbench.co. Still open: 172 of 324 crawler requests in the last 7 days got a 404; find the paths in AI Crawl Control, Metrics.
- Photo intake spec in `~/notes/plans/`.

## Next

- Shopify: validate `shopify-integration.md` (call back the nearly-won customer, try KaratCare), then write the phase 1 plan in `~/notes/plans/`.

## Context

- One founder does all of it.
- Jewellery Clinic Wholesale (tenant 8) is owned by family and won't churn; it's about 60% of all jobs taken in.
- PostHog project 718224 holds product events; AppSignal holds request logs.
