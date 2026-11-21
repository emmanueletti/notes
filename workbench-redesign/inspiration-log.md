# Workbench redesign: inspiration log

Source: Raindrop exports `~/Downloads/inspiration.csv` and `design.csv` (2026-11-12). Fonts and colours pulled from each site's HTML and CSS, not from screenshots.

| Site | What it is | Type | Colour | Built with |
| --- | --- | --- | --- | --- |
| dodopayments.com | Billing SaaS | Apfel Grotezk headings, Inter body | Lime #c6fe1e, black, pastel mesh | Astro, Tailwind v4 |
| trychroma.com | AI infra | IBM Plex Mono, Inter | Orange #ff5100, near-black, #fafafa | Next.js |
| getfernand.com | "Fast, calm" support tool | Inter, Monaco | Navy #1a2035, blue #00a0ff, grey | |
| stephango.com | Personal essays | System UI and content fonts, mono | Flexoki warm paper #fffcf0 | |
| cloudship.co.uk | Plain software for small businesses | Schibsted Grotesk, JetBrains Mono | Mint #7ef2b8, grey-900 | Astro |
| daltonmills.com | AI platform for trades | Cooper BT Light (serif) headings, Instrument Sans | Cream #faf4ee, sand #f3e4d4, green #3c7d65 | Webflow |
| helentseng.com | Artist portfolio | Typekit, Inconsolata | Violet #4f1aff, pink #f94877 | Squarespace |
| thelightphone.com/blog | Calm-tech hardware | Akkurat, Futura | Warm greys #c6c5c2, #7a7a77 | |
| pg-lang.com | Creative company | Custom serif, Times, Courier, Helvetica | Almost none | |
| stupidsimple.tools | Tool directory | Transcript Pro, Transcript Mono | Red-orange #d34323, teal #108474 | |
| ky.fyi/embrace-friction | Essay on letterpress and going slow | Sans, mono | Warm near-black #21201c, tomato #e54d2e | Astro |
| joshpigford.com/projects | Maker portfolio | Inter, Gambarino (serif) | Yellow #ffe00d, warm #f0efea | |
| minimalissimo.com | Minimal architecture mag | Serif, sans, mono | Greys | Next.js |
| normadesign.it | "Non-graphic" design studio (favourite) | Arial | Black, white, #dedede | Eleventy |
| arithmeticcreative.com | Branding studio | JS-rendered, not read | | |
| tachyons.io | CSS toolkit | Mono, Times, sans | Pastels | |

## Themes

1. Calm over hype: Light Phone, Fernand, Embrace friction, Minimalissimo, Steph Ango.
2. Warm paper instead of white, warm near-black instead of blue-black.
3. Editorial type: a serif or classic face for voice, a plain sans for UI, mono as a "tool" accent.
4. One accent colour used sparingly, mostly warm orange or red.
5. Plain talk to small businesses: Cloudship, Dalton Mills, personal maker sites.
6. Reduction: Norma, pgLang, Tachyons. Few colours, no gradients or illustrations, type and spacing do the work.

Outliers: Dodo (loud SaaS: lime, mesh gradients) and Helen Tseng (bright artist palette).

Closest analogue for Workbench: Dalton Mills (vertical SaaS for trades, cream, serif headings, deep green).

## userjot.com (added 2026-11-12)

Liked: the product tiles. A tile holds a short headline and one sentence top-left, then a product fragment placed off-centre that runs off the tile's bottom or right edge. Some fragments are built in HTML from the real UI (chat bubbles, an inbox split view), not screenshots. Tiles are uneven widths (wide plus narrow), not three equal cards.
Not taken: their large radius tiles, warm grey tile fill, coloured avatar circles, tiny uppercase badges.

Mobile: user wants a generic grey device frame with no iPhone or Android tells (no notch, island, home bar or buttons).

## brunch.work/information (added 2026-11-12)

Two-person Montreal studio. Next.js. Font ABC Monument Grotesk (Dinamo, paid), variable weight 375.
- One size for everything: all text 16px / 1.44, tracking -0.01em, weight 375. Hierarchy only from colour (muted #a1a1aa labels vs ink #131718) and position.
- Label column + value column: "Services" muted, right-aligned beside a plain list. A typographic table without lines.
- Page as a poster: short content pinned to the viewport edges (title top, intro left, lists right, footer bottom), lots of empty space.
- Ground #fafafa, cool ink #131718.
- States in type: current page is italic and underlined; links are plain underlines.
- Caveat: muted #a1a1aa on #fafafa is about 2.4:1, fails AA.
