# Workbench: custom CSS to inline Tailwind

Goal: delete `server/app/assets/stylesheets/`. Every rule ends inline in markup, in a Uniform component, or in a compiled Tailwind file. Zero visual change.

## Context

- Tailwind v4 via tailwindcss-rails. Entry `server/app/assets/tailwind/application.css` (compiled). Output `app/assets/builds/tailwind.css`.
- `app/assets/stylesheets/*.css` served raw via `stylesheet_link_tag "application"` (`app/views/application/_head_content.html.erb:47`) and `"print"` (`app/views/layouts/print.html.erb:14`). Raw CSS can't use `--spacing()`, `@apply`, variants.
- Theme names (Uniform `theme.css`): `bg-surface`, `bg-page`, `bg-paper`, `bg-highlight`, `text-muted`, `text-default`, `border-divider`, `border-default`, `text-danger`, `rounded-item`, `rounded-surface`, type roles `text-page-title`. Read `uniform/uniform/app/assets/tailwind/studio_uniform_engine/` for full list. NEVER invent names.
- Breakpoints: `sm` 40rem, `md` 48rem, `lg` 64rem. `max-sm:` = `width < 40rem`.
- Uncommitted Tailwind migration work sits in these files now. MUST NOT start until `git status app/assets/stylesheets` is clean.

## Decided

Destination per rule, first match wins:

1. Uniform component already covers it: use the `u-` class, delete rule.
2. Styles markup we render (ERB, helper, presenter, JS template string): inline utilities.
3. Same utility mix 3+ places, or generic (not Workbench domain): list as Uniform candidate in output. Inline for now. NEVER edit the uniform gem.
4. Can't be inline: third-party or generated DOM (trix, fernand widget, `@rails/activestorage` uploads), `@page`, `::view-transition-*`, global element resets. Move to `app/assets/tailwind/<name>.css`, `@import` it from `application.css`, wrap in `@layer components` (or `@layer base` for resets). Rewrite with theme vars, `--spacing(n)`, `@apply` where shorter.
5. Rule unused (class/selector has no hit in `app/`): delete.

Ruled out: `@apply`-ing whole old classes into a new `.foo` file (just relocates the CSS), `tailwind.config.js`, third-party Tailwind plugins.

## v4 mapping cheatsheet

| Old CSS | Inline |
|---|---|
| `calc(var(--spacing) * 4)` | `p-4` |
| `width:48px;height:48px` | `size-12` |
| `var(--u-badge-color)` | `bg-(--u-badge-color)` |
| exact value, no theme match | `w-[8.5in]`, last resort |
| `@media (hover: hover) { :hover }` | `hover:` (v4 already gates on hover) |
| `@media (hover: none)` | `@custom-variant touch (@media (hover: none));` in `application.css`, then `touch:` |
| `@media (width < 40rem)` | `max-sm:` |
| `@media (width >= 48rem)` | `md:` |
| `.parent > li` | `*:` on parent, or class on child (prefer child) |
| `.parent svg` | `[&_svg]:` on parent, or class on svg (prefer svg) |
| `.parent:hover svg` | `group` on parent, `group-hover:` on svg |
| `body:has(#x) .y` | `[body:has(#x)_&]:` on `.y` if markup ours, else rule 4 |
| `[data-state=open]` | `data-[state=open]:` |
| `!important` | `utility!` |
| `field-sizing: content` | `field-sizing-content` |
| `color-mix(...)` hover | `hover:bg-(--u-badge-color)/85` if visually equal, else arbitrary value |
| `transition: opacity 120ms` | `transition-opacity duration-120` |

Do / don't:

```erb
<%# don't %> <ul class="photo-grid">
<%# do %>    <ul class="grid grid-cols-5 gap-2">
```

```ruby
# don't
"bg-#{color}-500"
# do
{ danger: "bg-danger", neutral: "bg-(--border-color-divider)" }.fetch(tone)
```

## Steps per file (one subagent = one CSS file)

1. Read whole CSS file. For each selector, `grep -rn` its class/id in `app/ config/locales test/`. Build table: selector | used in | destination (Decided 1-5).
2. If selector used by JS (`querySelector`, `classList`, `closest`, Stimulus): JS hook becomes a Stimulus target, `id` or `data-` attribute. Styling class goes inline. NEVER let JS depend on a styling class.
3. If JS builds the element (template string, `createElement`): write full utility names in JS string. Confirm they land in `app/assets/builds/tailwind.css` after build.
4. If helper/presenter emits the class: put utilities in the helper. Variant maps use full literal strings.
5. If same markup repeats in 2+ views (`photo-grid` in dashboard and portal): extract shared partial or helper first, then inline once.
6. Inline utilities per cheatsheet. Keep existing `u-` classes. Order in `class`: Uniform class, layout, box, type, colour, variants.
7. Rule-4 leftovers: create `app/assets/tailwind/<file>.css`, import it in `app/assets/tailwind/application.css`.
8. Tests selecting removed classes (`assert_selector ".photo-grid"`): switch to `id`/`data-` hook. NEVER assert copy.
9. Delete CSS file. Remove its `@import url(...)` line from `app/assets/stylesheets/application.css`.
10. `bin/rails tailwindcss:build`. MUST succeed.
11. Visual check in Chrome (local connection), `http://app.workbench.localhost:3000`, user's running dev server (NEVER start it). Before and after, light and dark, widths 375, 768, 1280. Pages: every view from step 1 table. If difference: fix, recheck.
12. Run tests for touched views/helpers/controllers only. NEVER full suite.

## Rules

- MUST keep pixel parity. Refactor only markup structure (partials, hooks), never look.
- MUST prefer theme value over arbitrary value. Arbitrary only for print measures, third-party sizes, one-off exact px.
- NEVER build class names by interpolation.
- NEVER add comments except a non-obvious why.
- NEVER edit files outside the step-1 table plus `app/assets/tailwind/`.
- NEVER commit, stage or push. Lead agent commits per file after human approval, `git commit -- <paths>`.
- Lines under 120 chars. Long class lists: split `class:` across lines in helpers, never rewrap untouched code.
- Stop and report if: a selector targets markup in a gem, a rule needs `!important` to win over Uniform, or parity can't be reached.

## Waves

Files touch disjoint views inside a wave, so agents run in parallel. Next wave starts after previous wave approved.

| Wave | Files | Notes |
|---|---|---|
| 1 | `base.css`, `job-statuses.css`, `support-chat.css`, `portal.css`, `error-page.css`, `terms.css`, `messages.css` | `base.css`: `[hidden]` reset to `@layer base`; `.u-card > header` fixes are Uniform candidates; `.button_to button` into button helper. `support-chat.css`: fernand DOM, rule 4. `error-page.css`: keep parity with `public/404.html`. |
| 2 | `direct-uploads.css`, `job-intake.css`, `photos.css` | `direct-uploads.js` builds DOM, step 3. `job-intake.css`: `view-transition-name` inline via `[view-transition-name:job-intake-client]`, `::view-transition-*` rules rule 4. `photos.css`: shared partial first, `darkroom` hooks in `photo_viewer_controller.js`. |
| 3 | `print.css`, `actiontext.css` | `print.css`: `@page` and `.print-body` resets rule 4 in `app/assets/tailwind/print.css`; sheet sizes inline arbitrary. `actiontext.css` (619 lines): trix DOM, rule 4 in `app/assets/tailwind/trix.css`, delete unused selectors, `@apply` theme utilities. List as Uniform rich-text candidate. |
| 4 (lead) | `application.css` | Delete `app/assets/stylesheets/`. Remove `stylesheet_link_tag "application"` and `"print"` from both layouts. `bin/studio style`, `bin/studio lint`, targeted tests, full visual pass. |

## Output (each subagent)

```
file: <css file>
table: selector | used in | destination
files changed: <paths>
uniform candidates: <utility mix> | <places>
leftover css: <app/assets/tailwind/x.css lines, why>
checked: pages + widths + themes
tests: <command> <result>
```

## Done

- `app/assets/stylesheets/` gone, no `stylesheet_link_tag "application"`/`"print"`.
- `grep -rn` of every deleted class returns 0 hits in `app/ test/`.
- `bin/rails tailwindcss:build`, `bin/studio lint`, `bin/rails test` pass.
- Visual pass shows no difference.
