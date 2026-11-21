# Tailscale design notes for Uniform

Gathered 2026-11-17. Sources: the Spellbook npm package (`@tailscale/spellbook` 0.0.38, BSD-3, React + Tailwind v4 + Radix + lucide-react; README says not maintained for outside use) and computed styles measured on console.tailscale.com/admin/machines. Workbench measured on Home in the same browser (devicePixelRatio 1.5, so screenshots are 1.5x CSS px).

## Type

| | Tailscale | Uniform today |
|---|---|---|
| Family | Inter, system fallback | Switzer |
| Base | 14/20, letter-spacing -0.015em (-0.21px) on everything | 16/24 body, 14/21 chrome, no tracking |
| Nav, buttons, inputs, table cells | all 14 | nav and buttons 14, lists now 16 |
| Small | 12, only for uppercase table headers and badges | 12 and 14 for details |
| Page title | 24/30, 600, -0.025em (`pageTitle` = text-3xl class, rendered 24) | 32/36, 500, -0.02em |
| Section title | text-xl 600 -0.025em | 16 500 |
| Table header | 12, 700, uppercase, +0.05em, muted | none |

The point is one size for nearly everything, with hierarchy from weight and colour.

## Weight

- 400: body, inactive nav, table cells, secondary line in a row
- 500: active nav item, buttons, badges, field labels
- 600: the row's primary name, page and section titles
- 700: uppercase table headers only

Uniform uses 500 on every nav item (active and inactive look the same), on buttons, h1 and h2, and 400 on list row names. Chrome is heavier than content; Tailscale inverts that.

## Colour (light)

- text base #232222, muted #706e6d, disabled #afacab
- border base #eeebea (lighter than Uniform's card border #d3d3ce), interactive border #dad6d5
- app bg #f7f5f4 warm, surfaces #fff
- primary #3f5db3 (links underlined with a pale decoration, offset 4px)
- status text: danger #940821, warning #983705, success #0e6245
- colour appears only for meaning: green connected dot, red upgrade icon, blue primary button and links

## Surfaces

- card: 12px radius, hairline #eeebea border, shadow 0 4px 12px rgb(0 0 0 / 3%), 20px padding
- buttons: 36px tall, 6px radius, 0 12px padding, shadow 0 1px 1px rgb(0 0 0 / 4%)
- badges: 12/500, 2px radius, flat grey fill #eeebea, text #444342
- radius scale 2/4/6/8/12
- content max-width 1600, 40px side padding

## Rows

- table rows 60px for two lines, 8px vertical cell padding, hover tint, hairline dividers
- primary line 600, secondary line 400 in the same text colour (not muted)

## Icons

- lucide-react, same set as Uniform
- Lucide (class lucide-*), stroke-width 2 in the 24 grid, scaled to 16px, so the line renders at about 1.33px (Uniform draws a fixed 1.5px with non-scaling-stroke, so it is heavier)
- sidebar icons 16px in the text colour; the 18px icon is the tailnet logo
- icons beside text in tables and chips are muted (#706e6d or #afacab) unless they carry status

## Candidates to prototype

1. Interface base 14/20 everywhere with -0.015em tracking; 12 only for uppercase labels and badges
2. Weight ladder 400 / 500 active-and-controls / 600 primary / 700 caps labels; inactive nav at 400
3. Inter for interface text, Switzer for display only
4. Page title 24/600
5. Lighter dividers and card border, 12px card radius, faint card shadow, warm app background behind white cards
6. Thinner icon line, about 1.33px at 16px
7. Primary row line 600, secondary line in default colour

## Decisions (Uniform refinements prototype)

Prototype: https://claude.ai/artifact/SDaCLkXWZpNLYM2WPFLWjF, built by the scratchpad refine/build.py.

1. Type, 2026-11-17: Inter for interface text at 14/20 everywhere, -0.015em tracking, page title 24, 12 only for badges and caps labels. Switzer stays for wordmark and display. Applies to the business audience; consumer stays at 16. Uniform needs Inter self-hosted as woff2 (OFL).
2. Sidebar nav, 2026-11-17: keep the 264px width and the paper background (Uniform's vintage tech-paper look). Nav icons in the text colour, not grey. A gap between groups instead of section labels. Current item a lighter ink tint (5%, hover 3%) instead of 9%.
3. Sidebar footer, 2026-11-17: Tailscale layout. Guides and Help above a rule; Help opens a menu each app fills with its own links (Help centre, guides, what's new, chat, feedback). Account row: round 28px avatar, name, email address under it in 12px grey, no chevron. Account menu as wide as the sidebar with roomy rows: Appearance, rule, Log out in red.
4. Cards vs open sections (direction, 2026-11-17): cards stay for grouped data and actions (Home, job page, reports). Settings pages use cardless setting rows. Do not make every surface boxless.
5. Font, 2026-11-17: Inter replaces Switzer as Uniform's sans (--u-font-sans). Switzer leaves the system; display stays Apfel Grotezk, wordmark Instrument Serif, code IBM Plex Mono.
6. Muted text, 2026-11-17: Tailscale rule. Everything you read is in the main text colour (page and card subtitles, row second lines, modal body). Grey only for labels: column headers, field hints, meta, section labels. Verified on the Machines page: 49 text runs in #232222, 10 grey, all labels.
7. Settings layout, 2026-11-17: setting rows for settings pages. No cards; each setting is a heading and one line saying what it does. Switches and single actions on the right and apply straight away; text fields underneath, capped at 24rem, save on blur; read-only values in a tinted box with Copy; groups separated by a hairline and a 20px heading; 768px column. In Uniform it is a CSS pattern, no JS: u-settings container, u-setting row, u-setting-stacked for fields underneath. Saving on change or blur is app-side (a form per row, Workbench debounced-submit).

## Final picks (2026-11-17)

Type C (Inter 14/20, -0.015em, page title 24) · Weight D (400, 500 for names, titles, current nav) · Colour E (flat cards, hairline edge, light dividers, dark header rule, names in text colour) · Icons B (1.33px line) · Density B (list rows 12px padding, table rows 44px) · Numbers A (IBM Plex Mono stays, vintage tech paper) · Muted B (labels only) · Settings rows · Sidebar footer B · Page widths B (1600 data, 768 settings and forms) · Sidebar nav B (264 paper, text-colour icons, gaps, 5% current, 4px highlight) · Shape D (4px frames, pill actions, round avatars and knobs).

Fonts: Inter replaces Switzer. Wordmarks stay Instrument Serif and Bricolage Grotesque; headline Apfel Grotezk; mono IBM Plex Mono.

Watch: row name vs description with 500/400 in one colour. Judge on real Workbench data; fallback is 600 for row names only.

## Uniform change list

1. Fonts: self-host Inter (OFL woff2, 400 and 500), --u-font-sans to Inter, drop Switzer files and @font-face, -0.015em tracking on body.
2. Type scale (business audience): body, small 14/20, caption 12 for badges and caps labels, page title 24. Revert the list body-size bump.
3. Weights: inactive nav 400, row names and titles 500, buttons 500, column headers 400.
4. Colour: divider #ebeae6, border #e3e2dd, dark rule under column headers kept, names in tables in text colour, muted only for labels (page and card subtitles, row details, dialog body to text colour).
5. Shape: --u-radius-default 4px, --u-radius-pill unchanged, sidebar current and hover 4px, menu items and list hover 4px.
6. Icons: stroke 1.33px, default icon 16px.
7. Density: list rows 12px block padding, table rows 44px.
8. Sidebar: nav icons text colour, drop section labels for a gap, current 5% tint, hover 3%. Footer: links above a rule, help menu slot apps fill, account row with round 28px avatar, name and email address, no chevron, roomy account menu (Appearance, rule, Log out in danger).
9. Container: add a narrow 768px width for settings, forms and prose.
10. Settings pattern: u-settings, u-setting, u-setting-stacked (CSS only), groups split by hairline and 20px heading, read-only value box with Copy.
11. List fixes already in progress: avatar flex none, progress count min-width, trailing icon pushed to the end.
12. Fieldset: make the bordered fieldset with the legend in the border intentional (border token, 4px radius), as in the Paid by example.
13. Docs: Braun added to inspiration. Save prototype examples to pages: settings rows (new patterns/settings page), the new sidebar with footer and help menu (sidebar and dashboard-shell pages), the forms with the Paid by radio group (form and radio pages), job page with toolbar and icon buttons (navigation and icon pages), Home cards (patterns/dashboard-shell). Update typography, colour, shape-and-depth, iconography and space-and-layout foundations.

## Settings organisation (2026-11-17)

Settings folds open in the main sidebar (Tailscale), not a nav swap and not an in-page side nav. The Settings group holds shop pages only, in order: General, Team, Billing, Job statuses, Job form, Reminders, Messages, Policies. Personal pages (Profile, Preferences, Appearance) live in the account menu. Each settings page uses the narrow column, setting rows, and General ends in the danger zone.
