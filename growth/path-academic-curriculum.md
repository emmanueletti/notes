# Path B: The Full Academic Curriculum

Written 2026-09-10. One of four candidate paths. See `README.md` for the
comparison and `canon.md` for the shared resource list.

**Thesis:** cover all nine areas of a computer science education, no holes,
including the mathematical and formal layers. The only path on which protocol
invention is a literal rather than symbolic goal.

Follows teachyourselfcs.com, which is the best existing map for this and is
free.

---

## Who this makes you

Someone who can read any systems paper and evaluate it rather than just absorb
it. Who can state a correctness property precisely and defend it. Who could
plausibly contribute something original to distributed systems or language
design, given years of contact with a real problem in that domain.

Also: someone with no gaps. Every other path on this list has a shape you would
eventually notice. This one does not.

---

## The cost

Roughly 1,200 to 1,500 hours. At 250 hours a year that is five to six years. At
400 a year, three to four, but 400 hours a year competes seriously with running
a company and the FIRE timeline.

Highest cost of the four paths, by roughly double.

---

## The curriculum

The nine TYCS areas. Order is somewhat flexible; this is a reasonable one.

**1. Programming.** SICP, or *Composing Programs* as the gentler entry. The
metacircular evaluator is the payoff.

**2. Mathematics for CS.** MIT 6.042, *Mathematics for Computer Science*
(Lehman, Leighton, Meyer), free PDF. Induction, proof technique, graphs,
counting, probability. This is the area every practitioner skips and the one
that gates everything formal downstream.

**3. Computer Architecture.** CSAPP. Nand2Tetris first if the gap from logic
gates feels like magic.

**4. Algorithms and Data Structures.** *The Algorithm Design Manual* (Skiena),
which is the practitioner's one. Roughgarden's course for the analysis.

**5. Operating Systems.** OSTEP, with the projects.

**6. Networking.** Kurose and Ross, *Computer Networking: A Top-Down Approach*.
Beej's Guide for the socket-level practice.

**7. Databases.** Berkeley CS186 (Hellerstein). *Readings in Database Systems*
(the Red Book), free. *Architecture of a Database System*, free paper. DDIA
alongside.

**8. Languages and Compilers.** Crafting Interpreters, both halves.
Nand2Tetris part two.

**9. Distributed Systems.** DDIA second half, then MIT 6.824 with the labs.

### The invention layer, on top

This is what separates Path B from the rest, and it is the reason to choose it.

- **Paper reading as a discipline.** Keshav's *How to Read a Paper*, the
  three-pass method. Then one paper a month, forever.
- **The consensus canon.** FLP impossibility (Fischer, Lynch, Paterson).
  *Paxos Made Simple* (Lamport). *In Search of an Understandable Consensus
  Algorithm* (Ongaro and Ousterhout), then Ongaro's full thesis, which is where
  the design reasoning lives.
- **Formal specification.** Lamport's TLA+ video course, then *Specifying
  Systems*. Raft was specified in TLA+. This is the tool that converts a clever
  idea about a protocol into a claim you can defend.

---

## Canon picks for this path

The textbooks above are the spine. These are what keep it from becoming a
reading list, and several are better than the canonical text on the same
subject.

**Programming Pearls** and **The Practice of Programming** for craft.
**Distributed Systems for Fun and Profit** (free) before 6.824, never after.
**Jepsen** alongside the consensus papers, because it shows the theory failing in
production. **Beautiful Racket** (free) as the delightful counterweight to SICP.
**The Linux Programming Interface** as the systems reference. **Hillel Wayne**
as the practical on-ramp to formal methods, ahead of Lamport's own material.
**Papers We Love** recordings to calibrate whether you read a paper correctly.

## What this skips

Nothing, which is the point and also the problem.

---

## Interaction with Workbench

Poor, honestly. Areas 2 and 4 in particular have close to zero product payoff.
The formal methods layer has none at all unless the studio ends up building
something protocol-shaped.

This path treats the business as a funding source for the education rather than
as a beneficiary of it. That is a coherent choice, but it should be made with
open eyes, and it makes the five-year FIRE number harder.

---

## How you would know it is working

- You can read a paper's abstract and predict its contribution before the intro.
- You can state a safety property and a liveness property for a system you just
  designed.
- Given an algorithm, you can bound its complexity without looking it up.
- You can specify something small in TLA+ and have the model checker find a bug
  you did not see.
- The Raft paper reads as a set of design choices rather than as received truth.

---

## Failure mode of this path

**Library accumulation.** By a wide margin the highest risk of the four. Much of
this curriculum never touches a keyboard, reading feels like progress, and you
can finish with a great deal of knowledge you cannot deploy. The person who has
read CSAPP and the person who has written a cache simulator are not the same
person, and only one of them can use it.

Antidote, non-negotiable: an artifact per area, no exceptions, including the
mathematical ones. For 6.042 that means proofs written out and checked, not
chapters read.

Second failure mode: **the theory becomes the identity.** It is more comfortable
to be someone who studies consensus than someone who ships. Watch for the point
where the curriculum has become a way to avoid the harder, vaguer work of the
business.
