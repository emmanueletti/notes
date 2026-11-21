# Belly AI cost research

2026-11-05. Scope: Bella plans (claude-sonnet-5-5, low) and recipe imports
(claude-haiku-5-5). Quality bar: the bella_plan eval, 13 fixtures, one of
them production sized (dinner_real_size).

## Verdict

Our prompts are not the main problem. The task shape is. Bella asks the
model to do clock arithmetic and enforce counted limits (earliest start, no
stacking, note length, no refs in notes). Those are exactly the checks Haiku
failed, and they are the jobs code does exactly. Move them into Ruby, then
re-test Haiku at high effort behind a validator, with Sonnet as the fallback.

The bill itself is small: about $0.32 over 30 days, imports 63%, Bella 22%.
The risk is Bella volume: a plan costs about 33 imports.

## Where the money goes

- Bella, measured in production: 2.5 to 4.7 cents a plan. About 3k uncached
  input, 2.4k system prompt cache-written every run and never read, 1.4k to
  3.5k output. Output is 55 to 75% of the cost (thinking plus JSON).
- Imports: about 0.1 cents a call on Haiku 5.5. Not worth optimizing yet.
- Prices (Anthropic pricing page, fetched 2026-11-05): Sonnet 5.5 $2 in /
  $10 out, cache write 1.25x, cache read 0.05x. Haiku 5.5 $0.10 / $0.50,
  cache read 0.1x.

## What PostHog actually does

Not Haiku everywhere. From their repo: the main PostHog AI agent runs
Sonnet 4.6 (medium effort, 1h prompt cache); research mode uses Opus;
compaction uses Sonnet 5. Haiku only does narrow, checkable jobs (error
grouping judge, alert detector, task titles, enrichment). Their agent e2e
config keeps Sonnet for "tests the cheap model can't handle (structured
output)". Their blog: a single loop beat subagents. Pricing page says they
pick the cheapest model per feature; no per-feature cost published.

Sources: github.com/PostHog/posthog (ee/hogai/core/agent_modes/executables.py,
products/alerts/backend/judge/llm.py, packages/agent/.../e2e/README.md),
posthog.com/blog/8-learnings-from-1-year-of-agents-posthog-ai,
posthog.com/docs/posthog-ai/pricing.

## Levers, ranked by expected saving

1. Code does the scheduling (architecture, needs eval). Model returns
   tasks with dish/step refs, order, dependencies, duration and notes; Ruby
   places them on the clock backwards from serve time, clamps to
   earliest_start, de-stacks, trims notes, strips refs. Removes most of the
   failure classes Haiku hit and shrinks the prompt's rules section.
   Sources: anthropic.com/engineering/building-effective-agents ("programmatic
   gates"), arxiv.org/abs/2402.01817 (LLM-Modulo), applied-llms.org
   ("prioritize deterministic workflows").
2. Validator plus repair, then cascade (architecture, needs eval). Fix in
   code what code can fix (Vercel v0 autofixers, vercel.com/blog/how-we-made-v0-an-effective-coding-agent);
   else one re-ask with the specific errors (instructor reask pattern); else
   fall back to Sonnet. If Haiku passes about 80%, average cost drops to
   roughly a quarter (estimate, not measured).
3. Re-test Haiku at high effort (tradeoff, needs eval). Our CLI eval
   passes the model but not the effort, so Haiku ran at the CLI default.
   Anthropic's Haiku 5.5 guide: high "suits strict instruction following";
   low skips checks. Even at 2-3x output tokens Haiku stays far cheaper.
4. Cut output tokens (free win, verify with eval). All 8 task keys are
   required, so every task writes its nulls; estimated may be droppable;
   short keys help. Structured outputs reject maxLength/minimum, so length
   limits belong in code anyway. Keep thinking on; never add a reasoning
   field to the JSON.
5. Drop the cache marker for Bella (free win, small). Plans are far apart,
   so the 1.25x write never pays back: about 0.12 cents a plan.
6. Re-sweep Sonnet effort only if staying on Sonnet; low already passes.

Skipped: Batch API (a host waits on the plan), fine-tuning (no first-party
Haiku fine-tuning found; scale far too small), semantic caching (plans are
unique).

## Bugs found on the way

- Admin cost query (app/queries/admin/llm_generations_query.rb) prices cache
  reads at 0.1x for every model; Sonnet 5.5 is 0.05x. No effect today
  (Bella never reads cache), wrong once it does.
- Fixed this session: Bella $ai_generation had no user (476aefb); dropped
  too-early tasks and the eval's decide path (ed08d9b).

## Unverified practitioner claims

Treat as leads, not numbers: Intercom swapping a ~$250K/month GPT task for a
fine-tuned Qwen 14B (podcast); Notion 2 s to 350 ms with small fine-tuned
models (vendor case study); "Structure Tax" and "Constraint Tax" papers on
answer-first schemas hurting small models (reasoning-first fixes it); an HN
post claiming format changes beat model switches; routing posts claiming
50-85% (mostly modelled, one anecdote $212 to $138 a week). Nothing found
with measured numbers from Linear, Ramp, Hex, Replit, Duolingo or Reddit.

## Next steps

1. Prototype lever 1 behind the eval: new output schema (no absolute
   minutes from the model), a Ruby scheduler, a validator. CLI evals free.
2. Run Haiku at high on the CLI, then one approved live run of Haiku high
   vs Sonnet low on the new shape, priced per passed plan.
3. Ship the cascade if Haiku clears the bar; keep Sonnet as fallback.
4. Small cleanups any time: drop Bella's cache marker, fix the 0.05x price.

## Prototype results (2026-11-05)

Built: Bella::PlanRepair (clamp to earliest start, spread stacked minutes,
drop notes leaking refs, cut long notes), Bella::PlanCheck (invented refs,
step under wrong dish, duplicate step refs, dropped host task, refs in
assumptions), Bella::PlanCascade (Haiku then Sonnet). The CLI eval now
honours effort (it ignored it before, so every earlier CLI Haiku run was at
the CLI default).

CLI (free): Haiku high + repair 13/13 with a 360 s CLI timeout; Haiku
medium + repair 13/13; cascade 13/13 (Haiku answered 12).

Live:
- Haiku high + repair: 10/13, 2.2k to 13k output tokens, 11 to 60 s, about
  0.4 cents per passing plan. ragu_day and dinner_real_size hit the 16k cap
  (no_text_block). Run cost about 6 cents.
- Haiku medium + repair: 11/13, 1.4k to 8.3k output, 7 to 39 s, about 0.23
  cents per passing plan. dinner_real_size hit the cap again; over_budget
  invented refs. Run cost about 3.5 cents.
- Sonnet low (earlier the same day): 13/13, 0.35k to 1.7k output, 3 to 11 s,
  0.8 cents on small fixtures, 2.4 on dinner_real_size.

Conclusion: Haiku thinks about 5 to 10x more than Sonnet low, so it is only
2 to 3x cheaper on small parties and fails the production-sized one at both
efforts. A cascade would burn a capped Haiku attempt on every real party and
then pay for Sonnet anyway: dearer and far slower than Sonnet alone. Stay on
Sonnet low; keep repair and check in PlanBuilder; drop the cascade until a
Haiku finishes real-sized parties under the cap.

## Round 2 (2026-11-05, 9 of 10 approved live runs used)

Committed: 51e9bea PartyPlanRepair + PartyPlanCheck in PlanBuilder, CLI
eval honours effort. Uncommitted, awaiting review: the output trim, the
thinking switch, the per-dish split prototype.

Output trim (PlanRequest schema: only description and minutes_from_arrival
required, estimated dropped, prompt says leave out fields that don't apply):
13/13 live. Small fixtures -22% output (8,379 to 6,503 tokens). The big
fixture swings 1.7k to 5.4k output on both old and new schema (3 samples
each, old schema re-run in memory), so on big parties thinking variance
dominates and the trim's effect is lost in the noise.

Thinking off (Sonnet low, thinking between_tools): 13/13 on the full run,
then dinner_real_size 1.36k / 1.37k / 1.54k output in 9 to 10 s (vs 3.7k to
5.4k and 30 to 43 s with thinking). About 2.1 cents a real-sized plan vs
about 4.2. One miss: ragu_day (north star) failed once in 3 (fresh pasta
too early); with thinking it passed every run today. Quality call for the
user. Plans saved in /tmp/claude-1000/-home-emmanueletti-projects-itsusstudio-belly/5210b968-9705-4503-aa61-b016a5af0bb5/scratchpad/live7_thinking_off.txt and live8.

Per-dish split prototype (Bella::DishPlanRequest per dish on Haiku 5.5
medium, Bella::PartyPlanSchedule puts milestones on the clock from each
course's serve time, then PartyPlanRepair): build fixtures only. CLI 7/8
(the panna cotta went on the party day, 8 h before dessert, where the
fixture wants the day before: defensible). Live 8/8. dinner_real_size 8.7k
output across 5 calls, about 0.47 cents; small builds 0.1 to 0.25 cents.
Latency is summed sequential calls (6 to 47 s); parallel calls would cut it
to the slowest dish. Plans in /tmp/claude-1000/-home-emmanueletti-projects-itsusstudio-belly/5210b968-9705-4503-aa61-b016a5af0bb5/scratchpad/live9_split_haiku.txt.

Split prototype gaps before it could ship: chores, adjust, catch-up and
rebuild (open tasks) still need the whole-plan prompt; the assumptions line
is English template text; no one-cook check across dishes beyond de-stacking;
calls run in sequence; one LlmGeneration row would need to sum several
calls' usage.

Cost per real-sized plan, measured: Sonnet thinking ~4.2c, Sonnet thinking
off ~2.1c, split on Haiku ~0.5c.

## Open-weight models hosted in the West (research 2026-11-05)

Headline: Haiku 5.5 ($0.10 / $0.50) already sits at open-weight market
prices. gpt-oss-120b is dearer than Haiku on every host checked ($0.15 /
$0.60). Only the very cheapest (DeepSeek V4 Flash $0.09/$0.18, Mistral Small
3.2 24B $0.075/$0.20, gpt-oss-20b $0.075/$0.30) save 2 to 3x, which on a
0.1 to 0.5 cent split plan is a fraction of a cent. The big gap is against
Sonnet ($2/$10). So the useful question is whether an open model can do the
whole-plan job (chores, adjust, catch-up) that Haiku can't, not whether one
can replace Haiku.

Shortlist (verify prices before use; several are aggregator figures):
1. Groq: gpt-oss-120b $0.15/$0.60 or gpt-oss-20b $0.075/$0.30; strict
   token-level JSON schema (all properties required); no retention by
   default, self-serve ZDR; US only (GCP). console.groq.com/docs/your-data
2. Mistral La Plateforme: Mistral Small 4 about $0.15/$0.60 (unverified);
   EU company and hosting, DPA available; training shown as opt-out and ZDR
   reportedly on request; strict schema enforcement unverified.
3. Fireworks: gpt-oss-120b about $0.15/$0.60; ZDR by default on serverless,
   JSON schema and grammar modes (schema mode disables reasoning output);
   region/SOC 2/DPA not found.
4. DeepInfra: cheapest (DeepSeek V4 Flash, Mistral Small 3.2, Qwen3 235B);
   no logging or training; region/SOC 2/DPA not stated.
5. Scaleway (France): gpt-oss-120b EUR 0.15/0.60, Mistral Small 3.2 EUR
   0.15/0.35; EU data centres; retention unverified.

Quality: Artificial Analysis puts Haiku 5.5 about level with GLM-5.3-Flash
and above DeepSeek V4 Flash; no head-to-head instruction-following data.
Practitioner reports are anecdotal (one Sonnet to DeepSeek V3 switch, $1,800
to $290 a month, 5 to 10% worse on edge cases). Our own bella_plan eval is
the real test.

Integration: Bella uses output_config json_schema (not a forced tool, as the
research assumed). A second provider means a second client behind LlmGate
(ruby-openai or the official openai gem with base_url), strict-mode schema
tweaks (Groq wants every property required), and eval support for it.

Risks: model and price churn (Groq preview models, Mistral retirements,
Together repricing); possible US restrictions on hosted Chinese-origin
models (secondary sources only), which favours gpt-oss / Mistral / Gemma as
defaults. New subprocessor under Law 25: privacy impact assessment before
data leaves Quebec (s.17), written contract limiting use and retention
(s.18.3), DPA/SCCs for EU users, privacy policy update. Routing through
OpenRouter adds the underlying host as a further subprocessor.

Suggested next step if we pursue it: add one OpenAI-compatible client
behind LlmGate (Groq gpt-oss-120b first: strict schema, ZDR, cheap), run the
whole-plan bella_plan eval on it, and compare with Sonnet low thinking off
(2.1 cents) and the Haiku split (0.5 cents).
