# Workbench foundations

## Principle

Norma's "nothing special" is the default: obvious, proven, no decoration. Every
deviation is deliberate and recorded below with its reason.

## Deviations log

| Deviation                                | Where                                                           | Why                                                                                                                                                        |
| ---------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Apfel Grotezk for headlines              | Marketing headlines (32px+) and wordmark only                   | One place for voice and warmth; jewellery is a craft trade. Decided 2026-11-12.                                                                            |
| Off-white paper #f5f4ef for halftone images only | The ground of one-ink halftone images; nowhere else in the interface | Reads as vintage technical paper; pages stay white. Decided 2026-11-12. |
| Motion for items added to or removed from a collection | Rows, list items, chips, cards entering or leaving | Instant add/remove makes the list jump and hides what changed. Reveals (modals, menus, panels, toasts) stay instant. Decided 2026-11-12. |
| Pills for buttons and chips; every other shape square | Buttons, chips, segmented controls | Norma default is square everywhere; the pill is a signal for pressable or label, like colour as a signal. Decided 2026-11-12. |
| 32px targets for mouse and trackpad | Nav links and other dense controls when `pointer: fine`; touch stays 44px | 44px exists for fingers. With a mouse, 32px rows let groups read as groups and stay above the WCAG 2.5.8 minimum of 24px. Token --u-size-tap-target-fine. Decided 2026-11-12. |
| Three spot primaries (red, blue, yellow) | Flat fields on marketing, signals in the app                    | Swiss poster reference; Norma allows colour only as a signal, so each primary has one fixed meaning. Decided 2026-11-12.                                   |

## Colour (in progress)

- Paper by context: site (marketing, blog, copy pages) #f8f7f4, dark #131311;
  app #ffffff, dark #0f0f0e. App surface #f7f7f5, line #e7e7e3, border #d3d3ce
  (dark #191918 surface). Ink #1a1a18.
- App screenshots on the marketing site read as white sheets on soft paper;
  frame them with a border, no shadow.
- Red #e8503a (overdue, destructive; black text), blue #2f5bd3 / text #2449b0
  (links, in progress; white text), yellow #f3c22c (waiting, attention; black
  text).
- Picked 2026-11-12: Vermilion #e8503a (ink text 4.7), Cobalt #2f5bd3 (white
  text 5.9, link #2449b0 7.4), Warm yellow #f3c22c (ink text 10.4), Pine #277a4d
  (white text 5.3) as success.
- Scope: studio-wide base for every app; apps make their own decisions on top
  later.
- Greys: four (line, border, control, muted), decided 2026-11-12. No surface
  grey: cards are white (dark: #1b1b19, the lightest surface for the theme).
  Strict guardrails below. Dark mode not tuned (yellow wash #4a3f12 reads
  olive).
- Highlight: yellow wash #fbeeb0, decided 2026-11-12. Only for search matches
  and the row just changed; never a status, never selection (selected rows use
  an ink bar on the left edge).

### Grey guardrails (draft)

Tokens are named by job, never by lightness (no grey-1..4, no gray-100..900), so
nobody picks a grey "because it looks right".

| Token             | Light / dark      | Only for                                                                                        | Never for                                |
| ----------------- | ----------------- | ----------------------------------------------------------------------------------------------- | ---------------------------------------- |
| card (not a grey) | #ffffff / #1b1b19 | Background of a container: card, table, panel, popover                                          | Nesting a card inside a card; tinting it |
| line              | #e6e4de / #2a2926 | 1px dividers between rows or items inside a container                                           | Outer edges of containers, text, fills   |
| border            | #d2cfc7 / #3a3935 | 1px outer edge of a container                                                                   | Row dividers, inputs, text               |
| control           | #8c8981 / #75726b | Borders of inputs, selects, checkboxes; disabled control text and border                        | Readable text, decoration, containers    |
| muted             | #6b6964 / #9c9890 | Secondary text: captions, meta, labels, table headers, placeholders, help text. Must pass 4.5:1 | Primary content, headings, lines, fills  |

Ink covers everything else: text, headings, buttons, the rule under a table
header, focus-free emphasis.

Enforcement

- Only these tokens exist in the theme. Remove Tailwind's default gray, slate,
  zinc, neutral and stone scales so `text-gray-500` cannot compile.
- No opacity tricks to make new greys (`text-ink/60`, `opacity-50` on text).
- A lint check fails on raw hex values and default gray utilities in views.
- The design system README and every app's CLAUDE.md carry this table; the
  design-review skill checks it.

## Typography (decided 2026-11-12)

Families

- Apfel Grotezk Mittel (OFL, github.com/collletttivo/apfel-grotezk): voice.
  Marketing headlines and wordmark only, 32px and up. Never in the app.
- Switzer 400 and 500 (Fontshare free license): everything else, marketing and
  app.
- IBM Plex Mono 400 (OFL): labels and data (job numbers, prices, dates, sizes).

Weights

- Switzer 400 for reading, 500 for emphasis and controls. Apfel Mittel only.
  Plex Mono 400 only.
- No 600 or 700 anywhere.

Scale (locked 2026-11-12, with per-surface allowlists below)

| Token    | Size | Line height | Tracking                          | Face                                        |
| -------- | ---- | ----------- | --------------------------------- | ------------------------------------------- |
| caption  | 12   | 16          | 0 (mono labels uppercase +0.04em) | Switzer 400/500, Plex Mono                  |
| small    | 14   | 20          | 0                                 | Switzer 400/500                             |
| body     | 16   | 24          | 0                                 | Switzer 400                                 |
| lead     | 20   | 28          | -0.01em                           | Switzer 400/500                             |
| title    | 32   | 36          | -0.02em                           | Apfel Mittel (marketing), Switzer 500 (app) |
| headline | 56   | 60          | -0.03em                           | Apfel Mittel                                |
| display  | 96   | 96          | -0.035em                          | Apfel Mittel, once per page                 |

Checked 2026-11-12: Switzer's default digits are all the same width (576 units),
so figures line up without a tnum feature. Apfel's digits are proportional, so
never use Apfel for figures that must align.

## Space and layout (accepted 2026-11-12, built from scratch)

Not derived from existing studio conventions. Derived from the type and from
proximity.

Unit 4px (every line height is a multiple of 4). Gutter = body leading (24px).

| Was named | px  | Relationship (description only; code uses --u-space-N) |
| -------- | --- | ------------------------------------------------------ |
| inside   | 4   | Inside one element: icon to label, chip padding        |
| together | 8   | Parts of one item: label to input, title to meta       |
| group    | 16  | Items in a group or list; component padding            |
| block    | 24  | Between blocks; card padding; grid gutter              |
| section  | 48  | Between sections in an app; intro to content on a site |
| chapter  | 96  | Between sections on a site                             |

Grid: 12 columns, gutter 24 (16 compact). Margins 16 compact, 24 medium, 48
wide. Breakpoints: compact < 640, medium 640-1023, wide >= 1024. Widths: reading
measure 65ch; app content set by its content, not a fixed container.

Decided 2026-11-12

- Row hover in app tables: no fill; the row's link underlines.
- App pages cap at 1280px; forms and text-heavy pages limit lines to about 65ch;
  tables may use the full 1280.
- space-24 (96px) stays the same on every screen size, no phone exception.
- Type sizes per surface (locked 2026-11-12, 56 kept for site section headings):
  app 12, 14, 16, 20, 32 (page title 32, section heading 20, default 14, long
  text 16, meta and help 12). Site 12, 16, 20, 32, 56, 96. Corrects the earlier
  table, which had app page titles at 20 and app section titles at 32.

## Shape and depth (in progress, 2026-11-12)

- Floating layers (menus, popovers, toasts, modals): option B, grey border plus one soft shadow token, ink-tinted modal backdrop (--u-color-backdrop). Decided 2026-11-12. User found A (ink border) hard to read and C (hard offset) childish. Cards and everything resting on the page keep no shadow.
- Corners: user drawn to 8 + pills; square risks reading as the AI-editorial look. Proposed: 8px for objects (cards, tables, menus, modals, inputs), full pill for buttons and chips, square for flat colour fields and full-width bands. Pending confirmation.
- Borders: 1px everywhere; 2px focus ring only; 3px ink bar for selected or just-changed rows.

## Avoiding the AI-editorial look (applied to the test page 2026-11-12)

- Plex Mono only for data that must align or be copied: IDs, prices, dates, codes, hex values. Never for labels, eyebrows, table headers, chips or tags.
- Labels and table headers: Switzer, sentence case, no letter-spacing, muted. Uppercase is not used.
- No decorative section numbering (01 / 02 / 03) unless the content is a real sequence.
- Group by space first. Lines only inside tables and lists; no rules between page sections, no rule under the nav, no rules above note columns.
- No coloured rail or accent bar on cards or alerts. Signals use the 8px square marker or a chip.
- Radius rule in force: 8px objects, pills for buttons, chips and segmented controls, 0 for flat colour fields.

Decided 2026-11-12 (after reviewing the cleaned test page)
- Deviation: Plex Mono stays for prices, dates and IDs, not only codes. Reason: inspiration from old technical research papers; the typewriter feel on data is intended.
- Deviation: status chips stay filled in their signal colour. Reason: a deliberate accent in otherwise quiet tables.
- Boxes: a card only when something is a separate object (a table, a panel, an alert, a selectable option). Never a card inside a card. Lists of settings or comparisons are rows separated by lines, not stacked cards.

Decided 2026-11-12 (simplify)
- Paper is white #ffffff everywhere: marketing, blogs, copy pages and apps. Soft #f8f7f4 and Off-white are dropped. Dark paper #0f0f0e, card #191918. Line #e7e7e3, border #d3d3ce on white.
- Cards are white on white, so a card is defined by its 1px border alone. App screenshots on the site get the same 1px border.
- Corners: square + pills. Objects (cards, tables, inputs, menus, modals, toasts, panels) are square. Buttons, chips and segmented controls are pills. Flat colour fields are square. Logged as a deviation: the pill is a signal for "press this" or "this is a label", never decoration.

## Imagery (in progress, 2026-11-12)

- Product tiles (UserJot-style): square, 1px border, headline + one sentence top-left, fragment off-centre bleeding off the bottom or right. Uneven widths on the 12-column grid. Built fragments allowed when made from real app components with realistic copy.
- Lead-colour tile backgrounds: user likes them. Open: one lead tile per row, or every tile.
- On a lead-colour field, nothing else in a spot colour sits directly on the field (a blue bubble on red clashes). Elements on the field turn ink; spot colours are fine inside a white card placed on the field.
- Phones: generic grey frame (border grey, dark #3a3935), no notch, island, home bar or buttons. Rounded because it depicts a device; narrow imagery exception.
- Dithering: recommended out of the base (trend cluster with mono and brutalism, loses detail, scales badly). Apps may adopt it as their own deviation.
- Decided 2026-11-12: at most one lead-colour tile per row. Built fragments and screenshots both allowed, built preferred.
- Dalton Mills check: not 1-bit dithering. Their images are a one-ink halftone (green on cream, like a screen print or engraving) for people, plus technical line drawings and blueprints. Open: allow a one-ink halftone treatment for people and atmosphere images only?

Decided 2026-11-12 (halftone)
- One-ink halftone is an allowed image style: one subject cut out on white source, printed in ink or one of the four colours, never yellow, on off-white paper #f5f4ef. Never for the thing a customer is buying.

Decided 2026-11-12 (imagery closed)
- Technical drawings and diagrams allowed, ink or one of the four colours, labels in Plex Mono.
- "Printed matter" (halftones and drawings) sits on off-white #f5f4ef; screenshots and colour photos sit on white.
- Image types: colour photo for anything a customer buys or must see accurately; halftone for people, tools, atmosphere; drawing to explain how something works or is measured; screenshot or built fragment to show the product.
- Dithering stays out of the base; an app may adopt it as its own deviation.
- Document the printed-matter look (halftones, drawings, Fig. captions, off-white paper) as the studio brand aesthetic, used especially in blogs and articles.

## Iconography (decided 2026-11-12)

- Set: Phosphor Regular (MIT, @phosphor-icons/core), used exactly as published. Decided 2026-11-12 after comparing Carbon, Phosphor Light, Phosphor Regular, Material Sharp and Iconoir on a full app screen. Rounded line ends pair with the pill buttons and chips.
- Regular weight only. No mixing Phosphor's other weights (thin, light, bold, fill, duotone).
- Replaces the studio's Lucide default. Follow-up: update the studio-designer `install-svg-icon` skill and the hq conventions (they name Lucide).
- Sizes 16px (with 12-14px text) and 20px (with 16px+ text). Colour inherits text (ink or muted); a spot colour only when the icon is a signal.
- Icon alone only for the universal set (close, search, menu, more, back, chevrons, add, external, sort, row actions), always with a hidden label. Everything else is icon plus word or word alone.
- Never: icons on headings, feature-illustration icons, icons in body text, emoji. Status uses square markers and chips.
- Icon buttons use the 32px target (u-btn-icon), including table row actions. Updated 2026-11-12 when targets standardized at 32px.

## Motion (decided 2026-11-12)

- Instant by default: menus, modals, panels, toasts, expanding sections, hover, navigation, tabs.
- Two things move:
  1. Progress indicators (a determinate bar when the wait is known; muted "Loading…" text otherwise). No skeleton shimmer.
  2. Items added to or removed from a collection (table rows, list items, chips, cards): the item fades and the space opens or closes. Enter 200ms, exit 130ms, one ease-out curve, no bounce. Updated 2026-11-12.
- Reduced motion: add/remove motion still runs (user decision 2026-11-12), as a fade plus the space opening or closing, with no other movement. Progress still moves. Everything else is already instant.
- Without motion elsewhere: confirm actions with a toast in a fixed spot, reserve space for content that loads in, move focus to the next row after a removal.

## Status

All foundation pillars decided on 2026-11-12: principles, typography, colour, space and layout, shape and depth, imagery, iconography, motion. Remaining: dark mode tuning pass, writing the system up (tokens, README, guardrails), updating studio skills and conventions (Lucide to Phosphor, monoform tokens), then the Workbench marketing redesign.

## Dark mode review (2026-11-12)

Measured on the test page: ink on paper 16.1, ink on card 14.5, muted on paper 6.7, link 8.0, red as text 6.0; chips 5.0 to 11.1 with dark text; ink on highlight 8.8. Text is fully readable.
Fixed 2026-11-12: dark line #2a2926 -> #383733 (1.45 on card), dark border #3a3935 -> #4a4844 (2.1), dark yellow highlight #4a3f12 -> #735a00 (ink on it 5.5). Built fragments follow the theme (dark card #1b1b19) except inside lead-colour fields. Technical drawings sit on off-white #f5f4ef like halftones.
Other notes: yellow highlight #4a3f12 reads olive; white app screenshots and phone screens glare on dark pages (show dark-mode screenshots in dark mode); large lead-colour fields are bright on dark.

## Uniform token naming (decided 2026-11-12)

- One name per spacing step (decided 2026-11-12): the token number (space-6). Relationship words (inside, together, group, block, section, chapter) are descriptions in the docs, never names.
- Pattern `--u-{category}-{role}-{variant}` with the common vocabulary (bg, text, border, space, font). Metaphors (paper, ink, chapter) stay in the docs, not in code.
- Colour by meaning: --u-color-bg-surface (white, pages and cards), -bg-paper, -text, -text-muted, -divider, -border, -border-input, -link, -danger, -info, -warning, -success, -highlight, -text-on-{signal}.
- Space as 4px multiples: --u-space-1, 2, 4, 6, 12, 24. Font sizes by size: --u-font-size-12 ... -96. Fonts: --u-font-display, -sans, -mono.
- No context switching (decided 2026-11-12): no u-site or other class that changes what tokens or classes mean. Sites opt in explicitly with u-bg-paper and the site-only type classes.
- No lead colour (decided 2026-11-12): no per-product lead token or brand colour. Designers, human or agent, choose which of the four colours to use and where, within the colour rules.
- Intent classes for type: u-text-hero, section-title, page-title (apps), article-title (32 Apfel, sites), heading, lead, body, small, caption, data, muted, strong. Spacing intent through layout primitives (u-stack, u-row, u-grid) plus u-gap-{n} and u-pad-{n}; no margin utilities.

Deviations list cleaned up 2026-11-12 (Norma test): only departures from Norma's own position count. Removed "Filled status chips" (colour as a signal is Norma; it becomes a chip component detail) and "Smaller targets for a mouse" (a studio accessibility sizing rule, now on Space and layout). "Four spot colours" narrowed to "Colour blocks on marketing pages"; the signal colours themselves are within Norma. Deviations exist for two reasons: usability, or a deliberate signature.
