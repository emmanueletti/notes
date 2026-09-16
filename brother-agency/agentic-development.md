# Agentic development

## Problem

Brother Creative Agency builds WordPress sites for a growing roster of
organizations. Every build pulls Sean off growing the agency and onto producing
website deliverables.

## Opportunity

LLMs can now write and run code far cheaper and faster than a human developer,
but only when the workflow is simple, reproducible, and standard.

What follows is six decisions, each judged on whether it makes the system
simpler and lets agents move faster.

## Decision 1: Context and knowledge structure

This covers how an agent gets oriented to the agency, a client, and a repo.

Today that runs through an 8-layer knowledge architecture with many moving
pieces. The tiering idea underneath it is sound. The machinery around it is docs
about docs, and it costs real maintenance time.

Keep the tiering but simplify the process. Three tiers:

- Agency HQ knowledge repo: agency-wide methods, doctrine, and standards.
- Per-client knowledge repo: relationship, meeting intelligence, project memory.
- Per-repo `AGENTS.md`: the implementation details for that specific projects.

## Decision 2: Project foundation

The concrete structure of a WordPress project repo.

Repos today are wp-content only, with a strict `.gitignore`. That is clean, but
it is not reproducible: core is not pinned, and there is no environment parity.
WP Engine and Cloud Dev currently paper over the gap.

Adopt Composer plus Docker (DDEV), keeping the classic `wp-content` layout.

- Composer pins wp-core and plugins as versioned dependencies. `composer.lock`
  becomes the manifest the strict `.gitignore` currently lacks.
- Docker (DDEV) runs each project in its own PHP and MySQL/MariaDB versions,
  isolated and reproducible.

Reproducibility is what makes agent builds deterministic. `composer install`
plus a container rebuild gets any project back to an identical state.

Bedrock is the obvious candidate here and is deliberately not adopted. It is a
real standard within the Composer-based WordPress niche, but its two distinctive
features are a `web/` document root and `.env`-driven config loaded through
`wp-config.php`. WP Engine allows neither: the docroot is fixed at the install
root, and WP Engine owns `wp-config.php`. Running Bedrock there requires a build
step that flattens `web/app/` back to `wp-content/` plus an autoloader mu-plugin
shim. That is cost without benefit, because the reproducibility this decision is
actually after comes from Composer and DDEV, not from Bedrock. Revisit only if
hosting moves to a platform where the docroot can point at `web/` (Kinsta,
Upsun, Sevalla).

The cost: premium plugins need Composer setup, and the team has to learn some
Composer basics. Both ACF Pro and Gravity Forms publish official Composer
endpoints authenticated with the license key, so this is configuration rather
than custom infrastructure. Credentials live in 1Password and reach CI as
`COMPOSER_AUTH`. Agents handle the setup, and it is a one-time cost per project
template.

## Decision 3: Build methodology

How pages actually get built.

Today: Beaver Builder plus Themer plus ACF plus custom shortcode renderers, with
the design living in the database. Most of the agency's ceremony traces back to
this one fact. DB-change receipts, snapshot-before-edit, Themer boundary
doctrine, shortcode-duplication rules, QA-surface machinery: all of it exists to
cope with design-as-database. The agency is already partway toward ACF Blocks.

Move to design-as-code, with a shared component library surfaced as ACF Blocks,
and retire Beaver Builder.

- A central brother agency component library means build once, reuse across
  similar client sites.
- ACF Blocks put markup in code and content in structured fields. ACF Local JSON
  (already in the repos) keeps field config in git.
- Tailwind fits on top of this rather than competing with it. Agents write it
  well, and utilities in markup mean one place to write and style. The reuse
  comes from ACF Blocks; Tailwind is just the styling layer.

Design becomes text agents can build, diff, and reuse. The DB-as-truth ceremony
goes away with it, and staging turns into an ordinary code deploy instead of a
database merge.

One discipline is worth keeping: validate the components and blocks. The
[industry scar][acf] here is that unvalidated block systems drift over time. A
lean QA surface for the component library earns its keep.

## Decision 4: Source control and integration

Where source lives, and how branches integrate.

Right now source lives on a self-hosted Gitea instance on one laptop, with no
off-site backup, plus a hand-built merge queue sitting on the integration path
of every repo, maintained by AI . This is the riskiest thing in the agency: a
single point of failure with no vendor behind it.

Move to a managed git host, GitHub or GitLab, and use its merge queue, protected
branches, and PR checks.

Then the vendor maintains the integration path instead of the agency, and
backups, access control, and CI arrive with it. Agents open PRs against a
platform they already know well rather than a custom queue.

## Decision 5: Hosting, environments, and deploy

Where sites run, and how code reaches staging and production.

Today: WP Engine, plus a custom sandbox control plane that spins up disposable
per-branch QA worlds, plus ssh-pull deploy with custom apply scripts.

Stay on WP Engine. Two fixed environments per site, Staging and Production, both
deployed from GitHub Actions. Retire the custom sandbox and the ssh-pull apply
tooling.

Per-branch and per-PR preview environments are explicitly not wanted. DDEV local
is where a branch gets reviewed, which is what Decision 2 buys. Dropping that
requirement removes the only reason to consider a PaaS migration, and it retires
the sandbox control plane, the review worlds, and the Review Console with
nothing needed to replace them.

Deployment stays branch-based: push `staging` for staging, push `main` for
production. Code flows up, content flows down, so pull production content into
staging when you want a realistic preview.

One correction to the earlier [research][hosting]. WP Engine's native git-push
deploy pushes the repo to the WordPress root with no build step, so it cannot
run `composer install`. Keeping plugins Composer-managed therefore means
deploying through GitHub Actions: build first, then sync `wp-content/` with WP
Engine's official deploy action. That is WP Engine's own documented path for
Composer-based sites. Still low risk and still no migration, but it is not
"configure what you already have".

Provisioning gap: BOH has Production, Staging, and Development on WP Engine. SAV
records only `savprd` (Production) and needs a Staging environment before it can
follow this flow.

## Decision 6: Secrets and access

Agents and humands should never have access to raw secrets without access
controls. Brother already uses 1Password which has vault access patterns that
scripts and skills can implement.

## Reference

[Industry research][research] grounds these decisions in what modern WordPress
agencies do, with the guides and case studies behind them.

[research]: ./industry-research.md
[consensus]: ./industry-research.md#the-consensus-stack
[acf]: ./industry-research.md#acf-blocks-strong-consensus-one-real-caveat
[hosting]: ./industry-research.md#hosting-a-nuance-that-may-avoid-a-migration
