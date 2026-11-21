# Uniform on Tailwind v4

Written 2026-11-19. Status: building (slices 1 to 3 done in the working tree, uncommitted).
Repos: ~/projects/itsusstudio/uniform (gem in `uniform/`, docs site at root), ~/projects/itsusstudio/workbench/server.
Supersedes: the Uniform-only setup from 2026-11-17 (Tailwind removed from Workbench).

Uniform becomes the studio's tuned Tailwind v4 layer. Apps get all of Tailwind, with Uniform's tokens and components on top as the standard library. Agents build one-offs with plain utilities, and patterns that repeat get promoted into Uniform.

## Problem

One-off screens are slow to build because pure-CSS Uniform has about 40 utilities, so any layout outside them needs a new CSS file or a Uniform edit. Prototyping in artifacts makes this worse: every change means editing Uniform, rebuilding and reloading. A fuller Uniform utility layer would rebuild what Tailwind already has, and agents already know Tailwind.

## Who

The studio: Mackenzie and the agents building Workbench, the docs site and later apps. No customer-facing change.

## Evidence

- Mackenzie's own experience building Workbench screens and artifact prototypes (conversation 2026-11-19). Single source, internal.
- Uniform's `utilities.css` is 175 lines: gap 1, 2, 4, 6, 12, 24 only, one padding class, no flex direction, grid columns or responsive variants.
- The docs site carries about 900 lines of docs-only CSS (`frontend/styles/site/`), mostly per-example demo classes, which makes review slow.

## Decisions already made

- Full Tailwind stays. NEVER wipe a default namespace (`--color-*: initial` and the like). Uniform only adds tokens to the theme.
- Idiomatic setup, like daisyUI and shadcn: the app writes `@import "tailwindcss";` then imports Uniform. Uniform uses Tailwind's own layers (`theme`, `base`, `components`, `utilities`). The `uniform.*` layers go away.
- Preflight is the baseline, because it's the industry standard and what agents expect. Uniform components assume preflight's reset and never compensate for browser defaults. Uniform's `base.css` shrinks to what preflight doesn't cover.
- Colour tokens stay as `light-dark()` in `tokens.css`. `@theme inline` maps Tailwind names to them (`--color-surface: var(--u-color-bg-surface)`), so `bg-surface` flips in dark mode and inside forced-dark areas like the sidebar with no `dark:` needed.
- Static tokens (spacing, breakpoints, fonts) go in plain `@theme`. `--spacing` is set to Uniform's base unit.
- One `@custom-variant dark` block covering system mode and `data-u-theme`, as a safety net for default-palette one-offs.
- Components stay as semantic classes (`u-btn`) in `@layer components`. `@apply` is allowed and preferred for anything a utility can express, so promoting a repeated class list into Uniform is a paste. Plain CSS only for what utilities can't express (structural selectors, `:has()`, state attributes). Uniform depends on Tailwind's build; it isn't meant to work without it.
- Typography roles become functional `@utility` rules so variants work (`md:text-role-page-title`).
- Theme utility names have no prefix (`bg-surface`, `text-muted`). The `u-` prefix marks components only.
- Studio gem views may use Tailwind utilities. A gem that does ships `app/assets/tailwind/<engine_name>/engine.css` with `@source` for its views and helpers, and the app imports it (as studio-auth does). Changed 2026-11-19; the earlier rule was "gem views emit only `u-*` classes".
- Belly stays on its locked toolshed and Uniform revisions (the pre-Tailwind classes) until it's migrated. Don't bump either in Belly before then.
- Tailwind comes in through `tailwindcss-rails` with the standalone binary (no npm), pinned to an exact version. Artifacts load `@tailwindcss/browser` from jsdelivr, pinned to an exact version.
- No third-party Tailwind lint packages. Drift checks are an agent review skill.
- Docs site stays on Bridgetown and keeps dogfooding Uniform. No third-party docs theme.

## Deliberately out of scope

- Restricting Tailwind or blocking classes. The review reports, it never fails a build.
- A JS Tailwind plugin for Uniform. A CSS import is enough and needs no Node.
- Uniform CSS working without Tailwind. Uniform is a Tailwind layer.
- Moving component markup into Tailwind class lists (shadcn-style copy-paste). ERB keeps `u-*` classes.
- Mailers. Email can't use the CSS, and `Studio::Uniform::Mail` stays as it is.
- Other studio apps (Belly, Canvas, Deja Yum). They follow after Workbench proves the setup.
- Renaming Uniform's raw tokens (`--u-*`).

## Approach

### Uniform files (`uniform/assets/uniform/`)

| File | Holds |
|---|---|
| `tokens.css` | Raw `--u-*` variables with `light-dark()`. Unchanged. |
| `theme.css` | `@theme` for static tokens, `@theme inline` mapping semantic names to `--u-*`. |
| `variants.css` | `@custom-variant dark` (system plus `data-u-theme`). |
| `base.css` | `@layer base`, only what preflight lacks: typography defaults, focus rings, `color-scheme`. |
| `components/*.css` | `@layer components`, plain CSS. |
| `utilities.css` | `@utility` for design-decision classes only (typography roles, wordmark). Spacing and flex utilities deleted. |
| `tailwind.css` | Entry point importing the above in order. |
| `artifact-starter.html` | Uniform CSS, pinned `@tailwindcss/browser`, inline theme. |

### App setup (Workbench)

```css
@import "tailwindcss";
@import "<uniform gem>/tailwind.css";
```

`app/assets/stylesheets/` keeps only screen files Tailwind can't replace (print, ActionText).

### Agent review skill (`uniform-review`)

Runs on a diff or folder. Reports, never blocks. Checks:
- arbitrary values (`p-[13px]`)
- default palette colours, plus a missing `dark:` variant
- the same class list 3+ times (component candidate)
- hand-rolled markup copying a Uniform component
- class names built by interpolation in Ruby (`"text-#{tone}"`)
- `border` without a colour (v4 defaults to `currentColor`)
- non-`u-*` classes in studio gem views or Uniform helpers

Output: `file:line`, the class, a count per value. Also a step in `production-review`.

### Promotion loop

1. One-off built with plain Tailwind.
2. Review reports the pattern.
3. Mackenzie approves. It moves into Uniform as a token, `@utility` or component.
4. Gem bump. Review then reports the old class lists as "replace with `u-x`".

## Flow

Agent building a screen:
1. Reads `/llms.txt`: component, then token, then Tailwind utility.
2. Uses a `u-*` component if one fits.
3. Fills layout and one-offs with Tailwind utilities, Uniform colours first.
4. Runs `uniform-review` before asking to commit.

Agent prototyping in an artifact:
1. Starts from `artifact-starter.html`.
2. Builds with the same classes as the app, no rebuild loop.
3. Moves the markup into ERB as is.

## Data and model changes

None.

## Risks

- **Drift:** agents write `flex gap-3 px-4 py-2 rounded` instead of `u-button`. Mitigation: `llms.txt` order, `uniform-review`, the promotion loop. If the review keeps finding reinvented components, tighten the agent rule.
- **Moving onto preflight:** preflight resets more than Uniform's base does (paragraph margins, list styles, link underlines, button and heading defaults). Screens that leaned on browser defaults get fixed to build on preflight, not the other way round. Every Workbench screen and docs page gets a visual pass in its slice.
- **Gem CSS import:** `tailwindcss-rails` engine support is experimental, and its docs and code disagree on the filename (`engine.css` or `application.css`). If it doesn't work, fallback: a build step copies the gem's CSS into the app before Tailwind runs. Serving Uniform outside the Tailwind build is not an option, because components use `@apply`.
- **Opacity modifiers on `light-dark()` tokens** (`bg-surface/50` compiles to `color-mix()`): unverified.
- **Supply chain:** Tailwind's standalone binary is a new dependency. Pin it, follow the 48-hour rule in `dependency-update`.

## Rollout

No Flipper flag: this is a build-time CSS change. Rollout is per slice, each one reviewed and committed on its own. Roll back by reverting the slice's commits. Workbench stays on the released Uniform gem until slice 3 lands.

## Success metric

An artifact prototype moves into a Workbench screen with no new CSS file and no Uniform edit. Measure on the next 5 screens built after slice 3 (target: 4 of 5). Stop and reconsider if `uniform-review` reports reinvented components on 3 or more of those 5 screens.

## Next steps

Decided 2026-11-19: the docs site is the first consumer, then Workbench in the same push, because Workbench dev runs on the local Uniform checkout.

Built 2026-11-19 (differs from the plan above):
- Kept `u-grid` as a block (twelve columns, gutter, container, full-width children). Children use `@2xl:col-span-*`. The long Tailwind form repeated about 350 times.
- Deleted `u-stack`, `u-row`, `u-gap-*`, `u-span-*`, `u-first/hidden-when-stacked`, `u-section`, `u-sidebar-layout`, `u-visually-hidden`, `u-text-muted`, `u-text-strong`, `u-bg-*`, `u-max-width-*`, `u-truncate` and friends, about 84 margin resets, `[hidden]` rules, `layers.css` and `uniform_stylesheet_tags`.
- Gem CSS URLs are logical asset paths (`/uniform/...`), because the Tailwind CLI doesn't rebase URLs. The docs site serves the gem folder through a `src/uniform` symlink.
- Engine entry is `uniform/app/assets/tailwind/studio_uniform_engine/engine.css` (the engine is named `studio_uniform_engine`).
- Tailwind pinned to 4.3.4 in both (tailwindcss-ruby and npm).

Second pass 2026-11-19:
- tokens.css deleted. Tokens are Tailwind theme variables in theme.css (`@theme static`), with property namespaces for colours so classes are `bg-surface`, `text-muted`, `border-input`.
- `--u-space-*` replaced by `--spacing(n)`. Named spacing: `--spacing-edge`, `-gutter`, `-section`, `-target`, `-control`, `-field`, `-row`.
- Type roles are `--text-*` theme entries with weight and tracking; utilities.css deleted; `u-text-data` became `u-data`.
- Width media queries use `--theme(--breakpoint-sm|lg)`.
- `u-container-wide`/`-narrow` replaced by `max-w-page-wide`/`-narrow`; `u-container` kept (Tailwind's container keeps breakpoint max-widths that override ours once flattened).
- `u-prose` kept: the typography plugin would need more overrides than the component has lines.
- Docs build: postcss-import, read-cache and the jit-refresh hook removed; esbuild watches Tailwind's dependency messages.
- Business audience is now the default (theme needs values).


1. **Proof on the docs site** (no commits). In Uniform: draft `theme.css` and `variants.css` from the current `tokens.css`. In the docs site: add Tailwind to the esbuild/PostCSS build and import Tailwind plus the drafts. One artifact page using the starter. Verify:
   - the gem CSS import (engine convention, or the fallback)
   - `bg-surface` in light, dark, system and the sidebar
   - the `dark:` variant in all three modes
   - `bg-surface/50`
   - preflight damage on that page

   Stop and show results before slice 2.
2. **Uniform on Tailwind's layers.** All Uniform files above. Delete `layers.css` and the spacing and flex utilities. Typography roles become `@utility`. Docs site builds with Tailwind. Visual pass on every docs page.
3. **Workbench migration.** Add `tailwindcss-rails`, swap the head stylesheets, delete `app/assets/builds/tailwind.css` (leftover), replace removed Uniform utilities, visual pass on every screen.
4. **`llms.txt` and `uniform-conventions` skill.** Component, token, utility order; the dark rule; NEVER Sass or CSS modules; no dynamic class names.
5. **`uniform-review` skill** (studio-developer plugin, in toolshed). Hook into `production-review`.
6. **Docs site cleanup.** Replace `demos.css` staging classes with utilities in the example partials. Collapse `*-demo-open` classes into one `data-demo-open` convention. Cut decorative specimens. Keep token and colour references, frames, screen iframe and mailer CSS.
7. **Update memory and CLAUDE.md** files that say Workbench is Uniform-only.

## Open questions

- Gem CSS import: engine convention or fallback? Answered by the proof.
- Typography rename (`u-text-*` to `text-role-*`): every app updates its classes. Decide in slice 2. Owner: Mackenzie.
- Exact Tailwind version to pin. Decide in slice 1 per `dependency-update`.
