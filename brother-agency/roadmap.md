# Roadmap

Purpose: sequence the move to the simplified stack over months, de-risked by
proving it on one project before migrating more. Grounded in the six
[decisions][plan], the [current-state audit][audit], and [industry
research][research].

## Principles

- Pilot first. Prove the new stack end to end on a single project, observe how it
  handles, then expand. No broad migration before the pilot earns it.
- One at a time, in waves. After the pilot, migrate a few projects at a time, not
  a big bang. Each wave teaches the next.
- Gates between phases. Each phase ends with an explicit go / adjust / stop
  decision against success criteria, not a calendar date.
- Urgent safety first. Fix the backup risk before anything else, independent of
  the migration.
- Retire on zero-dependency. A bespoke tool is decommissioned only once nothing
  depends on it, never on faith.
- Two tracks run in parallel: new builds start on the new stack immediately;
  existing sites migrate gradually.

## Phase 1: Pilot one project (about 3 to 6 weeks)

Goal: run one project through the entire new stack and watch how agents handle
it.

- Setup: choose the managed git host (GitHub or GitLab) and pick the pilot
  project. Prefer the next new client build (greenfield isolates the new-stack
  build workflow from migration risk); if none is near, a small low-risk
  existing site.
- Project foundation: Bedrock plus Composer plus Docker (DDEV) for the pilot
  repo. Pinned core, reproducible local env.
- Source control: the pilot repo lives on the managed git host, using its
  built-in merge queue and PR checks. No `tool-gitea-merge-queue`.
- Build methodology: build the pilot with ACF Blocks. Seed the component library
  with only the blocks this project needs (for example hero, eyelid header,
  carousel, CTA). Do not build the whole library up front; grow it per project.
- Context: a lean per-repo `AGENTS.md` plus the client knowledge repo plus the
  HQ knowledge repo. No gardener, tombstones, or generated indexes.
- Hosting and deploy: host-native git-push deploy. Try WP Engine git-push with
  Bedrock first; only reach for a PaaS if per-branch previews prove necessary.
- Keep a lean QA surface for the component blocks (the one discipline worth
  keeping).

Observe throughout: where agents move faster, where they stumble, what ceremony
turned out unnecessary, what was actually missed.

Gate 1: the decision point the whole roadmap hinges on. Proceed only if the
pilot shows the stack is simpler to operate and agents ship faster, with no
worse quality. If not, adjust the stack and re-run, or stop. Capture the verdict
and the learnings.

## Phase 2: Templatize and write the playbook (about 2 to 4 weeks)

Goal: turn one proven project into a repeatable path.

- Extract a project template from the pilot (Bedrock plus DDEV plus ACF Blocks
  scaffold plus the lean `AGENTS.md`).
- Write two short playbooks: new-build-on-the-new-stack, and
  migrate-an-existing-site-to-the-new-stack.
- Promote the pilot's blocks into the shared component library as the first
  reusable set.
- All new client builds start on the new stack from here on.

Gate 2: a second project (new build) runs through the template smoothly.

## Phase 3: Migrate existing sites in waves (the bulk, several months)

Goal: move the existing roster over, learning each wave.

- Migrate two to three sites per wave using the playbook: adopt Bedrock, move the
  repo to the managed git host, purge bloated history with `git filter-repo`,
  switch to host-native git-push deploy, rebuild page assembly as ACF Blocks
  where the site is being reworked.
- Prioritize by value and simplicity: start with low-risk or actively-worked
  sites; leave fragile or soon-to-be-retired sites for last or never.
- After each wave, review: what broke, what the playbook missed, update it.
- Preserve the hard-won Beaver Builder and WordPress gotcha notes as reference
  during the transition so knowledge is not lost as the old ceremony retires.

Gate 3 (recurring): each wave completes cleanly before the next starts.

## Phase 4: Retire bespoke infrastructure (overlaps Phase 3)

Goal: delete the maintenance sink as its dependents leave. This is where the
open bug backlog collapses.

As projects stop depending on each system, decommission it:

- Sandbox control plane (`tool-bca-sandbox`) once previews come from the host.
- Merge queue (`tool-gitea-merge-queue`) once repos use the managed host's queue.
- WP Engine transport (`tool-bca-wpe`) and ssh-pull once git-push deploy is
  standard.
- Collapse the 8-layer knowledge system into the lean 3-tier structure.
- Migrate off self-hosted Gitea once every repo lives on the managed host, then
  retire it.

Retire each only when nothing depends on it. Snapshot and archive before
deleting.

Gate 4: each system has zero remaining dependents before it is turned off.

## Phase 5: Steady state and scale (ongoing)

- New client sites are born on the standard stack.
- The component library compounds: each site adds or reuses blocks, so each new
  build is faster than the last.
- The founder maintains a small, standard, mostly-vendor-maintained surface
  instead of a bespoke platform, and gets time back to grow the studio.

## How to know it is working

Signal, not vanity metrics:

- Agents ship a site change or a new build in less wall-clock time and with less
  back-and-forth.
- The infrastructure bug backlog shrinks (the open issues today are dominated by
  the three bespoke systems being retired).
- Less founder time spent maintaining tooling and firefighting infra.
- More of each new build is assembling existing components rather than building
  from scratch.

## Risks and guardrails

- Do not big-bang. The pilot and wave structure exists to keep any failure small.
- Do not retire a tool before its dependents are gone.
- Content and DB migration on existing sites is the fiddly part; migrate content
  carefully and keep rollback points.
- Keep the old Gitea until the git-host migration is fully proven.
- Re-platform hosting only if previews justify it; default to configuring WP
  Engine's git-push.

## Reference

- [Six major decisions][plan]
- [Current-state audit][audit]
- [Industry research][research]

[plan]: ./agentic-development.md
[audit]: ./current-state-audit.md
[research]: ./industry-research.md
