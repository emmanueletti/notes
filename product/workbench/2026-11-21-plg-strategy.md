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
6. **AI assistant check, monthly**: run the prompt set from section 3 across the assistants. Log whether Workbench comes up and which sources are cited. Those sources are where we need to be.
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

## 2b. Stories and editorial

**Customer stories, 2027.** Video case studies and interviews with shops, made with a local Montreal filmmaker who has agreed to trade services. Each story gets its own page (video, transcript, real numbers), cut into short clips for social and help pages. Transcripts make video searchable and quotable by AI assistants. Start with Jewellery Clinic Wholesale (before and after photo intake) and SarahBijoux. Ask consent for names, numbers and footage in writing.

**A jewellers' magazine.** An editorial publication featuring innovative young independent brands with an ethical and sustainable focus: their craft, their bench, how they run the business. Why it works:

- It attracts exactly the shops we want, and positions Workbench as a tastemaker, not a vendor (as Shopify's merchant stories and Mailchimp's content studio did, from general knowledge).
- Featured brands share their feature, which brings their audience and links back to us. That's the closest thing we have to user-generated content.
- Each feature earns a warm relationship with a brand that might use Workbench, without a sales pitch.
- It ranks for brand names and ethical jewellery searches.

Rules: feature brands on merit, never only customers or only people who pay. The ethical claim must be real: repair extends a piece's life, which is the honest centre of it. Start with one feature a month, filmed or photographed with the filmmaker.

## 3. AI recommendations: the new loop

Being recommended by ChatGPT, Claude, Gemini and Perplexity is the priority channel. Researched 2026-11-21.

### Why

Tally (bootstrapped, about 10 people) says AI search overtook its "Made with Tally" viral loop as its biggest acquisition channel: "43% of new users discover Tally through ChatGPT, Claude, Gemini, Perplexity, and friends" (Tally blog, 2026-09-22). ChatGPT became their #1 referral source in 2025, after GPT-4o began browsing the web by default and pulling in forums, Reddit, blogs and user content. Their stated tactics: track where assistants mention and cite them, find prompts where they're missing, audit the help centre, keep comparison pages current, stay present in public conversations. They ask every new user how they found Tally, and say the survey shows far more AI-driven sign-ups than tracking does. Their caveats: they don't control the channel, a model update can reshuffle recommendations overnight, and it can't be bought.

For a niche like jewellery repair software, few pages compete for these answers, so a small team can win them.

### Fix first: we block AI crawlers today

Checked 2026-11-21. useworkbench.co serves a Cloudflare-managed `robots.txt` that disallows the training crawlers (GPTBot, ClaudeBot, Google-Extended, Applebot-Extended, anthropic-ai, CCBot and others), with `Content-Signal: ai-train=no`. Cloudflare also returns 403 to ClaudeBot, PerplexityBot and GPTBot (retested 2026-11-21 with their full user agents; Claude-SearchBot and normal browsers get 200). Search and user-fetch bots (OAI-SearchBot, ChatGPT-User, Claude-SearchBot, Claude-User, Perplexity-User, Googlebot, Bingbot) get through.

Consequences: what models know without browsing never includes Workbench, and Perplexity's indexer can't read the site. For a business that wants to be recommended, that's the wrong default.

- In Cloudflare, turn off AI bot blocking and the managed `robots.txt` for useworkbench.co. Allow every AI crawler, training ones included, and set `ai-train=yes`.
- Keep the app and portal domains closed to crawlers. Only the marketing site opens.
- Re-test each bot after the change.

### Content assistants cite

- **"Best X" lists dominate citations.** An Ahrefs study of 26,283 URLs that ChatGPT cited for software and service prompts found 43.8% were "best X" list pages (via getreditus). Write an honest "Best jewellery repair software" page that includes competitors, and get Workbench into lists others publish (outreach to the authors of existing roundups).
- **Comparison pages**: keep all 9 current. Refresh each when a competitor's pricing changes. Add Gem Logic, Jewel360, QuantumRepair and FixyFlow.
- **Answer first**: on every important page, a 40 to 60 word direct answer right under the heading ("Workbench is repair and custom order software for independent jewellers and trade shops..."), then detail. Assistants lift that block.
- **Help centre**: complete, one question per article, audited monthly so facts are current (Tally does this with Claude).
- **Original data**: publish what nobody else has, from anonymised Workbench data. For example, a yearly jewellery repair report (typical turnaround by repair type, share of jobs with photos, busiest months). Original numbers get cited.
- **French**: the same pages in French. French prompts have even fewer competing answers.
- **Video with transcripts**: the filmmaker's stories and magazine features on YouTube, with transcripts on the site. YouTube is among the most cited sources.

### Off-site presence

Assistants rely on what others say, not only on our site.

- **Reddit and Ganoksin** (Reddit is the most cited domain across assistants in several 2026 studies): a founder answers real questions, says plainly that they make Workbench, and never posts under fake accounts.
- **Review sites**: free listings on G2, Capterra and GetApp, with reviews from happy shops. Studies found sites listed on several review platforms get cited more, though one study of ChatGPT disagrees for software. Cheap either way.
- **The magazine**: featured brands link to and talk about Workbench.
- **Connector directories**: once the MCP server exists, listing in Claude's and ChatGPT's connector directories puts Workbench inside the assistants themselves.
- **Shopify App Store**, once the app exists.

### Entity clarity

"Workbench" is a common word, shared with other products (MySQL Workbench and others). Assistants must know which Workbench we mean.

- Always pair the name with the category, in one consistent line everywhere: "Workbench, the back office for jewellers that runs itself" (position in `2026-11-21-brand-positioning.md`).
- Win prompts around hands-free work: "jewellery repair software without data entry", "fastest way to log jewellery repairs", "scan jewellery repair envelopes". Comparison pages argue time saved, not feature counts.
- `Organization` and `SoftwareApplication` structured data on the home page, with `sameAs` links to LinkedIn, Instagram, YouTube, G2 and Capterra.
- Consistent profiles on LinkedIn, Crunchbase and a Wikidata entry.
- `FAQPage` on help articles, `HowTo` on guides.

### llms.txt

Keep `llms.txt` and `/ai-info` because they cost nothing and help agents doing tasks, but don't count on them for recommendations. Ahrefs found 97% of llms.txt files got zero requests in a month, OpenAI's crawler fetched robots.txt about 4,000 times against 7 for llms.txt in one log study, and Google says its search and AI Overviews don't use it. Keep `/ai-info` facts exact; update it the day pricing changes.

### Measuring

- **Prompt set, monthly**: 20 prompts in English and French across ChatGPT, Claude, Gemini, Perplexity and Google's AI Overviews. Three kinds: category ("best jewellery repair software"), problem ("how do jewellers track repairs"), competitor ("Gem Logic alternative"). Log whether Workbench appears, its position, and which sources are cited. Missing prompts are the work list.
- **Tools**: Tally uses Ahrefs and Promptwatch. Start by hand with the prompt set; buy a tool when the set outgrows a spreadsheet.
- **Ask every new shop** how they found us (the setup question), with "An AI assistant suggested it" and which one. Trust the survey over tracking, as Tally does.
- **PostHog referrers**: chatgpt.com, claude.ai, perplexity.ai, gemini.google.com, copilot.microsoft.com.
- **Target**: Workbench named in at least half of the category prompts by 2027-06-01.

### Baseline audit, 2026-11-21

Run by hand by another session (workbench-4a) through Google AI Mode, Perplexity (signed in) and ChatGPT.

- **Buyer prompts**: Google AI Mode named Workbench in 0 of 4. Perplexity in 2 of 4: top 3 for "jewellery repair tracking software for shops in Canada", 5th of 5 for "back office software for an independent jewellery brand". ChatGPT unusable for the test: the account knew Workbench was ours. Perplexity added "Montréal" on its own, so results are personalised by location.
- **Branded prompts**: Google answers "What is Workbench for jewellers?" with physical jeweller's benches; the software gets one line. Perplexity puts the software first. Both describe us correctly when given useworkbench.co.
- **Why Google skips us**: it cites Capterra and GetApp Canada, Reddit r/jewellerymaking, the Shopify App Store, YouTube, SourceForge and competitors' pages updated in November 2026. We're on none of them. Perplexity reads our site live and cites only useworkbench.co.
- **Name collision**: "The Workbench London" (a ring-carving kit brand with Vogue and Dragons' Den coverage) and physical benches own the word. Keep the name, always add the descriptor, and check trademarks before the redesign.
- **Site**: no `ld+json` structured data anywhere in `marketing/src/`. `src/_data/ai_info.yml:7` still carries the old repair-shop positioning, and Perplexity quotes it almost word for word ("repair-led", "less of a complete ERP"). Claims engines attributed to us that need checking: "signed terms", updates "in the customer's preferred language and tone", "30-day trial, no card".
- **Competitors in answers without a comparison page**: PrismaNote (in nearly every answer; closest to us, a standalone repair tool that keeps the shop's till), Gem Logic, Jewel360, wJewel. Also seen: Flawless POS, Luxare, Jewelia, PIRO Retail, Noble (a Shopify app), Hubtiger, Repair Pilot, Datopia Flow, JewelryStudioManager.

Fixes, by impact:

1. Capterra, GetApp and Software Advice listings, Canada and US, with 5 to 10 reviews from current shops. The main fix for Google.
2. Rewrite `ai_info.yml` and `llms.txt` to the current position ("the back office that runs itself") and verified facts only.
3. Comparison pages: vs PrismaNote, vs Gem Logic, vs Jewel360.
4. One answer-shaped page, "jewellery repair tracking software", leading with Canada and bilingual, where we already win.
5. Structured data: `SoftwareApplication` and `Organization`, plus `FAQPage` on comparison pages.
6. A short intake demo on YouTube, and genuine help in r/jewellerymaking.
7. Untested so far: ChatGPT signed out, and a location outside Montréal.

### Our own tracker (studio tooling)

Gauge ($599 a month, 600 prompts a day across ChatGPT, Google AI Mode and Copilot; logos include PostHog and Supabase), Profound, Peec, Otterly and Semrush sell AI visibility tracking. Alternative: a small studio gem plus a recurring job that runs a fixed prompt set per product (Workbench, Belly, Canvas, Deja Yum) through the engine APIs (OpenAI, Perplexity Sonar, Gemini with grounding), stores mention, rank, citations and competitors, and charts the trend. Replaces $500+ a month per product. API answers differ from the consumer apps, so spot-check by hand.

### Getting found, for our shops

A jewellery owner told the founders that what they want most is more customers. Growth tools for shops are in scope and core (founders, relayed 2026-11-21): like Shopify, Workbench wins when its shops make money. Ideas:

- **Services as structured data**: publish each shop's services (repair, resizing, custom) as structured data and feeds AI shopping and agents read.
- **Visibility check in Workbench**: about 20 local prompts a week ("custom jeweller in Surrey", "ring resizing near me"), shown as "you appear in 2 of 20, competitor X in 9". A hook, an upsell and a reason to sign in.
- **Review asks at pickup**, when the customer is happiest. Reviews feed local search and AI answers. The jeweller sends them.
- **Care reminders** for repeat work: cleaning, rhodium replating, prong checks, watch batteries.
- **Quote follow-up** so forgotten quotes become jobs.
- **Paid growth add-ons**: for example "Get found" (visibility check, feed, review asks), priced for small shops, around C$20 to 50 a month.

Validate first: no jeweller has said "AI doesn't recommend us" yet. Run about 30 local prompts by hand for 5 shops; ask Willy and 2 or 3 others whether customers say they found them through ChatGPT or Google AI, and what "more customers" means to them (for Willy's wholesale shop, customers are stores).

Full action list with impact, effort and order: `aeo-action-plan.md`.

### Rhythm

- Monthly: run the prompt set, audit the help centre, refresh comparison pages.
- Every pricing or feature change: update `/ai-info`, comparison pages and the help centre the same day.

Sources: [Tally, 6 years in](https://blog.tally.so/6-years-in-6-million-far/), [Tally, 2 to $3M ARR](https://blog.tally.so/from-2-to-3m-arr-how-we-bootstrapped-tally-with-a-tiny-team/), [getreditus on LLM citations](https://getreditus.com/blog/how-to-get-cited-by-llms), [Contently, sources LLMs cite](https://contently.com/2026/04/29/top-sources-llms-cite/), [DerivateX ChatGPT software study](https://derivatex.agency/report/chatgpt-software-recommendation-sources/), [Optimizely on llms.txt](https://www.optimizely.com/field-notes/articles/does-llms-txt-work), [GEO guide for B2B SaaS](https://guptadeepak.com/the-complete-guide-to-generative-engine-optimization-what-b2b-saas-companies-need-to-know-in-2026/). Most GEO studies come from vendors; treat figures as indicative.

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
| Unblock AI crawlers on useworkbench.co in Cloudflare, re-test each bot | Emmanuel |
| Capterra, GetApp and Software Advice listings, then ask 5 to 10 shops for reviews | Founders |
| Rewrite `ai_info.yml` and `llms.txt` to the current position, verified facts only | Emmanuel |
| Comparison pages vs PrismaNote, Gem Logic, Jewel360 | Founders |
| Answer page "jewellery repair tracking software", leading with Canada and bilingual | Founders |
| Structured data: `SoftwareApplication`, `Organization`, `FAQPage` on comparison pages | Emmanuel |
| Short intake demo on YouTube; genuine answers in r/jewellerymaking | Founders |
| Re-run the AI prompts signed out of ChatGPT and from outside Montréal | Founders |
| Check the facts engines attribute to us ("signed terms", "preferred language and tone", "30-day trial, no card") and fix the site where wrong | Emmanuel |
| Write the 20-prompt set and run it once as a baseline | Founders |
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
