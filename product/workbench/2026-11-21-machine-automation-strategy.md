# Machine automation strategy, 2026-11-21

How Workbench uses AI, machine learning and plain automation, from an MCP server to Ramp-style intake. Written as advice; the founders decide.

## Vision

The operator never has to type. A job arrives in whatever form it already exists (paper, photo, email, voice), the machine fills it in, and a person approves.

Ramp won finance teams this way: receipts arrive by text or email, Ramp fills them in and matches them, and a human approves in one tap. Workbench does the same for repair and custom jobs.

This is how Workbench delivers its position, "the back office that runs itself" (`2026-11-21-brand-positioning.md`). Every opportunity below passes one test: does it remove a step the operator does by hand? Photo intake is the launch moment for that position.

## Evidence

- Lost deals in the field: shops said manual data entry was too slow, especially with people waiting in line. (Founders' account. Write down which shops and when.)
- Jewellery Clinic Wholesale (Willy) got excited about taking in jobs from a photo of the store's paper form.
- Same shop, measured: about 25 jobs a day on an iPad (PostHog 2026-11-07 to 2026-11-20 shows about 33 a day, about 990 a month), median intake 109 seconds, 95% of it in the photos step.
- Willy asked to stop filling in paper forms, and for the ordering store and its reference number on each job.
- Some shops say they use ChatGPT or Claude every day. (How many: unknown.)
- Wholesale shops get many orders from the brands and stores they work for, and staff type each one into Workbench by hand, one at a time. Volume is the pain: every order means retyping what the brand already wrote on its form or email. This is why stacks of forms (2) and the forwarding email address (4) matter most for wholesale.

Conclusion: slow intake is the objection that loses deals. Automation is a sales tool as much as a feature.

## Principles

1. **Ship with AI, harden what gets used.** Use a language model to ship a feature fast and learn whether shops want it. Once a feature gets real use, replace the busy parts with deterministic code or proven machine learning (OCR, barcode reading, rules, per-store form templates) wherever that is cheaper, faster or more reliable. AI is for learning quickly; deterministic code is for running at scale.
2. **Deterministic first where the answer is already known.** Reading a QR code, matching a customer by phone or email address, setting a due date from the shop's rules: no AI needed.
3. **AI drafts, people approve.** Nothing goes live and nothing reaches a customer without a person. The jeweller does the talking.
4. **Every feature removes a step we can measure**, so it can be priced fairly.
5. **Never lose money on tokens.** Where the shop brings its own model (MCP), our cost is near zero. Where we pay for the model: a monthly allowance in the plan, credits beyond it, a firm cap, and the token cost of every feature logged from day one (studio `llm-features` conventions).
6. **Speed is the feature.** Everything feels instant: save before the server answers, keyboard shortcuts, no loading screens (see the speed decision in `sarahbijoux.md`).

## Take it in now, finish it later

The line problem is that the customer waits while staff type. Split intake in two:

1. **At the counter, about 10 seconds**: photograph the piece or the store's form, pick or type the customer's name, hand over the stub. The customer leaves.
2. **Afterwards, away from the customer**: the machine drafts item, metal, stones, condition, the work to do and the due date. Staff check and approve when the line is gone.

Even with no AI at all, a quick take-in that is finished later shortens the line. AI then removes the finishing work.

## Opportunities

Ranked by evidence and value. "Start with" is the fast first version, "Harden to" is what busy parts become.

### Ways a job arrives

| # | Opportunity | Start with | Harden to | Priority |
| --- | --- | --- | --- | --- |
| 1 | Photo of the store's paper form becomes a draft job: store matched, reference number, item, work | Vision language model | OCR plus a template per store's form | First |
| 2 | Stack of forms: photograph the day's forms, get a draft per form to approve | Same, in a batch | Same | First, right after 1 |
| 3 | Quick take-in at the counter (photo plus name, finish later) | Plain product work, no AI | n/a | First, ships with 1 |
| 4 | Forwarding email address per shop (`jobs@shop.useworkbench.ca`): forward an enquiry or a store's order, get a draft job with the customer matched | Language model reading the email | Rules for repeat senders and formats | Second |
| 5 | Text a photo to the shop's number, get a draft job | Same pipeline as 1 | Same | After US texting registration (A2P 10DLC) |
| 6 | Voice: "14k yellow gold ring, size 6 to 7, re-tip four prongs, needed Friday" becomes a filled-in job | Speech-to-text plus a language model | A dedicated speech model, field rules | Third |

### Filling it in

| # | Opportunity | Start with | Harden to | Priority |
| --- | --- | --- | --- | --- |
| 7 | Item details from photos of the piece: type, metal, stones, draft condition notes (also protects the shop in damage disputes) | Vision language model (plan: `workbench-photo-intake-llm.md`) | Smaller trained classifier for common types | First |
| 8 | Matching: existing customer instead of a duplicate; a piece seen before ("sizing in March") | Deterministic (phone, email address, name), model for fuzzy cases | Deterministic plus image similarity | Second |
| 9 | Suggested price and due date from the shop's own history | Rules from past jobs | Statistics per work type | Second |

### After the job is in

| # | Opportunity | Start with | Harden to | Priority |
| --- | --- | --- | --- | --- |
| 10 | One place to approve every draft, one tap or keystroke each | Product work | n/a | First, everything needs it |
| 11 | Morning summary: stalled, due today, waiting on the client | Deterministic queries, model writes the summary | Deterministic template | Second |
| 12 | Search in plain words ("Mrs. Chen's emerald ring from the summer") | Language model turns words into filters | Search index with synonyms | Third |
| 13 | Message drafts with the job details, in the client's language (French or English). The jeweller sends. | Language model | Templates for common messages | Second |
| 14 | Scan the stub at pickup to open the job | Deterministic QR | n/a | With QR supplies (`2026-11-21-supply-store-strategy.md`) |
| 15 | Find the part in the family parts business's catalogue and draft the order | Language model plus catalogue search | Catalogue search with part numbers | Later |
| 16 | "Is my ring ready?" answered from the job's status, by text or portal, opt-in only | Deterministic status lookup, model for wording | Deterministic | Later, opt-in |

## The agent ladder

From lowest barrier to highest. Each step helps the next.

| Step | What | Money | Recommendation |
| --- | --- | --- | --- |
| 1. Readable by agents | `llms.txt`, `/ai-info`, a complete help centre | Acquisition, not revenue | Mostly done. Keep facts current. |
| 2. MCP server | Shops connect ChatGPT or Claude to Workbench: what's overdue, draft an update, monthly counts | Their subscription pays for the model; near-zero cost. In paid plans, maybe Scale only later. Also a discovery channel through connector directories. | Early. Read-only tools first, then confirmed writes (add a note, change a status). Never send to customers from MCP. One server covers ChatGPT and Claude. Sign-in through OAuth: check whether studio-auth can be the provider. Every request scoped to the shop, rate-limited, logged. |
| 3. API and webhooks | Outside access for the Shopify app, Zapier and other businesses' agents | Included | After MCP, shares its foundation |
| 4. AI inside Workbench | Opportunities above, intake first | Allowance in the plan, credits beyond, firm cap | The main bet |
| 5. Background agents | Morning summary, drafted messages, suggested quotes, part orders, all approved by a person | Add-on or top plan, priced on time saved | After intake proves itself |
| 6. Agents talking to agents | A store's agent sends a job to a trade shop's agent, which accepts and sets the due date. The trade network loop, run by machines. | Future | Too early. Steps 2 to 5 make it possible. |

Before building MCP tools, ask the shops that use ChatGPT or Claude every day: "What do you use it for in your shop today?" Likely answers (customer messages, product descriptions, captions, pricing, French and English translation) become the first tools.

## First bet: photo intake at Jewellery Clinic Wholesale

- Build: quick take-in (3), paper form photo to draft (1), stacks (2), item details from piece photos (7), one place to approve (10). Behind a flag.
- Before building: get photos of 10 real store forms from Willy, and agree what must be captured while the customer is still at the counter (name, phone, deposit, signature).
- Metric: counter time per job (the customer's wait). Baseline about 109 seconds. Target under 20.
- Second metric: share of drafts staff approve without changes.
- Stop rule: if counter time doesn't halve, or staff rewrite most drafts, stop and rethink before rolling out.
- Then: call back the shops lost over manual entry and show them.

## Deliberately out of scope

- Anything sent to a customer without a person approving it.
- Benji as a general chat assistant before single-job features prove themselves. It costs tokens and its value is hard to measure.
- Training our own models before a feature has real use.
- Agent-to-agent work between shops for now.

## Open

- Which deals were lost over manual entry: shops, dates, what they said. Owner: founders.
- How many shops use ChatGPT or Claude daily, and for what. Owner: founders.
- Whether studio-auth can act as an OAuth provider for MCP. Owner: Emmanuel.
- Plan allowance and credit price for AI features, once costs per job are measured. Owner: founders.
- Write the first bet as a spec in `~/notes/plans/`. Owner: Emmanuel.
