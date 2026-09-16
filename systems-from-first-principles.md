# How Your Computer Runs a Program: a First-Principles Guide

A companion to `debugging-hanging-systems.md`. That one is "what to type when
something breaks." This one is "what is actually happening underneath," built up
from nothing, one layer at a time.

Read it in order the first time. Each layer assumes the one before it. Even the
layers you think you know have a "you might not know" note, because the gap
between "I've heard of this" and "I can reason about it at 2am" is where bugs
hide.

The mental model the whole guide hangs on: **a request, or any work, travels
down through a stack of layers and back up.** When something breaks, the symptom
shows up at one layer but the cause usually lives a layer or two below. Learning
the layers is learning where to look.

```
   you / the browser
   └─ HTTP over the network            (Layer 6)
      └─ the web server (puma)         (Layer 7)
         └─ the framework (Rails/Rack) (Layer 8)
            └─ your code
               └─ a lock               (Layer 4)
                  └─ the DB driver     (Layer 9)
                     └─ the database
                        └─ a container (Layer 10)
   all running as ...
   processes & threads on the OS       (Layer 1)
   using memory                        (Layer 2)
   observable through /proc & logs      (Layers 3, 11)
   on top of the kernel + hardware
```

---

# Layer 1: What a running program actually is

**Core idea: a program on disk is a dead file; running it creates a *process*,
and the thing that actually executes is a *thread* inside it.**

When you type `bin/rails server`, here is the chain:

1. On disk, an executable is just a file in a known format (on Linux, ELF). It
   contains machine code and instructions for how to lay it out in memory.
2. The kernel creates a **process**: a private memory space, plus a list of
   resources (open files, network sockets), plus at least one **thread**.
3. A **thread** is the unit the CPU runs: a sequence of instructions with its own
   stack and registers. One process can have many threads, all sharing the same
   memory.

The useful distinction: **a process owns resources; a thread does the running.**
A process with three threads is one memory space with three independent
"cursors" executing code at once.

### The scheduler and time-slicing

You have a handful of CPU cores but hundreds of threads. The kernel's
**scheduler** rapidly rotates threads on and off the cores, a few milliseconds
each. That switch (save one thread's registers, load another's) is a **context
switch**. It happens so fast everything looks simultaneous. Real parallelism is
capped at the number of cores; the rest is fast taking-turns.

### Thread states: the single most useful concept for debugging hangs

At any instant, each thread is in one state:

| State | Name | Plain meaning |
|-------|------|---------------|
| `R` | running / runnable | on a core now, or ready and waiting for a turn |
| `S` | interruptible sleep | voluntarily waiting for something (a lock, a reply, a timer); ~0 CPU |
| `D` | uninterruptible sleep | stuck in the kernel, almost always disk or network-filesystem IO; cannot even be killed |
| `T` | stopped | paused (a debugger, or Ctrl-Z) |
| `Z` | zombie | finished, but its parent has not collected the exit code yet |

When something hangs, your very first question is decided here:
- **`R` and burning CPU** = it is *spinning* in a loop. Different bug, different
  tools (a profiler).
- **`S`/`D` and ~0 CPU** = it is *waiting*. Now go find what it waits on.

In the incident, every thread was `S`. Nothing was running. A process where all
threads are asleep and none are runnable is the textbook picture of a
**deadlock**: everyone is waiting, no one is working.

### How processes are born: fork and exec

Unix creates processes with two steps that are worth knowing because they explain
a lot of odd behavior:
- `fork()` duplicates the current process, giving a near-identical child (same
  memory, copied lazily).
- `exec()` replaces a process's program with a different one.

A shell runs a command by forking itself, then `exec`ing your program in the
child. Web servers like puma can `fork` worker processes to use multiple cores.

**You might not know:** after `fork`, the child shares the parent's memory pages
copy-on-write (they are only physically copied when one side writes). This makes
forking cheap, but it also means a library holding an open network handle or a
lock at fork time can misbehave in the child. (Your `bin/dev` sets
`PGGSSENCMODE=disable` specifically to dodge a Postgres-driver crash after fork.
That is this layer leaking into config.)

### Identifiers

- **PID**: process id. **TID**: thread id (the main thread's TID equals the PID).
  **PPID**: parent's PID.
- Explore: `ps -eLf` (the `L` shows threads), `ps -o pid,ppid,stat,comm`.

---

# Layer 2: Memory, the layer that caused your OOM

**Core idea: every process thinks it has a huge private memory all to itself.
That is a convincing illusion the kernel maintains, and understanding the
illusion explains swap, the page cache, and the OOM killer.**

### Virtual memory and pages

Programs never touch physical RAM addresses directly. Each process gets a
**virtual address space**: a flat range of addresses that is its own. Hardware
(the MMU) plus kernel **page tables** translate each virtual address to a real
physical location on the fly.

Memory is handled in fixed chunks called **pages**, almost always 4 KB. RAM is
divided into page-sized **frames**. The page table maps a process's virtual pages
to physical frames, and different processes can map the same frame (that is how
shared libraries are shared).

Why this matters: it lets the kernel lie productively. A virtual page can map to
RAM, or to disk (swap), or to nothing yet, and the process cannot tell the
difference until it touches it.

### RSS vs VSZ: the numbers that confused you in the OOM log

Two different "memory used" numbers, and they mean very different things:

- **VSZ (virtual size)**: how much address space the process has *reserved*. This
  can be enormous and mostly unused.
- **RSS (resident set size)**: how much is *actually in physical RAM right now*.
  This is the number that costs real memory.

In the OOM log, a `claude` process showed `total-vm: 73913840kB` (about 74 GB
VSZ) but `anon-rss: 7341308kB` (about 7 GB actually resident). It had *reserved*
74 GB of address space but was only *using* 7 GB of RAM. **The OOM killer cares
about RSS, not VSZ.** This is why "74 GB" did not mean the machine had 74 GB; it
is reserved address space, mostly empty.

Why reserve so much? **Overcommit and lazy allocation.** When a program asks for
memory, the kernel hands back virtual address space immediately but does not
attach physical frames until the program first *writes* to a page (which triggers
a **page fault** that the kernel services by finding a real frame). Programs
routinely reserve far more than they use, so the kernel lets the sum of all
reservations exceed RAM. That is "overcommit."

### Free memory is a lie (in a good way): the page cache

Spare RAM is not left idle. The kernel fills it with the **page cache**: copies of
files you have read, kept around in case you need them again. So `free -h` will
almost always show little "free" memory and a lot of "buff/cache." That cache is
**reclaimable**: the moment a program needs RAM, the kernel drops cache pages to
make room.

This is why the column to read in `free -h` is **available**, not **free**.
"Available" estimates how much you could allocate right now including reclaimable
cache. You saw 13 GB free but 21 GB available; the difference is cache standing
by.

### Swap, and your zram twist

When RAM genuinely runs short, the kernel moves rarely-used pages out to **swap**
to free frames for active work. Traditionally swap is a disk file or partition:
slow, but real extra capacity.

Your machine uses **zram** instead: a compressed block device that lives *in
RAM*, used as swap. Pages "swapped out" are compressed and kept in memory. You
saw `3.5 GB DATA` compress to `1.3 GB TOTAL`, roughly 2.7x. The trade: you spend
CPU to compress, and you get more effective capacity, but it does **not** give you
headroom outside RAM the way disk swap does. Heavy swapping to zram consumes RAM
rather than relieving it. That is part of why a memory storm on your box tips over
fast: the pressure valve is made of the same RAM that is under pressure.

When the working set exceeds RAM and the system swaps constantly, you get
**thrashing**: it spends all its time moving pages and almost none doing work.
Everything crawls. That is often the felt experience right before an OOM.

### The OOM killer: who dies and why

When the kernel cannot free enough to satisfy an allocation (even after
reclaiming cache and swapping), it triggers the **OOM (out of memory) killer**.
It scores every process for "badness" (roughly RSS + swap used, larger = more
likely to die), then kills the worst one to recover memory.

You can bias that score per process with **`oom_score_adj`**, a value from -1000
(never kill me) to +1000 (kill me first). The killed `claude` had
`oom_score_adj: 200`: Claude Code deliberately raises its own score so it gets
sacrificed before your browser, editor, or database. So in the log, **claude is
the victim, not the culprit.** The culprit is whatever filled RAM, which you find
by reading the kernel's process table dump, not by looking at who got killed.

### systemd-oomd: the proactive killer behind GNOME's notification

Modern Fedora also runs **systemd-oomd** in userspace. Instead of waiting for the
kernel to hit a hard wall, it watches **pressure** and **swap usage** per group
of processes and kills proactively. Defaults: if swap usage passes 90%, or if
memory "pressure" stays high (more than 60%) for 30 seconds, it kills a whole
group. Those are the kills GNOME surfaces as "X was terminated because the system
ran low on memory." Because it reacts to *pressure*, it can fire while plain
`free` still shows some bytes available.

What is "pressure"? The kernel exposes **PSI (Pressure Stall Information)** in
`/proc/pressure/{cpu,memory,io}`: the percentage of time tasks were stalled
waiting for that resource. `cat /proc/pressure/memory` is a great early-warning
gauge.

### cgroups: how the system groups processes for all this

systemd-oomd kills *groups*, not lone processes, because Linux organizes
processes into **cgroups** (control groups): a kernel feature for accounting and
limiting resources (memory, CPU, IO) per group. systemd places everything into a
tree of cgroups called slices and scopes. In your OOM log,
`task_memcg=/user.slice/user-1000.slice/.../app-ghostty-...scope` tells you the
killed process lived in a cgroup created for a Ghostty terminal window. That is
how the system knew which "app" to attribute and potentially kill.

**You might not know:** containers (Layer 10) are built from these same cgroups
plus namespaces. Memory limits on a container are just a cgroup memory limit. So
this layer and the Docker layer are the same primitives wearing different hats.

### Explore your memory

```sh
free -h                      # available is the number that matters
cat /proc/meminfo            # the full picture free summarizes
cat /proc/pressure/memory    # live memory pressure (PSI)
swapon --show; zramctl       # what your swap actually is
ps -eo pid,rss,vsz,comm --sort=-rss | head   # top RAM users (RSS vs VSZ)
```

---

# Layer 3: /proc, the kernel's window you can `cat`

**Core idea: Linux exposes the kernel's live internal state as a fake
filesystem, so reading process and system internals is just reading files.**

`/proc` is a **virtual filesystem**: the "files" are not on disk, they are
generated on read from kernel data structures. This is the unifying idea behind
half the tools in the playbook; many of them are just friendly readers of
`/proc`.

Per process (`/proc/<pid>/`), and per thread (`/proc/<pid>/task/<tid>/`):

| Path | What you learn |
|------|----------------|
| `task/*/stat` | per-thread state letter (field 3) and counters |
| `task/*/comm` | thread name |
| `task/*/wchan` | the kernel function the thread is asleep in (Layer 4) |
| `task/*/syscall` | the system call it is parked in |
| `task/*/stack` | kernel-side call stack (needs root) |
| `fd/` | every open file and socket (symlinks to the real targets) |
| `environ` | environment variables (NUL-separated) |
| `status`, `maps`, `smaps` | memory usage and the full memory map |
| `limits` | ulimits in effect |
| `cmdline` | the exact command and args it was launched with |

System-wide:

| Path | What you learn |
|------|----------------|
| `/proc/meminfo`, `/proc/loadavg` | memory, load average |
| `/proc/pressure/*` | PSI stall info |
| `/proc/cpuinfo` | cores and features |
| `/proc/sys/...` | kernel tunables, the things `sysctl` reads/writes |
| `/proc/<pid>/net/`, `/proc/net/` | sockets and network tables |

**You might not know:** `ps`, `top`, `free`, `ss`, and `lsof` are largely just
parsers over `/proc` (and its sibling `/sys`). When a tool is missing on a box,
you can usually get the same answer by reading `/proc` directly. That is exactly
what the playbook one-liner does to dump every thread's state and wchan.

```sh
ls /proc/self/fd            # the file descriptors of the process reading this
cat /proc/self/status       # who am I, memory, threads
```

---

# Layer 4: Concurrency and locks, where the deadlock lived

**Core idea: when multiple threads touch the same data, they need to take turns,
and the mechanism for taking turns can itself get stuck.**

### Why locks exist

Two threads incrementing the same counter can interleave and lose updates. That
is a **race condition**. To prevent it, code wraps the shared data in a **lock**.
The most common is a **mutex** (mutual exclusion): only one thread may hold it at
a time; others that try to acquire it **block** (go to sleep) until the holder
releases. The protected region is a **critical section**.

The deal you make with a mutex: correctness in exchange for the risk that, if the
holder never releases, everyone else waits forever.

### Futexes: what `wchan: futex` actually meant

A mutex is built on a kernel primitive called a **futex** ("fast userspace
mutex"). The clever part: when a lock is uncontended, acquiring and releasing it
is a single atomic CPU instruction entirely in userspace, no kernel involved,
very fast. Only when a thread must *wait* for a contended lock does it make the
`futex` **system call** to ask the kernel to put it to sleep until woken.

So when `/proc/.../wchan` says `futex_do_wait` and `syscall` is `202` (the futex
syscall), it means precisely: **this thread is asleep waiting for a lock another
thread is holding.** Many threads in that state equals lock contention, or a
deadlock.

### Condition variables

A close cousin: a **condition variable** lets a thread sleep until "some
condition becomes true," with another thread signaling when it changes (think a
work queue: workers sleep until a job arrives). These also show up as futex waits.
An idle worker pool sleeping on "is there work yet" looks similar to a deadlock at
the wchan level, which is why you confirm with a backtrace (Layer 11), not wchan
alone.

### Deadlock

A **deadlock** is when a set of threads can never proceed. The clean case is a
cycle: A holds lock 1 and wants lock 2; B holds lock 2 and wants lock 1. The case
in your incident was simpler and just as fatal: **one worker grabbed a mutex,
then blocked forever on a dead database while still holding it.** Every other
worker that needed that mutex piled up behind it. No cycle, just a holder that
never came back.

Classic necessary conditions (handy checklist when you suspect one): mutual
exclusion, hold-and-wait, no preemption, and circular wait.

### The Ruby angle: the GVL

Ruby (like CPython) has a **Global VM Lock (GVL)**, sometimes called the GIL.
Only one thread runs Ruby code at a time per process. Threads still help, because
the GVL is released during IO (network, disk, sleeping), so while one thread
waits on the database another can run Ruby. But CPU-bound Ruby does not speed up
with threads; for that you need multiple processes (Layer 7's "workers"). This is
why Ruby servers offer both threads (cheap, great for IO-bound web work) and
worker processes (real parallelism).

**You might not know:** the specific lock that hung your app was a Rails
application-level mutex around `check_pending_migrations` (a dev-only safety check
that runs each request). It is not a Ruby language lock or a kernel lock; it is
ordinary application code calling `Mutex#synchronize`. Locks exist at every layer,
and a backtrace is how you tell which one you are stuck in.

```sh
# see lock waits across a process's threads
for t in /proc/<pid>/task/*; do echo "$(cat $t/comm): $(cat $t/wchan)"; done
```

---

# Layer 5: Networking, sockets, and "hang vs refuse"

**Core idea: programs talk over the network through *sockets* identified by an IP
address and a port, and a connection goes through a precise handshake whose
failure modes explain exactly why something refuses versus hangs.**

### Sockets, addresses, ports

A **socket** is a communication endpoint, and to your program it is just another
file descriptor you can read and write. An endpoint is named by an **IP address**
(which machine) plus a **port** (which program on that machine), 0 to 65535. A
server **binds** to a port and **listens**; clients **connect** to that
address+port.

`localhost` is the name for your own machine, IP `127.0.0.1` (IPv4) or `::1`
(IPv6). Traffic to it never leaves the box. In the incident the app talked to
`localhost:5433`.

### The TCP three-way handshake

TCP is the reliable, ordered connection protocol under HTTP and Postgres. Opening
a connection is a three-step handshake:

1. Client sends **SYN** ("let's talk").
2. Server replies **SYN-ACK** ("ok, let's talk").
3. Client sends **ACK** ("great").

After step 3 the connection is **established**. Crucially, "established at the TCP
level" is not the same as "the application is paying attention." This gap is the
whole story of hang-vs-refuse.

### The two queues, and Recv-Q

A listening socket has two kernel queues:
- the **SYN queue** for half-finished handshakes, and
- the **accept queue** for completed connections waiting for the application to
  call `accept()` and start handling them.

`ss -tln` shows, for a `LISTEN` row:
- **Recv-Q** = how many completed connections are sitting in the accept queue
  *unaccepted right now*, and
- **Send-Q** = the maximum size of that queue (the backlog).

Healthy server: it calls `accept()` constantly, so Recv-Q stays near 0. **A
lingering nonzero Recv-Q means the application stopped accepting**: alive enough to
hold the port, wedged enough to ignore clients. You saw `Recv-Q 14`: fourteen
connections (your piled-up puma workers) had completed the TCP handshake but the
process behind the port never picked them up.

### The three outcomes of a connect attempt

| You observe | What happened | Why |
|-------------|---------------|-----|
| **Refused** (instant error) | nothing is listening on that port | the kernel replies RST immediately |
| **Hang** (waits forever) | something listens but never completes the app-level exchange (or a firewall silently drops the SYN) | handshake completes or stalls with no answer; nothing tells the client to give up |
| **Connected** | a real server accepted and responded | the happy path |

This table is worth memorizing. "Refused" and "hang" feel similar in a browser
but point at opposite causes: refused means *absent*, hang means *present but
stuck*. The incident hung (not refused) precisely because the container's port
forwarder was still listening in front of a dead database.

### Explore

```sh
ss -tlnp                      # listening TCP sockets + owning process
ss -tnp                       # established connections
ss -s                         # summary counts
# is a port answering? open, refused, or hang?
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/localhost/5433 && echo open || echo refused'
```

---

# Layer 6: HTTP, the request itself

**Core idea: HTTP is a simple text-based request/response conversation carried
over a TCP connection.**

When the browser asks for a page, over an established TCP connection it sends a
**request**: a method (`GET`, `POST`, ...), a path (`/`), headers (host, cookies,
content type), and an optional body. The server sends back a **response**: a
status code (`200` ok, `404` not found, `500` error), headers, and a body (the
HTML, JSON, etc.).

`curl` is just a program that speaks this conversation from the command line, which
is why it is the cleanest way to test a server without a browser in the way. The
flags from the playbook:
- `-m 5` give up after 5 seconds (so *you* do not hang while testing a hang),
- `-s` quiet,
- `-o /dev/null` throw away the body,
- `-w "%{http_code} %{time_total}\n"` print just the status and timing.

**You might not know:** a hang at this layer (curl waits, no status) versus a fast
`000`/refused tells you, before you touch anything else, whether you are dealing
with "present but stuck" or "absent," the same distinction as Layer 5. And the
*timing* matters: a request that returns in 30 ms versus 30 s versus never are
three different bugs.

**You might not know:** the browser does extra work a single `curl` does not: it
opens several connections, requests sub-resources (CSS, JS, images), and reuses
connections (keep-alive). So "the browser spins forever" can have causes a single
`curl` will not reproduce. When in doubt, test with `curl` to strip the browser's
complexity away. That is exactly why the first real diagnostic in the incident
was a `curl`, not a screenshot.

---

# Layer 7: The web server (puma)

**Core idea: a web server's job is to accept network connections, turn raw bytes
into a request your framework understands, run it, and write the response back,
many times concurrently.**

Puma (the Ruby app server here) handles concurrency two ways, and the difference
is Layer 1 and Layer 4 made concrete:

- **Worker processes**: separate OS processes (created by `fork`). True
  parallelism across cores, isolated memory (one crashing does not take the
  others), but each costs full memory. Set by `WEB_CONCURRENCY`.
- **Threads**: multiple threads inside one process, sharing memory. Cheap, and
  excellent for IO-bound web work because Ruby releases the GVL during IO. Bounded
  by `RAILS_MAX_THREADS`.

A typical request's life inside puma:
1. The accept loop pulls a connection off the listen socket's accept queue
   (Layer 5).
2. A thread from the **thread pool** is assigned to it.
3. That thread parses the HTTP bytes into a request, builds a Ruby hash describing
   it (the Rack `env`), and calls the application (Layer 8).
4. The app returns `[status, headers, body]`; puma writes it back over the socket.
5. The thread returns to the pool for the next request.

Now the incident makes mechanical sense: each stuck request occupied a pool
thread, and each of those threads blocked on the same mutex. Once every pool
thread was parked, puma had nothing left to assign, so *new* connections just sat
in the accept queue (hence `Recv-Q 14`). The web server was healthy; it had simply
run out of free workers because they were all stuck one layer down.

**You might not know:** in development, servers often run a single worker with a
few threads, so a *single* stuck request that holds a shared lock can wedge the
whole app. The same bug in production with several workers might only degrade it.
"Works dramatically worse in dev" can be a concurrency-shape artifact, not a
different bug.

```sh
ps -o pid,ppid,nlwp,rss,comm -p <puma_pid>   # nlwp = number of threads
```

---

# Layer 8: The framework (Rails and Rack)

**Core idea: the framework receives the bare request from the web server and
passes it through a stack of wrappers (middleware) before and after your code
runs. Knowing the order of that stack lets you pinpoint where a request died.**

### Rack: the contract

**Rack** is the thin standard between Ruby web servers and Ruby frameworks. A Rack
app is anything with a method `call(env)` that returns `[status, headers, body]`.
Puma speaks Rack; Rails is a Rack app. That one interface is why you can swap
servers and frameworks freely.

### Middleware: the onion

A Rails request does not jump straight to your controller. It descends through a
**middleware stack**: a series of wrapping `call` methods, each able to do
something before and after the next. Host checking, static files, cookies,
sessions, logging, exception rendering, code reloading, and the dev-only pending
migration check are all middleware. Picture an onion: the request goes in through
every layer, hits the router and your controller at the core, and the response
comes back out through the same layers.

You can print the actual stack:
```sh
bin/rails middleware
```

### Why the missing log line was the key clue

Two log lines mark positions in this journey:
- `Started GET "/"` is emitted by an early logging middleware, near the outside of
  the onion.
- `Processing by SomeController#action` is emitted once the request reaches the
  controller, at the core.

In the incident you saw the first but never the second. That single fact placed
the hang **inside the middleware stack, before any controller code ran**, which
instantly cleared your mailer, views, and controllers of suspicion. Learning to
read "what should have been logged next and was not" is one of the highest-value
debugging skills, and it lives at this layer.

The specific culprit was `ActiveRecord::Migration` `check_pending_migrations`, a
development middleware that, on each request, asks the database "are there
migrations you have not run?" To ask, it needs a database connection, which sent
the request down into Layer 9, where it got stuck.

**You might not know:** development mode also wraps requests in a **code reloader**
with a "load interlock" so it can safely swap reloaded classes between requests.
This is more machinery (and more locks) than production runs, which is another
reason dev can hang or behave differently. The convenience of "edit a file, just
refresh" is paid for with real concurrency complexity under the hood.

---

# Layer 9: The database connection

**Core idea: talking to a database means holding a network connection to it, and
because connections are expensive, apps share a small *pool* of them. Both the
pool and the connecting handshake have failure modes.**

### The connection pool

Opening a database connection (a TCP connect plus an authentication handshake) is
slow relative to a query, so apps keep a **connection pool**: a small fixed set of
open connections that threads borrow ("checkout") and return ("checkin"). The pool
size caps how many queries run at once. If all connections are checked out, the
next thread waits.

### A connection is just a socket speaking a protocol

Under the pool, each connection is a TCP socket (Layer 5) to Postgres, exchanging
messages in the **Postgres wire protocol**. Opening one means: TCP handshake, then
a startup/auth exchange where the client and server agree on user, database, and
encoding.

### Where it hung

The Postgres driver opens connections **asynchronously**: it starts the connect
and then **waits** for the socket to become ready, looping until the handshake
finishes. In the incident there was **no connect timeout**, so when the TCP
connection completed (the container's port forwarder accepted it) but the Postgres
startup handshake never came (because the database behind it was dead), the
driver's wait had nothing to wait *for* and no deadline. It blocked forever. That
forever-wait, while a Rails mutex was held, is what cascaded all the way back up
to your browser spinning.

The lesson that generalizes: **any network call without a timeout is a potential
permanent hang.** Timeouts are not a nicety; they are what converts "hang forever"
into "fail fast and recover."

### Verify a database properly

A port answering is the weakest possible signal. Prove the *handshake completes*:
```sh
pg_isready -h localhost -p 5433                          # is it accepting?
psql -h localhost -p 5433 -U postgres -c 'select 1'      # does a real query return?
```
Always verify with the strongest signal you can run, not the easiest.

---

# Layer 10: Containers and Docker

**Core idea: a container is not a virtual machine. It is ordinary processes on
your host, fenced off by two kernel features (namespaces for isolation, cgroups
for limits), with its own filesystem from an image.**

### Images vs containers

- An **image** is a read-only template: a packaged filesystem plus metadata (what
  to run, which ports, env). `postgres:18` is an image.
- A **container** is a running instance of an image: the image's files, plus a
  thin writable layer on top, plus isolation. You can start, stop, and destroy
  containers; the image stays put.

### What actually isolates a container

Two Layer-2/Layer-1 primitives you have already met:
- **Namespaces** control what a process can *see*: its own process list (it sees
  PID 1 as its main process), its own network stack, its own filesystem mounts,
  its own hostname. Same kernel, separate views.
- **cgroups** control what a process can *use*: memory, CPU, IO limits and
  accounting (the same cgroups from Layer 2).

So a Postgres container is just the Postgres process running on your kernel, in a
network namespace where it thinks it owns port 5432, with a filesystem from the
`postgres:18` image, accounted in a cgroup. No emulated hardware, which is why
containers start in milliseconds while VMs take seconds.

### Port mapping, and why your bug *hung* instead of *refused*

Because a container has its own network namespace, its ports are not your host's
ports until you map them. Your compose file maps `"5433:5432"`: host port 5433
forwards to the container's port 5432. Docker implements this with a helper
process (**docker-proxy**) and/or kernel firewall rules (iptables/nftables DNAT)
that listen on the host port and forward into the container.

Here is the subtle part that produced the exact symptom: that host-side forwarder
can keep **listening on 5433 even when the container behind it is unhealthy or
gone**. So connections to 5433 completed their TCP handshake against the forwarder
(no "refused"), but there was no live Postgres to finish the conversation, so they
hung. The `Recv-Q 14` you saw was on that forwarder's socket. Two layers (Docker
networking and TCP queues) combined to turn a dead database into a hang rather
than a clean error.

### Volumes: why your data did not vanish

A container's writable layer is destroyed when the container is removed. Anything
that must persist lives in a **volume**, a storage area managed by Docker and
mounted into the container. Your compose file maps the `db_data` volume to
Postgres's data directory, so you can destroy and recreate the container without
losing the database.

### Restart policies: what you just added

A container exits when its main process exits (crash, OOM-kill, daemon restart). A
**restart policy** tells Docker whether to bring it back:
- `no` (default): stay down.
- `on-failure`: restart only on a nonzero exit.
- `always`: always restart, even ones you stopped on purpose (when the daemon
  restarts).
- `unless-stopped`: restart on crash/OOM/daemon-restart, but respect a deliberate
  `docker stop`.

You added `unless-stopped`, which is the right default for a dev database: it
self-heals after the exact OOM scenario that bit you, without fighting you when you
intentionally stop it. Note a policy set in the compose file only applies to
containers *created* afterward, which is why you also ran `docker update --restart`
to apply it to the already-running ones.

### Explore

```sh
docker ps -a                                   # all containers and their status
docker inspect -f '{{.State.Status}} {{.HostConfig.RestartPolicy.Name}}' <name>
docker logs <name> --tail 50                   # the container's own stdout/stderr
docker stats --no-stream                       # live per-container CPU/mem (cgroups)
```

---

# Layer 11: Logs and the journal

**Core idea: a program's output goes to file descriptors (stdout/stderr) that
point *somewhere* depending on how it was launched, and systemd captures service
output into a queryable database called the journal.**

### stdout, stderr, and where they actually go

Every process starts with three open file descriptors by convention: `0` stdin,
`1` stdout, `2` stderr. "Printing" is writing to fd 1; "logging an error" is
writing to fd 2. Where those land is decided by whoever launched the process: a
terminal (you see it), a file (`> log.txt`), a pipe (another program), or the
journal.

This is the mechanism behind the `rb_backtrace()` trick in the playbook. Ruby's
backtrace printer writes to fd 2. Under foreman, fd 2 was the terminal you started
`bin/dev` in, not anywhere I could read. So I redirected that process's fd 2 to a
file (`dup2`) before triggering the dump. Understanding "fd 2 points wherever the
launcher pointed it" is what made that move obvious instead of magic.

### syslog, journald, and units

systemd runs services and captures their stdout/stderr into the **journal** (the
`systemd-journald` service). `journalctl` queries it: structured, timestamped,
filterable, and persistent across reboots if configured.

- A **unit** is something systemd manages (a service, a socket, a timer). A
  **slice** and a **scope** are cgroup groupings (Layer 2 again).
- `journalctl -u <unit>` filters to one service.
- `journalctl -k` shows **kernel** messages (the same stream as `dmesg`, which is
  the kernel's ring buffer). The OOM killer logs here, which is why the forensic
  step used `journalctl -k`.

### Live state vs forensics

The deepest habit at this layer: when something already happened (a crash, a
kill), **the live tools lie**. `free` shows memory now, not at the moment of the
OOM. `ps` shows what survived. To reconstruct a past event you read what the
system *wrote down* at the time. That is what the journal is for. The whole OOM
investigation was reading the kernel's notes from 13:41 and 13:51, not poking at
the current machine.

```sh
journalctl -k --since "1 hour ago"     # kernel log (OOM, hardware, fs)
journalctl -u docker --since today      # one service
journalctl -f                           # follow live
journalctl --list-boots                 # per-boot history
```

---

# Layer 12: The debugging toolbox, mapped to layers

Each tool observes one or two layers. Knowing which tool sees which layer is most
of the skill; the rest is reading output.

| Tool | Layer it sees | One-line use |
|------|---------------|--------------|
| `curl -m` | HTTP / app | is it up, slow, hanging, or refusing? |
| `ps`, `ps -eLf` | processes / threads | what is running, parent/child, thread count, state |
| `top`, `htop` | CPU + memory, live | spinning (high CPU) vs waiting (idle) |
| `free`, `/proc/meminfo` | system memory | available (not free) is the real number |
| `/proc/<pid>/...` | everything per process | states, wchan, fds, env, maps, raw and universal |
| `ss -tlnp` | sockets / TCP | who listens, who connects, accept-queue backlog |
| `lsof` | open files/sockets | which process holds which file/socket/port |
| `gdb -p` | in-process call stacks | the exact code line a thread is stuck on |
| `rbspy`/`py-spy`/`jstack` | language-level stacks | the script-level backtrace, no gdb gymnastics |
| `docker ps/inspect/logs` | containers | container state, config, its own output |
| `journalctl -k`, `dmesg` | kernel, historical | OOM kills, hardware, filesystem events |
| `journalctl -u` | service logs, historical | what a service logged, including past runs |

**You might not know:** several of these (`ps`, `ss`, `lsof`, `free`, `top`) are
just curated readers of `/proc` and `/sys`. If a box is missing a tool, you can
often read the underlying file directly. The tools are conveniences; `/proc` is
the source of truth.

---

# How it all connected: the incident as one story across the layers

Read top to bottom, this is the same investigation as the playbook, but now you
can see which layer each step is reasoning about.

1. **HTTP (6):** `curl -m` showed requests hang, not refuse. Present but stuck.
2. **Web server (7) + processes (1):** `ps` showed puma alive. So it blocks
   *during* handling.
3. **Framework (8):** the log had `Started` but never `Processing by`. The hang is
   inside middleware, before app code.
4. **Process state (1):** every thread was `S`, none `R`. Not a loop, a wait.
   Whole-process wait equals deadlock.
5. **Locks (4) via /proc (3):** `wchan` was `futex` everywhere. Threads waiting on
   a lock.
6. **Locks (4) via gdb (11):** the backtrace showed a worker stuck in
   `Mutex#synchronize`, and another in a socket wait with no timeout.
7. **DB connection (9):** the Ruby backtrace traced the mutex holder to
   `check_pending_migrations` opening a Postgres connection that never completed.
8. **Networking (5):** `ss` showed port 5433 listening with `Recv-Q 14`,
   unanswered connections. Present but wedged.
9. **Containers (10):** `docker ps -a` showed the Postgres container `Exited`.
   Root cause.
10. **Memory (2) + journal (11):** `journalctl -k` showed the OOM killer had run,
    triggered by multi-GB processes filling a 30 GB box whose swap is zram. That
    killed the container and started the whole chain.
11. **The fix:** restart the container (10), verify with a real query (9), restart
    the app (7), and add a restart policy (10) so an OOM can never wedge the app
    again.

One symptom at the top (browser spins), one dead thing at the bottom (a container),
and a chain of layers connecting them. **Debugging is walking that chain on
purpose, asking at each layer "is the problem here, or below me?", until you reach
something that is simply broken.** Every concept in this guide is just a tool for
answering that question at one specific layer.

---

# Where to go next (a learning path)

If you want to turn this from "I read it once" into reflexes:

- **Processes:** run `htop`, sort by CPU then by memory, and identify what each
  top process is. Watch states change as you start/stop apps.
- **Memory:** keep `watch -n1 'free -h; echo; cat /proc/pressure/memory'` open
  while you open heavy apps. Watch available fall and pressure rise.
- **Networking:** `ss -tlnp` and identify every listener on your machine. Then
  `curl` a few and watch the three outcomes (open, refused, hang).
- **/proc:** pick any running PID and read its `status`, `fd/`, and
  `task/*/wchan`. Predict what it is doing, then confirm.
- **Containers:** `docker inspect` one of yours and find its ports, volume, and
  restart policy in the JSON.
- **The journal:** `journalctl -k -f` in a spare terminal for a day. You will be
  surprised what the kernel quietly records.
- **A book when you want the deep version:** "The Linux Programming Interface"
  (Kerrisk) is the canonical reference for Layers 1 to 5.

The playbook (`debugging-hanging-systems.md`) is the quick-reference for when
something is on fire. This guide is the "why" underneath it. Re-read a layer
whenever a bug drags you into it; it will read differently once you have felt the
problem it describes.
