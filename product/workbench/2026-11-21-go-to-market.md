# Go-to-market, 2026-11-21

Advice from a working session on growth. SarahBijoux has its own note: `sarahbijoux.md`.

## Verdict

Shift most time to distribution, but fix self-serve onboarding first. Every shop that stayed was won in person. Every shop that signed up alone left within days. Pouring sign-ups into that is a leaky bucket.

Order: plug the leak, grow through shops we already have, then add partners. No budget is needed if we trade value instead of money.

## Market

Vision: the Shopify of the jewellery industry, later the platform for craftspeople with repair and custom work (not phones or computers). Dream client: Veja's repair workshop in Paris. For now, niche down and master jewellery.

| Serve now, in this order | Main channel |
| --- | --- |
| 1. Wholesale repair shops | Referrals, the portal loop, jeweller buildings, family parts business |
| 2. Independent brands (SarahBijoux, Myler, Frank Darling) | SarahBijoux as a reference, Quebec first |
| 3. Shopify brands | Shopify App Store, once the app exists |
| 4. Students | Free tier and instructors |

Out of scope for now: legacy retail jewellers on The Edge, and mall chains like Peoples.

## Evidence

- Activity 2026-11-07 to 2026-11-21 (PostHog): repair counters lead. The Jewellery Clinics, C Creations, Fort Richmond, Russell and Solitaire House were active 10 to 13 of 15 days.
- Every shop that stayed (the Jewellery Clinics, SarahBijoux) came through in-person visits in Montreal, demos and setup emails.
- Self-serve sign-ups left: Flux and Stone (#52), Chronos Watch Repair (#55), C Creations duplicate (#53).
- Trials: 2 of 4 made an intake within 7 days (2026-11-07 to 2026-11-16).
- PostHog has no source data, because every shop signed up before tracking started on 2026-11-07.
- Conclusion: we don't know yet whether the product keeps shops on its own. We know in-person help does.

## 1. Plug the leak

- Rule: no new channel until 3 of every 4 trials make a real ticket within 7 days.
- Offer a 15-minute setup call to every new sign-up within 1 hour, and make their first real ticket on the call.
- Write down what the in-person shops needed, visit by visit (questions, settings changed, where they got stuck). The most common items are the self-serve onboarding spec. Compare it with the setup flow (decided 2026-11-18) and the getting started page.
- Help matched to value:

| Who | Help |
| --- | --- |
| Wholesale shops and big names | In person or video, we set it up |
| Independent brands | One video call for the first ticket |
| Students, free tier | Self-serve only |

- Don't launch the free tier until self-serve works, or it fills Workbench with dead accounts. Use it to test self-serve.

## 2. Setup question

Add as setup step 2, behind a flag:

```
Who brings you work?
Pick all that apply.

[ ] People who come to us directly
[ ] Other jewellery businesses, like stores and brands
```

Hint on the second option: "For example, if you do repairs or setting for other stores."

- Alert the founders by email or Slack when a sign-up ticks "Other jewellery businesses", so we call within the hour.
- Later, show wholesale-only features (store reference numbers, which Willy asked for) to those shops.
- That makes 5 question steps. If PostHog shows drop-off, cut "What do you want help with?", since it changes nothing in the app.

## 3. Grow with no budget

What we can trade instead of money:

| We give | Who wants it |
| --- | --- |
| Free months, or a founding-shop price locked for life | Early shops, referrers |
| Revenue share, for example 20% of a referred shop's first year, paid after they pay | Suppliers, sales reps, instructors |
| A "preferred supplier" link inside Workbench | Suppliers, family business |
| Free accounts | Students, instructors |
| Setup done for them | Every shop |

Deals:

- **Existing shops**: ask Willy (Jewellery Clinic Wholesale) and C Creations for 3 names each, with a free month for each shop that joins.
- **Portal loop**: stores send work to wholesale shops. If those stores can follow their jobs in the Workbench portal, every wholesale shop shows Workbench to dozens of stores. Check whether the portal works for business customers.
- **Family parts business** (watch and clock parts, worldwide): they get new buyers (a parts discount for Workbench shops, later a "Find this part" link on tickets), we get a card in every order with its own trial code, plus one newsletter mention sent by them. We can't email their list ourselves: CASL (Canada's anti-spam law) requires the customer's consent.
- **Suppliers** (casting, findings, tools, stones): they get stores that sell more, a preferred listing and a revenue share. We get their reps, who visit stores weekly and can do the in-person part.
- **Jeweller buildings**: one afternoon with an iPad, first ticket set up on the spot, founding price, and a free month per referral inside the building.
- Decide whether pure watch and clock repairers are in our market, or only the jewellery stores among the family business's customers.

Wholesale shops are also reached through suppliers (Stuller, Rio Grande, Gesswein), trade groups (MJSA, CJA), bench jeweller Facebook groups, Ganoksin, and a Google Maps calling list ("jewellery repair wholesale", "trade shop").

Paid, later, only after a free channel proves which shops convert: trade newsletters (Canadian Jeweller, JCK, National Jeweler, InStore, MJSA Journal), AWCI and NAWCC for watch repairers, Google Ads on searches like "jewellery repair software", Instagram ads for independents, and school sponsorships. Trade shows come last.

## 4. Printed material

Only print what does a job.

- **Quick-start card at the bench** (for staff): the one that matters, because it carries part of a visit.

  ```
  Take in a job

  1. Tap New job, then pick the client or add a new one.
  2. Fill in the job details and add photos of the piece.
  3. Have the client sign your terms on the iPad, then print
     or email their copy.

  Have more than one piece? Add each one as its own item
  before the client signs.
  ```

  ```
  Every day

  - Change a job's status from the job list as the work moves.
  - Find any job by the client's name or the job number.

  Stuck or unsure? Text Emmanuel at [phone]. You'll get
  an answer the same day.
  ```

- **Leave-behind card** for visits: one sentence on what Workbench does, a sign-up QR code, and a referral code naming the shop or rep.
- **Branding that already goes out**: printed tickets, shop emails and the portal already say "Powered by Workbench". Turn the printed line into a short URL or QR code, since wholesale tickets travel to stores.
- Skip brochures, stickers, counter posters and swag. Walk-in customers aren't our buyers.

## 5. Email

- itsusstudio.com authentication passes (SPF, DKIM, DMARC tested 2026-11-21). Postmaster Tools shows a compliant spam rate and too little Gmail volume to judge reputation. Its "Needs work" flags dated from 2026-08-30 and are stale.
- No replies most likely comes from timing and channel, not spam filters.
- Welcome emails: send from a real address within 1 hour of sign-up. Ask one question that takes 5 seconds, like "Is most of your work repairs or custom pieces?" Text when there's a phone number, DM independents on Instagram, and use the in-app chat while they set up. No stock product welcome.
- Cold email: use a separate lookalike domain, warmed up for a few weeks, sending 20 to 30 a day per inbox. Plain text, no tracking pixel, no link in the first email. The first line is a true detail about them.

## 6. Flux and Stone (#52)

- Signed up 2026-10-24 (Victoria, BC). Saved the shop address, started a ticket with himself as the client, and stopped at item details. Came back to that step 2026-10-25, then left for good. No errors.
- Trial extended to 2026-12-21. Reply in Emmanuel's 2026-10-26 thread. Say nothing drawn from usage data.

Email 1, now:

```
Hi Nathan,

I've extended your Workbench trial to Dec 21, so there's no rush to decide before the holidays.

Was there anything you needed Workbench to do that was missing? We're a small team still shaping it, so if something didn't fit how your shop works, we can change it.

A one-line reply is plenty, and if now's a bad time, tell me and I'll check back in the new year.

Cheers,
Emmanuel
```

Follow-ups in the same thread. Stop when he replies.

- 2026-11-28: offer a 15-minute setup call with one real piece, Tuesday or Wednesday.
- 2026-12-05: ask where they write down a repair or order today (paper envelope, spreadsheet, phone).
- 2026-12-17: the trial ends Dec 21, and a reply gets it extended into the new year.

## Roadmap order

1. Self-serve onboarding, from the in-person spec.
2. Speed work and custom projects for SarahBijoux (see `sarahbijoux.md`).
3. Free tier for solo jewellers and students, once self-serve works.
4. Team tier at $50 and Scale at $100, with existing shops grandfathered.
5. Benji AI assistant.

## Metric

New shops that make a real ticket within 7 days, per week. Each channel gets a stop date when it starts. For example, drop the order card if it brings in fewer than 3 sign-ups by 2027-01-15.

## Next 2 weeks

| Action | Owner |
| --- | --- |
| Setup call offered to each new sign-up within 1 hour | Emmanuel |
| Write the in-person onboarding spec (what each visited shop needed) | Founders |
| Flux and Stone email 1, trial set to 2026-12-21 | Emmanuel |
| Referral ask to Willy and C Creations | Founders |
| Check whether the portal works for business customers | Emmanuel |
| Order card with the family business, with its own code | Emmanuel |
| One afternoon in a jeweller building with an iPad | Founders |
| Print the quick-start card | Founders |
| Setup question and wholesale sign-up alert, behind a flag | Emmanuel |

## Open

- Whether pure watch and clock repairers are in our market. Owner: founders.
- Which supplier to approach first, and the revenue share percentage. Owner: founders.
- The phone number for the quick-start card. Owner: Emmanuel.
