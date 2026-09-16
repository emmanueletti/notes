# SMS Provider DX for Canadian SMBs — Strategy Doc

**Status:** exploration / not committed
**Date:** 2026-05-07
**Author:** Emmanuel
**Context:** Triggered by repeated friction onboarding to SMS providers as a Quebec-based Rails SaaS founder running Workbench (IT'S US STUDIO).

---

## 1. The trigger

Workbench needs a working SMS path (transactional notifications, appointment reminders, job-ready pings, with hardcoded STOP/HELP append for compliance). Twilio is the incumbent. Two complaints have surfaced together:

1. Twilio's admin console is bloated and hard to navigate.
2. Twilio's US A2P 10DLC registration keeps failing, with no clear path to human support.

A "switch providers" reflex turned into a multi-hour evaluation that hit walls at every dev-forward alternative. The walls themselves are the most useful artifact of the exercise — they reveal a real market gap.

---

## 2. What actually happened

| Provider | Outcome | Failure mode |
|---|---|---|
| Twilio | Incumbent | 10DLC rejection, admin pain, no human support path |
| Telnyx | Abandoned at signup | "Account Levels Upgrade" required LinkedIn or GitHub OAuth + confusing AI-credit reset language |
| Plivo | Region-blocked | "Signup is not available in your region at this time" — Canada blocked |
| SignalWire | Phone-verify rejected | SMS verification refused for Canadian mobile (`+1 604`); voice fallback offered but not attempted |

Each wall was *different*. None were "Canadian businesses can't use this provider" — all were anti-fraud trial-signup gates that misfire on the signature *Quebec-based solo founder + Canadian mobile + free trial*.

---

## 3. Why the friction is structural, not provider-specific

- **Regulatory transition.** US (TCR / 10DLC) and Canada (CWTA registration, CRTC STIR/SHAKEN) are mid-rollout. Providers are still calibrating their compliance + fraud responses.
- **Canadian VoIP fraud signature.** Solo Canadian-mobile-number trial signups are a known fraud-ring pattern. Providers err on the side of blocking.
- **Self-serve trial is the wrong door.** Real Canadian businesses get on these platforms via sales-led onboarding, voice verification fallback, or non-phone-verification providers (AWS). Self-serve trial flow is not built for our profile.
- **The dev-forward providers most aggressively gate signups** — because they have the smallest fraud-loss tolerance. Ironic but consistent.

---

## 4. Remaining real options for Workbench

Filtered to: accepts Canadian businesses, viable for a Rails SaaS, not enterprise sales-only.

### Top picks

- **AWS End User Messaging (formerly Pinpoint SMS)**
  - Available in `ca-central-1` (Montreal)
  - IAM + credit card auth (no phone-verify gate)
  - Supports US 10DLC and Canadian SMS
  - Ruby SDK: `aws-sdk-pinpointsmsvoicev2`
  - Trade-off: no `Messaging Service` abstraction, more glue code, AWS console admin

- **Twilio (resubmit 10DLC)**
  - The actual problem is almost certainly a fixable TCR submission (EIN/legal-name mismatch, weak campaign description, missing opt-in evidence, or sample-message content review failure)
  - Twilio's regulatory ticket queue is a real human path
  - Toll-free verification is an alternate path with a different (often easier) review

- **ClickSend**
  - Australian, owned by Sinch
  - Available in Canada, supports US 10DLC
  - Self-serve, simple admin (less power, more findable)
  - Ruby SDK exists; webhook ergonomics weaker than competitors

### Worth trying, with caveats

- **SignalWire via voice verification** — Twilio-compatible API, lowest migration cost; the phone-verify wall was a fraud filter, not a region block
- **Vonage / Nexmo** — available in Canada but admin no better than Twilio's

### Skip

- **Bird (formerly MessageBird)** — mid-rebrand chaos
- **Telesign** — enterprise 2FA focus, overkill
- **TextMagic / SimpleTexting** — marketing-blast oriented, not transactional SaaS
- **Bandwidth, Sinch direct, Infobip, LINK Mobility** — sales-led only

---

## 5. The startup question

> *"How hard is it to launch a startup that is SMS messaging aimed at developers and technical SMBs in Canada?"*

**Hard. Capital-intensive. Slow margins. But the wedge is real.**

### What you'd actually be building

Not telecom infrastructure. A **DX layer + compliance-handling service** on top of someone's wholesale carrier-direct API (Bandwidth, Sinch, Telus/Rogers wholesale). 95% of "SMS providers" are doing this. Differentiation = onboarding, admin, support, billing, compliance.

### Regulatory ceiling

This is where most attempts die:

- **CWTA registration** — to send to Canadian numbers at scale, register as a CSP or contract through one. Months, lawyers, ~$15–30k.
- **TCR / 10DLC (US)** — same gauntlet, but now you run it for customers. A 10DLC concierge desk *is* the value prop.
- **CASL** — Canadian anti-spam law, more aggressive than US TCPA. Penalties up to $10M/violation. You become liable for downstream sender behavior.
- **Quebec Bill 96** — French-first customer-facing copy required. Few US providers handle this — real moat for a Quebec-based founder.
- **PIPEDA** — Canadian privacy law. Standard SaaS hygiene.
- **Fraud / KYC** — every gate I just hit exists because Canadian VoIP fraud is expensive. I'd inherit that problem.

12–18 months of regulatory + carrier setup before the first paying customer at real volume.

### Economics

- Wholesale CA SMS: $0.003–0.006 per message. Retail: $0.01–0.03. 3–5x markup, fractions of a cent.
- Real revenue requires millions of messages/month.
- SMS category is roughly flat; iMessage/RCS/WhatsApp/in-app push eat discretionary use cases. Transactional SMS is durable but slow-growing.
- Canadian SMB software market is ~5–7% of NA. Niche-of-a-niche.
- Realistic capital to launch credibly: **$300k–$1M.**
- Realistic time to ramen-profitable: **2–3 years.**
- Realistic exit: lifestyle business at $2–10M ARR, or acquisition by Sinch/Bandwidth/a Canadian telco.

### Where the wedge actually is

Don't compete on "SMS API." Compete on the things that just burned me:

1. **Onboarding that doesn't humiliate Canadian founders.** No SMS-verify, no LinkedIn OAuth, no AI-credit theater. Stripe-quality signup.
2. **TCR/CWTA concierge as a service.** Flat fee + per-message. Most defensible piece — painful, recurring, incumbents are bad at it.
3. **Opinionated DX.** Postmark-for-SMS. One way to send, sane defaults, gorgeous logs, real webhooks. Rails-first SDK.
4. **French-first / Quebec-compliant by default.** No incumbent does this well. Free differentiation for a Quebec founder.
5. **Human support in Canadian timezones.** Hours, not days.

---

## 6. The OSS-vs-SaaS split

I initially conflated two products. Untangling:

### What an OSS library *can* legitimately do

- Provider-agnostic interface (`ActionSMS`-style) — Twilio, AWS, SignalWire, ClickSend behind one API. Swap in config, not code.
- Compliance ergonomics in code: STOP/HELP append, opt-out tracking models, audit-log generation, idempotency keys, retry-with-jitter, webhook signature normalization. *Not* regulatory itself — code that proves compliance later.
- French-first / locale-aware templating. Quebec Bill 96 at the rendering layer.
- Rails-native primitives: ActiveJob integration, ActionMailer-style class-based message definitions, fixtures, Rake tasks for opt-out reconciliation.
- Provider-migration tooling: CLI that diffs usage and flags breakage. Lowers switching cost — direct attack on incumbent lock-in.

### What an OSS library *cannot* do

- TCR / CWTA registration
- KYC / underwriting
- Carrier contracts
- Fraud risk on inbound numbers
- Per-message cost

### The open-core split

Same playbook as Postmark, Linear, Plausible:

- **OSS library** = lead-gen + credibility + community. Proves domain expertise. Becomes the default mental model for "SMS in Rails (Canadian edition)."
- **Paid SaaS layer** = regulatory + operational concierge. Filing TCR/CWTA on customers' behalf. Managed multi-provider endpoint with auto-failover. Carrier rejection handling. Flat fee + per-message.

The regulatory pain *is* the moat. You can't OSS it because the value is the human team + legal entity + carrier relationships.

---

## 7. The "I can't even sign up" objection

Building DX for providers I can't sign up for sounds incoherent. Resolution:

- The walls hit are **trial-signup fraud gates**, not "Canadian businesses can't use this provider." Real businesses use these every day.
- Real-business paths: sales-led signup, voice verification, AWS-style IAM auth, or being a paying customer from day one.
- **Don't need accounts on every provider to build a multi-provider library.** Need:
  - One production provider to dogfood. Already have Twilio.
  - One alternative adapter. AWS End User Messaging is closest.
  - Public API docs for the rest. All providers publish complete refs.
  - Community PRs for adapter coverage. Standard OSS pattern.
- The lived experience of bouncing off four providers' onboarding **is the credibility**. The library exists *because* of that pain.

---

## 8. Decisions

### Now (this week)

- **Unblock Workbench's SMS path.** Two viable moves:
  - **Option A:** Resubmit Twilio TCR with corrected campaign description. Capture exact rejection reason from the registration ticket. Fix EIN/legal-name match, opt-in evidence, sample-message copy. Hours of work, no migration cost.
  - **Option B:** Sign up for AWS End User Messaging in `ca-central-1`, build adapter, migrate. Larger effort but routes around all consumer-grade fraud gates.
- **Default: Option A first**, since migration cost is real and the rejection is almost certainly fixable. Option B becomes the fallback if the second TCR submission also fails.

### Soon (next 1–3 months)

- Whichever provider wins, **document every gross spot in the SMS code path**. Those gross spots are the future library's spec.
- Build the abstraction the *third* time the same code is written, not the first. No premature library.
- Continue noting Quebec/Canada-specific friction (locale, opt-out wording, CASL audit trail).

### Later (6–12 months)

- If the Workbench SMS code has stabilized into a clean abstraction worth sharing, extract it as an OSS gem under the Studio name with a clear README.
- Use Workbench as the dogfood. Don't market it. Let other Canadian Rails SMBs find it organically.
- Re-evaluate the SaaS concierge layer only if the OSS layer shows traction with real users (not just stars).

### Not now

- **Do not start a Canadian SMS startup as a primary venture.** 12–18 months of regulatory ramp + capital intensity + slow-margin commodity input + competition with well-funded incumbents. Workbench has clearer unit economics and domain defensibility.
- **Do not pivot Workbench resources to this.** It is a side observation, not a roadmap item.

---

## 9. Open questions

- What is the actual TCR rejection reason on the existing Twilio submission? (Pull from registration ticket; resubmit informed.)
- Does Workbench already need French-first SMS templating for existing Quebec customers, or is that hypothetical?
- Is toll-free verification a viable parallel path while 10DLC is in flight?
- If AWS becomes the primary, what's the minimum-viable Canadian SMS routing setup (long code vs short code vs toll-free)?

---

## 10. Reference

- US registration: The Campaign Registry (TCR) — brand + campaign vetting for 10DLC
- Canada registration: CWTA (Canadian Wireless Telecommunications Association) registry
- Canadian privacy: PIPEDA
- Canadian anti-spam: CASL — applies to SMS, not just email
- Quebec language: Bill 96 / Charter of the French Language — applies to commercial messaging to Quebec residents
- Voice authenticity (related, not SMS): CRTC STIR/SHAKEN
