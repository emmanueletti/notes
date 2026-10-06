# Belly for Professionals

Written 2026-09-20. Monetization exploration: free consumer Belly funded by a
paid tier for coaches. Replaces the strategy in the deleted
`docs/rethinking-belly.md` on the monetization question only. Everything in that
doc about the consumer product, the cycle syncing method, and the studio
sequencing still stands unless contradicted here.

## 1. The idea

Belly stays free for consumers, who in this reading are unlikely to pay. Revenue
comes from Belly for Professionals: a paid tier for coaches, meal planners, and
anyone who plans meals for other people.

Two markets look like one from the outside and are not. Separating them is the
whole analysis.

## 2. Registered dietitians: stay out

114,716 registered dietitians in the US as of September 2026. Licensed,
clinical, billing insurance, handling protected health information.

That market is taken and well funded:

| Product         | Shape                                                       | Price                           | Funding                        |
| --------------- | ----------------------------------------------------------- | ------------------------------- | ------------------------------ |
| Practice Better | Practice management plus EHR, charting, SOAP notes, billing | $30/mo starter, $60 white-label | $27M, Series B                 |
| Healthie        | ONC-certified EHR plus marketplace, API-first               | enterprise                      | $40.3M, $23M Series B Oct 2024 |
| Nutrium         | Dietitian-specific, 350k registered pros in 90 countries    | from $15-19/mo                  | -                              |
| That Clean Life | Meal-plan-first, 7,000+ recipes, client-facing PDFs         | $30/$60                         | -                              |
| NutriAdmin      | Macro generator, day editor, client portal, branded PDF     | mid                             | -                              |
| Foodzilla       | AI plan generation, claims 10k+ pros                        | mid                             | -                              |

Market is roughly $1.2B in 2024 growing to $2.5B by 2033 at 9.6% CAGR. Real, and
defended.

Reasons to stay out:

- Compliance. Client health data is PHI. HIPAA and PHIPA scope for a two-person
  team.
- The nutrient database is the moat and we do not have one. Verified USDA or CNF
  grade data plus ingredient matching is the expensive unglamorous core these
  companies spent years on.
- Belly's assets do not transfer. We have recipe import, grocery lists,
  playlists, week plans, sharing. Clinical practice needs client records, intake
  forms, SOAP notes, nutrient analysis against DRI, billing.
- No founder-channel fit. The cofounder's community access is to young
  professional women, not to clinicians.

## 3. Coaches: the actual market

Different animal. Unregulated, self-employed, buying tools out of pocket,
already paying.

| Segment                                  | Size                                                       |
| ---------------------------------------- | ---------------------------------------------------------- |
| Personal trainers US                     | ~376,000 employed, ~325,000 businesses, $13.9B market 2025 |
| Precision Nutrition certified coaches    | 18,851 across 151 countries                                |
| Health and wellness coaches, online-only | uncounted, large, no licence required                      |

Serviceable slice: coaches who do nutrition and work online. Call it 50,000 to
100,000 globally. We need hundreds, so the size of the slice is not the
constraint.

## 4. Why this is a real signal and not a guess

Coaches already pay for coaching software:

| Platform   | Price                                                                      |
| ---------- | -------------------------------------------------------------------------- |
| Trainerize | $35/mo small book up to $245/mo unlimited, about $5 per client             |
| TrueCoach  | $26 for 5 clients, $58 for 20, $137 for 50, plus 5% card fee from Jan 2026 |
| Everfit    | free to 5 clients, about $63/mo at 25, $117 at 100                         |

The load-bearing fact: Trainerize and Everfit both sell nutrition and meal
planning as a separate paid add-on at roughly $33 to $45 per month on top of the
base subscription, and it is the weakest part of both products. The recurring
coach complaint is that if a client needs a personalized nutrition program with
recipes and a grocery list, it has to be built somewhere else.

So coaches are already paying $33 to $45 a month for a bad version of exactly
what Belly does, with the complaint documented publicly. That is willingness to
pay, at a known price point, with a named gap. It is the strongest market signal
found anywhere in this exploration, and it is stronger than anything we have on
the consumer side.

## 5. The business model

Coach-funded freemium, or B2B2C. Established pattern: Trainerize, TrueCoach and
Everfit all give the client app away and charge the coach. Practice Better gives
the client portal away. Cronometer Pro is the closest analogue to what Belly
would be doing.

Pricing: the coach pays, tiered by client count. Not per-client charged to the
client.

- $29/mo up to 10 clients
- $59/mo up to 30
- $99/mo unlimited

Anchored to the add-on price coaches already accept rather than to consumer meal
planning prices.

Revenue math. At $59/mo, $10k MRR is about 170 coaches. The consumer path needs
roughly 1,250 subscribers at $8, which at 2 to 5 percent freemium conversion
implies 25,000 to 60,000 free users. 170 is a number two people can reach. That
is the argument for this whole direction.

Distribution is the second prize and possibly the larger one. Each coach carries
15 to 40 clients into the consumer app. 170 coaches is roughly 4,000 consumer
users we did not have to acquire. Belly's current problem is 30 users. This is
the only channel on the table that multiplies.

## 6. What breaks

Not fatal. This is the work.

Free is not free for us. `RecipePhotoExtractor` makes LLM calls, images cost
storage. Every free client carries COGS, and coach-brought users arrive in
bursts without converting. Cap the free tier on imports per month and storage,
and model the unit cost before setting coach prices. Otherwise a successful
coach launch is a bill.

No nutrient data. Coaches need macros per meal and per day. We have
`ingredient`, `scaled_ingredient` and `fractional_quantity`, which is quantities
and no nutrition. Adding verified nutrient data plus ingredient-to-food matching
is months, not weeks, and it is the gating item for being a coach's nutrition
tool rather than their recipe tool.

Client engagement on pushed apps is poor. Our 33 percent DAU/MAU comes from
people who chose Belly. Clients handed an app by their coach behave nothing like
that. Do not project current retention onto them.

Coach churn is high. Coaching businesses fail, and the customer disappearing is
not a product failure but it is still churn. Budget for it.

Mildly two-sided. The coach stays only if clients use it, clients use it because
the coach pushes it. Better than a marketplace because the coach can force
adoption, but not one-sided.

## 7. Where cycle syncing lands

It survives the move to B2B, and lands better than a generic pro tier would.

Women's health and hormone-focused coaching is a real and growing coach niche
with close to zero purpose-built tooling. "The meal planning tool built for
coaches working with women's cycles" is a sharper wedge than a generic
professional tier, keeps the defensibility argument intact, and holds for the
same reason it held in consumer: the general all-in-ones will not build it.

A coach is also a better buyer of a method than a consumer is. The YNAB analogy
carries over.

Same constraint as before. Frame it as responding to how you feel across your
cycle. No clinical or hormonal claims.

## 8. Scope

Reuse what exists:

- `space` and `membership` for the coach workspace with clients as members
- `playlist`, `playlist_share` and `week_plan` for assigning a plan to a client
- Recipe import and grocery lists, which are the best part of Belly and exactly
  what Trainerize lacks

Build:

- Coach dashboard: client list, who has a plan, who has stalled
- Assign a plan to a client, client sees it in normal Belly
- Nutrient data and macro totals, the expensive one
- Branded PDF export, cheap and high perceived value because coaches want their
  logo on the plan
- Seats and billing

Explicitly not building: SOAP notes, scheduling, intake forms, video consults,
invoicing. That is Practice Better's product and competing there loses.

## 9. Next steps

Do not build first.

1. Find 10 coaches, starting with the cofounder's community. Ask what they use
   today and what they pay for nutrition tooling. One week, no engineering.
2. Pre-sell founding-coach pricing for a product that does not exist. If 5 of 10
   pay, build it. If none pay, a year was saved.
3. Still run the consumer pricing test. One email to the user who already
   offered, then the other 29. "Consumers never pay" is an assumption and our
   own record contains a user who offered unprompted. The answer decides whether
   free-forever is a strategy or a concession.
4. Model free-tier COGS per client before quoting any coach price.
5. Then build, narrow, women's health coaches first.

## 10. Verdict

A professional tier for coaches is worth pursuing. A professional tier for
dietitians is not.

The difference is regulation, incumbent funding, and the fact that coaches are
already paying for a worse version of the product we already have.

## Sources

- https://www.cdrnet.org/registry-statistics
- https://www.precisionnutrition.com/certified-coach-directory
- https://www.ibisworld.com/united-states/industry/personal-trainers/4189/
- https://assistantcoach.fit/blog/real-cost-fitness-coaching-software/
- https://assistantcoach.fit/blog/hidden-fees-fitness-coaching-software/
- https://www.promealplan.com/en/blog/trainerize-alternative-meal-planning
- https://www.promealplan.com/en/blog/promealplan-vs-trainerize
- https://www.fitbudd.com/insights/everfit-vs-trainerize-vs-truecoach
- https://www.gethealthie.com/blog/healthie-ehr-raises-series-b
- https://tracxn.com/d/companies/practicebetter/__tGXQsMJoqWx-o4eZy-4NV0FCO9lOpuV2AJkROfeNO7c
- https://www.verifiedmarketresearch.com/product/dietitian-software-market/
- https://www.promealplan.com/en/blog/dietitian-meal-planning-software
