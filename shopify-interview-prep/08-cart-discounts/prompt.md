# Cart with discounts

Not candidate-reported. This is plausible Shopify-flavored practice: it's commerce, it grows one rule at a time, and money handling is a real senior signal there. Treat it as a stretch problem, not a known question.

## Prompt

Build a shopping cart.

- `add(sku, unit_price, quantity)`: adding the same SKU again increases its quantity.
- `remove(sku)`
- `totals`: subtotal and total.

Store money as integer cents with a currency. No floats.

## Follow-ups they add

1. A percentage discount on the whole cart: 10% off.
2. A fixed discount: $5 off. The total can't go below zero.
3. Buy X get Y: buy 2 mugs, get 1 free. Ask: with 7 mugs, how many are free? (2.)
4. Stacking. With 10% off and $5 off on a $100 cart, is the total $85 or $85.50? Decide an order, and make it not depend on the order the discounts were added.
5. Tax, applied after discounts.
6. Currency: reject adding a USD item to a CAD cart.

## Core idea

Every discount is an object with one method: given the lines and the running total, return an adjustment (a label and an amount). The cart sorts discounts by priority, applies each to the running total, and records the adjustments. Tax goes on what's left.

So a new kind of discount is a new class. The cart doesn't change.

Money is a value object: cents plus currency. Adding two different currencies raises an error. Rounding happens in one method, so the rounding rule is a decision you make once.

## Design that takes the follow-ups

- `Money`: cents and currency. `+`, `-`, `*`, compare, and `percent(rate)`, which is the only place that rounds.
- `LineItem`: sku, unit price, quantity. `subtotal`.
- Discounts: `BuyXGetY`, `PercentOff`, `FixedOff`. Each has a `priority` and `adjustment(lines, running_total)`.
- `Adjustment`: label and amount. A receipt shows these lines.
- `Totals`: subtotal, adjustments, tax, total.
- `Cart`: lines, discounts, tax rate. `totals` runs the pipeline.

## Senior talking points

- Floats lose cents: `0.1 + 0.2 != 0.3`. Integer cents, always. Mention that some currencies have no minor unit (JPY) or three decimals (KWD), so "cents" really means the smallest unit.
- Pick a rounding rule and name it. Banker's rounding (half to even) avoids a small bias in favor of rounding up. Round once at the end of each step, not on every line.
- Stacking order is a business rule. Item deals, then percentages, then fixed amounts is a common default. Put it in data (a priority), not in if statements.
- Percent then fixed gives the customer less off than fixed then percent. Say which one the merchant would want.
- Tax per line vs per order. Per line needs the discount spread across lines in proportion, and the rounding remainder put somewhere. Name it as the likely next follow-up.
- Discount rules that can't combine ("not valid with other offers") fit as a flag on the discount and a filter step before applying.

## Test cases to name before the AI does

- Adding the same SKU twice merges the line
- An empty cart totals zero
- 10% off $100 is $90
- $5 off a $3 cart is $0, not negative
- 7 mugs with buy 2 get 1 gives 2 free
- 10% and $5 on $100 is $85, whatever order they were added in
- 13% tax on $80 after a $20 discount is $10.40
- Rounding a half cent
- Mixing currencies raises an error
- Quantity 0 and a 120% discount are rejected
