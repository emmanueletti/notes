# Belly Insiders — membership implementation plan

Status: Stripe integration built and tested in sandbox. Not live.
Last reconciled against the repo: 2026-09-24.
Repo: `~/projects/itsusstudio/belly`, server at `server/`. Branch `main`.

**Read `docs/stripe-setup.md` in the repo first.** That is the playbook for how billing works and how to add a product. This doc is the plan: decisions, rationale, and what is left. It does not duplicate the playbook.

This doc is the handoff. Read "Decisions already made" before changing anything — most of it was argued through once already and the reasoning is recorded so it does not get re-litigated.

---

## Product shape

**Belly Insiders** is the programme. **Insider** and **Patron** are the two tiers, singular, used as labels on badges. "Member" was considered and rejected: it is inert against a fully-featured free tier.

The core promise, which constrains everything else:

> Belly is free forever for cooking. Money buys access and influence, not features.

No feature is gated behind payment. The only defensible metering is AI (photo scan, link import), because it has real marginal cost per use. Whether the free tier is metered at all is **still undecided**.

Consequence to keep in mind: conversion will run ~1–3% of actives, not the 5–10% of an app with a clipped free tier. Revenue expectations should be set accordingly. The programme is about sustainability and belonging, not ARR.

### Pricing

Annual only. No monthly. CAD is the base currency. Tax behaviour is **inclusive** on all plans and currencies.

| Tier | CAD | USD | EUR |
|---|---|---|---|
| Insider | 39 | 29 | 25 |
| Patron | 139 | 99 | 85 |

These are deliberate local prices, not FX conversions. Do not "correct" them to match spot rates.

---

## Decisions already made

Each of these was reasoned through. Change them only with a reason, and update this doc if you do.

**Annual only.** At $29, monthly loses ~15% to Stripe's fixed fee versus 3.9% annually, and consumer monthly churn (5–10%/mo, ~6 month median lifetime) means annual yields roughly 2x the lifetime value. Annual also turns a recurring bill into a single decision made on enthusiasm.

**No price lock / grandfathering promise.** Lunch Money does the opposite and advertises it as a feature, funding it by raising new-subscriber prices. This was a deliberate divergence, not an oversight.

**Fixed tiers, not pay-what-you-want.** PWYW on a *recurring* Stripe price is unverified — Lunch Money does it but the mechanism was never confirmed. Do not build on it without checking.

**Multi-currency via Stripe `currency_options`** on a single Price per tier, plus Adaptive Pricing for everywhere else. One Price, one `lookup_key`, amounts declared per currency. Manual currency prices override Adaptive Pricing for those currencies; Adaptive fills the gaps (AUD, JPY, GBP).

**No Pay gem.** Hand-rolled `Billing::` module, Stripe only, Checkout + Customer Portal. Pay's main value is its webhook layer, which the polling design deletes. Steal Pay's schema field names as reference if useful.

**Polling, not webhooks.** From Gary Bernhardt / Execute Program (Changelog Ship It ep. 62). His reason is debuggability: "Stripe has this mechanism where they basically forward the WebHooks into your local machine… I've found that to be unreliable," and you cannot distinguish a billing bug from flaky delivery. His implementation is an hourly worker running a bounded query for recently-expired subscriptions, ~45s total, accepting up to an hour of free access as a gift.

**Standard Stripe, not Managed Payments.** MoR costs 6.4% + 30c, makes **Link** the merchant of record (Link-branded receipts, `LINK.COM*` statement descriptor, no custom checkout domain, order management on link.com), and has reported renewal-reliability problems — one operator reported 80% of renewals stuck. For annual billing, where there is one charge per member per year, that asymmetry is unacceptable. It is a per-Checkout-Session flag (`managed_payments: {enabled: true}`), so it can be switched on per market later when EU VAT becomes real work.

**Separate Stripe account per studio app, all under one Us Studio Organization.** Organizations is self-serve from the Dashboard, up to 75 accounts, no volume gate. Gives consolidated reporting, account groups and Sigma across accounts without touching any integration. Accounts stay isolated at the API level — it is a reporting and admin layer, not shared billing.

**Do not build a QueenBee.** Stripe Organizations now covers the reporting half off the shelf. The remaining half is cross-product identity, which is an SSO problem, not a billing one. Revisit when 3+ products actually charge money.

**Comps, staff and gifts go in a separate `billing_grants` table**, NOT as non-billable plan codes. This differs from Workbench deliberately: Belly polls, so `billing_subscriptions` must stay a pure mirror of Stripe where every row has a `stripe_subscription_id` and anything without a counterpart is a bug.

**Free is not a plan and gets no row.** There is no `cook` entry in the catalog and no subscription row for free users. Entitlement is derived, never stored. Time-based expiry then enforces itself locally with no sweeper job — that property is what makes the polling design safe.

**Tax inclusive everywhere.** The price is the price, nothing added at checkout. Right for EUR and good for the patronage framing. The cost: once over the CAD $30k GST/HST threshold, tax comes out of the 39 rather than on top, roughly 11% of Canadian revenue at 13% HST. Changing it later means new plan codes.

**Plan switching is allowed through the Portal**, with `proration: always_invoice` and downgrades at period end (`config/stripe.yml`). Never refund a downgrade mid-year.

**Gift years were cut.** The Patron copy no longer mentions them. `Billing::Grant` keeps `"gift"` in `REASONS` but nothing issues one; the model earns its place on `comp` and `staff`.

**Feature-flagged, not native-gated.** Originally the surface was hidden with `hotwire_native_app?` to dodge Apple and Google anti-steering. Replaced with a Flipper flag because IAP is planned, so the native gate is not permanent.

---

## Apple and Google constraint

Relevant because it shapes phasing, and an agent unaware of it may "helpfully" expose checkout in the native shells.

- Guideline 3.1.3 bans buttons, links or other calls to action steering to outside purchase. Indirection does not help — a help page reached in four taps is still in-app content, and Belly is a Hotwire Native web view so **everything** served to the shell is in-app content.
- Hiding the CTA from App Review is worse: that is guideline 2.3.1, hidden functionality, where account termination is on the table rather than a rejection.
- The **US storefront** allows external purchase links since the 2025 Epic injunction, via an entitlement you apply for. Sanctioned, no commission. Gate by storefront.
- **Canada has no equivalent.** In Canada it is IAP or silence.
- Spotify's "global" approach is actually silence: since 2016 you cannot subscribe in their iOS app at all. That works because everyone knows spotify.com exists. Belly has no such brand awareness, so silence converts nobody.
- **Email is the sanctioned channel.** Apple explicitly permits using contact info obtained outside the app. In phase 1 this is the real conversion channel; the card is secondary.
- You may show *status* in-app — badge, perks, "You're an Insider" — under 3.1.3(b) multiplatform services. You just cannot sell or steer.

Commission maths, for when IAP is on the table: Small Business Program is 15% under $1M/yr, so $29 nets $24.65 versus $27.86 through Stripe. About $3.20/member/year. The real cost of IAP is engineering and permanent surface area, and the real benefit is reach, not margin.

---

## Tax posture

Low urgency, non-zero, and the risk is not a knock on the door.

- **Income tax** on revenue is real from dollar one.
- **Canadian GST/HST**: small supplier threshold is CAD $30,000 over four consecutive quarters. At CAD $39/yr that is ~770 members. Register when you cross it, not before.
- **EU and UK** have no threshold for non-EU/non-UK sellers of digital services — technically owed from the first sale, practically unenforced at micro-scale.
- **US sales tax**: economic nexus is typically $100k or 200 transactions per state, and many states do not tax consumer SaaS at all.
- The realistic failure mode is **due diligence**, not enforcement. Years of unremitted EU VAT surfaces when someone's accountant reads the books.
- **Stripe Tax** is free where you are registered nowhere, then 0.5% per transaction in registered jurisdictions on the Checkout integration path (the flat CA$0.50 API path is 3.4x worse at a $29 ticket). Tax Complete starts at CA$120/mo — ignore it.
- Turn Stripe Tax on at launch for threshold monitoring even though it will bill nothing.

---

## What exists now

Commits on `main`, oldest first:

```
c5c1d91 refactor(settings): share one layout across settings pages
7ddf517 refactor(settings): build settings sections from Data objects
9296207 test: register feature flags before each test
c1222db feat(billing): complete the plan catalog
815d055 feat(billing): add Stripe and a sandbox plan sync task
ff3ad75 feat(insiders): add the Insiders settings panel
45ce52e feat(insiders): add the Insider prompt card
```

Paths below are relative to `server/`.

```
config/billing_plans.yml                       code, name, description, billing_period, tax_code,
                                               tax_behavior, base_currency, prices
config/stripe.yml                              portal + tax config, applied by a rake task
config/feature_flags.yml                       feature_enable_insiders_memberships_{web,native}

app/models/billing/plan.rb                     ActiveModel value object + validations
app/models/billing/catalog.rb                  Catalog.plans / Catalog.plan(code)
app/models/billing/currency.rb                 SUPPORTED, DEFAULT, for_country, supported?
app/models/billing/subscription.rb             Stripe mirror, ENTITLED_STATUSES, entitled scope, sync
app/models/billing/grant.rb                    REASONS gift/comp/staff, active scope
app/models/billing/sync_cursor.rb              reconciler cursor

app/services/billing/subscription_reconciler.rb  reconcile_changes / reconcile_all / reconcile_customer
app/jobs/billing/reconcile_subscriptions_job.rb  hourly at minute 20

app/controllers/concerns/billing_currency.rb   chosen_currency
app/controllers/dashboard/billing/{checkouts,checkout_returns,portals,portal_returns}_controller.rb

app/helpers/dashboard/insiders_helper.rb       PLAN_PERKS, membership_status, price formatting
app/views/dashboard/settings/insiders.html.erb
app/views/dashboard/settings/_insiders_invitation.html.erb   tier cards + currency toggle
app/views/dashboard/settings/_insiders_management.html.erb   status, badge, manage
app/views/dashboard/shared/_insiders_callout.html.erb        the ink prompt card

lib/tasks/billing.rake                         create_stripe_plans, configure_stripe, reconcile_all
docs/stripe-setup.md                           the playbook (repo root, not under server/)
```

Routes:

```
POST /dashboard/billing/checkout          checkouts#create
GET  /dashboard/billing/checkout_return   checkout_returns#show
POST /dashboard/billing/portal            portals#create
GET  /dashboard/billing/portal_return     portal_returns#show
GET  /dashboard/settings/insiders         settings#insiders
```

Schema:

- `billing_subscriptions` — polymorphic owner, `stripe_customer_id`, `stripe_subscription_id` (unique), `stripe_price_id`, `plan_code`, `status`, `current_period_end` (indexed), `cancel_at`, `synced_at`
- `billing_grants` — polymorphic owner, `plan_code`, `reason`, `expires_at`, `revoked_at`, `granted_by_id`, `note`
- `billing_sync_cursors` — `name` (unique), `last_event_id`, `checked_at`

Entitlement on `User`: `insider?`, `insider_plan`, `insider_since`, `granted_insider?`,
`current_billing_subscription`, plus `has_many :billing_subscriptions` / `:billing_grants`.
Derived from both sources. `insider_plan` uses `Catalog.plans.rfind`, so **catalog order is tier
order** — the last matching plan in the file wins. That is why there is no `rank` field.

Tests: 32, all green. `test/models/billing/`, `test/services/billing/`,
`test/controllers/dashboard/billing/` (4 files), and three factories. No system tests, deliberately.

Perks the copy promises (`PLAN_PERKS` in `app/helpers/dashboard/insiders_helper.rb`):

- **Insider** — an Insider-only app icon and badge; early access to new features; new perks as the program grows
- **Patron** — a Patron-only app icon and badge; a say in what we build next; priority support from the makers; new perks as the program grows

None are built. "New perks as the program grows" is a deliberate hedge that buys room.

Card placements, both rendering `dashboard/shared/insiders_callout`: the recipes index under the
search bar, and settings below the Log out button.

The `feature_enable_insiders_memberships_web` and `feature_enable_insiders_memberships_native` flags are **enabled globally in development only**. Off in staging and production.
Toggle at `/admin/flipper`.

---

## Conventions this code follows

**One identifier.** The plan `code` IS the Stripe Price `lookup_key`. No `price_id` appears anywhere in the repo — a resolver translates at runtime. This is Workbench's rule; the full playbook is `~/projects/itsusstudio/workbench/docs/playbooks/subscription-plan-changes.md` and is the studio source of truth. Belly calls the field `code` where Workbench calls it `plan_code`, because `Plan#plan_code` stutters.

**A meaningful change is a new code, never an in-place edit.** Different price, cadence or feature mix means a new `code`; the old entry stays marked `legacy: true` (field not yet added to `Plan` — add it with the first price change). Never edit a price in YAML while customers are on it: that retroactively rewrites what every receipt says they bought.

**Build on demand.** This design was stripped hard on purpose. `rank`, `at_least?`, a `legacy` flag, a `Billing::Configuration` object and a free `cook` plan were all built and then deleted because nothing used them yet. (The grants table and entitlement resolution were later built for real.) Each remaining one has a named trigger below. Do not reintroduce them speculatively.

**No code comments.** Project rule, applies absolutely. Reasoning goes in commit messages and in this doc.

**Never run the `op` CLI.** Secrets are the human's job. Name the exact command for them (`bin/credentials-edit <env>`) and wait.

**No commits without approval.** Every time, per commit.

---

## Phases

### Phase 1 — Stripe setup (human, blocks everything below)

- [ ] CAD is the base because it is the Canadian Stripe account's native settlement currency, which Adaptive Pricing requires. USD and EUR payments convert to CAD at payout with an FX fee; decide whether to add USD settlement (a USD bank account) to avoid that on USD sales.
- [ ] Create the Us Studio **Organization** in the Dashboard, or note a decision to defer
- [x] Sandbox products and prices are created from `config/billing_plans.yml` by `bin/rails billing:create_stripe_plans` (idempotent, refuses live keys). Done for "Belly sandbox", which development and staging share. Live products were updated by hand in the Dashboard
- [x] Sandbox: create Product `Belly Insider`, tax code `txcd_10103000` (SaaS – personal use)
- [x] Sandbox: create Product `Belly Patron`, same tax code
- [x] Sandbox: yearly Price under each, **base currency CAD**, amounts 39 and 139
- [x] Sandbox: add currency options — Insider USD 29 / EUR 25, Patron USD 99 / EUR 85
- [x] Sandbox: set `lookup_key` to exactly `insider_yearly` and `patron_yearly`
- [x] Set `tax_behavior` for **every** currency in `currency_options` — missing one makes Checkout silently fall back to the default currency
- [x] Enable Stripe Tax
- [ ] Repeat all of the above in live mode once the flow works end to end

### Phase 2 — Taking money

- [x] Add the `stripe` gem (19.6.2, API version pinned to `2026-08-26.dahlia` in `config/initializers/stripe.rb`)
- [x] Stripe keys into credentials per environment (human runs `bin/credentials-edit`)
- [ ] Price resolver: `code` → `price_id` via `lookup_key`, cached per process
- [x] Checkout Session creation — the Insider and Patron cards on the Insiders settings panel `button_to` `Dashboard::Billing::CheckoutsController#create`, which resolves the price by lookup key and redirects to hosted Checkout. The standalone checkout page was deleted. Price lookup is one API call per click, not cached yet
- [x] Pass `currency` on the session **only** when the user explicitly overrode (`BillingCurrency#chosen_currency`: toggle param or cookie); omitting it lets Checkout localize automatically
- [x] `billing_subscriptions` migration: polymorphic owner, `stripe_customer_id`, `stripe_subscription_id` (unique index), `stripe_price_id`, `plan_code`, `status`, `current_period_end` (indexed), `cancel_at` (not `cancel_at_period_end`: on API 2026-08-26.dahlia the Customer Portal schedules the end with `cancel_at` and leaves `cancel_at_period_end` false), `synced_at`
- [x] `Billing::Subscription` model with an `entitled` scope
- [x] Return handler lives at `GET /dashboard/billing/checkout_return` (`Dashboard::Billing::CheckoutReturnsController#show`), then redirects to the Insiders settings page. Return handler: `success_url` carries `session_id`, retrieve it, upsert the row, grant access immediately
- [x] Customer Portal session, linked from the info page
- [x] Portal return re-syncs that one customer

**Trap:** `current_period_end` is **no longer on the Subscription object**. It moved to subscription items in the 2025 API versions. Read it as `subscription.items.data.map(&:current_period_end).min`. The list endpoint's `current_period_end` filter is documented as matching the minimum item value. Pin the API version and leave one terse comment on that line — the next reader will try `subscription.current_period_end` and get nil.

### Phase 3 — Knowing who paid, over time

- [x] Built as `Billing::SubscriptionReconciler` (app/services/billing). Hourly `Billing::ReconcileSubscriptionsJob` runs `reconcile_changes`: it lists `customer.subscription.created/updated/deleted` events newer than a stored cursor (`billing_sync_cursors`, `ending_before`), re-fetches each changed subscription once with the pinned API version, syncs it through `Billing::Subscription.sync` (owner from the existing row or `subscription_data.metadata.user_id`), then advances the cursor to the newest event. Work scales with changes, not total subscriptions, and nothing is reprocessed. A cursor older than Stripe's 30-day event retention stops the job with a `cursor_expired` warning; `bin/rails billing:reconcile_all` (full list, then cursor reset) is the manual recovery and bootstrap. Earlier versions (bounded windows, a nightly sweep, then an hourly full list) were built and replaced. A scheduled monthly or quarterly full reconcile is an option if drift ever shows up; not scheduled yet. Each changed subscription is re-fetched one request at a time (Stripe has no bulk retrieve by ID, and Search only filters on created, metadata and status). Trigger to revisit: those requests become a noticeable cost or slow the job. Next step then: use the newest event's `data.object` when `event.api_version` matches the pinned version, and only re-fetch otherwise
- [x] (original) Hourly sync job, bounded window: `Stripe::Subscription.list(status: "all", current_period_end: {gte: 2.days.ago.to_i, lte: 1.hour.from_now.to_i}, expand: ["data.items.data.price"], limit: 100)` with `auto_paging_each`
- [x] Nightly full sweep for refunds, disputes, and local rows Stripe no longer has
- [x] Register both in `config/recurring.yml` (Solid Queue). Make the upsert idempotent and keyed on `stripe_subscription_id`
- [x] Entitlement predicate: status in `["active", "trialing", "past_due"]` **and** `current_period_end > Billing.grace.ago`. `past_due` stays entitled on purpose — Stripe retries a failed card for days and cutting someone off on day one of dunning is hostile
- [x] `user.insider?` and current-subscription lookup. Use `has_many` + a current scope, not `has_one` — someone can cancel and resubscribe and hold two rows
- [ ] `bin/rails billing:check` rake task: every plan has exactly one active Stripe Price with a matching lookup key, amount, currency, interval and tax behavior; every `plan_code` in the DB exists in the catalog. Read-only, safe in production, run before every PR and after every deploy
- [x] "You're an Insider" state on the info page, replacing the join CTA
- [ ] Tests using `Stripe::TestHelpers::TestClock` plus the `test_clock` filter on the list endpoint. This is the whole reason polling is easier to be conservative about — advance a clock, run the job, assert the row changed
- [ ] Ask the human before adding any system test

**Expand the price** in the list call and read `lookup_key` straight off it. Workbench needs a separate resolver call for inbound webhooks; the polling design gets inbound resolution for free.

### Phase 4 — Deliver what the copy promises

The Insiders panel promises perks that do not exist. Either build them or cut the bullets before launch. Gift years were already cut from the copy.

- [ ] **Insider and Patron app icons and badges** — the only concrete unbuilt perk named in the copy. Native work in both shells (iOS alt icons, Android activity-alias) plus the in-app badge
- [ ] Decide what **"a say in what we build next"** and **"priority support from the makers"** mean operationally. Both are ongoing obligations to people paying CAD 139/yr with no natural end. Define them or cut them
- [ ] Beta channel — TestFlight external and Play internal. Process, not code
- [ ] Build notes page, Insider-gated
- [ ] Gift years: the `billing_grants` table and `Billing::Grant` (with an `active` scope) exist; gift code issuance and redemption do not. Original spec: `billing_grants` table (polymorphic owner, `plan_code`, `reason`, `expires_at`, `revoked_at`, `granted_by`, `note`), gift code issuance and redemption. A gifted Insider carries `plan_code: "insider_yearly"` with `reason: "gift"` — same entitlement, same badge, no parallel definition
- [x] Grants get **no grace period**. Grace covers Stripe dunning and sync lag, neither of which applies to something you handed out
- [ ] Supporters page, if keeping that bullet
- [ ] AI allowance metering — blocked on the open decision below. This is a usage counter keyed by user and period in its own table, NOT a billing row

### Phase 5 — IAP

- [ ] Read Joe Masilotti's free deep dive: <https://newsletter.masilotti.com/p/hotwire-native-deep-dive-in-app-purchases>
- [ ] Decide: PurchaseKit (<https://purchasekit.com>, hosted, drop-in bridge components for both platforms, normalizes Apple and Google webhooks, works standalone without the Pay gem) vs RevenueCat (mature, no Hotwire bridge, write it yourself) vs hand-rolled StoreKit 2
- [ ] Note PurchaseKit puts a third party in the revenue path and is young — assess maturity before it becomes load-bearing
- [ ] StoreKit bridge component, web-rendered paywall firing a native purchase
- [ ] Play Billing for Android
- [ ] Reconcile a second subscription source into the same mirror
- [ ] Remove or relax the native gating — `feature_enable_insiders_memberships_native` already covers this, nothing structural changes

### Phase 6 — Ops and comms

- [ ] Renewal reminder emails. Stripe sends anniversary notices before the 6- and 12-month marks for AU and UK customers and at 12 months elsewhere; confirm what is required versus what you want to send
- [ ] Refund policy — a stated 14-day no-questions window is cheaper than chargebacks
- [ ] Auto-renew on by default with a pre-charge email. Silent annual charges generate disputes
- [ ] Email campaign to existing users. **In phase 1 this is the actual conversion channel**, not the card
- [ ] `usebelly.app/insiders` on the marketing site
- [ ] Plan for the renewal cliff: everyone who joins at launch decides again the same week next year

---

## Open decisions

- [ ] **AI metering on the free tier.** Never answered. The import-allowance bullets have since been removed from the copy, so this is now a product decision rather than a launch blocker
- [x] **Geo currency detection.** Built as the `BillingCurrency` controller concern: `?currency=` param (remembered in the `billing_currency` cookie), then the cookie, then `Billing::Currency.for_country(CF-IPCountry)`, then `Billing::Currency::DEFAULT` (CAD). `for_country` maps CA → CAD, 21 eurozone codes → EUR, any other known country → USD, and unknown (`XX`, `T1`, blank) → nil. Whether `CF-IPCountry` actually reaches the app in production is still unconfirmed
- [ ] **Supporters page.** Promised in the Patron tier copy, does not exist
- [ ] **Perk scope.** Roadmap voting and an open call were deliberately dropped from the copy because they become obligations owed forever. Confirm they stay out

---

## Triggers for things deliberately not built

| Not built | Bring it back when |
|---|---|
| `rank` on Plan | Catalog order stops being sufficient — `User#insider_plan` relies on `rfind` over `Catalog.plans` |
| `at_least?` | The first gated feature |
| Nightly or periodic full sweep | The event cursor proves insufficient. `billing:reconcile_all` exists for manual recovery |
| `legacy` flag on Plan | The first price change |
| `Billing::Configuration` object | A second app needs different wiring |
| Free `cook` plan in the catalog | Entitlement needs to return a Plan rather than nil, or a comparison grid wants one loop |
| `plans.freeze` | Already back — `Catalog.plans` memoizes a shared array |
| The `money` gem | A zero-decimal currency (JPY, KRW) breaks the `× 100` assumption, or the pricing page needs per-locale symbol placement |
| The `countries` gem | Never for this. The ISO check is the wrong check — you need "currencies we accept", which no gem knows |

---

## Gotchas worth not rediscovering

- **`current_period_end` is no longer on the Stripe Subscription object.** It moved to subscription items in the 2025 API versions; read it from `items.data`.
- **Catalog order is tier order.** `User#insider_plan` uses `rfind`, so a new tier goes in the right position in `billing_plans.yml`.
- **`Dashboard::Billing` shadows `Billing`** under nested-module definitions. Belly uses compact class style so it resolves correctly, but `Dashboard::Billing::CheckoutsController` writes `::Billing` explicitly so it cannot break later.
- **Duplicate ids.** The callout card uses `data-insiders-callout`, not an id, because the add modal can render over the recipes index and both copies would be in the DOM.
- **Flipper strict mode raises** in development and test (`config.flipper.strict = :raise`). Any new flag must be added to `config/feature_flags.yml` and `bin/rails flipper:sync` run, or `Flipper.enabled?` raises.
- **Checkout has no currency picker.** Stripe auto-detects location; passing `currency` on the session *disables* that localization. The picker belongs on your own page.
- **Testing currency presentment** needs no VPN — pass `customer_email: "test+location_FR@example.com"`.
- **Subscription currency is fixed for life.** Someone who joins in CAD stays in CAD. Changing means cancel and resubscribe.
- **Stripe's `mask`/shorthand and Lightning CSS** reorder `animation` shorthand in the built Tailwind — grep for `infinite <name>`, not `<name> 6s`, when checking a build.
- **The automation browser tab is backgrounded**, so `document.timeline.currentTime` is frozen and CSS animations never advance. You cannot verify motion from Claude-in-Chrome; measure geometry instead and have the human watch.
- **Port 3000 may be Workbench**, not Belly. Check before assuming a running server is the right app. Belly's dev host is `http://app.belly.localhost:3000`.

---

## Brand values for Stripe branding settings

Converted from the oklch tokens in `monoform/global.css`, so they drift if those change.
Brand colour `#16100B` (`--primary`), accent `#0A441A` (`--brand-foreground`), background
`#F7F2EE` (`--background`). Icon: the flower, square, rendered from
`server/app/assets/images/belly-flower.svg`. Logo: `marketing/frontend/images/belly-wordmark.png`.

---

## Reference

- In-repo playbook: `docs/stripe-setup.md`
- Workbench playbook (studio source of truth): `~/projects/itsusstudio/workbench/docs/playbooks/subscription-plan-changes.md`
- Workbench catalog for comparison: `config/subscription_plans.yml`, `app/models/subscriptions/plan.rb`, `app/models/subscriptions/plan_catalog.rb`
- Gary Bernhardt on operational simplicity: <https://changelog.com/shipit/62>
- Glass membership (tier naming precedent): <https://glass.photo/membership>
- Lunch Money pricing (Canadian indie, multi-currency, PWYW annual, price lock): <https://lunchmoney.app/pricing>
- Stripe Organizations: <https://docs.stripe.com/get-started/account/orgs>
- Stripe manual currency prices: <https://docs.stripe.com/payments/checkout/localize-prices/manual-currency-prices>
- Stripe Adaptive Pricing: <https://docs.stripe.com/payments/currencies/localize-prices/adaptive-pricing>
- Stripe Managed Payments (for the record, not in use): <https://docs.stripe.com/managed-payments>
