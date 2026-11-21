# Shopify recruiter call prep (30 min)

Anything marked [fill] is a fact only you know. Fill those in before the call.
Don't invent numbers.

## Contents

1. [Cheat sheet](#cheat-sheet)
2. [Game plan](#game-plan)
3. [Intro and why you're back](#intro-and-why-youre-back)
4. [Project stories](#project-stories)
5. [How you use AI](#how-you-use-ai)
6. [Compensation](#compensation)
7. [Questions to ask](#questions-to-ask)
8. [Tricky questions](#tricky-questions)

## Cheat sheet

Specific. Honest. Curious. Stop at 2 minutes.

### Intro (60s)

Shopify Shipping ~4 yrs, intern to senior. Rating engine ($100M/yr), UPS off
legacy card (team of 2), tracking 1B+/day to Yugabyte (team of 3). Left Mar
2026, two-person studio: Workbench (63K+ jobs, 10 shops daily), Belly
(web/iOS/Android, AI import). Want a small team that ships a lot.

### Why back

The year made me better at what Shopify wants now: product judgment, AI
leverage, small teams. I love building more than selling. Building for
independents at scale happens here.

### Story 1: Workbench

Paper tags, lost jobs, "is it ready?" calls. First version: [fill]. Watched
in-shop, iterated. 63K+ jobs, 95K+ updates, 6K+ notifications.

### Bonus: changed course

Custom projects built on an unvalidated assumption. Rejected as rigid. Asked
what hurt: "time to store files in the drive." Cut it to a thin Drive
integration. Rule: repairs are logistics, custom work is a relationship.

### Story 2: Belly import

URL, photo or text to a structured recipe on Haiku. ~1K imports, 4.9/5, 59%
weekly return. Only 23% rated, so went after signal on every import.

### AI

- Daily: Claude Code, parallel agents, I review every diff.
- Built: studio guardrail plugins/skills; Bella (validators + fallback + 13-case
  evals); Shopify incident-report workflow.
- Let me down: Haiku failed clock math. Moved it to Ruby. Model for judgment,
  code for arithmetic.
- Show: Bella evals.

### Comp

"Targeting CA$240K to CA$270K total for senior. Flexible on the split. Level
and total matter most." Then silence. Private floor (never say it): CA$225K at
Senior.

### Ask

1. Senior loop: rounds, OA, deep dive?
2. Own AI setup (Claude Code) in pair programming?
3. Going back to [manager]'s team: does that change the loop or who interviews
   me?
4. Anything that would make the hiring team hesitate?

### Decided answers

- Studio after I join: [fill]
- Start date: [fill]
- Other interviews: [fill]

## Game plan

This is a conversation, not a coding round. The recruiter wants to leave the
call able to write one paragraph to the hiring team: "Builds real things, uses
AI for real, knows what they want, easy to work with." Everything in this sheet
exists to make that paragraph easy to write.

### What 10/10 looks like

- Under 60 seconds to say who you are. Under 2 minutes per story. You stop
  talking before they lose interest.
- Every claim has a number, and every number is true.
- The AI answer is specific enough that they could picture your terminal.
- You say "let me down" with a real example. Almost nobody does this.
- Comp is said once, calmly, as a range, with no apology.
- You ask 2 or 3 sharp questions, and you leave knowing the next steps and the
  loop format.

### Run of show (30 min)

- 0-3: small talk, then they explain the call. Smile, keep it short.
- 3-5: "Tell me about yourself." The 60-second intro.
- 5-15: What you've built. Story 1 (Workbench), Story 2 (Belly imports). The
  bonus story if they ask, or tuck it into story 1.
- 15-22: How you use AI.
- 22-26: Comp, and they explain Flex Comp.
- 26-30: Your questions and next steps.

If they run long on one section, drop story 2 and keep AI. AI is the section
they care about most.

### Day before

- Fill in every [fill].
- Say each story out loud with a timer, twice. Cut anything past 2 minutes.
- Read the Candidate Guide they linked, and skim one recent Shopify Engineering
  blog post so you can mention it naturally.
- Pick the one thing you'll show if they say "can you show me" (see How you use
  AI). Have it open in a tab.
- Fix the "zero self-caused outages" line on the Shopify tab first (see Tricky
  questions).

### 10 minutes before

- Quiet room, headphones, camera at eye level, good light.
- Close everything except the cheat sheet and the thing you might show.
- Water. Phone on silent.
- One line to remember: specific, honest, curious.

### Right after

Write down within 10 minutes: their name, the team or org mentioned, the next
round, the AI rules for the coding rounds, the comp range they gave, and
anything they reacted strongly to. Send a short thank-you the same day.

## Intro and why you're back

### 60-second intro

Say it, don't read it. Aim for about 150 words.

> I'm Emmanuel. I spent almost four years at Shopify on Shipping, starting as an
> intern and leaving as a senior developer. I worked on the rating engine that
> prices every Shipping label, moved UPS off its legacy rate card on a team of
> two, and helped move the tracking service, 1B+ requests a day, onto Shopify's
> shared database on a team of three.
>
> In March I left to co-found a two-person software studio. We built Workbench,
> a back office that independent jewellers use every day, with 63K+ jobs through
> it, and Belly, a recipe app on web, iOS and Android with an AI import
> pipeline. Running that taught me to own the whole loop: talking to customers,
> deciding what to build, and shipping it fast with AI doing a lot of the
> typing.
>
> Now I want to bring that back to Shopify, on [manager]'s team, a small team
> that ships a lot.

Why this works: it opens with Shopify credibility, shows small teams twice, puts
the founder year in their language (product thinking, AI, shipping fast), and
ends with what they told your manager they want.

### Why you left (if asked)

Keep it positive and about learning, never about escaping.

> I'd wanted to build a product end to end for a long time: find the customer,
> decide what to build, ship it, support it. Shopify made me a good engineer. I
> wanted to find out if I could be a good builder too.

### Why you're back

This is the question that matters most. They want to hear that you're coming
back for a reason, not falling back.

> Two things. First, the year made me better at exactly what Shopify is asking
> for now: product judgment, using AI as leverage, and doing a lot with two or
> three people. Second, I learned that the part I love most is building, not
> selling. On a small team I spent more of my time on distribution than on
> product. Shopify is where building for independent businesses happens at the
> biggest scale, and I'd rather do that here than anywhere else. And I get to
> work with [manager] again, on a team already working the way I've been
> working for the past year.

[fill] If there's a personal reason you're comfortable sharing (stability, a
specific team, people you miss working with), add one honest sentence. Honesty
beats polish.

### If they ask "what happens to the studio?"

See Tricky questions. Decide your answer before the call.

## Project stories

The email asks for this exact shape, so use it. Problem, how you defined it, the
first thing you built, how you got adoption, what changed with numbers. Keep
each to under 2 minutes. Lead with the problem, not the tech.

### Story 1: Workbench (lead with this one)

Problem: independent jewellers run repairs on paper tags, binders, and memory.
Jobs get lost, customers call asking "is it ready?", and the jeweller is the
bottleneck for every update.

How you defined it: [fill: how you found it. The first shop, who they were, what
you watched them do. If the first shop was family, say so plainly. It's a good
origin story, not a weakness.] You narrowed it to one job: track every repair
from intake to pickup and let the customer know where it is.

First thing you built: [fill: the smallest first version. For example, a job
ticket with stages and a printable tag with a QR code.]

Adoption: you were in the shop, watching. [fill: what you changed because of
what you saw.] Now 10 shops pay for it and use it daily.

What changed: 63K+ jobs, 95K+ status updates, 6K+ customer notifications. [fill
if you have it: time saved per shop, or fewer "is it ready?" calls.]

Close with: "The product works. Every shop uses it daily. What I learned is that
for a two-person team, distribution was the hard part, not building."

### Bonus story: you changed course on your own idea (tie it to Workbench)

The email lists this as a bonus. Most candidates skip it, so having it ready is
a strong signal.

- We built custom projects, a full workflow for bespoke jewellery: estimates,
  renderings, structured fields.
- I built it on an assumption I hadn't validated: that jewellers wanted a formal
  system for custom work.
- The first studio to try it said no. It felt rigid and impersonal, and it got
  between them and their client, which is the whole relationship in custom work.
- So I asked what actually hurt. The answer was narrow: "the time it takes to
  store files in the drive."
- I stopped adding fields. Instead of a competing system, I scoped a thin Google
  Drive integration: create the folder automatically and drop files in from the
  job.
- Bigger lesson, now a product rule: repairs are logistics, so software helps.
  Custom work is a relationship, so software stays out of the conversation. We
  removed the client-facing custom portal.

One line to end on: "The evidence said the shape was wrong, so I cut it, even
though I'd built it."

### Story 2: Belly's AI recipe import

Problem: getting a recipe into any app is manual copying. People save recipes
from Instagram, blogs and screenshots, and never cook them.

First thing you built: an LLM pipeline that turns a URL, a social link, a photo
or pasted text into a structured recipe, on Claude Haiku.

Adoption: imports became the main way recipes get in. About 1K imports, 400+
last month, rated 4.9/5. Belly has 190+ users, and 59% of monthly users come
back every week.

The interesting part, a measure-it-honestly moment: only 23% of imports were
getting rated (64 of 274). The two real bugs that month, Dutch total time read
as prep time and steps packed into one, each came from a single low rating with
typed feedback. Everyone who fixed an import by hand and didn't rate it told us
nothing. So I went after signal on every import, not just the rated ones. [fill:
what you shipped, and one result if you have it.]

Close with: "The rating looked great at 4.9. The real question was what the
other 77% were telling us."

### Backup story: shadow rating at Shopify

Use this if they want something from your Shopify time, or a craft story.

- Before moving UPS off its legacy rate card, we built a shadow-rating tool that
  priced live requests on both paths and diffed the results before the gradual
  rollout.
- It caught the legacy card quietly undercharging.
- Point to make: when you're touching a $100M/yr pricing path, you prove it's
  correct on real traffic before you trust it.

### Delivery rules

- Say "we" for team work and "I" for your decisions. Be precise about which is
  which.
- One number per story that you say slowly.
- Stop at 2 minutes and ask: "Want me to go deeper on any part?"

## How you use AI

The email says "specific examples beat general enthusiasm." So: name tools, name
workflows, give one honest failure. Aim for about 3 minutes, then offer to show
something.

### Day to day (30 seconds)

> Claude Code is my main tool, in the terminal, all day. I plan with it, have it
> implement while I review the diffs, and I run several agents in parallel on
> separate tasks in the same repo. I also use Claude in Chrome for browser work,
> like checking a feature end to end or researching, and the Claude API inside
> the products themselves.

[fill: anything else you use daily: Cursor, Codex, a model for writing,
AppSignal or PostHog MCPs for production debugging.]

### Workflows and agents you built (pick 2)

1. Studio guardrails as Claude Code plugins and skills. Every studio app gets
   the same rules automatically: safe migrations, AI code review before merge,
   shared conventions, background-job rules. Point: "I don't rely on remembering
   best practice. I encode it once and every agent follows it."
2. Bella, an AI party-planning assistant. A host gives a menu, and it returns a
   timed prep plan. Structured Claude output, Ruby validators that check and
   repair each plan, a Haiku-to-Sonnet fallback, and a 13-case eval suite
   including one production-sized fixture. Point: "I treat a prompt like code.
   It has tests."
3. At Shopify: a Claude Code workflow that drafted incident reports from logs,
   data and Slack. [fill: who used it, and how much time it saved per incident.]
4. Belly's import pipeline. Haiku turns messy input into structured recipes at
   about 0.1 cents a call.

### Where AI made you faster (one concrete line)

[fill with a real example, e.g. "Belly shipped on web, iOS and Android from one
Rails codebase. As a two-person team, that wasn't realistic without agents doing
most of the implementation while I did design and review."]

### Where AI let you down (the answer that sets you apart)

Have two ready. Lead with the first.

1. Models are bad at exact constraints. In Bella, Haiku kept failing clock
   arithmetic and counted limits: earliest start times, no stacking, note
   length. The fix wasn't a better prompt. I moved those checks into Ruby,
   because code does exact things exactly, and put the model behind a validator
   with Sonnet as the fallback. Lesson: let the model do judgment and let code
   do arithmetic.
2. Agents in production need guardrails. During an image backfill on Workbench,
   the plan undercounted the files (about 9k estimated, 20k real) and ran heavy
   jobs inside the web process. It took the app down several times in one night.
   I fixed it and wrote a retro. Now every production backfill starts with four
   numbers: rows, time per item, memory per item, and memory available. Lesson:
   the AI moves fast, so the human has to own sizing and blast radius. (Only use
   this if you're comfortable owning the outage. See Tricky questions.)

### What to show if they ask

Pick one and have it open:

- The Bella eval suite running (fastest "wow")
- One studio Claude Code skill or plugin file, to show how a guardrail is
  encoded
- The backfill retro, as an example of how you learn from incidents

### Phrases to use

- "I drive, the agent types."
- "I review every diff before it lands."
- "Model for judgment, code for arithmetic."
- "I encode the rule once so every agent follows it."

### Avoid

- "I use AI for everything" (enthusiasm without specifics)
- Claiming AI wrote it all and you just accepted it
- Bashing AI, or being dismissive of the memo culture

## Compensation

Shopify covers comp on the first call on purpose. Saying a range calmly is part
of making a good impression.

### What the data says (Canada, Senior / L6)

- Levels.fyi, Apr 2026: L6 median total comp about CA$246K. L7 about CA$360K.
- Levels.fyi job-family snapshots, Feb 2026: L6 about CA$210-220K.
- Blind, Dec 2025: an L6 candidate was told roughly CA$200K-300K.
- Blind, Nov 2025: an L5/L6 data science candidate asked for CA$350K all in, and
  the recruiter was fine with it.
- [fill: your own total comp when you left in Feb 2026. This is your strongest
  anchor. They may already have it.]

### Your range

Say: CA$240K to CA$270K total comp.

Private floor: CA$225K at Senior. Don't say it.

Why this range:

- Levels.fyi, Nov 18 2026: Canada L6 median CA$244K, L5 median CA$164K. The
  bottom of your range (240K) sits right at the L6 median.
- You were Senior for 4 months (Nov 2025 to Feb 2026), so you were near the
  bottom of the L6 band when you left. Asking well above the median would
  clash with that history. Shopify can see your old comp and level.
- The top (270K) leaves room for the founder year and your manager's backing
  without looking like a Staff ask.

Check before the call: if your total comp when you left was above CA$240K, set
the bottom of your range at or above it.

The real risk is level, not dollars. L5 is about CA$80K a year less than L6.
Decide now whether you'd accept L5 (with a fast path to L6) or hold out for L6.
Don't decide that on the call.

### How to say it

> I'm targeting a total comp range of CA$240K to CA$270K for a senior role. I know
> Shopify lets people choose their cash and equity mix, so I'm flexible on the
> split. Total comp and the level matter most to me.

Then stop talking. Don't justify, apologize, or fill the silence.

If they push for a single number:

> Within that range, where I land depends on the level and the team. I'd rather
> get the level right first.

If they give their band first, react to the band, not your range:

> That works. Given my time on Shipping and the last year owning everything end
> to end, I'd hope to land in the middle of that band, not the bottom.

### Level is the real lever

- You were promoted to Senior in Nov 2025 and left 4 months later. The risk is
  being re-levelled to L5 because your senior track record is short.
- Get ahead of it with evidence of senior-level work, not your title: the UPS
  migration (wrote the design, shipped on a team of 2), the rating engine
  expertise and handover, mentoring an intern, and a year of owning everything
  end to end.
- Your manager is your biggest lever on level. Before the call, ask them
  directly: "What level are you putting me in for, and is there anything I
  should say or avoid on comp?" If they say L6, the recruiter call is about
  confirming, not convincing.
- Say you're aiming for Senior. Don't sound defensive about the 4 months. If
  they bring it up, own it: "Short on the title, but the scope came before the
  promotion, and the last year added more."
- Ask: "How do you decide level for returning employees? Does my time away
  count?"

### Stretch goal: CA$300K (private, never say it on this call)

On the recruiter call you say the realistic band (CA$240K to CA$270K). The push
to CA$300K happens at the offer stage, after the interviews have made the case
for you. CA$300K is the top of the L6 band, so every step below is about getting
rated a strong senior, not just a pass.

Before the recruiter call:
- Ask [manager] what level they're putting you in for and where the top of that
  band is. If the band tops out under CA$300K, the stretch goal is the top of
  the band, whatever that is.

During the loop, play for "strong hire", not "hire":
- Pair programming: lead the design, review the AI's output out loud, add tests
  without being asked, and name the next requirement before they give it.
  Practice until every problem in the kit is comfortable, not just passable.
- Technical deep dive: pick UPS or the tracking migration. Cover the problem,
  options you rejected, what broke, and what you'd do differently. Show scope
  and judgment, not tasks.
- Life story: one clear thread. You went after bigger ownership each time
  (intern, rating engine expert, UPS design, founder), and you're coming back
  with it.
- Recruiter call: stay calm on comp, and ask sharp questions. The recruiter's
  notes travel with you.

Build leverage in parallel:
- Keep other processes moving (Float, Wealthsimple, StackAdapt). A real offer
  at CA$250K+ is the strongest reason a recruiter has to go to the top of a
  band.
- Ask [manager] to push for top of band when the offer is being built.

At the offer:
- If it comes in below CA$300K, thank them, then ask once: "I'm really excited
  about this. Given the loop feedback and [competing offer, if any], is there
  room to get closer to CA$300K?" Then stop talking.
- If cash is capped, ask about the level first, then a signing bonus or
  equity. Choosing more equity also raises the headline number through the 5%
  bonus. It's riskier, and the call is yours.
- Decide your walk-away number before the offer call, not during it.

If you miss: a strong L6 offer in the realistic band is still a good outcome,
and a strong loop puts you on track for the next level faster.

### Flex Comp, so you understand what they'll explain

- You choose the split between cash, RSUs and options. You can change it about
  four times a year.
- There's a 5% bonus on extra equity you choose.
- There's no one-year cliff. Vesting starts right away.
- Some people take part as Shop Cash.

I can't advise you on which split to pick. That depends on your finances and
risk tolerance. Decide what matters to you before the call (stability vs upside)
so you can answer "what matters most?" in one sentence.

### What matters most (have a one-line answer)

> Total comp and getting the level right come first. After that, a small team
> where I can ship a lot. I'm flexible on the cash and equity split.

### Don't

- Don't say "whatever's fair."
- Don't give your FIRE math or your expenses.
- Don't negotiate hard on this call. It's about alignment, so there are no
  surprises later.

## Questions to ask

Ask 2 or 3. Pick the ones not already answered. The first two are must-asks for
the coding prep.

### Process (must ask)

1. What does the loop look like for a senior role: number of rounds, order, any
   online assessment, and is there a technical deep dive or system design round?
2. In the pair programming rounds, can I use my own setup, Claude Code in my own
   editor? Anything I should know about how AI use is evaluated?
3. What's the timeline from here, and who's the next person I talk to?

### Team and work (pick 1 or 2)

4. I'm going back to [manager]'s team. Does a known team placement change
   anything in the loop, like who interviews me or whether [manager] is part of
   the decision?
5. [manager] mentioned teams of 2 or 3 engineers working with a lot of AI
   leverage. From your side, what does that look like across Shopify right now?
6. What separates the engineers who've done really well in the last six months
   from the rest?
7. How do teams decide what to build? How close are engineers to merchants?

### Returning employee

8. Is there anything different in the process for returning employees? Does my
   previous performance history carry over?

### Good closing line

> Is there anything in my background you'd want me to clarify, or anything that
> would make the hiring team hesitate?

It's a strong question. It lets you fix a concern while you're still on the
call.

### Don't ask

- Things the Candidate Guide already answers
- Vacation or perks on the first call
- "What does Shopify do?"-level questions

## Tricky questions

Decide these answers before the call. Being vague here is the easiest way to
lose points.

### 1. "What happens to Workbench and the studio?"

This is the most likely tricky question. Workbench integrates with Shopify, and
Shopify will care about conflicts of interest and focus.

[fill: decide. The options are:]

- Wind down or hand off: "I'm winding it down / handing it off before I start.
  Shopify gets my full focus."
- Keep it as a small side project: "It runs mostly on rails now. I'd disclose it
  and follow Shopify's outside-activity policy, and it wouldn't take time from
  work."
- Sell it or pass it to my co-founder.

Whatever you choose, say it in one sentence, mention disclosure, and lead with
focus. Don't improvise this one.

### 2. "Why didn't the studio work out?" (or "Is it failing?")

Don't apologize, and don't oversell.

> The products work. Workbench has 10 paying shops using it daily, and Belly has
> strong weekly retention. What I learned is that for two people, distribution
> was the constraint, not building. I'm much more excited about building than
> about selling, and Shopify is where building for independent businesses
> happens at scale.

### 3. "You have 'zero self-caused outages' on your resume..."

Fix this before the call. The Workbench image backfill on 2026-11-07/08 caused
several outages (see ~/notes/retros/2026-11-07-workbench-backfill-oom.md). Your
Shopify tab still says "zero self-caused outages". Your manager or a later
interviewer could ask about it, and an overclaim is worse than an outage.

Suggested replacement: "Ran production with safe migrations, AI code review, and
exception monitoring; wrote retros for every incident." Or a version that names
what changed after the backfill outage.

If an outage comes up, own it: what happened, what you changed, the four-numbers
rule. Owning an outage well is a senior signal.

### 4. "Why should we rehire someone who left?"

> I left on good terms to learn something I couldn't learn here, and I came back
> with it: product judgment, end-to-end ownership, and a lot of hands-on AI. You
> get someone who already knows the codebase and culture, and has grown since.

### 5. "Were you laid off?" or "Why only a year?"

You weren't laid off. You left to build. Say it plainly. On why only a year: "I
gave it a real try, learned what I came to learn, and saw that I'm happiest
building."

### 6. "What level are you looking for?"

> Senior. I was promoted in Nov 2025, but I'd been working at that scope before
> the title, like leading the UPS migration and being the rating engine expert.
> And the last year added more scope, not less.

### 7. "Are you interviewing elsewhere?"

Be honest and brief. [fill: yes or no.] If yes: "I've had a few conversations,
but Shopify is my first choice, which is why I reached out to my old manager."
Don't name companies unless asked.

### 8. "When could you start?" / "Remote?"

[fill: earliest start date, considering any studio wind-down. Where you're
based.]

### 9. "What would your old manager say about you?"

[fill: one strength they'd name, and one thing you've worked on since. Your
manager may be asked directly, so make it consistent with what they'd say.]

### 10. "Tell me about a time you worked under pressure."

UPS launch-critical work, or USPS and DHL Express launches on tight deadlines.
[fill: one specific launch, the deadline, what you cut, what shipped.] Or the
backfill outage night: calm diagnosis, pausing the queue, scaling up, finding
the real ceiling.
