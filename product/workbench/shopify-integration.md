# Shopify integration, 2026-11-21

What a best-in-class Shopify integration looks like for Workbench. Investigation, not a spec; the build gets its own plan in `~/notes/plans/` once validated.

## Verdict

Aim for **zero data entry**: a shop installs Workbench from the Shopify App Store and never types a customer, an order or a payment twice. Jobs start from the Shopify POS screen, an online order or a storefront form; deposits and pickup payments run through the shop's own Shopify checkout; status shows in the customer's Shopify account. Workbench becomes the repair and custom work layer Shopify doesn't have.

Why it matters: a nearly-won customer said Shopify integration was a deal breaker, because they did not want to do "data entry". Most young operators on Workbench already use Shopify. And the App Store is a channel AI assistants cite.

## Principles

1. **Shopify owns customers, orders, payments and products. Workbench owns jobs.** Each record lives in one place; the other side links to it.
2. **Never ask for something Shopify already knows.** Shop name, address, logo, locations, staff, currency, language and customers come from the install.
3. **Work where staff already are.** At the counter that's the Shopify POS screen; online it's the storefront and the customer's account.
4. **Instant and both ways.** Webhooks in, Admin API out, with every change shown on both sides within seconds.
5. **Respect the shop's brand and the jeweller's voice.** Customer-facing pieces match the shop's theme; messages are drafted, never sent automatically by default.

## Shopify surfaces we can use

From Shopify developer docs and secondary sources, 2026-11-21. Check current docs before building; Shopify ships API versions quarterly.

| Surface | What it lets us do |
| --- | --- |
| Admin GraphQL API and webhooks | Read and write customers, orders, draft orders, products, locations, staff; hear about changes |
| POS UI extensions | A tile on the POS home screen; blocks and actions on customer details, order details, draft order details and cart line items (targets such as `pos.customer-details.block.render`, `pos.home.tile.render`) |
| Customer account UI extensions | Blocks and action buttons on the customer's order status and order list pages; available on Basic plans and up |
| Theme app extensions | Blocks the shop adds to its storefront theme, such as a "book a repair" form or a "track my repair" page |
| Draft orders | Quotes and deposits as a payable invoice link through the shop's own checkout |
| Metafields and metaobjects | Store the job link on the Shopify customer and order, so each side points at the other |
| Shopify Flow (to verify) | Workbench events ("job ready for pickup") as Flow triggers, so shops automate with their own tools |
| Shopify App Pricing or Billing API | Required for App Store apps: charges go through Shopify, not our Stripe |

## The integration, flow by flow

### Install: setup in one click

- Install from the App Store, sign in with Shopify, and the Workbench shop is created from the store: name, address, logo, currency, language, locations, staff.
- Customers are linked on demand (when a job is created for them), not bulk-copied.
- Result: no setup form. The first screen is "take in your first job".

### Take in a job at the counter (POS)

- **On the POS home screen**, a Workbench tile: "New repair". Opens intake inside POS.
- **On a customer's page in POS**, a block shows their open jobs and repair history, with "New job for this customer". Name, phone and email address come from Shopify.
- **On an order's page in POS**, "Start a repair or resize from this item": the piece they bought becomes the job's item, with what was paid and when.
- Photo intake (`2026-11-21-machine-automation-strategy.md`) runs inside the same flow.

### Take in a job online

- **Storefront "Book a repair" form** (theme app extension): the customer describes the piece, adds photos and picks a drop-off time. It arrives as a draft job, customer created or matched in Shopify.
- **A Shopify order becomes a job**: an order for a resizing, engraving or custom ring (tagged product or product type) creates the job automatically, with the order's details.

### Money

- **Deposits and quotes as draft orders**: Workbench creates a draft order for the estimate or deposit; the customer pays through the shop's own checkout or at the POS. When it's paid, the job shows paid.
- **Pickup at the till**: the job's balance goes to the POS cart as a line item. Paying it marks the job picked up.
- The shop's own Shopify Payments carries the money. No payments for us to run, no new terminal.

### The customer's side

- **Order status page and account** (customer account UI extensions): "Your repair: in progress, ready Friday", with the shop's photos at intake. No separate portal sign-in for Shopify shops.
- **Track my repair** on the storefront for customers without an account.

### Keeping customers coming back

- Care reminders and review asks (`2026-11-21-plg-strategy.md`, getting found) as Shopify customer segments or Flow triggers, so shops send them with Shopify Email or their own tools, in their own voice.
- Repair history on the customer's record feeds the shop's own marketing.

### Custom work

- A custom ring order on the storefront or a consultation booking starts a custom project, with the deposit as a draft order and the final piece as an order.

## What exists today on the App Store

| App | Notes |
| --- | --- |
| KaratCare: Jewelry Repairs | Jewellery-specific repair management with a branded repair portal; from US$49 a month. The closest direct competitor on Shopify; study it first. Review counts differ between listings. |
| RepairRight Repair Tickets | General repair tickets and status page; Pro US$79 a month |
| RepairTracker, Unified Repairs Support, RepairProof, Pit Crew | General repair, few reviews |
| RepairDesk | General repair (phones), on the App Store |

Workbench's edge over them: jewellery depth (wholesale, trade work, custom), photo intake ("never type"), POS-native intake, and bilingual French and English.

## Business terms

- **Billing**: App Store apps must charge through Shopify App Pricing or the Billing API. Shopify takes 0% on the first US$1M of lifetime app revenue, then 15%, plus about 2.9% processing. So Shopify shops pay through Shopify, likely in USD; other shops keep paying through our Stripe. Two billing paths, one plan structure.
- **Built for Shopify badge**: better placement in App Store search. Criteria include admin speed and real installs and reviews; check the current list. Worth aiming for from the start.
- **Partner referrals**: 20% recurring of the Shopify subscription for brands we bring to Shopify (`2026-11-21-pricing-profitability.md`).

## Phases

1. **No retyping (the deal breaker)**: install from the App Store with setup from the store, customers linked both ways, POS tile and customer block, pickup paid at the POS till. Embedded in Shopify admin.
2. **Online**: Shopify orders become jobs, storefront "Book a repair" and "Track my repair", status in customer accounts, deposits as draft orders.
3. **Growth**: Flow triggers, care reminders and review asks through Shopify, custom work from storefront orders, Built for Shopify badge.

## Risks and requirements

- **Protected customer data**: Shopify requires apps to request access to customer names, emails and phone numbers and meet data protection requirements. Plan for the review.
- **Mandatory privacy webhooks** (customer data requests and deletion) and app review before listing.
- **API versions change every quarter**; budget upkeep.
- **One founder**: phase 1 alone is weeks of work. Keep Square to the light version for SarahBijoux.

## Validate first

- Call back the nearly-won customer: what exactly did they want to stop typing, and which Shopify screens do they use at the counter?
- Ask the young operators on Shopify the "other tools" questions in `customer-interview-script.md`.
- Install KaratCare and RepairRight on a development store and note what they do well and badly.

## Sources

[POS UI extensions](https://shopify.dev/docs/api/pos-ui-extensions/latest), [POS Action API](https://shopify.dev/docs/api/pos-ui-extensions/latest/target-apis/standard-apis/action-api), [Extending Shopify POS](https://shopify.dev/docs/apps/build/pos), [Customer account UI extensions](https://shopify.dev/docs/api/customer-account-ui-extensions/latest), [Order status targets](https://shopify.dev/docs/api/customer-account-ui-extensions/latest/targets/order-status), [Customer account apps by plan](https://help.shopify.com/en/manual/checkout-settings/customize-checkout-configurations/checkout-apps), [App Store requirements](https://shopify.dev/docs/apps/launch/shopify-app-store/app-store-requirements), [Revenue share](https://shopify.dev/docs/apps/launch/distribution/revenue-share.md), [Built for Shopify updates](https://www.shopify.com/partners/blog/built-for-shopify-updates), [KaratCare](https://apps.shopify.com/karatcare), [RepairRight](https://apps.shopify.com/repairright), [RepairTracker](https://apps.shopify.com/repairtracker).
