# Nav review and improvement plan

Date: 2026-10-25
Scope: wp-content/themes/northwest-rebuild — inc/audience.php, inc/nav-render.php,
inc/nav-options.php, inc/nav-ia.php, assets/js/nav.js, assets/css/nav.css,
the speculation rules in functions.php.

## How it works today

- Audiences (For Students, For Partner Networks) are rows in the ACF "Nav
  Options" page. Each row picks a main menu, an optional secondary menu and a
  lane CTA. The current audience is the row whose home URL is the longest
  prefix of the request path; no cookie.
- The header renders four parts: audience bar, Tier 1 (main menu + Give),
  Tier 2 (secondary menu + lane CTA), and a mobile bar. Below 1200px a
  full-screen drawer replaces them, with audience tabs and a one-level
  sliding drilldown.
- Without ACF the theme falls back to the hard-coded IA in inc/nav-ia.php.
- nav.js handles dropdown toggles, the drawer, hiding the audience bar on
  scroll, and a fade between pages for browsers without view transitions.

The structure is sound: small functions, escaped output, no menu walker
subclassing, URL-derived state that caches well. The issues below are mostly
edge cases and accessibility.

## Findings

### Bugs

1. Scroll lock gets stuck. Opening the drawer adds `nw-drawer-locked` to
   body. If the viewport then crosses 1200px (resize, tablet rotation), CSS
   hides the drawer but body keeps `overflow: hidden`, so the page can't
   scroll. nav.js:91-113, nav.css:323 and :480.
2. Drilldown timer race. Going back starts a 320ms timer that hides every
   sub panel. Opening another sub panel inside that window shows a blank
   panel. nav.js:74-89.
3. Deleted pages become dead links. `nws_nav_tree()` doesn't skip menu items
   WordPress marks `_invalid` (target page trashed or deleted); core's walker
   does. None exist today. nav-render.php:22-45.
4. Menu settings are dropped. Target ("open in new tab"), rel, CSS classes
   and title attribute set in Appearance > Menus never reach the markup.
   nav-render.php:33-38.

### Accessibility

5. The drawer isn't a modal. No `role="dialog"`/`aria-modal`/label, and Tab
   moves focus to the page hidden behind it. Needs a dialog role plus `inert`
   on the rest of the page while open (or a focus trap).
6. Desktop dropdowns stay open when keyboard focus tabs out of them; only
   Escape or an outside click closes them.
7. Audience tabs use `aria-current="page"` even when you're on a subpage of
   that audience. `aria-current="true"` is the accurate value there.

### Performance and behaviour

8. Two speculation-rules blocks ship on every page: WordPress core's
   (prefetch, conservative, with sensible exclusions) and the theme's
   (prerender on hover for every same-origin link). The theme's version lacks
   core's exclusions (`/wp-content/*`, `rel=nofollow`, `.no-prefetch`), so
   hovering a PDF or a plugin link triggers a prerender. Each prerender is a
   full uncached PHP render, and it can count as a visit in WP Statistics.
   Fix: drop the theme block and set prerender/moderate through core's
   `wp_speculation_rules_configuration` filter, so there is one ruleset with
   core's exclusions.
9. The fade fallback hijacks every same-origin link click: it cancels the
   click and navigates 160ms later. That breaks `download` links, ignores
   handlers that other scripts register later on document, and adds latency.
   Cross-document view transitions are a progressive enhancement; browsers
   without them can do a plain navigation. Remove it. nav.js:174-201.
10. `nws_icon()` reads the SVG from disk on every call (around 20 per page).
    Cache per request.

### Maintainability

11. Audience key comes from the label. Renaming "For Students" in Nav Options
    changes the body class and key. Nothing in CSS uses that class today. Add
    a stable key field, or drop the body class if nothing needs it.
12. Hard-coded content: the Give URL and label, "Learn More", "Open menu",
    "Back". Move the Give link into Nav Options; wrap UI strings in
    `__()` with the theme text domain.
13. The fallback IA is `require`d (not cached) on each call. Minor; goes
    away if the fallback is only a demo aid.

### Before the theme can go to production (not code)

14. Production has no ACF Pro. The nav (and bca-renderer) need ACF Pro
    licensed and active on production, Nav Options populated, and the three
    menus created there. Without it the nav falls back to the demo IA.
15. Product question for the founder: shared pages (About, News, Events) are
    outside /partner-networks/, so they always show the Students lane, even
    to someone who arrived from the partner side. That follows the "no
    cookie" rule; confirm it's the intended trade-off.

## Plan

PR 1, drawer and dropdown fixes (items 1, 2, 5, 6, 7). JS and markup only;
no data changes. Verify in Chrome at 390px and 1280px: open/close, drilldown
back-and-forth, Escape, Tab order, resize across 1200px with the drawer open.

PR 2, remove page-transition JS and consolidate speculation rules (items 8,
9). Small, mostly deletions. Verify that one speculationrules block remains
and links navigate normally with the fade gone.

PR 3, menu data fidelity (items 3, 4, 10, 11, 12). Touches PHP rendering;
verify on a staging DB pull with a trashed page in a menu and a "new tab"
item.

Separately: item 14 is a prerequisite for launch, and item 15 is a question
for the founder.

Not proposed: rewriting the nav as blocks/FSE or a menu walker. The current
structure fits the design and is easy to read.

## Testing

There are no automated tests. For these PRs, verification is manual in
Chrome against `ddev pull-db staging`. Worth adding later: a small Playwright
smoke test (desktop and mobile nav open, navigate, Escape) run against DDEV,
which agents can also run.
