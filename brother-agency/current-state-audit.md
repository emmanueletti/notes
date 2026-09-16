# Current state audit

Purpose: document what Brother Creative Agency runs today, compare it to the
modern industry standard ([industry research][research]) and to the six
[planned proposals][plan], and articulate how the recommendations increase
productivity into the next phase of scale.

## Method and caveat

Audited by exploring the agency Gitea over the browser and cloning key repos
locally (`agency-knowledge`, a client runtime repo, a client knowledge repo).
The instance audited is labeled "WRITABLE REHEARSAL - NOT PRIMARY"; it is
representative but may not be authoritative on repo sizes or the very latest
state. The primary is a local Gitea on the founder's laptop.

## What Brother runs today

Infrastructure and agents:

- Self-hosted Gitea as source of truth, single `sean/` owner, ~44 repos.
- The agent is OpenAI Codex. Instruction files are `AGENTS.md`.
- A hand-built merge queue enrolls every repo with protected `main`; integration
  is worktree-per-task, no direct-main.
- Local dev is WPDev/Cloud Dev with disposable per-branch sandbox QA worlds.
- Hosting is WP Engine, with dedicated transport and keychain tooling.
- Secrets use 1Password (SSH keys via the 1Password agent; secrets kept out of
  git); a separate file-share surface handles agent-to-founder handoffs.

Repo taxonomy (naming-convention grouping, polyrepo by concern):

- `client-<name>` (Markdown): relationship and meeting intelligence, project
  memory.
- `client-<name>-wordpress` (PHP): the WordPress runtime, wp-content only.
- `client-<name>-editor-wiki`, extra site repos for some clients.
- `agency-knowledge`: the canonical knowledge base and doctrine.
- `tool-*`: roughly ten internal tools (sandbox control plane, merge queue, bug
  filer, docs compiler, OpenAI control plane, WP Engine transport, artifact
  registry, time tracker, meeting-intelligence intake, git hooks).
- `plugins-wordpress` and `wordpress-plugin-*`: premium plugin artifacts and
  shared plugins.

Knowledge system (`agency-knowledge`):

- An 8-layer knowledge architecture with `AGENTS.md`, `ARCHITECTURE.md`,
  `INDEX.md`, `CURRENT.md`, `WORDPRESS-METHODOLOGY.md`, and domain folders
  (`acf/`, `beaver-builder/`, `wpengine/`, `methods/`, `figma/`, `clients/`,
  `project-cockpits/`, and more).
- Automation and doctrine on top: a corpus-gardener, tombstone ledgers,
  template-stamped files, generated index blocks, status vocabularies, guest
  books, promotion doctrine, and a mechanical-enforcement doctrine.

Build methodology:

- Beaver Builder plus Themer plus ACF plus custom shortcode renderers, with
  design living in the database.
- Runtime repos are Beaver Builder child themes (`acf-json/`, `classes/`,
  `functions.php`, component renderers, `style.css`) plus mu-plugins.
- No `composer.json`, no build step, no Tailwind. Plain PHP and CSS.
- ACF Local JSON is committed to git (field config as code).
- Deploy via a WP Engine deploy config and deterministic apply scripts.
- Premium plugins are gitignored and stored as artifacts.

## Findings

Genuine strengths (credit where due):

- Rigorous git hygiene. New runtime repos are tiny and clean; a sampled runtime
  repo was 745 KiB with core, uploads, plugins, and dumps all gitignored.
- Knowledge is already split from runtime, which matches both the industry
  standard and the plan.
- ACF Local JSON in git is config-as-code done right.
- Already mid-transition toward ACF Blocks, the correct direction.
- A real audit trail (receipts) for agent actions on client sites. Some of this
  ceremony is legitimate agent-tax, not waste.
- 1Password and deterministic deploy tooling are already in place.

Concerns (scale and maintenance risks):

- Tooling-to-deliverable ratio is inverted. Around ten bespoke `tool-*` repos
  are a platform team's output resting on a solo, non-technical founder plus
  agents. Every one is maintenance surface competing with client work.
- The knowledge system is largely documentation about documentation. A large
  share of agent effort maintains the system that describes the work.
- Enterprise ceremony on a solo operation: a hand-built merge queue on the
  critical path of every repo, protected main, worktree-per-task, and a
  git-tracked receipt for every runtime change.
- Repo sprawl (two to six repos per client) is partly what the registry and
  index tooling then exists to manage. Complexity generating complexity.
- Not reproducible. No pinned core, no container parity, so agents can hit
  works-in-my-environment failures and projects cannot run isolated stacks.

## Documented pain: what the issue tracker shows

The issue trackers are the clearest evidence of where the current state hurts.
Across all repos there were 217 issues at audit time: 71 open and 146 closed.
Bugs file into each tool's own repo, with cross-cutting ones in
`agency-bug-issues`. The striking finding is what they are about: almost none are
about building client WordPress sites. They are overwhelmingly about the bespoke
agentic infrastructure breaking.

The open issues concentrate hard in the three core bespoke systems: the WPDev
sandbox control plane (`tool-bca-sandbox`), the hand-built merge queue
(`tool-gitea-merge-queue`), and the WP Engine transport tool (`tool-bca-wpe`).
These are exactly the pieces the plan recommends retiring in favor of managed
platforms. Typical open bugs: sandbox snapshot and lane failures, WordPress OOM
and 502s in sandboxes, the merge queue writing SQLite state into caller
worktrees, and the WPE tool selecting an incompatible rsync and failing.

Representative sample across the trackers:

- Agent platform (OpenClaw): updater leaves stale extensions and rejects new
  versions (blocker), auth watchdog went blind after a SQLite migration, browser
  stop leaves Chrome running, LaunchAgent points at a broken Node after a
  library drift (blocker).
- Agent desktop (Codex/Claude): Desktop appears dead after an update while the
  backend completes, provider-migrated tasks silently lose execution tools
  (blocker), task events dropped during concurrent work, annotation clicks
  ignored.
- Internal tools: `tool-agency-time-tracker` alone generated a cluster of
  billing-correctness and security bugs (rounding divergence, unenforced
  capability, no login throttling, stale-lock installs). `tool-bca-wpe` selects
  the wrong rsync and fails. A load balancer logs a bootstrap token in
  plaintext.
- The infrastructure itself: the local Gitea exposes confusing legacy surfaces
  and a stale primary label; the Computer Use bridge times out on Chrome.

Two patterns stand out:

- Recurring security defects in home-built tooling: plaintext API keys in
  gateway logs, a bootstrap token logged in plaintext, a secret-bearing config
  field printed, an auth endpoint with no throttling, a granted capability never
  enforced. Each is a self-inflicted exposure from software the agency built and
  now must secure itself.
- Self-maintenance as planned work: the agency runs named sprints purely to fix
  its own tooling (wpdev-control-plane, bug-filer-reliability,
  tracker-review-fixes, wpdev-site-identity). Agents file bugs about their own
  operating environment.

Interpretation: the bespoke platform is a maintenance sink. It produces a
continuous stream of high-severity work (many major, several blocker, several
security) that has nothing to do with client deliverables. This is the inverted
tooling-to-deliverable ratio made concrete. Every hour spent here is stolen from
client sites and from growing the agency. Retiring bespoke tools in favor of
managed, vendor-maintained platforms removes most of this class of work
outright, and removes the security burden of securing home-built infrastructure.

## Three-way comparison

Current state vs industry standard vs the plan's recommendation.

| Area | Current | Industry standard | Plan recommendation |
| --- | --- | --- | --- |
| Context and knowledge | 8-layer system plus gardener, tombstones, guest books | Short AGENTS.md plus self-describing code | Lean 3-tier: HQ, client, per-repo AGENTS.md |
| Project foundation | wp-content-only repos, not reproducible | Bedrock plus Composer plus DDEV, reproducible | Bedrock plus Composer plus Docker |
| Build methodology | Beaver Builder plus DB-as-truth plus shortcodes | ACF Blocks reusable component library | Design-as-code: ACF Blocks plus component library |
| Source control and integration | Self-hosted Gitea plus hand-built merge queue, no backup | Managed git host with built-in merge queue | Managed git host (GitHub or GitLab) |
| Hosting, environments, deploy | WP Engine plus bespoke sandbox plus ssh-pull | Host-native git-push deploy plus previews | Configure WP Engine git-push, or move to PaaS |
| Secrets and access | 1Password | Dedicated secrets or password manager | 1Password (keep) |

Reading of the comparison:

- Areas already aligned or ahead: knowledge/runtime split, git hygiene, ACF JSON
  as code, 1Password, the ACF Blocks direction.
- Areas where the current state is heavier than both industry and plan: the
  knowledge doctrine, the merge queue, the sandbox control plane, the `tool-*`
  fleet.
- Areas where the current state lags the standard: reproducibility (no
  Bedrock/Docker) and a managed integration path.

## Why the complexity exists

Three forces, worth separating because only some are fixable by simplification:

1. Agent-tax (legitimate). Receipts and mechanical gates exist because agents do
   the work on client production and can go off-script. Some ceremony survives
   any rebuild.
2. Beaver Builder and design-as-database (accidental, fixable). Most ceremony
   (DB receipts, snapshot-before-edit, Themer boundaries, shortcode-duplication
   rules, QA-surface machinery) exists to cope with design living in the
   database. Design-as-code dissolves this category.
3. Solo-founder accretion (accidental, fixable). A talented, overloaded founder
   hacking with agents accumulates bespoke tools and doctrine. Each was a
   reasonable local fix; together they are a maintenance load that does not
   scale.

## How the recommendations enable the next phase of scale

The through-line: simplification is the enabler, agent throughput is the payoff.
Each recommendation removes drag or adds leverage.

- Reproducible builds (Bedrock plus Docker) make agent builds deterministic.
  Agents stop debugging environments, and many client sites on divergent stacks
  run in parallel. This raises how many builds can be in flight at once.
- A reusable component library surfaced as ACF Blocks turns each new site into
  "assemble known blocks with new tokens and content," which is the agentic
  sweet spot. Build-once-reuse-many compounds: the more similar the sites, the
  faster each new one ships. Agents are strong at Tailwind and ACF Blocks.
- Design-as-code dissolves the DB-as-truth ceremony. Staging becomes a normal
  code deploy, not a database merge, and the receipts, snapshots, and gotcha
  doctrine around Beaver Builder mostly disappear. Less ceremony per change.
- A lean 3-tier context cuts the agent effort spent maintaining the knowledge
  system. Agents orient faster and spend cycles on client work, not gardening.
- A managed git host plus host-native git-push deploy retire the merge queue,
  the sandbox control plane, and the ssh-pull tooling. The vendor maintains the
  critical path, not the founder.
- Retiring the `tool-*` fleet reclaims the founder's and agents' time. That time
  goes to the component library (the moat) and to Sean growing the studio.

Net effect: throughput per site goes up (reproducible, reusable, less ceremony),
maintenance drag goes down (standard stack, vendor-maintained infra), and the
founder is freed from being the single maintainer of a bespoke platform. That is
the difference between a system that ships sites and a system that can scale the
number of sites without scaling the founder's hours.

## Urgent items independent of the plan

- Purge history on the bloated repos. A `.gitignore` stops new bloat but does not
  shrink existing repos; the gigabytes live in history. Rewrite history with
  `git filter-repo` (or BFG), then re-clone.

## Reference

- [Six major decisions and recommendations][plan]
- [Industry research and sources][research]

[plan]: ./agentic-development.md
[research]: ./industry-research.md
