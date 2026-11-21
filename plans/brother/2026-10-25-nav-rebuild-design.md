# Nav rebuild: design

Date: 2026-10-25
Status: built (desktop, dropdowns, mobile); sign-off pending
Replaces: the audience-switcher nav in northwest-rebuild (inc/nav-*.php,
inc/audience.php, assets/js/nav.js, assets/css/nav.css). The review in
2026-10-25-nav-review.md is the list of mistakes not to repeat.

## Source designs (Figma "Northwest - Internal", ycKscXj4jUmXtm7fhsWY5P)

- Menu component, two variants, both "light" colour:
  - default (Students): 1502:6522 on "[NEW] Home"
  - partners (Partner Networks, with sub nav): 1381:5035 on "Explore Program"
- Dark colour version (light page behind the header): 1130:12424 on
  "Partner Networks"
- Dropdown explorations: 989:2075 (panel under the bar) and 989:2195
  (dropdown children shown as a yellow second bar), page "New Site Mockups V1"
- No mobile nav, sticky/scrolled state or dropdown-final designs exist yet.

## What the design shows

Three stacked rows, 1300px wide at the 1440 artboard, floating over the hero:

1. Utility row (no background): audience tabs left, email and phone right.
   Active tab has a 2px yellow underline; inactive tabs at 50% opacity.
   16px Afacad Bold.
2. Main bar: rounded card (15px radius, 40/20 padding). Logo left (200x45),
   menu centre (18px Afacad Bold, 40px gaps, optional dropdown caret), CTA
   button right (orange, asymmetric radius 25/5/25/5).
3. Sub nav (optional): full-width pill (radius 100), light blue, items
   centred, 16px Afacad Bold, 40px gaps.

Two colour schemes, chosen by what's behind the header:

| Scheme | Utility text | Main bar | Menu text | Logo |
|---|---|---|---|---|
| light (over dark hero) | #FFFFF9 | Sand #EFEFE9 | Dark Blue #113840 | colour |
| dark (over light page) | #113840 | Dark Blue #113840 | #FFFFF9 | white |

Header height: 116px without section links, 170px with them (at 1440; the component frame says 167, but its sub nav ends at 170).

Design tokens from Figma: Dark Green #3F4E31, Yellow #EAB600, Dark Blue
#113840, Text Light #FFFFF9, Medium Orange #CD6500, Sand #EFEFE9, Light Blue
#97CCD9. The theme's current tokens differ (orange #e05d02, no sand); align
them to Figma as part of the rebuild.

## Decisions (2026-10-25)

1. Each page has an explicit audience, inherited from its parent; no URL
   guessing.
2. CTA comes from the audience; any page can override it.
3. Pages with no audience (directly or inherited) use the default audience,
   the first one in the list.
4. Each audience has its own main menu; all share one visual design.

## Data model

Everything editors change lives in screens they already know.

Site-wide, Appearance > Navigation (ACF options page):
- Audiences (repeater, order = tab order, first = default):
  label, home page, main menu (select a WP menu), CTA (link)
- Contact: email, phone

Per page, a "Navigation" box in the page sidebar (ACF field group on pages):
- Audience: only for exceptions. An audience's home page claims itself and
  every page under it; pages outside any use the default audience.
- Section links: Automatic (default) shows the pages under the top-level
  menu item the visitor is in, so editors control it by editing the menu.
  None, or A different menu (for #anchor links to parts of a page), apply
  to the page and the pages under it.
- Header button: link, empty = the audience's button. Applies to the pages
  under it too.

Header look (decided 2026-10-25, follows Figma): dark-blue bar by default.
A hero whose image the editor marks as dark (`nw-hero--dark`, a field next
to the image upload in the hero section) switches the header to the sand
bar with off-white top row. CSS reads it with :has(), so there's no page
setting. Later: pre-fill that field from the image's measured brightness
on upload.

Menus are ordinary WordPress menus (Appearance > Menus), named by role so
they group: "Audience menu – For Students", "Section links – Gap Year",
"Footer – About". The menu editor shows where each menu appears. Labels, order, nesting, "open in new tab" and CSS classes all come
from the menu editor. No menu content in theme code.

## Rendering

- Server-rendered PHP, no cookies, so WP Engine's page cache stays valid.
- One function resolves the nav context for the current request (audience,
  main menu, sub nav, CTA, colour) once; templates only render it.
- Menu trees come from wp_get_nav_menu_items, skipping `_invalid` items and
  carrying target, rel, classes and title through.
- Same data renders the desktop header and the mobile drawer.

## Reuse

Build the header as a self-contained theme component: one PHP template, its
CSS and JS, and a single nav-context function as its only input. That unit
is what moves into bca-wp-starter for the next client site.

Not a block. The sub nav sits in the header stack over the hero and sets the
reserved header height, while a block renders inside page content below the
header. A block also loses inheritance (every child page would need its own
copy), and 177 of the 207 staging pages are Beaver Builder layouts, where
block content doesn't render.

Later option for in-page anchor sub navs: "this page's sections", built from
anchors already in the page content, so editors maintain nothing extra.
Depends on the page-building decision below.

## Floating over the hero

- The header is absolutely positioned over the top of the page.
- The theme sets `--nw-header-h` per breakpoint, plus the sub-nav height when
  a sub nav is present (known server-side, so a body class sets it with no
  JS and no layout shift).
- Hero sections (`nw-hero`) pad their top by the header space. Pages
  without a hero pad `main` instead, so content never sits under the nav.

## Behaviour and accessibility (from the review)

- Dropdowns: button toggles with aria-expanded, close on Escape, outside
  click and focus leaving; hover only enhances.
- Mobile drawer: a dialog (role, aria-modal, label) with the rest of the page
  inert while open; closes itself if the viewport crosses to desktop.
- aria-current="page" on the current item, "true" on its ancestors and the
  active audience tab.
- No click-hijacking page transitions; one speculation-rules block via core's
  configuration filter.
- Asset versions from file mtimes (done).

## Built with interim decisions (2026-10-25)

Built on main through 8b0f9ea and later. These were open; the build took
the defaults below so the design team can confirm or change them.

1. Mobile (no design existed): below 1200px the bar shows logo, button
   (hidden under 480px) and a menu button; section links scroll sideways
   under it. The menu is a full-screen dialog: audience tabs, the menu with
   sections that expand in place, section links, button, contact details.
2. Dropdowns: a panel under its parent item (styles from 989:2167), opened
   by a caret button or hover. Section links stay in the second row; the
   panel floats over them. The yellow second-bar pattern (989:2195) isn't
   built.
3. Section links are light blue for every audience.
4. The header scrolls away with the page (not sticky).
5. Partner Networks mock's active tab treated as a mock error.

## Still open

1. Sign-off on the five interim decisions above, mobile especially.
2. Decided: existing Beaver Builder pages stay; new pages use bca-renderer
   sections. Next: its hero section, with the image's light/dark field, which
   outputs `nw-hero` and `nw-hero--dark`.
3. Production needs ACF Pro, the Navigation settings and the audience menus
   before this theme goes live there.
