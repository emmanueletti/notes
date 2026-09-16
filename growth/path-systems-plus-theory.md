# Path D: Systems Builder plus a Theory Minor

Written 2026-09-10. Absorbed the former Path A (systems builder) on 2026-09-10,
since D was always A plus a narrow addition and two notes for one path was
overhead. Self-contained now. See `README.md` for the comparison against B and
C, and `canon.md` for the shared resource list.

**Thesis:** go genuinely deep in the highest-transfer areas with build-your-own-X
as the spine rather than a tip, and run one deliberately small theory strand
alongside it at low intensity. Reading serves the build, never the reverse. The
minor keeps the door to protocol-level work open without becoming the main
course.

---

## Who this makes you

Someone who can enter an unfamiliar systems codebase and have traction inside a
day. Who can be handed a performance problem in a language they do not write and
form a real hypothesis. Who can write Redis. Who can implement Raft, specify it
formally, find a bug in their own variation with a model checker, and hold a
defensible opinion about what should replace it.

That last clause is the honest version of the original ambition. Not "invented a
consensus protocol," which is a research outcome depending on years of contact
with one specific problem, but "is admitted to the room where that happens."

The workbench, explicitly. Optimized for the move you make when you do not know,
practised several dozen times.

---

## The cost

Roughly 300 to 350 hours a year. One hour most days, one weekend a month for
builds, and two hours a week for the minor taken out of the reading hour rather
than the build weekends. Five years to real depth, with useful capability
arriving inside the first year.

The weekend build blocks matter more than the daily hour. Reading is
interruptible, building is not.

---

## The major: the curriculum

Ordered. Each area ends in working code, and the artifact is the deliverable,
not the reading.

### 1. The machine, about 6 months

**OSTEP** (*Operating Systems: Three Easy Pieces*), free online. Processes,
scheduling, virtual memory, concurrency, persistence.

Artifacts:
- A shell. Fork, exec, pipes, redirection, job control. One weekend, and it
  removes the mystery from every process question you will ever have.
- A memory allocator. `malloc` and `free` over `mmap`. Teaches the heap by
  making you build one.
- A thread pool.
- `strace` a Rails boot and account for every class of syscall in the output.
- Read **xv6** end to end, about 6,000 lines. Then reread the OSTEP chapters on
  what you just read. This is the artifact that converts "operating system" from
  a category into a thing a person wrote.

### 2. Data, about 9 months

**Designing Data-Intensive Applications** (Kleppmann), first half. Then
**Database Internals** (Petrov). Postgres documentation throughout, which is
unusually good.

Artifacts:
- A key-value store with a write-ahead log. Then crash it mid-write and make
  recovery correct.
- Add a real index. B-tree or LSM tree, pick one and implement it badly.
- `EXPLAIN ANALYZE` on the Workbench production database until plans read at a
  glance. Extend `psql-cheatsheet.md` into a note on reading them.

### 3. Networking, about 6 months

**Beej's Guide to Network Programming**, free, start here. Then **Computer
Networking: A Top-Down Approach** (Kurose and Ross) for the layered model.

Artifacts:
- An HTTP/1.1 server on raw sockets. Then add keep-alive and chunked encoding,
  which is where it stops being a toy.
- A toy Redis speaking real RESP protocol, so `redis-cli` connects to it. This
  is the artifact that makes the Redis ambition concrete rather than symbolic.
- Read a packet capture of your own app and explain the handshake.

### 4. Concurrency, about 4 months

OSTEP's concurrency section again, deeper. **The Little Book of Semaphores**
(Downey), free. Then deliberate exposure to a different model: Go's channels or
Rust's ownership, purely to break the Ruby-shaped assumptions.

Artifacts:
- A job queue with at-least-once delivery and idempotent consumers.
- A connection pool with timeouts.
- Reproduce a race condition on purpose, then fix it, then prove it is fixed.

### 5. Languages, about 6 months

**Crafting Interpreters** (Nystrom), front half, typed not read.
`parsing-from-first-principles.md` is the prerequisite and is already written.

Artifacts:
- A working toy language.
- Then a real tool on Ruby's own AST via Prism: a custom linter rule or a codemod
  for the studio codebase. This is where the pillar starts paying rent.

### 6. Capstone, 6 to 9 months

**MIT 6.824** (now 6.5840), Robert Morris. Free lectures, public labs. Read
DDIA's second half alongside it.

Labs: MapReduce, then **Raft**, then a fault-tolerant key-value store, then
sharded. The Raft lab is where the original ambition gets satisfied honestly.
Implementing it is the prerequisite for ever having an opinion about improving
it.

Add **Release It!** (Nygard) here for production failure modes.

---

## Canon picks for the major

From `canon.md`, the ones that matter most here.

**The Linux Programming Interface** (Kerrisk) as the permanent reference you open
weekly for the rest of your career. **Beej's Guide** for sockets, free and
legendary. **Programming Pearls** (Bentley) read early and yearly, because it is
the closest thing to a book about the workbench itself. **Wizard Zines** (Julia
Evans) throughout, since no author models "brain as workbench" better. **Use The
Index, Luke** (free) as the fastest possible Postgres on-ramp. **Jepsen** for
failure modes, which reads like detective fiction. **Systems Performance**
(Gregg) once you start asking why things are slow.

For the builds: **Build Your Own X** as the index, **Codecrafters** when a build
has too high an activation cost, **Let's Build a Simple Database** (free) for the
storage engine, **Crafting Interpreters** and **Writing an Interpreter in Go**
for the language work.

---

## The minor

Three strands, run continuously rather than in phases. Roughly two hours a week
total. It is not a mathematics education. It is the four or five things from
mathematics and formal methods that actually gate systems work.

### 1. Proof and invariants, about 9 months

Not full discrete mathematics. The subset that transfers.

**How to Prove It**, Velleman, first third. Induction, contradiction,
quantifiers, how a proof is structured. Then selected chapters of **MIT 6.042**
(free): induction, graphs, and the probability sections. Skip counting and
number theory unless they catch.

The payoff is not the theorems. It is the habit of asking "what must be true
after every step, no matter what" and being able to answer precisely. That
question is the whole of concurrent and distributed correctness, and it is the
same question as the invariant move in `engineering-growth-plan.md`, pillar zero.

Artifact: for each system in the major, write down its invariants explicitly
before building it. Then find where you violated one.

### 2. Paper reading as a discipline, continuous forever

**How to Read a Paper**, Keshav. Free, three pages, the three-pass method. Read
it once and use it forever.

Then one paper a month, indefinitely. Start with the ones that have commentary
available so you get feedback on your reading:

- **Out of the Tar Pit**, Moseley and Marks
- **The End-to-End Argument in System Design**, Saltzer, Reed, Clark
- **A Note on Distributed Computing**, Waldo et al
- **FLP impossibility**, Fischer, Lynch, Paterson
- **Paxos Made Simple**, Lamport
- **In Search of an Understandable Consensus Algorithm**, Ongaro and Ousterhout
- **Dynamo**, DeCandia et al
- **The Google File System** and **MapReduce**
- **Readings in Database Systems** (the Red Book, free) for curated commentary

**Papers We Love** has recordings of people walking through many of these, which
is the cheapest way to calibrate whether you read one correctly.

Artifact: a one-paragraph note per paper, stating the trade-off it makes. If you
cannot state the trade-off in one sentence, you have not finished reading it.

### 3. Formal specification, deferred until after 6.824

**Do not start this early.** TLA+ before you have implemented a distributed
system is the purest library-shaped activity on this entire list. It only makes
sense once you have something you want to specify and a memory of a bug that a
model checker would have caught.

After the Raft lab: **Lamport's TLA+ Video Course** (free), then **Specifying
Systems** (free PDF) as reference. **Hillel Wayne's** writing is the practical
on-ramp and is aimed at working engineers rather than academics.

Artifact: specify something small you already built. The KV store's recovery
protocol, or the job queue's delivery guarantee. Let the model checker find
something. It will.

---

## The rule that makes this work

**The minor never blocks the major.** If a month is tight, the minor is what gets
cut, every time, without negotiation. Two hours a week, taken from the reading
hour. If the minor has consumed a build weekend even once, it has already gone
wrong.

If the minor has not taken within six months, drop it and run the major alone.
That is a legitimate outcome, not a failure. Unused theory decays faster than
anything else on this list, and a spine with no minor still produces the
capability in the first two paragraphs of this note.

---

## What this skips, deliberately

Complexity theory, the algorithm menagerie, compilers past interpretation, SICP,
and the bulk of discrete mathematics beyond the induction and invariant subset in
the minor.

Each is defensible on its own terms. None of them is what stands between you and
the capability described at the top. Add any of them later if a real problem
demands it, which is also the only condition under which they will stick.

---

## Interaction with Workbench

Good, on balance. Areas 2 and 3 are directly load-bearing: the product is a
data-intensive networked application, and every hour on Postgres or on HTTP
semantics returns immediately.

Areas 1, 4 and 6 are investment rather than return. They pay off as debugging
speed, which is real but hard to attribute.

The minor has close to zero product payoff, with one real exception: the
invariants habit from strand 1 transfers directly to schema design and to
reasoning about background jobs, which is where correctness bugs in a Rails app
actually live.

The build weekends compete with product weekends. That is the honest cost and
there is no way around it. Twelve weekends a year.

---

## How you would know it is working

- An unfamiliar codebase yields a mental model in an afternoon, not a week.
- Production problems get a hypothesis before they get a search engine.
- You reach for `strace`, `perf` or a packet capture without it feeling exotic.
- You have stopped treating any layer of your stack as magic.
- Someone describes a system and you can guess its failure modes.
- You can read a systems paper and state its trade-off in a sentence.
- Before building a concurrent thing, you write down what must always be true,
  and the list is right.
- A model checker has found a bug in something you were confident about.
- The Raft paper reads as choices with alternatives, not as received truth.

---

## Failure modes

**Building without reading.** You reinvent 1985 without knowing the names for
what you built, plateau at "clever amateur," and cannot talk to anyone who came
through the literature.

Antidote: the canonical text runs alongside every build, and after finishing an
artifact you read one real implementation of the same thing. Build your KV store,
then read LevelDB. Build your Redis, then read antirez's C, which is famously
clean.

**Artifact inflation.** The toy grows into a project, the project wants users,
and six months vanish. Timebox every build. Bad and finished beats good and
ongoing.

**The minor eats the major.** For someone who enjoys reading, theory is more
comfortable than building and easier to justify because it feels more serious.
Six months in you have read eleven papers, shipped no artifacts, and the reading
has produced nothing usable. The rule above is the entire defence.

**Starting TLA+ too early**, covered in strand 3. The temptation is strong
because it is the most impressive-sounding item in this directory. Defer it. It
is worth very little without a system in hand and a remembered bug.
