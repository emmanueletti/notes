# Path C: Product Leverage

Written 2026-09-10. One of four candidate paths. See `README.md` for the
comparison and `canon.md` for the shared resource list.

**Thesis:** learn only what is load-bearing on the business, in the order that
pays back soonest. Depth arrives as a side effect of solving real problems
rather than as a goal.

This is the original `engineering-growth-plan.md` ordering, isolated here so it
can be compared honestly against the others.

---

## Who this makes you

A strong technical founder. Someone who makes architecture calls that hold up
for three years, debugs production competently, evaluates a vendor properly, and
can calibrate a hiring bar one level above themselves.

Not someone who writes Redis. Not someone who reads a systems paper for
pleasure. The ceiling is "very good engineer with real systems literacy," which
is a genuinely valuable thing to be and is roughly the top decile of working
developers.

Worth naming plainly, since it is the reason this path is listed rather than
recommended: it is the one that does not produce the person described in the
original ambition.

---

## The cost

Roughly 150 hours a year, and a meaningful share of it hides inside work you
were going to do anyway. Lowest cost of the four by a wide margin, and the only
one that does not visibly compete with the FIRE timeline.

---

## The curriculum

### Phase 0, about 3 months. Postgres and SQL to real depth.

`EXPLAIN ANALYZE` until plans read at a glance. Index types and when each
applies. Lock types. `pg_stat_statements`. Connection pooling and why it exists.

**Use The Index, Luke** (free) is the fastest possible on-ramp, an afternoon
that changes every query you write afterward. Then **The Art of PostgreSQL**,
which is aimed precisely at application developers who under-use their database.

Artifact: extend `psql-cheatsheet.md` into a note on reading query plans.

### Phase 1, 6 to 9 months. DDIA.

**Designing Data-Intensive Applications**, one chapter a week with notes. The
first half reframes everything you know about databases. The second half is the
distributed material, which on this path can be read once, quickly, and shelved
until it becomes relevant.

Artifact: a note per part.

### Phase 2, 6 months. The machine.

**OSTEP** (free). Processes, scheduling, virtual memory, concurrency,
persistence. Pair with **Wizard Zines** for the practical layer and `strace` on
a Rails boot.

Skip the projects on this path. That is the compromise that makes it cheap, and
also the compromise that lowers the ceiling.

### Phase 3, 6 months. Languages.

**Crafting Interpreters**, front half, or **Writing an Interpreter in Go** if
the shorter book is more likely to be finished. `parsing-from-first-principles.md`
is the prerequisite and is already written.

Artifact: a linter rule or codemod on Ruby's AST via Prism. On this path the
justification is the tool, not the education.

### Phase 4 onward. Business-driven only.

No fixed curriculum. When the product hits a wall, study the wall. Queues,
caching, search, background processing, whatever arrives. **Release It!** when
reliability starts to matter. **6.824** only if the studio ever genuinely
distributes.

---

## What this skips

Networking beyond the practical, concurrency beyond what OSTEP covers in
passing, algorithms, mathematics, formal methods, compilers past interpretation,
and every build-your-own-X artifact except the one in Phase 3.

The artifacts are the real loss. This path is the most reading-heavy of the four
in proportion to building, which is precisely the library risk, accepted
deliberately in exchange for speed.

---

## Interaction with Workbench

Excellent, and that is the entire argument for it. Every phase returns inside a
quarter. Phase 0 probably pays for itself in a week of query work. There is no
month where the study and the business are pulling opposite directions.

---

## How you would know it is working

- Query plans read at a glance and slow endpoints get diagnosed, not guessed at.
- Schema decisions get made with the three-year consequence stated out loud.
- Production incidents resolve faster each quarter.
- You can evaluate a service or a gem properly instead of by vibes.
- Technical decisions in `studio/decisions/` hold up when reread.

---

## Failure mode of this path

**A quiet plateau, around year three.** Nothing forces you past the point where
the business stops caring. The business stops caring well before you become the
person in the original ambition, so the ceiling arrives without announcing
itself, and it arrives while everything feels fine.

The second failure mode is subtler: because every topic is justified by immediate
payback, you never build the habit of going deep into something with no visible
return. That habit is what makes obscure problem areas tractable later, and it is
not recoverable cheaply once ten years have gone by without it.

Choose this path if the studio is genuinely fragile and the next two years are
about survival. Revisit it the moment that stops being true.
