# Product-led growth strategy, 2026-11-21

The self-serve variant of `2026-11-21-go-to-market.md`. Shops find Workbench through search and AI assistants, set it up alone and bring others in through what they send out.

## Verdict

Search is worth doing, but the prize is owning every query in a small niche, not volume. People searching for jewellery repair software are rare but ready to buy. SEO compounds over 6 to 12 months, so start now and keep founder-led sales running meanwhile.

Product-led growth needs the same thing as sales: self-serve onboarding that works. The help centre does double duty, ranking in search and getting new shops through setup, so build it first.

## Where we are

- Marketing site (useworkbench.co, Bridgetown) already has: 9 comparison pages (vs The Edge, RepairDesk, RepairShopr, RepairTrax, spreadsheets, pen and paper, Trello, Asana, kanban), 5 help articles, 4 blog posts (3 from early 2025), `llms.txt` and an `/ai-info` page for AI assistants.
- `marketing/todo.md` lists 101 blog ideas, none written. They aren't checked against real searches.
- Traffic: about 20 visitors from 2026-11-10 (when PostHog went on the site) to 2026-11-21. One came from Google.
- No sign-up has a recorded source, because the setup question about it hasn't shipped and tracking started after every current shop signed up.
- One of our best customers found us through a Google search. We don't know what they typed.

## Inspiration

From general knowledge, to check before quoting:

- Tally grew from a generous free plan, "Made with Tally" on every form people send out, and a template gallery that ranks in search.
- Pallyy grew from SEO: content and free tools for social media managers that rank and lead into the product.

What carries over to Workbench: free tools and templates that rank, a help centre that ranks, our branding on everything shops send out, and a free plan once self-serve works. What doesn't: Tally's consumer-scale loop. A shop's customers aren't our buyers, except in wholesale, where the customers are other jewellery businesses.

## 1. Find out how people search

Do this before writing anything, and repeat it every quarter. The output is a keyword map: the query, what the searcher wants, and which page answers it.

1. **Ask the customer who found us on Google** what they typed. Ask every shop we onboard the same.
2. **Setup question follow-up**: when someone picks "Searching online", ask "What did you search for?" in a free-text field. When they pick "An AI assistant suggested it", ask which assistant.
3. **Google Search Console** for useworkbench.co: the actual queries we show up for, with impressions and clicks. Confirm it's verified, including for the old .ca domain, and check every .ca page redirects (301) to the matching .co page.
4. **Free keyword tools**: Google Keyword Planner (through a free Google Ads account), Google autocomplete and "People also ask", and Ahrefs Webmaster Tools (free for your own site). Seed terms: jewellery repair software, jewelry repair tracking, repair envelope, job bag, bench ticket, trade shop software, custom ring order tracking, plus the French versions (logiciel réparation bijoux).
5. **The trade's own words**: how jewellers describe the problem on Reddit (r/jewelers, r/jewelrymaking), Ganoksin and bench jeweller Facebook groups. Use their nouns ("envelope", "job bag", "take-in") on our pages.
6. **AI assistant check, monthly**: ask ChatGPT, Claude, Perplexity, Gemini and Google's AI Overviews a fixed set of 10 questions, like "best software to track jewelry repairs", "how do jewellers track repairs", "RepairShopr alternative for jewellery", and the same in French. Log whether Workbench comes up and which sources are cited. Those sources are where we need to be.
7. **Competitors**: which pages rank for our queries today. Most repair software targets phone and computer shops, which is our opening.

## 2. Pages to build, in order

1. **Help centre**, from 5 articles to complete coverage of the tasks. Public and indexable. One question per article, with the question's wording as the title. Screenshots. It ranks, AI assistants cite it, and it carries self-serve onboarding.
2. **Free tools and templates** (the Tally lesson). Each one answers a real search and ends with a line on how Workbench does it automatically:
   - Repair terms of service template for jewellers
   - Printable repair envelope or job bag ticket
   - Repair price list template
   - Custom ring order or commission agreement template
   - Ring size converter
   - Scrap gold value calculator
   - Jewellery care card
   Pick the first 3 from the keyword map, not this list.
3. **Pages by kind of customer**: wholesale trade shops, independent studios, custom engagement ring makers, watch repair. Each with real screenshots and a quote from a shop like them.
4. **Comparison pages**: keep the 9, add an honest "best jewellery repair software" page, and refresh each one when pricing changes.
5. **French**: the app already ships in French and Quebec is our next market. French pages face little competition. Start with the help centre and the top 3 tools.
6. **Blog**: only posts that answer a query on the keyword map. Cut the 101-idea list down to those.

Skip: mass-generated city pages and thin pages written to rank. Google now penalises them, and they hurt the pages that are good.

## 3. AI assistants

- Keep `llms.txt` and `/ai-info` exact. Update them the day pricing changes (Team $50, Scale $100).
- Assistants repeat what they find in places people discuss tools. Answer real questions on Reddit and Ganoksin as the founder, and say plainly that you make Workbench.
- Free listings on software directories (Capterra, G2, GetApp), then the Shopify App Store once the app exists. Ask happy shops for reviews there.
- Structured data on pages: `SoftwareApplication` on the home and pricing pages, `FAQPage` on help articles, `HowTo` on guides.
- Use the same words for Workbench everywhere: "Workbench, repair and custom order software for jewellers".

## 4. Loops that grow without us

A loop works only when the product's output lands in front of someone who could buy it. Most of what Workbench produces reaches the public, who never will. Wholesale work passes between jewellery businesses, so that is where the strong loop is.

Loops multiply whatever happens after sign-up. If self-serve still leaks, loops bring in more shops that stall. Fix onboarding alongside.

| Loop | How it runs | Strength | Recommendation |
| --- | --- | --- | --- |
| Trade network | A trade shop adds a store as a business client. The store follows its jobs in the portal, starts its own counter on Workbench, then sends work to its other trade shops through Workbench, and they join to receive it. | Strongest. Invites are part of the work, like DocuSign or Calendly. | Main bet. Start with business clients in the portal, behind a flag, tested with Willy and C Creations. Passing jobs between shops comes later. |
| Support to content | Every question a new shop asks becomes a public help article that ranks and gets cited by AI assistants, bringing the next shop. | Medium, cheap, also plugs the leak | Start now |
| Staff and students | Bench jewellers change shops and students graduate. People who learned on Workbench ask for it at their next shop (how Figma and Adobe won studios). | Slow, compounds over years | Needs the free plan and one account a person can carry between shops |
| Repair shop directory | Opt-in public page per shop. The public searching "jewellery repair Montreal" lands there, shops get customers, other jewellers notice. | Strong if it works, but a two-sided product | Test first whether shops want leads |
| Branding | "Powered by Workbench" on printed tickets, shop emails and the portal, linked to a page for jewellers with a source code. Printed tickets get a short URL or QR code. | Weak, mostly seen by the public | Turn on, cheap |
| Templates | Someone who downloads the terms template signs up with those terms already in settings | Medium | With the free tools |
| Referral offer | A free month for each shop referred | Weak to medium | Turn on, cheap |
| Physical supplies | QR envelopes, bags and transit pouches travel between trade shops and stores carrying the brand. See `2026-11-21-supply-store-strategy.md`. | Medium for wholesale | Test with QR labels first |
| Free plan | Solo jewellers and students start free | Medium | Only after self-serve works |

Measure the trade loop as stores invited per wholesale shop × share who sign up. Above 1 it grows alone; below 1 it still lowers the cost of each shop won by hand. Stop rule: if fewer than 1 in 10 invited stores sign up by 2027-03-01, keep the portal for its own value and stop treating it as a growth loop.

## 4b. Book a demo

Self-serve and sales sit side by side: "Try for free" for people who want to explore, "Book a demo" for wholesale shops and anyone unsure. A demo request is a buyer raising their hand.

Today the site has no way to book a call. "Watch demo" opens a Wistia video, the footer "Contact" is a mailto, help and FAQ send people to support@useworkbench.ca (old domain), and `ai_info.yml` points AI assistants at `/contact`, which doesn't exist.

- "Book a demo" in the top nav, next to "Try for free" in the hero, on pricing, at the end of every comparison page and in the help centre footer.
- Calendar embedded on the page, not a link out. Google Workspace appointment schedules (included) or Cal.com's free plan.
- Form: name, email address, shop name, optional phone, and "Who brings you work?" to spot wholesale shops before the call.
- 20 minutes, times in the visitor's time zone, early-morning and after-closing slots.
- Confirmation from a real address, reminder text the day before when there's a phone number.
- The same booking page inside the app as "Book a setup call" on Home during the trial.
- PostHog `demo_booked` event with the page it came from.
- Fix: support links to the new domain, and create `/contact` or point `contact_url` at the booking page.

## 5. Measuring it

- Pass the source (search query, landing page, referrer, UTM) from useworkbench.co into the sign-up, so every shop records where it came from. Use the same PostHog project on both domains.
- Search Console: impressions and clicks per page, monthly.
- PostHog: visits from chatgpt.com, perplexity.ai, claude.ai and gemini.google.com.
- **Metric**: sign-ups from search and AI per month that make a real ticket within 7 days. Write down the baseline on 2026-12-01. Review on 2027-03-01. If search brings fewer than 5 such shops a month by 2027-06-01, cut content spending back to the help centre.

## Next actions

| Action | Owner |
| --- | --- |
| Ask the Google-search customer what they typed | Founders |
| Confirm Search Console for .co, and check .ca redirects | Emmanuel |
| Setup follow-ups: search terms and which assistant | Emmanuel |
| Pass the source from the marketing site into sign-up | Emmanuel |
| First keyword map (steps 1 to 7) | Founders |
| First AI assistant check, with the 10 questions written down | Founders |
| Help centre: list every task a new shop does, write the top 10 | Founders |
| Link "Powered by Workbench" lines to a jewellers page with a source code | Emmanuel |
| "Book a demo" button and embedded booking page, plus the support link fixes | Emmanuel |
| Business clients in the portal, behind a flag, tested with Willy and C Creations | Emmanuel |

## Open

- Which customer found us on Google. Owner: founders.
- Whether we can afford 1 or 2 pieces of search content a week for 6 months while also selling. Owner: founders.
- Whether pure watch repair pages belong in scope (same open question as the go-to-market note). Owner: founders.
