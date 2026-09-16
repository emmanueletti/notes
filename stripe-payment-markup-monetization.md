# Monetizing payments on top of Stripe: do indie SaaS platforms add a markup?

Research report. All figures are 2025-2026 and change often. Verify current
rates before relying on any specific number.

## Headline answer

Yes. Layering a markup on top of Stripe's processing fee is a standard,
Stripe-sanctioned monetization model. Stripe's own monetization guide lists
"mark up each transaction" as one of five strategies, and Stripe ships a no-code
Dashboard tool (Settings > Connect > Platform pricing) to set it.

The mechanism is Connect's `application_fee_amount`. Critically: **Stripe takes
no additional fee on your markup**. The full application fee transfers to you;
Stripe's processing fee is netted separately. The markup is pure margin.

Important nuance: the no-code pricing tool is only available to platforms
**responsible for paying Stripe's fees** (you pay Stripe, then bill the
connected account). Stripe's docs split two models:

- **SaaS platforms** that pay Stripe's fees use application fees to recover or
  mark up processing costs.
- **Marketplaces** absorb Stripe's fees but charge a commission on payouts.

## Verified real-world examples

Strongest verified examples skew mid-size, not strictly indie. Genuinely
bootstrapped sub-$10M players do not publish their numbers, so that is a real
gap in the data. The model and fee structures below are well confirmed.

| Platform | Vertical | Fee structure | How it's presented |
|---|---|---|---|
| **HoneyBook** | Service-biz CRM/booking | 2.9% + $0.25 (card entered), 3.4% + $0.09 (Amex/Discover & card-on-file), 1.5% flat ACH (uncapped) | Published per-transaction schedule, blended into one rate |
| **Mindbody Payments** | Fitness/wellness | 2.99% + $0.30 in-person, 3.60% + $0.30 online. Built on Stripe Connect (confirmed via Stripe's own case study) | Single blended merchant rate; markup hidden inside it |
| **Gumroad** | Creator tools | 10% + $0.50 platform fee stacked on top of pass-through ~2.9% + $0.30 Stripe = ~12.9% + $0.80 | Marketed as a simplified "10% flat fee"; processor fee passed through |
| **StyleSeat** | Beauty/salon marketplace | 30% of first appointment capped at $50 per new client + $2.35 client-paid booking fee | Commission on marketplace-sourced clients + consumer booking fee |

Two patterns worth noting:

- **HoneyBook / Mindbody** bake the markup into a blended rate so the merchant
  never sees a separate "platform surcharge." HoneyBook's uncapped 1.5% ACH is
  quietly profitable: a $2,000 ACH deposit costs the merchant $30 vs Stripe's
  own $5 cap. That $25 spread is margin.
- **Gumroad** does the opposite: explicit stacking, processor fee passed
  straight through.

## What markup levels actually get accepted

- **Thin end:** ~0.3% margin -> customer pays 3.2% + $0.30. Stripe's own
  example. Barely noticeable.
- **Benchmark (read directionally, vendor survey data):** vertical-SaaS median
  take rates 0.46-0.60% under $50M volume, roughly doubling to 0.91-1.05% above
  $250M.
- **Entrenched verticals** (Mindbody) push effective markups into the
  few-hundred-bps range because they own the workflow.

Two hard constraints on how you set this:

1. **Small tickets are brutal.** On a $12 charge, 2.9% + $0.30 is already an
   effective ~5.4% before you add anything. The fixed $0.30 dominates on small
   amounts, so be careful adding percentage markup on small deposits.
2. **Visible surcharges cause real pushback.** J.D. Power 2025: 41% of
   cardholders declined to use a card because of a surcharge. This is why
   HoneyBook and Mindbody hide the markup in a blended rate rather than showing
   an explicit platform fee.

## The negotiation playbook (weakest-evidenced area, stay skeptical)

The popular claim that Stripe negotiates custom rates above $100K/month was
actively refuted (3 independent checks killed it). No reliable public volume
threshold exists. What is solid:

- Interchange-plus pricing favors high-volume platforms because bps savings
  compound. Stripe itself says "as your volume increases, markups can often be
  renegotiated." But there is no published number for when that conversation
  starts.
- Until you hit that undisclosed scale, you are on standard Connect: pay retail
  2.9% + $0.30, keep your application fee as margin.

## What this means for Winkly

Given solo lash techs and small deposits, the cleanest model is what HoneyBook
does: present one blended rate (e.g. "3.4% + $0.30 flat") that quietly includes
your margin over Stripe's 2.9% + $0.30, rather than an explicit surcharge line.
ACH for larger final payments is where the real margin hides if you ever add it.
Do not expect to undercut Stripe's cost until you have real volume, and even
then the negotiation threshold is genuinely unknown publicly.

## Caveats

- All figures are 2025-2026 and change often.
- Mindbody's worst-case bps figure came from a consultancy that sells
  fee-reduction services (biased, cherry-picked). The underlying rates are
  solid, the "355 bps" framing is not.
- The take-rate benchmark is from Rainforest, a Stripe Connect competitor. Read
  directionally.
- HoneyBook and Mindbody are mid-size, not indie. No genuinely bootstrapped
  player published verifiable numbers.

## Open questions

- At what concrete payment volume does Stripe actually move a platform off
  standard Connect onto negotiated interchange-plus/revenue-share pricing? The
  $100K/month threshold claim was refuted; no verified public number exists.
- What do genuinely indie booking tools (Vagaro, GlossGenius, Square
  Appointments) charge and how do they present it? Public data is thin. Closest
  comparables to Winkly, worth a dedicated dig.

## Sources

Primary: Stripe docs (connect/saas/tasks/app-fees, connect/platform-pricing-tools,
guides/introduction-to-monetizing-payments, resources/more/interchange-plus-pricing-explained),
Stripe Mindbody case study, HoneyBook/Gumroad/StyleSeat help centers.

Secondary (read with bias in mind): apideck/Rainforest 2026 benchmark, FeeTrace,
Bankrate (J.D. Power 2025 surcharge data), merchantcostconsulting.
