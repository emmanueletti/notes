# Fundamental Design Principles for Programmers

A curated list of the principles that actually pay rent in day-to-day code,
with the trade-offs that make them more than slogans. Skip the academic
versions; this is the working set.

The principles are grouped by *when you reach for them*, not alphabetically.

---

## When writing new code

### KISS (Keep It Simple, Stupid)

Default to the simplest thing that could work. Cleverness has a tax: future
you and everyone else who reads it. Optimize for the reader, not the writer.

A useful test: if you cannot explain a function in one sentence, it is
probably doing too much.

### YAGNI (You Aren't Gonna Need It)

Do not build for hypothetical future requirements. Most of them never
materialize, and the ones that do almost never look like you predicted. Every
unused abstraction is a tax on every reader who has to figure out whether it
is load-bearing.

This is the principle most often violated by experienced programmers, because
they have seen the future before and "know" what is coming.

### Naming is the highest-leverage skill

Bad names cost more than bad code. A well-named identifier eliminates the
need for half your comments. A misleading name actively poisons every reader.

Time spent renaming is rarely wasted. If you cannot find a good name for
something, that is often a sign the thing itself is wrong (wrong scope, wrong
responsibility, wrong abstraction).

Comments should explain *why*, never *what*. The code says what.

### Make it work, then make it right, then make it fast

In that order. Premature correctness pursuit (over-abstracting before you
understand the shape) is as bad as premature optimization. Get a working
first version, then refactor with knowledge you only have *because* it
works, then profile and optimize the parts that actually matter.

---

## When refactoring or removing duplication

### DRY (Don't Repeat Yourself), with the Rule of Three

DRY is widely misunderstood. The original meaning was about *knowledge*
duplication, not text duplication. Two functions that look similar may
encode entirely different ideas; merging them couples them forever.

The Rule of Three is the practical correction: do not abstract until you
have three concrete instances. Two examples are not enough data to know what
the abstraction should look like. Three give you a real signal.

A wrong abstraction is worse than duplication. Duplication is local; a wrong
abstraction is everywhere.

### Single Responsibility Principle

A module should have one reason to change. Note carefully: "one reason to
change", not "one thing to do." A function that validates, normalizes, and
saves a record can have a single responsibility (handling input for X) if
all three change together.

The signal you have violated this: when a small change in one area requires
edits scattered across the file.

### Separation of Concerns

A close cousin of SRP, applied at higher levels. Business logic, presentation,
and persistence should live in separate places. The boundaries between them
are where bugs hide and where flexibility comes from.

In Rails this is the M-V-C decomposition; in functional code it is often
"pure logic in the middle, side effects at the edges."

---

## When designing modules and APIs

### High cohesion, low coupling (the meta-principle)

Many other principles are special cases of this one.

- **High cohesion**: things that change together live together.
- **Low coupling**: things that change for different reasons should not
  depend on each other.

Most "this code feels bad" intuitions resolve to one of these.

### Composition over inheritance

Inheritance creates the tightest possible coupling: the child depends on the
*implementation* of the parent, not just its interface. Three levels deep and
nobody knows what state any object is in.

Composition (passing collaborators in) keeps coupling explicit and visible.
Reach for inheritance only when there is a genuine *is-a* relationship and the
hierarchy is shallow and stable. In Ruby, modules and `include` cover most of
the cases people misuse inheritance for.

### Open/Closed Principle

Code should be open for extension but closed for modification. Adding
behavior should mean writing new code, not editing existing code.

Practical implementations: plugin systems, drop-in directories (see
`drop-in-directory-pattern.md`), strategy pattern, dependency injection. The
goal is not "never edit existing code" but rather "the natural way to add
behavior X is to write a new file, not modify an old one."

### Dependency Inversion

Depend on abstractions, not concrete implementations. The high-level policy
of your code should not be coupled to low-level details (database driver,
HTTP library, file format).

In practice this means: pass dependencies in (constructor, function arg)
instead of reaching out to global state. It makes testing trivial and
swapping implementations possible.

The workbench `Sms.adapter` pattern (per memory) is a textbook example: the
business code talks to an interface, the concrete provider is injected.

### Information Hiding (Parnas)

The most underrated principle in the list. Hide what is *likely to change*;
expose what is *stable*.

A module's interface should reveal as little of its internals as possible.
This is why getter/setter sprawl in OOP is bad: it leaks internals as
"interface" and welds callers to implementation.

Ask of every public method: "if I rewrote the internals tomorrow, would this
have to change?" If yes, it is leaking too much.

### Deep modules over shallow modules (Ousterhout)

A deep module has a small interface and large functionality behind it. A
shallow module has a large interface relative to its functionality, which
adds cognitive overhead without paying for itself.

Many "Clean Code" style refactorings produce shallow modules: lots of tiny
functions that just call each other. This often makes code *harder* to read,
not easier, because you constantly jump around to follow the logic.

---

## When integrating with the world

### Boundaries: validate at edges, trust within

Validation, parsing, sanitization belong at the boundary where untrusted
input enters your system. Inside, trust the types and invariants.

This is the cure for defensive-programming sprawl, where every function
re-validates its inputs because nobody trusts anyone. Push validation to the
boundary, give the inside clean data, and the inside becomes much simpler.

In Rails: strong params and model validations at the edge; controllers and
service objects in the middle can assume the data is well-formed.

### Fail fast, fail loud

When something is wrong, surface it immediately and clearly. Silent failures
(swallowed exceptions, defaulted-to-zero values, "best effort" retries that
mask broken systems) are how production incidents become hours of debugging.

A loud failure at 9am is much cheaper than a quiet failure that corrupts
data for a week.

### Don't catch what you can't handle

`rescue` blocks should exist when you have something specific to do about
the error. `rescue => e; log; retry` patterns hide real problems. Let
exceptions bubble to the place that has enough context to act on them.

---

## When making it run forever

### Pure functions where possible

A pure function (no side effects, same input means same output) is the
easiest thing in the world to test, reason about, and parallelize. Push
side effects (IO, mutation, time, randomness) to the edges; keep the core
of the program made of pure transformations.

You will not always achieve this; you should always aim for it.

### Idempotence

An operation is idempotent if running it twice has the same effect as
running it once. Idempotent operations are safe to retry, safe to run from
multiple workers, safe to recover from partial failures.

Whenever possible, design APIs and jobs to be idempotent. The cost is small;
the operational benefit is enormous.

### Principle of Least Astonishment

Code should do what its name and shape suggest. A function called `validate_email`
should not also send a welcome email. A method called `find_user` should not
mutate the user. Surprise is the enemy of trust.

---

## Mindset and process

### Premature optimization is the root of all evil (Knuth, in context)

The full quote matters: "We should forget about small efficiencies, say
about 97% of the time. Yet we should not pass up our opportunities in that
critical 3%."

The principle is not "never optimize." It is "do not optimize before you
measure." Profile first; optimize the bottleneck; ignore the rest.

### Worse is better (Richard Gabriel)

Simpler implementations that solve 80% of the problem often beat complete
implementations. The simple thing ships, gets used, gets feedback, and
evolves. The complete thing never ships.

This is why minor languages with worse semantics (C, JavaScript, PHP)
beat technically superior contemporaries. Lesson: ship the worse-is-better
version, then iterate based on real use.

### Code is read far more than it is written

Optimize accordingly. Every clever line you write is paid for in dozens of
reading-passes by people (including future you) trying to understand it.

### Three similar lines is better than a premature abstraction

Restated: the cost of duplication is linear (some extra typing, some risk of
divergence). The cost of a wrong abstraction is super-linear (every caller
warps to fit it, every change ripples). Wait for the third instance before
you abstract.

### Boring is a feature

Use boring, well-understood tools where you can. Save your innovation budget
for the parts of your project that actually need novelty (usually the
domain). Pick PostgreSQL, not the new shiny database. Pick the framework
your team knows, not the framework with the prettiest documentation site.

---

## What to read next

A short, opinionated list. In rough priority order.

1. ***A Philosophy of Software Design*** by John Ousterhout. Short, dense,
   the best treatment of complexity, deep modules, and information hiding
   you will read. Counterweight to Clean Code dogma.

2. ***The Pragmatic Programmer*** by Andy Hunt and Dave Thomas. Broad,
   timeless, full of vocabulary you will use forever (DRY, orthogonality,
   tracer bullets, the broken window theory).

3. ***Refactoring*** by Martin Fowler. Practical and applies daily. Read it
   alongside whatever codebase you are currently working in.

4. ***The Art of Unix Programming*** by Eric S. Raymond. Free online. The
   philosophical foundation of the dispatcher pattern, composability, and
   "do one thing well." Ages well.

5. ***Designing Data-Intensive Applications*** by Martin Kleppmann. When
   your systems get big enough to need this, you will be glad you read it
   in advance.

6. ***Domain-Driven Design Distilled*** by Vaughn Vernon. The original Evans
   book is long; this is the 80/20 version. Worth it once your domain is
   complex enough that the model and the code start drifting apart.

7. ***Clean Code*** by Robert Martin. Read with a critical eye. The chapters
   on naming and functions are foundational vocabulary; the rules on
   function length and SRP are often taken too far. Use it for the
   vocabulary, not the dogma.

---

## Anti-list: principles to ignore or apply lightly

Worth knowing exist, worth being suspicious of:

- **The "Law" of Demeter** ("don't talk to strangers"). Sometimes useful,
  often produces wrapper sprawl. Use intuition, not rules.
- **"Functions should be no longer than X lines."** A useful smell, not a
  rule. Long functions that read top-to-bottom are often clearer than the
  same logic shattered into ten tiny ones.
- **Strict adherence to all of SOLID.** L (Liskov) and I (Interface
  Segregation) matter less day-to-day than the others. Do not over-index on
  the acronym.
- **Patterns for their own sake.** The Gang of Four catalog is a vocabulary,
  not a checklist. Most patterns are workarounds for missing language
  features. In Ruby and modern languages, half of them are unnecessary.
