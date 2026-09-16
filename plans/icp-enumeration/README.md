# Canadian ICP enumeration

Goal: an enumerated list of every Canadian shop matching the Workbench ICP, replacing the derived
300-600 estimate in `rethinking-workbench.md` section 15.2 with a measured number.

In a market this small the list is not market research. It is the sales pipeline.

## What was tried and rejected

**Canadian Jewellers Association directory.** Claims 1,000+ member locations. It is an ASP.NET
postback widget behind reCAPTCHA at `widgets.canadianjewellers.com`. Not scrapeable, and the captcha
is a clear signal they do not want it scraped. Worth pursuing as a membership or partnership
conversation instead. Members skew retail counter anyway, so it is a B-tier source for our ICP.

**Metal Arts Guild of Canada.** The artists page has 8 entries, one per province, almost all
blacksmiths and sculptors. Effectively empty and the wrong discipline. Dead end.

**Web search alone.** Produces real names but tails off fast and cannot get near complete coverage.
Good for seeding, useless for enumeration.

## The approach that works

Two stages.

**Stage 1, `enumerate.rb`.** Google Places Text Search across Canadian cities with jewellery-trade
query terms, English and French. Returns name, address, website, phone, rating, review count. This
gets near-complete coverage of anything with a physical presence and a Google listing, which is
almost everything including home-studio ateliers that take appointments.

**Stage 2, `score.rb`.** Fetch each website and score it against the ICP. The Places sweep returns
everything including chains and retail counters. Scoring separates the modern brand operator from
the legacy counter, which is the whole distinction section 4.1 rests on.

## Running it

    export GOOGLE_PLACES_API_KEY=...
    ruby enumerate.rb          # writes places_raw.csv
    ruby score.rb              # reads places_raw.csv, writes icp_scored.csv

Ruby stdlib only, no bundle needed.

Enable "Places API (New)" in Google Cloud. Cost is roughly $32 per 1,000 Text Search calls. A full
sweep is about 400-500 calls, so $13-16, likely covered by the monthly free tier. Check current
pricing before running, Google changed the free tier structure in 2025.

`score.rb` fetches several hundred websites. It sleeps between requests deliberately. Do not remove
that.

## Scoring, and what the tiers mean

| Signal | Points | Why |
|---|---|---|
| Shopify detected | +3 | Strongest single ICP marker. Section 4 ICP is Shopify-native |
| Instagram linked | +2 | Modern brand operator, Instagram-led discovery |
| Custom or bespoke language | +2 | Custom practice, the ICP-selecting feature |
| Repair language | +2 | Repairs is the proven loved thing and the wedge |
| French content | +1 | Quebec, where bilingual EN/FR is a real moat |
| Online booking or appointment | +1 | Atelier model, not walk-in counter |
| Wix, Squarespace, WordPress | +1 | Self-serve buyer, no IT department |
| No website | -3 | Almost always a legacy counter |
| Chain name match | -10 | Excluded outright |

Tiers: **A** is 8+, contact first. **B** is 5-7, worth qualifying. **C** is below 5, deprioritize.

The scoring is a first pass, not a verdict. Anything in A or B gets eyeballed before outreach.

## Sources still worth hand-working

These do not automate but they reach the ICP better than Places does, because the modern brand
operator may have a weak Google presence and a strong community presence.

- **One of a Kind Show** (Toronto, spring and winter) exhibitor lists. Best single fit for indie
  makers with ateliers. Past exhibitor lists are usually public.
- **Signatures Craft Show** (Ottawa, Quebec City). Same shape.
- **Conseil des métiers d'art du Québec** member directory. Highest-yield Quebec source.
- **Craft Ontario**, **Crafts Council of BC**, **Alberta Craft Council** member directories.
- **Jewellery school alumni.** George Brown Jewellery Arts, École de joaillerie de Montréal, VanArts,
  Georgian College, Alberta University of the Arts. Graduates who opened studios are exactly the ICP
  and are reachable through the schools, which also connects to the schools circle in section 9.3.
- **Instagram.** #canadianjeweller, #torontojeweller, #montrealjeweller, #vancouverjeweller,
  #bijouxsurmesure, #customringcanada. Manual, high signal, slow.
- **Etsy Canada** jewellery sellers with a studio address.

## Seed list

`seed.csv` holds 30 real shops found by search across Toronto, Montreal, Vancouver, Calgary and
Edmonton, plus known existing customers. Every entry came from a real search result with a live URL.
Nothing in it is inferred or generated.

Use it to sanity-check the Places sweep: if `enumerate.rb` misses shops that are already in
`seed.csv`, the query terms or city list need widening before trusting the totals.

## Gotcha that cost an hour

Shopify sites return 403 to a plain Net::HTTP request even with a browser User-Agent. curl gets 200
with the same UA. The trigger is the missing `Accept` and `Accept-Language` headers. Setting both
fixes it.

Do not set `Accept-Encoding` manually. Net::HTTP only auto-decompresses gzip when it sets that header
itself, so setting it by hand returns raw gzip bytes and every content match silently fails. That
failure mode is nasty: 200 responses, plausible body lengths, and zero Shopify hits.

The first run of this scorer reported 16 of 30 sites unreachable and zero Shopify detections. Both
numbers were artifacts.

## Seed results, run 2026-08-10

30 seed shops scored: 18 tier A, 10 tier B, 2 tier C, zero unreachable. In `seed_scored.csv`.

**13 of 30 are on Shopify.** That is direct evidence for the Shopify-native half of the section 4
ICP definition, which until now was an assumption.

Caveat on the tiers: the seed was hand-picked as ICP-shaped, so clustering at A proves the signals
fire, not that they discriminate. The thresholds need recalibrating after the first broad Places
sweep, which will include chains, pawn shops, watch repair and mall counters. Expect to raise the A
bar.

## What "done" looks like

A single CSV where every row is a real Canadian shop, tiered, with website and contact. Then the
number in section 15.2 stops being an estimate, and section 11's sequencing can be built on a real
denominator instead of a derived one.
