# Engineering Growth Plan

Written 2026-09-10. The long arc: web developer to engineer who can reason about
any system from first principles, as the technical half of an ambitious studio.

This is a decade document, not a year document. It is the index for the topic
notes in this directory, and the reasoning for what order to attack them in.

Related: `systems-from-first-principles.md`, `parsing-from-first-principles.md`,
`programming-design-principles.md`, `debugging-hanging-systems.md`,
`understanding-linux.md`, `mastering-my-tools.md`.

**Path not yet chosen.** `growth/` holds four articulated candidates and a
comparison. This document is path-independent: pillar zero, the method, the
hours accounting and the measurement survive whichever one wins. The sequencing
and resource sections below describe Path C (product leverage) and should be
read as one option rather than as the plan.

---

## The starting position

Four years of professional web development. Ruby and Rails, deep. Shipping
product to paying customers. Comfortable with the framework layer, comfortable
with the tools, comfortable delivering.

That is a real skill and it is not the thing being upgraded here. Framework
fluency is what a good developer has. What is missing is the layer underneath:
the ability to reason about a system nobody has explained to you.

---

## What "strong foundations" actually buys

Not trivia. Not interview performance. Three concrete capabilities:

**1. Debugging anything.** The gap between "I have heard of TCP backpressure"
and "I can reason about it at 2am with a customer waiting" is the entire gap.
Foundations are what let you form a hypothesis about a system you have never
read the source of, and be right often enough to be fast.

**2. Architecture decisions with a three-year horizon.** Most technical
decisions are cheap to make and expensive to unmake. The ones that hurt are
schema shape, consistency model, where state lives, what the failure modes are.
You cannot reason about those from framework knowledge. They live below it.

**3. Evaluating a technology in an afternoon.** Not "I read the marketing page."
Actually: what problem does this solve, what does it cost, what does it break,
is the trade it makes the trade I need. This is only possible when you already
understand the underlying problem it claims to solve.

For a CTO specifically, add a fourth: **calibrating a hiring bar.** You cannot
identify engineering judgment in someone else that you do not have yourself.

---

## The honest tension

There is a five-year FIRE target and a business with real customers. Deep study
and shipping compete for the same hours. Any plan that ignores this fails in
month two.

Two things resolve it.

**Learning must be load-bearing on the business.** Study the things that make
Workbench better, faster, or cheaper to run. Postgres depth pays rent next week.
Distributed consensus does not, at nine customers. Order the curriculum by what
compounds into the product, and the study time stops being a tax.

**Small and daily beats large and occasional.** One focused hour a day, five
days a week, is 250 hours a year. Ten years is 2,500 hours, which is enough to
be genuinely deep in four or five domains. An eight-hour Saturday every third
weekend is 130 hours a year and produces nothing durable, because retention
comes from spacing, not from intensity.

The marathon works through compounding. Compounding requires never taking a
month off, not going hard.

---

## Pillar zero: solving ambiguous problems

Sits under all five pillars below. Named separately because it is the one that
actually blocks, and because it is trainable in a way that feels like it is not.

**The anxiety in front of an ambiguous problem is a process gap, not a knowledge
gap.** People who look calm are not seeing the solution. They have a first move
that works when they cannot see the solution. The panic comes from having no
move, so the mind tries to hold the whole problem at once and overflows.

Two consequences worth internalising:

**Writing it down is most of the fix, not a nice-to-have.** Ambiguous problems
do not fit in working memory. Seven items, maybe. A real problem has thirty. On
paper it is just a list. The dread lives in the holding, not in the problem.

**Most "I do not know how to solve this" is actually "I cannot state this."**
Those feel identical from the inside and have opposite fixes. Attempting to
solve an unstated problem is what generates the spin.

### The routine

Polya's four phases, from *How to Solve It*. Nothing better has replaced it in
80 years.

1. Understand
2. Plan
3. Execute
4. Look back

The failure is skipping 1 and going straight to 3. Under pressure that feels
productive. It is the source of the anxiety, because you are building without
knowing what.

### Phase 1 moves: making it concrete

**Get one real example.** Ambiguity means the problem is stated abstractly, and
abstraction is where panic lives. Ask for one actual input, one actual customer,
one actual row. "Show me one" collapses more ambiguity than an hour of thinking.

**Restate it until it is boring.** If the restatement still sounds vague or
exciting, you do not have it yet. Boring means specific. Say it back to whoever
asked and watch their face.

**Write the unknowns list.** Literally: "things I do not know." Ambiguity feels
infinite. Written down it is usually four items. Rank them by which one, if
answered, collapses the most other uncertainty. Get that one first.

**Draw the boundary.** What is in scope, what is out, explicitly. Half of
ambiguity is unstated scope, and the asker will confirm a boundary readily once
you propose one.

**Write down what done looks like.** If you cannot describe the finished state,
you are not ready to plan. This question kills a surprising number of problems
outright, because sometimes nobody knows, and that is itself the finding.

### Phase 2 moves: the decomposition toolkit

"Break it into smaller pieces" is useless advice, because breaking it down is
the exact thing that feels impossible. These are the actual operations.

**Solve n=1.** One user, one file, one record, hardcoded. The general case is
often the specific case with a loop around it, and the specific case is always
tractable.

**Drop a constraint.** Solve the version where performance does not matter, or
it works for one customer only, or it runs manually. Add constraints back one at
a time, each against working code.

**Brute force first.** A dumb, slow, correct solution is a specification and a
test oracle. It also proves the problem is solvable, which does more for the
anxiety than any amount of planning.

**Work backwards.** Start at the desired end state, ask what must be true
immediately before it, then before that. Useful when the start is murky but the
goal is clear.

**Ask what would make this trivial.** Then ask why you cannot have that. The
answer names the real constraint, frequently not the one you were fighting.

**Find the invariant.** What must be true at every step regardless? For data
problems this is usually the whole design.

**Find the analogous problem.** Solved something with this shape before? Has
anyone? Most problems are a known problem wearing different vocabulary.

**Split on the biggest unknown, not the first one.** Instinct is to start where
there is traction, which feels good and leaves the risk to the end. Attack the
piece most likely to invalidate the whole approach.

### When genuinely stuck: the timeboxed spike

Two hours, throwaway code, and the goal is **information, not a solution**.
Write the question down first: "can Postgres do this under 200ms," "does this
API return what I need."

This is the highest-value anxiety conversion available. It turns "I am stuck and
something is wrong with me" into "I am running an experiment with a deadline."
Same uncertainty, different physiology, and it produces data either way.

### Ask, and ask specifically

Ambiguous problems from humans are almost always under-specified, because the
asker has context they forgot to transmit. Asking is not weakness. At CTO level
it is a large part of the job.

But ask *specific* questions, which requires phase 1 first. "Can you clarify"
gets nothing. "I am assuming this only needs to work for paying accounts and
that a two-minute delay is fine, true?" gets everything.

Default to stating an assumption rather than asking a question. People correct
faster than they specify.

### On the feeling itself

**It resolves at the first action, not at the answer.** You do not need to know
how it ends. You need one next move. That is why the routine works: it always
produces a move.

**Speed of the first move beats quality of the first move.** A mediocre first
move generates information. Sitting generates spin.

**Senior people feel it too.** The difference is starting the routine before the
feeling resolves, rather than waiting to feel ready. Waiting to feel ready is
the trap, because the feeling arrives after starting, never before.

**Ambiguity is the job at CTO level.** A well-specified problem is what gets
delegated. What lands on you is precisely what nobody has decomposed yet. This
is not a weakness to fix before the role. It is the central skill of the role.

### Training it

**A short design doc before every non-trivial feature.** One page: problem,
constraints, unknowns, approach, what done looks like. Forces the whole routine
under low stakes, where it is cheap. Also the artifact that makes you legible to
anyone hired later.

**Keep a decisions log with predicted consequences.** `studio/decisions/` is the
right shape already. Add the technical ones. Rereading them in two years is how
calibration develops, and nothing else builds it.

**Post-mortem decompositions, not just incidents.** After a hard problem: which
move actually broke it open? Over a year a personal pattern emerges and you
learn which two or three moves are yours.

**Take ambiguous problems on purpose, timeboxed.** Exposure with bounded
downside. The dread shrinks with repetition and only with repetition.

### Reading

**Are Your Lights On?**, Gause and Weinberg. Short, odd, entirely about problem
*definition* rather than problem solving. The most direct hit on this specific
difficulty.

**How to Solve It**, Polya. Math examples, universal method. The heuristics list
at the back is the toolkit above in its original form.

**The Art of Doing Science and Engineering**, Hamming. Especially "You and Your
Research." About choosing which problems deserve effort, which becomes the
binding constraint once decomposition is handled.

**Debugging**, David Agans. Nine rules, practical, aimed at the case where the
system is lying to you. Pairs with `debugging-hanging-systems.md`.

---

## The map: five pillars

The whole of practical CS fundamentals, for someone building products.

### 1. The machine

How a computer actually executes. Memory hierarchy, the stack, virtual memory,
processes and threads, syscalls, scheduling, file systems, how a binary becomes
a running process.

Why it matters: every performance problem and every mysterious hang bottoms out
here. It is also the layer that makes all the others make sense.

Core text: **OSTEP** (*Operating Systems: Three Easy Pieces*), free online.
More accessible than CSAPP and better as a first pass. **CSAPP** after, when
you want the memory and linking depth.

Already started: `systems-from-first-principles.md`, `understanding-linux.md`.

### 2. Data

Storage engines, indexing, query planning, transactions, isolation levels,
replication, the actual physics of getting bytes off a disk and into a response.

Why it matters: a Rails SaaS *is* a data-intensive application. This is the
pillar where a week of study most directly changes the product.

Core text: **Designing Data-Intensive Applications** (Kleppmann). Probably the
single highest-value technical book for this specific goal. Then **Database
Internals** (Petrov), then Postgres documentation, which is unusually good.

### 3. Abstraction and languages

Lexing, parsing, ASTs, interpreters, compilers, type systems, how a language
implements itself.

Why it matters: this is the "how do abstractions get built" pillar. It removes
the fear from metaprogramming, DSLs, code generation, tooling and static
analysis. It also permanently changes how you read any codebase, because you
stop seeing text and start seeing structure.

Core text: **Crafting Interpreters** (Nystrom), free online. Then **SICP** much
later. See `parsing-from-first-principles.md` for the starting concepts.

### 4. Distribution and failure

Consistency, partial failure, idempotency, queues, retries, backpressure,
observability, what actually happens when one of three machines stops answering.

Why it matters: eventually. Not yet. At nine customers this is theory. It
becomes urgent the moment there is a second service or a real queue.

Core text: DDIA again (second half), then **Release It!** (Nygard), then
papers.

### 5. Judgment

How to decide. Where complexity comes from, what abstraction costs, when to
build and when to buy, how to keep a codebase changeable for a decade.

Why it matters: this is the pillar that separates a senior engineer from a CTO,
and it is the one with the fewest good resources, because most of it comes from
having been wrong and remembered why.

Core text: **A Philosophy of Software Design** (Ousterhout), short and worth
rereading yearly. The paper **Out of the Tar Pit**. Own notes in
`programming-design-principles.md`.

---

## The sequencing

**The optimal order is the one that gets finished.** Curiosity is the scarce
resource here, not time. When something has genuinely caught interest, that is
the moment to spend on it, because motivation at the start of a hard book is
what carries you past chapter four. A theoretically better ordering studied
without appetite finishes at 15 percent and teaches nothing.

So: the order below is the default when nothing in particular is pulling. Follow
a live curiosity over it whenever one exists.

### Phase 0, now, about 3 months

**Postgres and SQL, to real depth.**

Not an ORM abstraction over it. `EXPLAIN ANALYZE` until query plans are readable
at a glance. Index types and when each one applies. What a sequential scan
costing 400ms actually means. Lock types. `pg_stat_statements`. Connection
pooling and why it exists.

Why first: fastest payback of anything on this list. It is the layer directly
under Rails, it is where production problems live, and it makes Phase 1 concrete
instead of abstract. Also cheap, since the material is documentation and a
production database that already exists.

Artifact: extend `psql-cheatsheet.md` into a real note on reading query plans.

### Phase 1, 6 to 9 months

**Designing Data-Intensive Applications.**

Read it slowly, one chapter a week, taking notes. It is not a book to skim. The
first half reframes everything already known about databases; the second half is
the distributed material and can be read faster on a first pass, since it is not
yet load-bearing.

Artifact: a note per part. Writing the note is how the reading sticks.

### Phase 2, 6 months

**The machine. OSTEP.**

Processes, scheduling, virtual memory, concurrency, persistence. Do the
projects, or at least the concurrency ones. This is where the mental model of
`systems-from-first-principles.md` gets filled in from underneath.

Pair it with reading real syscall traces. `strace` on a Rails boot is an
education.

### Phase 3, 6 months

**Languages and parsing. Crafting Interpreters, front half.**

`parsing-from-first-principles.md` is the prerequisite reading and is already
done. It covers tokenizing, lexer versus parser, what an AST is and why, the
four-stage pipeline, and a working Ruby lexer, recursive descent parser and
semantic analyzer. Start from there, not from zero.

**The primary text, and it is not close.**

**Crafting Interpreters**, Robert Nystrom. Free at craftinginterpreters.com,
paid print and ebook available. Builds two complete language implementations:
first a tree-walking interpreter, then a bytecode VM. Every line of code is in
the book and explained. The prose is the best in the field.

Type it, do not read it. The tree-walking interpreter in the first half is the
whole idea. The bytecode VM in the second half is optional on a first pass and
is better after OSTEP anyway, since it leans on the memory model.

Finishing the front half alone puts you past most working developers on this
topic.

**Shorter alternative, if 600 pages kills momentum.**

**Writing an Interpreter in Go**, Thorsten Ball. Half the length, test-driven,
brisker. Sequel is *Writing a Compiler in Go*. Less depth than Nystrom, faster
to finish. A finished short book beats an abandoned long one.

**Ruby-specific, and the reason this phase pays rent.**

**Ruby Under a Microscope**, Pat Shaughnessy. How Ruby itself tokenizes, parses
and compiles to YARV bytecode. Converts the theory into "so that is what happens
when I hit enter." Directly useful given Ruby is the daily language.

Then poke at real parsers from `irb`:

```ruby
require "ripper"
pp Ripper.sexp("total = price * 2 + 1")
```

Ruby hands over its own AST. Compare it to the hand-built one in
`parsing-from-first-principles.md`. Then read **Prism**, Ruby's current parser:
readable C, well documented, actively maintained. This is the "read real source"
practice applied to the pillar.

**Deeper, later.**

**SICP**, free online. The metacircular evaluator chapter is this idea in its
purest form. Heavy, Scheme, months of work. Worth it eventually, wrong as an
entry point. Listed again in Phase 4.

**Nand2Tetris**, free course plus *The Elements of Computing Systems*. Logic
gates to CPU to assembler to VM to compiler to OS. Widens the axis: you learn
what the compiler is compiling *to*. Twelve projects, genuinely finishable. Good
either here or in Phase 4 depending on whether the gap below the interpreter
still feels like magic.

Past interpretation, when the appetite is there: SSA form, optimization passes,
register allocation, codegen. Also type theory, if this pillar is the one that
catches.

**Skip.** The Dragon Book. Reference, not teacher. See the skip list below.

Artifact: a working toy language. Then, for real leverage, a small tool built on
Ruby's own AST. A custom linter rule, a codemod, or a static check specific to
the studio's codebase. That is the point where this pillar stops being theory
and starts paying for itself.

### Phase 4 onward, years 3 and beyond

At this point the foundations are in place and the ordering stops mattering.
Pick by what the business needs and what is interesting:

- Distributed systems properly. Papers: Raft, Dynamo, End-to-End Arguments.
- SICP, for the metacircular evaluator and the pure form of the abstraction idea.
- CSAPP, for linking, caches and the memory hierarchy in depth.
- Nand2Tetris, if the gap between logic gates and OSTEP still feels like magic.
- Type theory, if the language pillar caught.
- Compilers past interpretation: SSA, optimization passes, codegen.

---

## The method

The sequencing matters less than this section.

**Build first, read second.** Every topic gets an artifact. Read a chapter on
B-trees, then implement one badly. The implementation is where the
understanding happens; the reading only sets it up. A topic with no artifact was
entertainment.

**Build a toy version of the tools you use daily.** A web server. A job queue. A
key-value store with a write-ahead log. A tiny Git. A container runtime with
namespaces and cgroups. Each one takes a weekend or two and permanently removes
the magic from something used every day. This is the single highest-leverage
practice on this page.

**Write the note.** This directory is already the evidence that this works.
Explaining a thing in writing is the only reliable test of whether it is
understood, because prose cannot hide a gap the way a working program can.
Every phase above names an artifact for this reason.

**Read real source, not just books.** Rails, Prism, Postgres, Redis. Pick one
subsystem and follow it end to end. Books teach the concept; source teaches what
the concept costs when someone has to ship it.

**Predict before measuring.** Before running the benchmark, write down the
expected number. Before reading the query plan, guess it. Calibration is the
actual skill, and it only develops when the guess is committed to before the
answer appears.

**One thing at a time.** Two books in parallel is zero books finished. Depth is
the entire point; breadth is what four years of framework work already provided.

---

## What to skip

**Leetcode grinding.** Signals interview readiness, not engineering ability.
There is no plan here that involves interviewing. Algorithm *intuition* matters
and comes free from DDIA and OSTEP; memorized puzzle solutions do not.

**Framework hopping.** The next hot framework teaches nothing that Rails has not
already taught, because it sits at the same layer. Learning a genuinely
different *paradigm* (a strict type system, a different concurrency model, Rust's
ownership) is worth it. Learning a different way to write a controller is not.

**Survey courses and tutorial completion.** Breadth-first video courses produce a
feeling of learning with no retention. Completion is not the metric.

**The Dragon Book, for now.** It is a reference, not a teacher. People buy it,
read 40 pages, and conclude compilers are inaccessible.

**Anything read without building.** Stated three times deliberately.

---

## The CTO layer

Separate from the pillars, and does not come from books. Worth naming so it gets
deliberate attention rather than being absorbed by accident.

**Cost at a three-year horizon.** Every architecture choice has a carrying cost
that only shows up later. The skill is pricing that cost at decision time, and
it develops by writing decisions down with their predicted consequences and
rereading them two years later. `studio/decisions/` is the right shape for this
already; keep it and add the technical ones.

**Build versus buy.** The default answer for a small studio is buy, and the
skill is recognising the narrow set of cases where the default is wrong: when
the thing is the product, when the vendor's failure mode is unacceptable, when
the integration cost exceeds the build cost.

**Knowing what you do not know.** The most expensive CTO failure is confident
wrongness in a domain adjacent to a strength. Foundations reduce this because
they widen the set of things you can reason about, but the meta-skill is
noticing the boundary.

**Being the person who can debug anything.** In a small studio this is not
delegable and is the highest-value thing the technical founder can be. It is
also the direct output of pillars 1 and 2. `debugging-hanging-systems.md` is the
practical companion.

---

## Measuring it

Not by books finished. By capability, checked yearly.

- Can an unfamiliar production problem be reasoned about without a search engine?
- Can a query plan be read and predicted before running it?
- Can a paper be read and the trade-off it makes be stated in one sentence?
- Can a new technology be evaluated in an afternoon and the evaluation hold up?
- Has a toy version of something used daily been built this year?
- Is there a note in this directory explaining a thing that was opaque a year
  ago?
- Given an ambiguous problem, is there a first move within five minutes?

If all six are yes after a year, the plan is working regardless of how much of
the reading list is done.

---

## The cadence

**Daily, one hour, five days a week.** Morning, before the business has claimed
attention. Reading or building, not both in the same hour.

**Weekly, one artifact.** A note, a benchmark, a commit to the toy project.
Small. The point is the streak, not the size.

**Monthly, review.** What was learned, what is next, does the current phase still
make sense given what the business needs.

**Yearly, the six questions above.** And pick the next phase deliberately rather
than by drift.

Ten years of that is a different engineer. Six months of it is nothing, which is
the part that has to be accepted up front, and is also why most people do not
do it.
