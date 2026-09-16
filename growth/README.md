# Growth Paths

Written 2026-09-10. Candidate paths for the long arc, articulated separately so
they can be compared rather than blended. Pick one as the spine. Blending them
produces the worst of each, because every one of them works through sustained
depth and blending is how depth gets diluted.

- `path-systems-plus-theory.md` (D) **[recommended]**
- `path-academic-curriculum.md` (B)
- `path-product-leverage.md` (C)

Path A, the systems builder, was folded into D on 2026-09-10. D was always A
plus a narrow theory strand, and two notes for one path was overhead. D is
self-contained now, and running it without the minor is exactly what A was.

- `canon.md`, shared. The practitioner-legendary books, not just the textbooks.

Strategy, method and scheduling live in `../engineering-growth-plan.md`. That
document survives whichever path is chosen. Pillar zero on solving ambiguous
problems, the build-first method, the artifact rule and the honest hours
accounting are path-independent.

---

## The comparison

|                             | D: Systems builder plus theory minor **[recommended]** | B: Full academic                | C: Product leverage     |
| --------------------------- | ------------------------------------------------------ | ------------------------------- | ----------------------- |
| **Hours/year**              | 300-350                                                | 250-400                         | 150                     |
| **Years to depth**          | 5                                                      | 5-6                             | 3, then plateau         |
| **Writes Redis**            | yes                                                    | yes                             | no                      |
| **Implements Raft**         | yes, capstone                                          | yes                             | no                      |
| **Could invent a protocol** | admitted to the room                                   | plausibly                       | no                      |
| **Reads papers fluently**   | yes                                                    | yes                             | no                      |
| **Workbench payoff**        | high                                                   | medium                          | highest short term      |
| **Library risk**            | medium                                                 | highest                         | medium                  |
| **Business fit**            | good                                                   | poor                            | excellent               |
| **Main failure mode**       | minor eats the major                                   | accumulating unusable knowledge | quiet plateau at year 3 |

---

## What actually separates them

**D has an internal dial.** The spine is the six curriculum areas; the minor is
roughly 20 percent on top for proof, papers and formal specification. The minor
is worth it if the pull toward correctness arguments is genuine, and worthless
if it is aspirational, because unused theory decays faster than anything else on
this list. Six months in, if it has not taken, drop it and run the spine alone.
That is a legitimate outcome, and it is what the old Path A was.

**B is not a bigger D.** It is a different activity. Its centre of gravity is
reading and proving where D's is building. It is the only path where the Raft
ambition is literal rather than symbolic, and it is the only one with a serious
risk of producing knowledge you cannot deploy.

**C is a subset of D**, chosen by business payback rather than by transfer. It
is the correct answer if the studio is fragile and the next two years are about
survival. It is the wrong answer the moment that stops being true, and the
ceiling arrives quietly.

---

## The thing they all share

Every one of them works only through the method, not the content. Same book, two
outcomes: read it and you have a library, build against it and you have a
workbench.

The non-negotiables, whichever path wins:

- An artifact per topic. A topic with no artifact was entertainment.
- Build toy versions of tools you use daily. Highest workbench density
  available.
- Write the note. Prose cannot hide a gap the way working code can.
- Predict before measuring. Calibration only develops when the guess is
  committed before the answer appears.
- One thing at a time. Two books in parallel is zero books finished.
- Read one real implementation after each build.

---

## The Workbench asset

Worth stating once here, because it applies to all of them and was wrong in the
first draft of the growth plan.

The business is not purely a competitor for study hours. Nine customers in
production generate **real failures**, and real failures are the one input no
curriculum can manufacture. Failure shapes are the densest form of engineering
memory, and they only come from having been on the hook.

Every incident gets a written post-mortem including what you predicted versus
what it actually was. That habit is worth more than a year of reading, and it is
free, and it is already happening whether or not it gets written down.

---

## Recommendation

**D**, with the minor dropped if it has not taken within six months.

Reasoning: the spine produces the described capability, since the transferable
pattern library is a byproduct of building rather than reading, and the spine is
built entirely from artifacts. The minor costs little, is explicitly
subordinate, and buys the one thing the spine cannot: the ability to read the
literature and reason formally, which is what keeps the ceiling open past year
five.

B is the honest answer only if the pull toward theory is real. Test that cheaply
before committing, since it costs twice as much and carries the highest library
risk. The test: read _Out of the Tar Pit_ and the Raft paper this month using
Keshav's three-pass method. If that was energising rather than dutiful, B is
live. If it was a chore, D is the answer and the chore was the evidence.


https://chatgpt.com/share/6aa3101a-c528-83ea-8a43-3d1609333c1d
