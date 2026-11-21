# Belly party mode

Pending work only. Built pieces live in the code and git history (wt-belly
worktree, rebased on main).

## Ship the versions and Bella shell checkpoint

Plan versions and the Bella panel shell are committed on wt-belly (caec021,
with tests), checked on iOS and Android.

1. Before deploying, confirm production still has no party_tasks
   (`PartyTask.joins(:party).pluck("parties.name", :description)` returned []
   on 2026-10-31). The migrations set party_plan_version_id NOT NULL with no
   backfill, so any versionless task fails the deploy on boot. If tasks
   exist by then, delete them (founder test data) or restore a backfill.
2. feature_enable_bella stays off. Submitting a Bella action only closes the
   panel until the wiring below lands.
3. Rollback is unsafe once a restore has happened: older code reads tasks
   across every version and shows duplicates.
4. The plan_versions native sheet rule ships in the server's remote path
   config now and in the bundled copies with the next app builds.
5. Android release for 94b9572 (status bar gap) is still pending, and the
   prep plan party flag stays founders only until testers are added.
6. Ask testers whether they plan the day before and whether collaborators
   should be next.

## Prep plan follow-ups

- "N done" row closes again on every refresh. Keep it open across refreshes if
  testers notice.
- Day-before tasks are typed as hours ("26 h before"). Add a day option if
  testers plan the day before.
- Three unreachable Rails errors show without a field name (too long, must
  exist). Give them sentences if they ever become reachable.
- Android grocery list: the "walnuts" row is cut off by the add-item field
  (seen during testing, not from party work).
- Other party controllers (dishes, covers, menus, shares, course choices,
  dish menus and courses) still use hosted_parties.find and 404. Move them
  onto PartyScoped (find_by plus a redirect) when next touched.
- When scrolled, the party title slides under the back and ⋯ buttons in the
  iOS shell (seen during Bella testing, not from this work).

Deferred, and what brings each back

- Stored course serve times. Store serve times on the party when guests
  should see them on the menu.
- guest_count and scaling. Back with RSVPs or recipe scaling.
- Assignees. Back with collaborators.
- Dependencies, task kind (active/passive), resource (oven, stovetop, fridge).
  Back if testers report clashes in Bella's plans.
- Slack, tight and off-track status per course. Needs serve times and
  dependencies.
- Out-of-date banner (dish added, recipe changed, servings changed). Back if
  hosts ask Bella again after editing a recipe.

## Plan versions

Built. The rules Bella's builder must keep:

- A party's plan is its latest version (party.current_plan_version). Every
  task read and write goes through it; party.all_plan_tasks spans every
  version and is only for history and cleanup.
- Host edits change the current version in place. Only a Bella action or a
  restore creates a version, so the host's state before Bella is always a
  version to go back to.
- A task carried into a new version keeps its lineage_id
  (PartyTask#attributes_for_new_version is the list of fields that carry).
  Completion follows lineage: the newest version holding a lineage decides
  whether it is done.
- Restore is append only (PartyPlanRestorer). Undo after a Bella action is
  "restore the previous version", behind the neutral confirm.
- Task ids change between versions; a stale task link redirects to the prep
  plan with a message.

Pending: the history rows read "You", "Bella" or "Restored" with a time. Add
the Bella action name ("Bella · Catch me up") once llm_generations links a
version to its action.

## Bella

Bella is the host's assistant for the prep plan. She builds and re-times it;
the host owns every task and edits anything after her. Open to everyone
behind feature_enable_bella, a view-only flag kept after rollout as the off
switch for her AI spend. No Pro check yet.

North star: the ragu day (Claude Code session c04e1b36, 2026-08-19; only the
host's prompts survive, in ~/.claude/history.jsonl). A surprise dinner for a
wife landing at 5 pm: 6-hour bolognese, hand-rolled tagliatelle, a 45-minute
chocolate cake, a deep-cleaned home and a grocery run, planned at 8:30 am and
then used as a live companion for 9 hours. What made it work:

- Anchored on the moment she walks in, worked backwards in clock times from
  the host's real start ("my day starts at 9am"); fresh pasta last.
- Arrival was a moving target reasoned from real details (landing is not
  arriving: YUL to home by transit, so 7:20 pm), and the plan was rebuilt
  whole when it moved.
- The whole day, not only the food: groceries, cleaning, laundry, table, fit
  into the passive windows (simmer, dough rest, cake cooling).
- Status check-ins ("it's 2:34, 3 hrs left, floors done") answered with
  what's next; pace cues (when to top up the sauce, when to lid it and let it
  coast); a hold state so the long cook could wait if she ran late.
- It deferred to the host's own recipe and gear (one cake pan, no parchment)
  and offered a few touches to make the evening feel special.

Built (uncommitted on wt-belly after caec021)

- An espresso "✦ bella" pill (italic serif, gold sparkle) floats bottom-right
  on the prep plan, above the tab bar. It grows into a popover panel headed
  "ask bella" that lists the actions for the plan's state, and resets to the
  action list whenever it closes.
- Actions (Bella::PlanActions): no open tasks: "Build me a plan". Plan
  exists: "Rebuild my plan". Any open task overdue: "Catch me up" first.
  No dishes: "Add dishes to your menu first". While a run is in progress the
  panel says Bella is working instead.
- Build and Rebuild ask one question (Bella::PlanPresets): "Only on the party
  day" (default) or "Start the day before". Catch me up asks nothing.
  Optional chips under it (Bella::PlanChores): Groceries, Tidy up, Clean the
  bathroom, Laundry; Bella fits the chosen ones into the cooking's waiting
  windows. Light setup (the table, drinks) is always in.
- The prompt is role-first (an experienced host and calm guide writing a
  timeline to follow), with judgement over serve times, holds, setup and
  notes, and hard guardrails only for refs, earliest start, done tasks, host
  tasks (never dropped) and language. Each task can carry an optional note
  (how to tell it's done, how long it holds), shown in the task sheet and
  cleared when the host rewrites the task.
- The whole flow below runs: llm_generations, Bella::PlanBrief,
  Bella::PlanRequest (claude-sonnet-5-5, low effort, adaptive thinking,
  180 s timeout), Bella::PlanBuilder, Bella::PlanJob, a 10 per rolling 24
  hours cap, the planning and failed states, the staggered slide-in, the
  assumptions line, thumbs up or down, Undo, and PostHog events
  (bella_plan_requested, _completed, _failed, _rated, _undo_clicked).
- Evals: 9 fixtures in test/fixtures/files/llm/bella_plan (ragu_day is the
  north star; BELLA_EVAL_SHOW=1 prints each plan with notes for reading),
  `bin/rails "llm:eval:local_subscription_cli[bella_plan]"`. Live run
  2026-10-31: Sonnet 5.5 low 8/8, medium 7/8, about 0.6 cents a plan; Haiku
  5.5 failed Catch me up on the CLI (invented refs). BELLA_EVAL_MODEL and
  BELLA_EVAL_EFFORT compare settings. The unplannable-dish prompt fix after
  that run passed on the CLI only; include it in the next live run.
- Cost, measured in production (PostHog $ai_generation, Nov 2026): 2.5 to
  4.7 cents a plan on Sonnet 5.5 low, not the 0.6 the eval suggested. Real
  briefs run about 3k uncached input plus the 2.4k system prompt, and 1.4k
  to 3.5k output (thinking plus JSON); output is 55 to 75% of the cost. The
  system prompt is cache-written every run and never read (plans are far
  apart), so caching adds 25% on it. Forecast with 4 cents a plan; the 10 a
  day cap bounds one host at about 47 cents a day. For scale, all imports
  and grouping together cost 25 cents over the same 30 days.
- 2026-11-05 Haiku 5.5 on the CLI: 10/12, then 9/13, failing different
  fixtures each run (lunch timing, a note over 200 characters, stacked tasks,
  adjust). Not reliable enough to switch. Sonnet 5.5 passed 13/13 with the
  sharpened unplannable rule.
- Eval gap: PlanJob always sends a serving (from_answers falls back to
  together), but 11 of 12 fixtures omit serve, so the eval exercises a
  decide path production never takes. Haiku fails lunch on decide 3/3 and
  passes it on together 3/3. Decide whether to give fixtures a serve key and
  drop the decide wording from the prompt.
- 2026-11-05 live run, Sonnet 5.5 low with the sharpened unplannable rule:
  11/12, about 11 cents for the run. adjust_arrival_moved_earlier failed:
  T1 kept its -360 slot, before earliest_start -300 (passed on the CLI twice;
  unrelated to the rule change). Fixture briefs are 350 to 850 input and 340
  to 1,200 output tokens, against about 3k and 1.4k to 3.5k in production,
  which is why the eval priced a plan at under a cent. Fixtures need real
  sized parties before eval cost says anything about production cost.
- 2026-11-05 follow-up, done: the brief always sends a serving (together by
  default, as PlanJob does) and the prompt lost its decide wording; every
  fixture has a serve key; an open task before earliest_start is marked
  "too early" in the brief, because the builder drops such tasks and Sonnet
  kept the marinade at -360 twice live; adjust_arrival's grill task moved to
  -25 to match a together plan; new dinner_real_size fixture (5 dishes,
  import-length steps) at 3.2k in / 1.7k out, about 2.4 cents, close to
  production. Live run 13/13, about 13 cents.

Flow

1. BellaPlansController#create (host via PartyScoped, daily cap) creates a
   pending llm_generations row, enqueues the job, returns.
2. Job: limits_concurrency key: party, on_conflict: :discard, so a double
   tap can't start two runs. The SDK retries transient errors; no retry_on
   on top.
3. Brief, built in Ruby: plain text, sections in XML tags, short refs.
   - Action, preset, the party's meal type, minutes from now until arrival.
   - Current incomplete tasks with refs (T1, T2): description, dish ref,
     minutes from arrival, duration.
   - Per dish: ref (D1), course, recipe name, prep/cook/marinade times,
     serves, numbered steps (D1.1) with whitespace collapsed.
   - Step-text budget, about 12k characters across all dishes (tune from
     evals). Under it: full steps, step-level tasks with step links. Over it:
     each dish sends name, course, times and step count only and gets 1 to 3
     broad tasks. One mode per party.
   - No ingredients, no party name, details, date, guest or host data, no
     clock times.
4. One request through LlmGate with structured outputs (output_config
   json_schema; built in 8fe5730), not forced tool_choice (Sonnet 5.5 returns
   a 400 on it). Thinking on, effort as the cost dial. Stream the request and
   wait for the final message.
5. Output: the full new list of incomplete tasks, earliest first, up to about
   30. Each: description, dish ref, step ref, minutes from arrival, duration,
   estimated flag, optional from (a T ref the task continues). Per dish a
   not-plannable escape.
6. Builder (service): json_schemer check, refs mapped to party_dish_id and
   step_id (only this party's), lineage copied from from refs, completed
   tasks carried over through attributes_for_new_version. Drops tasks ending
   after their course is served. Writes a new bella version in one
   transaction (build all tasks on one version object; Party#build_plan_task
   keeps them on one version). Any failure marks the generation failed and
   leaves the plan as it was.
7. Page renders pending, failed or result from the generation row, so a
   reload or a backgrounded app shows the right state. A Turbo Stream
   broadcast only speeds that up. New plan arrives with a staggered
   slide-in, no fade. An assumptions line sits above the plan ("Mains at
   +60, all prep on the party day"); estimated durations are marked.
8. After a run: thumbs up or down inline, and Undo.

Prompt: Bella picks serve times per course and the day's earliest start
herself, from the courses and the meal type (a brunch serves everything
together; a dinner staggers courses). With "Start the day before" she moves
what keeps (doughs, braises, sauces, desserts, marinades) to the day before
and leaves what doesn't (salads, searing, frying) for the day. With "Only on
the party day" nothing lands the day before; on an early meal that means
starting as early as the window allows, never before 6 am. Last-minute tasks
are timed to each course's serve time. One cook's day: interleave dishes so
active work doesn't pile up at the same minute, and use one dish's waiting
time for another's work.

llm_generations

One row per model call, shared by every LLM feature (recipe import moves onto
it later, see the TODO on RecipeIngest::RecipeExtraction). Analysis data,
separate from the working plan, cleared after 60 days.

- kind, model, effort, status (pending | succeeded | failed), error_code,
  subject (polymorphic, the party for Bella), party_plan_version_id it
  produced, action, answers, input (the brief), output, input_tokens,
  output_tokens, cache tokens, duration_ms, dropped_task_count, rating
  (up | down), user_id, created_at.
- Rating also goes to PostHog, which keeps the history past the purge.
- Behaviour metrics: compare a generation's output with the version's tasks
  now, by lineage (edited, deleted, untouched, completed), plus ratings,
  undos and repeat actions.

Evals

Real parties in test/fixtures/files/llm/party_plan/, property checks in code,
pass/fail. Cases: over-budget party, staggered dinner courses, a brunch, no
day-before prep, an early meal, off-track party for Catch me up, Rebuild with
host-written tasks, a recipe with no steps. Properties: make-ahead work comes
out the day before only under "Start the day before", last-minute tasks land
just before their course's serve time, nothing before 6 am, no invented dish,
step or task refs, durations roughly match the recipe's stated times, active
tasks don't stack at the same minute, the empty recipe is not plannable.
Compare claude-sonnet-5-5 at medium and low effort with claude-haiku-5-5 on
the free CLI eval, then one approved live run. Cheapest that passes wins.
Rough cost per action: 2.5 to 4.7 cents on Sonnet (measured Nov 2026), about 0.2 cents on Haiku.

Quality loop

- Before launch: the host reads about 30 generated plans; failures become
  fixtures.
- After launch: read real plans every 2 to 4 weeks, thumbs-down and undone
  first plus a random sample, locally with read-only production queries. A
  rake task exports a generation to an eval fixture.
- PostHog LLM analytics already works ($ai_generation with tokens, cost,
  person; cost priced via OpenRouter and correct). Check the first Bella
  event has $ai_model_cost_used set for Sonnet 5.5. No failed generation
  recorded in 60 days, so the error path is unproven live.
- Prompt caching on the system prompt is about break-even at current traffic
  (5-minute cache, sparse calls). Leave it.

Build order (everything through PostHog events is built)

1. Commit the Bella backend (after review), deploy with feature_enable_bella
   off.
2. The host reads about 30 generated plans on real parties; failures become
   fixtures and prompt fixes, then one approved live eval run.
3. design-review and ui-microcopy on the panel and the result strip, then
   turn feature_enable_bella on for the founders.
4. One line each in weekly-health-check (LLM failure rate by code, p95 by
   kind, failed Bella jobs) and weekly-product-report (Bella adoption,
   actions per party). After about a week of beta data, write the
   studio-wide ai-feature-health skill in jean-claude (ratings, undo and
   edit rates, cost per action, the reading pass, fixture export).
5. Unplannable dishes are dropped quietly (only the assumptions line may
   mention them). Show them on the result strip if hosts are confused.

Cut, and what brings each back

- "Adjust my plan": too close to Rebuild for hosts or the prompt to tell
  apart. Back if hosts ask to keep their own tasks while Bella re-plans.
- Custom answers (serve time per course, earliest start, a three-level
  day-before choice): the form felt heavy. Back if Bella's own serve times
  and start times miss often.
- Free-text instructions: users ask for something the presets can't do.
- Push everything back (a plain Ruby shift): testers ask for it.
- Mixed broad and detailed tasks in one party: broad plans feel thin on big
  parties.
- Real token streaming: typical wait over about 15 seconds.
- Thumbs-down reasons: the reading pass can't tell why plans fail.
- Per-recipe breakdown cache with a Ruby scheduler and validator: clashes in
  plans, or repeat asks on the same recipes dominating spend.
- Pro gating: when Bella gets a price.
- RubyLLM: a multi-turn chat with Bella.
- A fallback provider: manual planning is the fallback.

## Collaborators

Host invites by email. The invite email links to an accept page: sign up or
log in, then land on the party as a collaborator. Collaborators add dishes
from their own recipes. Host can revoke an invitation or remove a
collaborator, along with their dishes.

Decisions

- Roles: host, collaborator (has an account, owns dishes), guest (link only, no
  record).
- Collaborators keep ownership of their recipes. A dish points at the owner's
  recipe in the owner's space. The party grants read access to it, nothing more.
- Live link, no snapshot. If the owner edits the recipe, the party shows the
  edit.
- Only the host invites collaborators. Guests cannot make themselves
  collaborators.
- Collaborators are not Space members. A Membership would expose the host's
  whole space.
- The dish owner never changes. Hosts have full create, edit and delete on
  every dish but cannot reassign one.
- A dish's recipe must come from a space its owner belongs to.

Tables

    party_invitations
      party_id, email, token (unique), invited_by_id (user), accepted_at
      unique on party_id + email
      Accepting creates the party_collaborators row. The person may not have
      a belly account yet, which is why the invitation isn't a collaborator
      row with a null user.

    party_collaborators
      party_id, user_id, unique on the pair
      Named this way, not "membership", because Membership already means
      space membership.

Open questions and traps

- Cook mode only opens recipes in the viewer's own space. A collaborator's
  recipe needs a read-only cook mode path through the party.
- Prep plan visibility: host only today. Decide whether collaborators see and
  tick tasks, and bring back assignees then.
- Live updates between collaborators' screens need Turbo Stream broadcasts;
  today the page only refreshes on its own timer.
- Public exposure. Contributing a recipe makes it readable by anyone with the
  party link. Say so in the UI at the moment of adding.
- Authorization. Recipe reads through a party must check the dish belongs to
  that party. Never trust a bare recipe id from params.

## Later, on demand

- "I'll bring something" from the guest view (guest becomes a collaborator
  without an invite).
- Requests for unowned slots ("someone bring a salad"). A separate model, so
  the rule that every dish has an owner stays.
- Free-text dishes ("chips and wine"), when someone asks.
- .ics add-to-calendar, RSVP, extra run-of-show events (toasts, games), a
  party template ("Friendsgiving"), an after-party graphic.
- Location on the party. It's personal data on a public link, so the host
  should know that when it comes back.
- Soft delete on parties (hard delete today).
- Analytics events, when there's a question to answer.

## Watch

- RecipeCopier hardcodes the analytics event "shared_playlist_recipe_saved".
  Pass the event name or source in, so party saves are counted separately.
- Long-lived branch drift. Merge to main behind the flag and rebase often.

## 2026-11-05 production routing (uncommitted)

- 186b528 committed the output trim.
- Bella::PlanFetcher routes runs. A fresh build with no chores and no open tasks makes one DishPlanRequest per dish (Haiku 5.5, medium, adaptive thinking), all in parallel threads, and PartyPlanSchedule puts the dishes on the clock. Any other run uses PlanRequest (Sonnet 5.5, low, thinking off via between_tools).
- PlanJob records the model and effort the fetcher actually used, so admin cost prices Haiku runs correctly.
- Per-dish assumptions are blank, so the status panel falls back to its localized "made by Bella" copy.
- Step budget is now per dish: each call sends its dish's steps unless that dish alone is over the budget.
- Live eval run 10, all 13 fixtures: 12 passed. The one failure was an eval rule (broad mode means no step refs) that doesn't apply per dish, and the check is now skipped there. Real-size build: 17 s, 3.3k in / 9k out on Haiku, about 0.5 cents. Whole-plan Sonnet runs were 3 to 7 s each.
- Follow-ups: chores in per-dish builds (a separate small call), and per-dish rebuilds once there are no open tasks.
