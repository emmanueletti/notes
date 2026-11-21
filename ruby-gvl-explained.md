# Ruby GVL explained

The GVL (Global VM Lock, formerly called the GIL, same idea as Python's GIL) belongs to CRuby/MRI, not Rails. Rails inherits it.

## Mental model: the kitchen

One kitchen, one stove, many cooks. Cooks waiting on the oven (IO) don't block anyone. Cooks chopping (CPU) need the stove one at a time.

Fixes:
- more kitchens (processes)
- fewer cooks per kitchen (fewer threads)
- chop faster (YJIT)
- hand the chopping to a machine that doesn't need the stove (native code that releases the GVL)

## Basics

### Mutex

Short for "mutual exclusion". A lock only one thread can hold at a time. In the kitchen it's the single key to the stove. To cook you take the key, and if someone else has it you wait.

```ruby
lock = Mutex.new
lock.synchronize do
  # only one thread can be in here at a time
end
```

The GVL is one giant mutex the Ruby VM takes before running any Ruby code.

### Ruby VM

Ruby code isn't run directly. Ruby parses it into bytecode (simple instructions like "push this value", "call this method"), and a virtual machine executes those instructions one by one. CRuby's VM is called YARV.

The VM also owns the shared machinery: the heap where every object lives, the garbage collector, the method caches.

Kitchen: the VM is the kitchen itself. Recipe reader, pantry (heap), dishwasher (GC), stove. Your Ruby code is the recipes.

### Process vs thread

A process is a running program with its own private memory, walled off by the OS. A separate kitchen with its own pantry.

A thread is a line of execution inside a process. Many threads share the same memory. Multiple cooks in one kitchen sharing one pantry.

The OS scheduler decides which thread runs on which core and can pause any thread at any moment (preemptive scheduling). A cook can get tapped on the shoulder mid-chop.

Trade-off: threads are cheap and share data easily, but sharing is exactly what makes them dangerous.

### Thread safety

Code is thread-safe if it behaves correctly when multiple threads run it at the same time. Classic failure is a race condition:

```ruby
@count += 1
```

Looks like one step, is three: read, add 1, write back.

```
Thread A reads 5
Thread B reads 5
Thread A writes 6
Thread B writes 6   # should be 7, one increment lost
```

Two cooks each see 5 eggs, each adds one, each labels the bowl "6". Fix: a mutex around the read-add-write.

The GVL does NOT make your code thread-safe. It can switch threads between the read and the write. It protects the VM's internals (the pantry shelving doesn't collapse), not your logic (your egg count).

### Concurrency vs parallelism

- Concurrency: juggling several tasks, possibly by switching between them.
- Parallelism: doing several tasks at literally the same instant on different cores.

The GVL gives Ruby concurrency but blocks parallelism within one process.

## What the GVL is

- One mutex per Ruby VM (one per Ractor since Ruby 3.0).
- A thread must hold the GVL to run Ruby code, so only one thread runs Ruby at a time.
- Released on blocking: IO (socket, DB query, HTTP), `sleep`, or C code that calls `rb_thread_call_without_gvl`.
- A timer thread forces a handoff every ~100ms so a CPU-heavy thread can't starve others.
- Threads overlap their waiting, not their computing.

## Foundational pattern

Coarse-grained locking, aka the "giant lock" or "big lock": one lock guards all shared state instead of many small locks. Underneath, plain mutual exclusion. Trade simplicity and correctness now for scalability later.

Same lineage:
- Linux BKL (Big Kernel Lock), which took Linux ~10 years to remove piece by piece
- Python GIL
- The monitor pattern scaled to a whole interpreter

## Why it's a feature, not a bug

It protects VM internals that aren't thread-safe: object heap, GC, method and constant caches, hash tables, symbol table.

1. Simplicity. No fine-grained locks everywhere in the VM, so fewer races, deadlocks and memory-ordering bugs.
2. C extension safety. Thousands of C gems assume nobody else touches Ruby objects concurrently. Removing the GVL would quietly break that ecosystem. This is the big one.
3. Single-thread speed. No atomic ops or per-object locks on the hot path. Fine-grained locking usually slows single-thread code (Python's no-GIL work showed a measurable tax).
4. Simpler GC. No coordinating many threads mutating the heap.
5. Fits the workload. Rails requests are mostly IO-bound, and threads release the GVL while waiting.

## Tradeoffs

- No multi-core for CPU work in one process: JSON, view rendering, serialization, crypto all run on one core per process.
- GVL contention latency: a thread finishes its DB query, then waits for the GVL to continue. Invisible in most APMs, looks like "slow Ruby".
- Noisy neighbour: one CPU-heavy request inflates latency for every other thread in the process.
- Convoy effect: threads queue on the lock under load, so p99 degrades before throughput does.
- More threads ≠ more throughput once CPU share is high (Amdahl's law: the serialized fraction caps speedup).

## What people do about it

- Processes for parallelism, threads for IO. Puma cluster mode: workers ≈ cores, a few threads each. `preload_app!` plus fork copy-on-write to share memory.
- Tune thread count. Rails 7.2 cut Puma's default from 5 threads to 3 because of GVL contention. More IO-heavy means more threads are fine; more CPU-heavy means fewer threads, more processes.
- Measure GVL wait. Ruby 3.2+ GVL instrumentation API (`rb_internal_thread_add_event_hook`). Gems: `gvltools` (Shopify), `gvl-tracing` (Ivo Anjo, timeline view).
- Spend less time holding the GVL: YJIT, native extensions that release it (`pg` does during queries), background jobs.
- Other models and runtimes, below.

## Concurrency models

### 1. Multiple processes (Puma workers, Unicorn, Pitchfork)

More kitchens. Each process has its own VM and own GVL, so 8 processes on 8 cores is true parallelism.

Pros: real multi-core use; isolation (one crash or leak doesn't take down others); no thread-safety issues between processes.

Cons: memory (500MB app × 8 = 4GB); processes can't share in-memory state, so it goes through DB, Redis, etc.

Mitigation: fork with copy-on-write. Load the app once, fork; children share the parent's memory pages until one writes to a page, and only then is that page copied. Pitchfork re-forks from a warmed-up worker to share even more.

### 2. Threads (Puma threads, Sidekiq concurrency)

More cooks per kitchen. While one waits on the oven (DB query), another uses the stove.

Pros: cheaper than processes; shared memory; great for IO-bound work.

Cons: GVL means CPU work doesn't parallelize; thread-safety bugs; each OS thread costs stack memory plus kernel context switches, so you can't have thousands.

### 3. Fibers and the async gem (Falcon server)

One cook juggling many dishes. A fiber is a lightweight unit of work that only switches when it chooses to, usually when it would wait on IO (cooperative scheduling: nobody gets tapped on the shoulder; a cook switches only when they put a pot on to boil). An event loop asks the OS "tell me when any of these sockets are ready" (epoll on Linux, kqueue on macOS, io_uring on newer Linux). Ruby 3.0's Fiber Scheduler made standard IO fiber-aware.

Pros: very cheap (KBs per fiber vs MBs per thread), so 10k open connections are fine (websockets, streaming, LLM API calls); fewer races since switches only happen at known points.

Cons: zero help for CPU work; one CPU-heavy or truly blocking call (a C library that doesn't cooperate) freezes every fiber on that thread; needs fiber-aware libraries throughout.

### 4. M:N threads (Ruby 3.3+, RUBY_MN_THREADS=1)

N Ruby threads multiplexed onto M OS threads, with Ruby scheduling instead of the kernel. Many cooks sharing a few aprons; whoever is actively working wears one.

Pros: Ruby threads become much cheaper, so you can have far more; cheaper switching.

Cons: still one GVL per Ractor, so no extra parallelism; new and opt-in, aimed mostly at non-main Ractors; C extension edge cases.

### 5. Ractors (Ruby 3.0+, experimental)

Sealed kitchens, each with its own stove (own GVL), passing containers through a hatch. Actor model: isolated units communicating by message passing instead of shared memory (Erlang and Elixir are built on this). Only deeply frozen objects can be shared; anything else is copied or moved (ownership transfers and the sender can't touch it anymore).

Pros: true parallelism in one process; no data races by construction.

Cons: experimental, with performance issues; most gems break because of global mutable state (class variables, module-level caches); Rails isn't Ractor-safe; copying cost; very different programming style.

### 6. Background jobs (Sidekiq, Solid Queue)

A separate catering kitchen for big orders. Not a new primitive. Moves CPU-heavy or slow work off the request path into different processes.

Pros: web latency stays low; scale job workers separately.

Cons: more infrastructure; eventual results; you need retries and idempotency (a job that runs twice must not double-charge anyone).

### 7. Native extensions that release the GVL

A machine that doesn't need the stove. C or Rust code processes raw bytes and calls `rb_thread_call_without_gvl`, letting other Ruby threads run in parallel.

Catch: while off the GVL it must not touch Ruby objects. It handed the key back, so no pantry access. Harder to write, and memory-safety bugs in C crash the whole process.

### Comparison

```
model            parallel CPU?  memory cost  main risk
processes        yes            high         RAM bloat
threads          no (GVL)       medium       race conditions
fibers/async     no             very low     one blocker stalls all
M:N threads      no             low          new/immature
ractors          yes            medium       gem incompatibility
bg jobs          via processes  high         infra + idempotency
native ext       yes            low          crashes, hard to write
```

## How JRuby and TruffleRuby get away without a GVL

The main reason CRuby keeps the GVL: thousands of C extensions written against CRuby's C API assume no concurrent access, and the VM internals weren't built for concurrency.

### JRuby

Ruby on the JVM, inheriting 25+ years of JVM concurrency engineering:
- JVM threads map to real OS threads and run truly in parallel
- A formal memory model defines what one thread sees of another's writes
- Garbage collectors built to work while many threads run
- JRuby's internals were designed thread-safe from the start

Crucially, JRuby doesn't run CRuby C extensions at all. No legacy assumptions to protect, so no need for the big lock. C-extension gems need Java versions (Nokogiri ships one).

It doesn't make your code safe. Concurrently mutating an Array or Hash can corrupt it or raise an error. Your races are real races now, because cooks truly work at the same moment.

Trade-offs: slow startup and JVM warmup (hurts CLIs and tests); higher baseline memory; gem compatibility gaps; usually trails CRuby on new Ruby versions.

Kitchen: a commercial kitchen with many stoves, built to code from day one, but your old home appliances don't plug in.

### TruffleRuby

Runs on GraalVM, with an advanced JIT that makes hot Ruby code very fast once warmed up.

Object trick: an object only reachable by one thread is "local" and skips synchronization. The moment it becomes reachable from another thread (e.g. stored in a shared variable), it's flipped to "shared" mode with synchronization. You pay for safety only on objects actually shared. A cook's private cutting board needs no rules; the communal bowl gets a lock once a second cook can reach it.

C extensions: emulates the CRuby C API and by default runs C extension code under a global lock, because those extensions assume a GVL. The lock isn't gone, it's shrunk to cover only the legacy code that needs it. Pure Ruby runs in parallel.

Trade-offs: long warmup before peak speed; high memory; some gem incompatibilities; smaller community and less production mileage.

### The pattern behind both

CRuby: one big lock around everything. JRuby and TruffleRuby: fine-grained or selective locking. Same journey as Linux removing the BKL, and Python now with free-threading in 3.13+. The price is always the same: more complex internals, some single-thread cost, and breaking the ecosystem's old assumptions.
