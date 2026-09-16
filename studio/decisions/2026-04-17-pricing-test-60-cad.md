# Pricing test: $60 CAD/mo for new customers

**Date:** 2026-04-17
**Reversibility:** Reversible (can be lowered back, though awkward)

## Context

Current pricing: $40 CAD/mo or $400 CAD/yr. Set early, conservative, fear-driven.

The honest comparison:

- The Edge: $4,600 USD upfront + 20% annual support, per workstation
- RepairDesk: from $99 USD / store / month
- RepairShopr: $50-100+ USD / month tier-dependent
- RepairTrax: ~$50-100 USD / month range
- Workbench: ~$29 USD/mo equivalent

We are materially below market for the value we deliver. Acquisition cost is high (3-5 founder hours per in-person customer). Current LTV/CAC math is grim.

## Options considered

1. **Hold at $40 CAD.** "We're new, we should be cheap to compete."
2. **Test at $60 CAD/mo, $600/yr for new customers.** Existing 10 grandfathered.
3. **Jump to $80 CAD/mo, $800/yr.** Still well below incumbents, more room to negotiate down.
4. **Move to per-feature or per-seat tiers.** Add complexity to capture more value from larger shops.

## Decision

**Option 2.** New customers from today onward see $60 CAD/mo or $600 CAD/yr (saves 2 months).

Existing 10 grandfathered indefinitely.

If conversion holds at $60 over the next 60 days (data from at least 30+ new visits attempted), raise again to $80.

## Why

- The "we should be cheap" instinct is fear-driven, not user-driven. Violates the principle in `northstar.md`.
- LTV at $40 CAD does not justify in-person acquisition cost. The economics force this.
- Annual at $600 (saves 2 months at the new monthly rate) gives a clean incentive to take annual, which improves cash flow and reduces churn risk.
- Per-seat pricing (Option 4) violates one of our explicit differentiators ("flat-rate pricing, unlimited team"). Don't break that.
- $80 (Option 3) is probably the right end state but the safer learning play is to step there in two moves and watch conversion.

## What this means we accept

- Slightly slower acquisition if conversion drops at the new price (acceptable trade-off for unit economics).
- Awkwardness of grandfathering — must hold the line and not extend grandfathered pricing to new customers who hear about it.
- Sales conversations now must justify a higher price. The case study becomes more important to land.

## Revisit trigger

Revisit at Day 60 (2026-06-15) with data:

- If conversion rate at $60 is within 80% of the $40 conversion rate → raise to $80.
- If conversion drops sharply → hold at $60, investigate which objection is the cause.
- If conversion *increases* at $60 (anchoring effect) → strongly consider $80 immediately.
