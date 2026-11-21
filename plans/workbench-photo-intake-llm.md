# Workbench: fill the intake form from a photo

2026-11-20. Feasibility scope, not a spec yet.

## Verdict

Feasible, cheap and mostly built already. Belly runs the same pattern in
production (photo of a recipe in, structured fields out, Haiku 5.5) for about
0.1 cents a call. On Haiku 5.5 a Workbench job would cost 0.07 to 0.17 cents.
At current traffic, every shop together would cost $1 to $3 a month. The real open question is
product, not cost: what shops would photograph, and how much time it saves.

## Open question to settle first

Jewellery Clinic (Wholesale), shop 8, is our best test bed. Their median intake
is 109s, but the details step is only 16s and the photos step is 104s
(PostHog, 14 days to 2026-11-18). Reading a paper slip saves at most those 16s
for them. Two versions of the feature use the same pipeline:

1. Photo of paperwork (the Ramp receipt pattern): a store's take-in slip or
   envelope fills client, reference (their "RCM"), work needed and notes. Only
   worth it if shops really receive paper with each job.
2. Photo of the piece: the photos they already take fill piece, metal, stones
   and condition. Adds no extra step, because the photo is taken anyway.

Ask Willy (shop 8) whether stores send paper with each job, and what's on it.
Owner: to be named. If the answer is no, build version 2 first.

## Traffic (PostHog, project 718224)

Raw SQL over `intake_completed` and `job_photo_upload_finished`, 2026-11-07
to 2026-11-20 (13.5 days, all the data the project has).

- 713 intakes across 11 shops, always 1 item per intake. That's about 1,580
  a month.
- Shop 8 alone is 409 (57%), about 910 a month. The next five shops do 25 to
  83 each, about 110 a month for a typical shop.
- Photos per intake (property only exists since 2026-11-19): shop 8 adds
  photos to 47 of 48 intakes, 5 photos each on average. Other shops add 0 to 2,
  and most of their intakes have none.
- Uploads average 0.5 to 1.1 MB after the browser shrinks them.

## Cost

Per call: a system prompt plus the shop's form schema (about 1,500 tokens) and
about 600 output tokens with thinking off or at low effort. Each photo sent at
1568px on the long edge is about 2,400 tokens, or about 1,000 at 1024px.
Prices from the Anthropic pricing table cached 2026-11-03, matching the Belly
research note fetched 2026-11-05. Haiku 5.5 is $0.10 in and $0.50 out per
million tokens. Sonnet 5.5 is 20 times that.

| Version | Per job (Haiku) | All shops a month (Haiku) | All shops a month (Sonnet) |
|---|---|---|---|
| Paperwork, 1 photo at 1568px | $0.0007 | $1.10 | $22 |
| Piece, 5 photos at 1024px | $0.0010 | $1.50 | $30 |
| Piece, 5 photos at 1568px | $0.0017 | $2.60 | $52 |

Shop 8 is a little over half of each figure. A typical shop costs under
$0.20 a month on Haiku and $1.50 to $3.50 on Sonnet. Allow 1.5 times for
retakes and retries. Cost doesn't constrain this feature at today's traffic or
at 10 times it, so the eval decides the model. Handwriting is where Haiku might
fall short, and Sonnet as a fallback for unclear photos would still keep the
average close to the Haiku column.

Usage suggests version 2 fits shop 8 best: they already shoot 5 photos per job,
so the input for the model is there with no extra step. Other shops rarely add
photos, so for them either version adds a step.

## Ease of implementation

Medium-low: about a week for a flagged first slice with evals. What exists:

- Belly: `AnthropicClient`, `LlmGate` (usage events, failure copy, dev
  providers for the Claude CLI and a fake), `llm_eval.rake`, and multi-photo
  extraction in `RecipeIngest::RecipeExtraction`.
- Workbench: per-shop form templates (`FormFieldDefinition`, select, checkbox,
  radio, text, number) that already validate allowed options, and
  `has_many_attached :images` on job items.

What's new:

- Build the tool schema from the shop's form template at call time. Select,
  radio and checkbox fields become enums, so the model can only pick a real
  option. Every field is nullable, so a field not visible in the photo stays
  empty.
- Map the output onto the intake form as a prefill. Nothing saves until the
  person confirms, and filled fields are marked so they get checked.
- Run the call in a job and push the prefill back with a Turbo Stream, with a
  loading state on the form. Expect 3 to 6 seconds.
- Fixtures: 15 to 20 real, anonymized photos from shop 8, with property checks
  ("metal is one of the shop's options", "no reference number invented when
  none is printed").

## Cost and quality practice

These are in the order they save money for this feature.

- Pick the cheapest model that passes the eval, and re-run the eval on every
  prompt, schema or model change.
- Downscale images before sending. Image cost scales with pixels, not
  content.
- Set effort explicitly on Haiku 5.5 (default is medium) and try thinking off.
  Output costs 5 times input, and thinking is output.
- Cap `max_tokens` to what the output needs.
- Call only when someone taps, never on every upload. Rate limit per user.
- Let code do what code can do exactly: option matching, number parsing,
  dates. The model reads the image and nothing else.
- Validate the output against the same schema with `json_schemer` and scrub
  "N/A" and "unknown" to nil. Reject a half-valid payload.
- Log tokens per call (the gate already does this to PostHog), so the bill
  per feature is a query, not a guess.

Prompt caching and the Batch API don't fit this feature. The prompt is close
to the minimum cacheable size and changes per shop, and Batch results arrive
too late for someone standing at the counter.

## Foundation for more LLM features

Decided 2026-11-20: no gem yet. Copy Belly's pieces into Workbench and make
them generic as they land, so a later extraction is a move, not a rewrite:

- One client with explicit timeouts and failures as dry-monads codes.
- The gate: usage events and metrics, generic failure copy (no recipe
  wording), refusal handling, and the dev provider switch so nobody needs an
  API key locally.
- A request object contract (model, effort, max tokens, schema, content,
  kind).
- Image preparation (downscale and base64).
- The eval rake task and `test/fixtures/files/llm/<feature>/` layout.

Revisit a `studio-llm` toolshed gem when a third app needs these, or when
Belly and Workbench copies start to drift.

## Privacy

Paperwork photos carry customer names and phone numbers to Anthropic. That's
a new data flow for Workbench, so the privacy policy and any subprocessor list
need updating before launch. Workbench has no `docs/security.md` yet, so this
would start one. Model output only prefills a form, so it never triggers a
send, charge or delete.

## Deliberately out of scope

- Auto-saving a job from a photo without a person confirming.
- Creating new customers from a photo without a match step.
- Any customer-facing AI text (customer messages stay human).
