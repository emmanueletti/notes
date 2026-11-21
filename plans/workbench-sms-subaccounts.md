# Workbench SMS: dedicated numbers on Twilio subaccounts

Status: design, not scheduled. Written 2026-11-03.

## Goal

Every repair shop texts its customers from its own phone number, registered to its own business, without any shop's traffic or reputation affecting another. Workbench handles the Twilio setup and carrier registration for the shop, the way Jobber does.

Today every shop sends from one shared Workbench number (one Messaging Service, credentials in `config/initializers/twilio.rb`). A STOP or carrier complaint against that number hits every shop, and a single A2P registration can't honestly describe many unrelated businesses.

## Shape

One Twilio subaccount per shop, owned by the Workbench parent account (Workbench is the ISV).

Inside each subaccount:
- one Messaging Service
- one or more phone numbers in that service
- the shop's Trust Hub records: Secondary Customer Profile, A2P TrustProduct, Brand registration, Campaign (US A2P 10DLC only, see Canada below)

Why subaccounts:
- Isolation. Suspension, spam flags or a bad campaign stay inside one shop.
- Usage per shop comes straight from Twilio's per-account usage, which per-shop billing needs.
- Closing a shop means closing its subaccount, and its numbers and records go with it.
- It's the structure Twilio's ISV onboarding assumes.

Cost: one more set of credentials per shop and an onboarding pipeline with several async approval steps.

## Data model

### SmsSender

Who a message goes out from. Every send resolves to exactly one sender.

| Column | Notes |
|---|---|
| repair_shop_id | null means the shared platform sender |
| kind | platform, dedicated |
| status | draft, provisioning, pending_registration, active, suspended, closed |
| twilio_account_sid | subaccount SID (parent SID for platform) |
| twilio_auth_token | encrypted with Active Record encryption |
| messaging_service_sid | |
| phone_number | E.164 |
| activated_at, suspended_at, closed_at | |

Resolution: `repair_shop.active_sms_sender || SmsSender.platform`. While a shop's dedicated sender is still registering, it keeps sending from platform.

### SmsSenderRegistration

One row per registration attempt, so rejections and resubmits have history.

| Column | Notes |
|---|---|
| sms_sender_id | |
| step | customer_profile, trust_product, brand, campaign |
| twilio_sid | BU..., BN..., QE..., etc. |
| status | mirrors Twilio's status for that object |
| failure_reason, error_codes | from Twilio evaluations and rejections |
| submitted_at, approved_at, rejected_at | |

### BusinessProfile on the shop

Brand registration needs legal business name, business type, tax ID (EIN or Canadian BN), registered address, website, authorized representative name, title, email address and phone. Store these on a `RepairShopBusinessProfile` that the shop fills in during onboarding. The address must match the registration documents, which is the same issue Twilio raised about the Quebec move.

### Already planned (from the patch and the foundation work)

- `SmsMessage` ledger with `sms_sender_id` on every row
- `SmsOptOut` scoped by `sms_sender_id`. A STOP to a shop's dedicated number opts that customer out of that shop only. STOPs recorded against the platform sender stay platform-wide.

## Onboarding flow

What the shop sees:
1. Settings → Text messaging → "Get your own number"
2. Fill in business details (prefilled from the shop record)
3. Pick a number by area code
4. Status screen: "Setting up", "Waiting on carrier approval", "Live", or "Needs changes" with the reason and a way to fix and resubmit
5. Until "Live", texts keep going out from the shared Workbench number, so nothing breaks

What runs behind it, each step its own idempotent job that stores the Twilio SID before moving on:
1. Create subaccount, store SID and encrypted auth token
2. Create Secondary Customer Profile, attach business info, authorized reps, address. Evaluate, then submit
3. Create A2P TrustProduct, attach profile, evaluate, submit
4. Create BrandRegistration (Standard or Low-Volume Standard based on expected volume). Fees apply here
5. Wait for brand APPROVED (status callback plus a polling fallback; Twilio says to contact support after 2 days IN_REVIEW)
6. Create Messaging Service with inbound and status callback URLs pointing at Workbench
7. Create the Campaign (UsAppToPerson) with use case, description, message flow, samples. Message samples come from the shop's real notification templates
8. Buy the number and add it to the Messaging Service
9. Campaign approved → sender `active`, shop switches over

Rules:
- One Brand/Campaign API request per second across all shops (Twilio rate limit). Run those jobs through a single concurrency-limited queue.
- Every step checks for an existing SID before creating, so a retried job never creates a duplicate brand or buys a second number.
- Registration status changes are pushed to the shop in-app and by email address on file.

## Webhooks

- Message status and inbound endpoints are shared by all senders. The Messaging Service in each subaccount points at the same Workbench URLs.
- Signature check: read `AccountSid` from the payload, load the matching `SmsSender`, validate with that sender's token. Unknown AccountSid → 403.
- Trust Hub and brand status callbacks go to a separate `/webhooks/twilio/registrations` endpoint, same verification, which updates `SmsSenderRegistration`.
- Store every verified payload in `TwilioWebhookEvent` before processing, for replay and audit.

To verify in a spike: whether subaccount webhooks are signed with the subaccount's auth token or the parent's. The docs don't say clearly. Twilio's newer signing keys (public beta) might let us use one key for all subaccounts, which would avoid storing per-shop tokens just for webhooks.

## Canada

Most Workbench traffic today is Canadian number to Canadian number. A2P 10DLC is a US program, so CA to CA traffic doesn't need brand and campaign registration. A Canadian shop texting US customers does.

Plan: a shop's sender only runs the registration steps when the shop texts US numbers (or always, if Twilio support says Canadian carriers are moving the same way). Confirm the current Canadian rules with Twilio before building, since this is the biggest effect on onboarding time.

## Billing

- Pass through or bundle: number rental (monthly), registration fees (one time per brand and campaign), per-segment message cost
- `SmsMessage.segments` and `price` give per-shop usage; reconcile monthly against the subaccount's Twilio usage records
- Decide pricing before building the onboarding UI, since the UI has to show it

## Migration from the shared number

- New shops: offer a dedicated number during onboarding, platform sender until live
- Existing shops: opt in from settings. No forced cutover
- When a shop's customers move to a new number, send one heads-up text from the old number ("We now text from 204-xxx-xxxx") so replies and STOPs land on the right number
- Opt-outs against the platform sender carry over to the shop's new sender. A customer who said STOP shouldn't start getting texts because the number changed

## Phases

1. Spike: create one subaccount by hand, register a test brand, confirm the webhook signing question and Canadian rules
2. `SmsSender` with platform row, sender resolution in the send path (part of the foundation work)
3. Business profile form and the provisioning job chain, behind a feature flag, run by Houston admins for one pilot shop
4. Shop-facing onboarding and status screens
5. Billing and usage reporting
6. Migration offer to existing shops

## Open questions

- Subaccount auth tokens: store encrypted per shop, or act on subaccounts with parent credentials and use signing keys for webhooks?
- Does Workbench pay registration fees up front, or does the shop?
- Sole proprietor shops without a tax ID: support the Sole Proprietor brand type, or require a registered business?
- Two-way texting: is a shared inbox in the dashboard part of this launch, or later?

## References

- [A2P 10DLC ISV API onboarding](https://www.twilio.com/docs/messaging/compliance/a2p-10dlc/onboarding-isv-api)
- [Webhook security](https://www.twilio.com/docs/usage/webhooks/webhooks-security)
- [Webhook signing keys](https://www.twilio.com/docs/usage/webhooks/webhook-shared-keys)
- [API best practices](https://www.twilio.com/docs/usage/rest-api-best-practices)
- Jobber links in the TODO at the top of `app/models/customer.rb`
