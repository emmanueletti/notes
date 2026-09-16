# The Canon

Written 2026-09-10. Shared across all four paths in this directory. The
textbooks are in the path notes. This is the other list: the books practitioners
actually press into each other's hands, the ones that changed how a generation
thought, and the free things that outperform paid courses.

Marked **free** where it is free and legal.

A book earns a place here by being _load-bearing_ rather than comprehensive.
Most are shorter than the textbook covering the same ground and worth more.

---

## Problem solving and craft judgment

**Programming Pearls**, Jon Bentley. The closest thing to a book about the
workbench itself. Each column is a real problem, a wrong first answer, and the
reasoning that gets to the right one. Short. Read it early and again yearly. Of
everything on this page it maps most directly onto "I do not know how to break
this down."

**The Practice of Programming**, Kernighan and Pike. Taste, distilled.
Debugging, interfaces, performance, style, all in 250 pages by two people who
earned it.

**A Philosophy of Software Design**, Ousterhout. Modern, short, contrarian in
the right places. Deep modules, shallow interfaces, complexity as the enemy.
Reread yearly, it lands differently each time.

**How to Solve It**, Polya. The original heuristics.

**Are Your Lights On?**, Gause and Weinberg. Problem _definition_, not problem
solving. Odd, short, and the single most direct hit on ambiguity anxiety.

**The Art of Doing Science and Engineering**, Hamming. Especially "You and Your
Research." About choosing which problems deserve a life.

**The Mythical Man-Month** and **No Silver Bullet**, Brooks. Fifty years old and
still describing your week.

**Out of the Tar Pit**, Moseley and Marks. **free** paper. The best thing
written on where complexity actually comes from.

**Thinking Forth**, Leo Brodie. **free**. Ostensibly about a dead language,
actually about decomposition and factoring, and a cult classic for that reason.

---

## The machine and systems

**The Linux Programming Interface**, Michael Kerrisk. The monument. 1500 pages,
not read front to back, but it is the book you own for the rest of your career
and open weekly. If you buy one physical book from this whole directory, this.

**Advanced Programming in the UNIX Environment**, W. Richard Stevens. APUE. The
predecessor and still worth it for the prose. Stevens wrote the clearest systems
explanations anyone has managed.

**Operating Systems: Three Easy Pieces**, Arpaci-Dusseau. **free**. Genuinely
fun, which no other OS textbook is. Deserves its reputation.

**Systems Performance** and **BPF Performance Tools**, Brendan Gregg. The modern
canon for "why is this slow" at the systems layer. His USE method alone is worth
the book.

**Hacker's Delight**, Henry Warren. Bit manipulation as an art form. Cult
classic, mostly useless, occasionally decisive.

**The Art of UNIX Programming**, Raymond. **free**. Philosophy more than
technique. Dated in places, foundational in others.

### Running the systems

**How Linux Works**, Brian Ward. The tour: boot sequence, systemd, udev, `/proc`
and `/sys`, filesystems, how userspace comes up. Placement matters here. How
Linux Works answers "what are all these pieces," TLPI answers "how do I program
against them," OSTEP answers "why is it built this way." A week of evenings, and
the parts that will actually land are the ones previously worked around rather
than understood, usually systemd and the boot chain.

**Absolute FreeBSD**, Michael W. Lucas. The FreeBSD administration book, and
Lucas is one of the best technical writers working. Jails, ZFS, ports, pf, the
boot chain. The right book the moment you actually run the system.

**Absolute OpenBSD**, Lucas. Same shape for OpenBSD. The 2013 edition is dated on
operational specifics and still the best single book on the system. OpenBSD's own
man pages, which are the best documentation in computing, cover the drift.

Running all three is worth more than it looks. One project owning the kernel,
the userland and the documentation produces a coherence Linux structurally
cannot have, and seeing the same problems solved three ways breaks Linux-shaped
assumptions the same way Go or Rust breaks Ruby-shaped ones. The comparative
view is the real payoff, not any one system.

---

## Reading an operating system end to end

Distinct from running one, and the higher-value activity. The test for whether a
weekend went well: did you read source, or did you read configuration docs.

**xv6**, MIT. **free**, with a **free** accompanying book. About 6,000 lines of
C, RISC-V, a Unix-like teaching OS used in 6.1810. The correct first answer to "I
want to read an entire operating system." Small enough to hold in your head,
real enough to teach the actual thing. Do this before any BSD source.

**The Design and Implementation of the FreeBSD Operating System**, McKusick,
Neville-Neil, Watson. The systems text, where Absolute FreeBSD is the ops manual.
McKusick wrote large parts of BSD. This is the book that explains why FreeBSD is
shaped the way it is.

**Lions' Commentary on UNIX 6th Edition**, John Lions. The legendary one. Nine
thousand lines of V6 source with line-by-line commentary, samizdat-copied for
twenty years before it could legally be published. Historical rather than
practical, and the clearest demonstration anywhere that a whole operating system
can fit in one person's head.

**OpenBSD source**, **free**. Small, coherent, consistently styled, heavily
audited. The production kernel a person can actually read. After xv6, and pairs
naturally with running it.

---

## Networking

**Beej's Guide to Network Programming**, **free**. Legendary. Thousands of
engineers learned sockets here. Start with it, not with the textbook.

**UNIX Network Programming**, Stevens. The other monument. Volume 1 is the
sockets bible.

**High Performance Browser Networking**, Ilya Grigorik. **free**. The best
explanation of TCP, TLS and HTTP behavior as it actually affects a web app.
Directly load-bearing for Rails work.

---

## Data and databases

**Designing Data-Intensive Applications**, Kleppmann. Already a modern classic
and correctly so. If the whole plan collapsed to one book, this one.

**Use The Index, Luke**, Markus Winand. **free**. The best explanation of
database indexing that exists, in any format. An afternoon, and it changes how
you write every query afterward.

**The Art of PostgreSQL**, Dimitri Fontaine. Written for application developers
who under-use their database. Very aimed at exactly the Rails habit of treating
Postgres as a dumb store.

**Database Internals**, Alex Petrov. The storage engine and the distributed
half, readable.

**Let's Build a Simple Database**, cstack. **free**. Builds a sqlite clone in C,
incrementally, online. The build-first companion to the reading above.

**Readings in Database Systems** (the Red Book), Hellerstein and Stonebraker.
**free**. Curated papers with commentary explaining why each mattered.

---

## Distributed systems

**Distributed Systems for Fun and Profit**, Mikito Takada. **free**. Short,
excellent, the right first thing. Read before 6.824, not after.

**MIT 6.824 / 6.5840**, Robert Morris. **free** lectures and labs. The labs
implement MapReduce, Raft, and a sharded fault-tolerant KV store. The single
highest-value free thing in this entire directory.

**Jepsen**, Kyle Kingsbury (aphyr). **free**. The "Call Me Maybe" series breaks
real databases and shows what their consistency claims actually mean. Reads like
detective fiction and teaches failure modes better than any textbook.

**Marc Brooker's blog**, **free**. AWS principal engineer writing clearly about
timeouts, retries, backoff and queueing theory as they actually behave.

**In Search of an Understandable Consensus Algorithm**, Ongaro and Ousterhout.
**free**. The Raft paper. Then the thesis, where the design reasoning lives.

**Release It!**, Michael Nygard. Production failure patterns. Circuit breakers,
bulkheads, the cascading failure taxonomy. The book that names the things that
take your site down.

---

## Languages, compilers, interpreters

**Crafting Interpreters**, Robert Nystrom. **free** online. The best-written
technical book of the last decade, and not only in its field. Two complete
implementations, every line explained.

**Writing an Interpreter in Go** and **Writing a Compiler in Go**, Thorsten
Ball. Shorter, test-driven, brisk. The pair many people finish when Nystrom
stalls them. No prerequisites, high completion rate.

**Beautiful Racket**, Matthew Butterick. **free** online. DSL creation, written
by a typographer, and it looks and reads unlike any other programming book.
Changes how you think about building small languages for real problems.

**Structure and Interpretation of Computer Programs**. **free**. The
metacircular evaluator chapter is the idea in its purest form. Heavy. Later.

**The Elements of Computing Systems** / Nand2Tetris. **free** course. Logic
gates to an OS in twelve projects. Fills in whatever still feels like magic
below the interpreter.

---

## Ruby, since it is the daily language

**Practical Object-Oriented Design in Ruby**, Sandi Metz. The Rails world's own
classic and it earns it. Dependency direction, message-based design, when
inheritance is wrong.

**Ruby Under a Microscope**, Pat Shaughnessy. How Ruby lexes, parses and
compiles to YARV bytecode. Turns theory into "so that is what happens when I hit
enter."

**Metaprogramming Ruby**, Paolo Perrotta. What Rails is actually doing.

**Prism**, Ruby's current parser. **free** source. Readable C, well documented.
Read it after Crafting Interpreters.

---

## Debugging and operations

**Debugging**, David Agans. Nine rules. Short, practical, aimed at the case
where the system is lying to you. Pairs with `debugging-hanging-systems.md`.

**Wizard Zines**, Julia Evans. **free** and paid. Comics about strace, DNS,
containers, TCP, profiling. The most workbench-shaped material anywhere: no
theory you cannot use by Tuesday. If any single author models "brain as
workbench," it is her.

**Site Reliability Engineering**, Google. **free** online. Uneven, but the
chapters on error budgets, alerting and postmortems are the reference.

---

## Build your own X

The highest workbench-density activity available. These are the guided versions
when a from-scratch build has too high an activation cost.

**Build Your Own X**, GitHub curated list. **free**. Index of hundreds of "build
your own database / git / docker / regex engine" tutorials.

**Codecrafters**, paid. Guided build-your-own-Redis, Git, Docker, SQLite, in the
language of your choice, with tests. Expensive, and the momentum is real.

**CS Primer**, Oz Nova, paid. Video and project-first. Same author as
teachyourselfcs.com. Use tactically when an area stalls, not as the spine.

**Writing a Simple Operating System from Scratch**, Nick Blundell. **free** PDF.
Bootloader to kernel, short enough to finish.

---

## People worth reading continuously

Free, and higher signal per hour than most books.

- **Julia Evans**, jvns.ca. Debugging, systems, the art of not being
  intimidated.
- **Dan Luu**, danluu.com. Empirical, contrarian, often about what the industry
  believes without evidence.
- **Brendan Gregg**, brendangregg.com. Performance, at depth.
- **Kyle Kingsbury**, aphyr.com. Distributed correctness, and very funny.
- **antirez**, antirez.com. Redis's author on writing systems software.
- **Hillel Wayne**, hillelwayne.com. Formal methods for people who ship.

---

## If you only do five things

1. Programming Pearls, for the workbench itself.
2. DDIA, for the product you are actually building.
3. Crafting Interpreters, front half, typed.
4. Beej plus your own HTTP server on raw sockets.
5. 6.824 with the Raft lab.

That is maybe two years at an hour a day, and it is most of the distance.
