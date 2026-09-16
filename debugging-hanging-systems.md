# Debugging a Hanging / Broken System: a Playbook

A field guide for "my app/server/computer is stuck and I don't know why."
Written from a real incident (dev server hung on every request; root cause was
a dead Postgres Docker container after the OOM-killer ran). The method
generalizes far beyond that one bug.

---

## The core loop

Every step below is the same loop repeated at a lower layer:

1. **Narrow the scope.** One thing or everything? Once or always? Fresh or only
   after a while? Each answer deletes half the suspects.
2. **Locate where it fails** before guessing a fix. Find the exact line/process
   that is stuck. Guessing fixes wastes time and can hide the real cause.
3. **Separate symptom from cause.** The thing that looks broken is usually a
   victim of something one layer down. Keep asking "is the problem here, or
   below me?"
4. **Go one layer deeper** and repeat, until you hit something that is simply
   dead or misconfigured.

The layers, top to bottom, for a web app:
browser -> HTTP -> web server (puma) -> framework middleware (Rails) ->
your code -> a lock -> the DB driver -> the database -> the container/OS ->
hardware/memory.

---

## The ladder I actually climbed (quick version)

1. `curl -m 5 ...` and `ps aux | grep puma` -> requests *hang*, server is *up*.
   So it blocks during handling, not before.
2. Read the log. `Started` was logged but `Processing by` never was. So it dies
   in middleware, before my code. (The missing line told me more than the
   present ones.)
3. Every fresh restart hung on its first request -> reproducible, not stale
   state -> restarting won't fix it.
4. `bin/rails runner 'puts :ok'` booted fine -> the app loads fine; only request
   handling is broken.
5. Read the stuck process (see "Reading a hung process" below) -> every thread
   asleep on a lock -> a deadlock, not a slow query or a loop.
6. `gdb` backtrace -> a worker stuck acquiring a Ruby mutex; another worker
   waiting on a socket forever.
7. Ruby-level backtrace -> the stuck path was "check pending migrations -> open
   DB connection -> hang." So it's the database, not Rails.
8. `ss -tlnp` on the DB port -> listening but with a backlog of unanswered
   connections (Recv-Q nonzero) -> "something is there but wedged."
9. `docker ps -a` -> the Postgres container was `Exited`. Root cause found.
10. Start it, verify with three independent checks, restart the app.

The rest of this doc explains the parts that are not obvious the first time.

---

## Part A: Processes, threads, and states (spinning vs waiting)

A running program is one or more **threads**. The OS scheduler hands each thread
slices of CPU. At any instant a thread is in a **state**. The ones that matter:

| State | Meaning | What it tells you |
|-------|---------|-------------------|
| `R` | Running or runnable (on CPU or ready for it) | If it is hung here, it is **spinning** in a loop, burning CPU |
| `S` | Sleeping, interruptible. Voluntarily waiting (a lock, a network reply, a timer) | **Waiting** on something. Uses ~0 CPU. Most "hangs" are this |
| `D` | Uninterruptible sleep. Stuck in the kernel, almost always disk/network-filesystem IO | Suspect a slow/dead disk, NFS, or a stuck mount. Cannot even be killed |
| `Z` | Zombie. Finished, but its parent has not collected it | A supervision bug, rarely the cause of a hang |
| `T` | Stopped (e.g. paused by a debugger or Ctrl-Z) | Someone/something paused it |

**The first question for any hang: is it spinning or waiting?**

- Open `top` (or `htop`). If the process sits at ~100% CPU (or 100% x N cores),
  it is **spinning**: a loop with no exit. Hunt the loop (a profiler, or repeated
  backtraces that always land in the same code).
- If it sits at ~0% CPU but is unresponsive, it is **waiting**: blocked on a lock,
  a socket, or disk. Now you go find *what* it waits on (Parts B and C).

This single fork in the road saves enormous time. Spinning and waiting need
completely different tools.

---

## Part B: /proc, the live window into a process

`/proc` is a fake filesystem the Linux kernel exposes. It is not files on disk,
it is a live view of the kernel's data, presented as files so you can `cat` them.

- `/proc/<pid>/` is one process.
- `/proc/<pid>/task/<tid>/` is one **thread** inside it. The `*` glob over
  `task/` lets you inspect every thread at once.

The files I used most:

| Path | What it gives you |
|------|-------------------|
| `/proc/<pid>/task/*/stat` | many fields; **field 3** is the state letter (R/S/D...) |
| `/proc/<pid>/task/*/comm` | the thread's name (often the file:line where it was created) |
| `/proc/<pid>/task/*/wchan` | the **wait channel**: the kernel function it is sleeping in |
| `/proc/<pid>/task/*/syscall` | the syscall it is currently parked in (number + args) |
| `/proc/<pid>/task/*/stack` | the kernel-side stack (usually needs root) |
| `/proc/<pid>/environ` | environment variables (null-separated; `tr '\0' '\n'` to read) |
| `/proc/<pid>/fd/` | every open file and socket the process holds |
| `/proc/<pid>/status`, `/maps` | memory usage and the memory map |

A handy one-liner to see every thread's state, what it waits on, and its name:

```sh
PID=12345
for t in /proc/$PID/task/*; do
  printf "%s  state=%s  wchan=%s  %s\n" \
    "$(basename "$t")" \
    "$(awk '{print $3}' "$t/stat")" \
    "$(cat "$t/wchan")" \
    "$(cat "$t/comm")"
done
```

If every line says `S` and the wchan is a lock or poll, you are looking at a
process that is entirely parked. Nothing is running. That is the signature of a
**deadlock** (everyone waiting, no one working).

---

## Part C: wchan and syscall, decoding what a sleeping thread waits on

`wchan` ("wait channel") is the name of the kernel function the thread fell
asleep in. You do not need to memorize them; recognize the families:

| wchan contains | Meaning | Plain English |
|----------------|---------|---------------|
| `futex...` | waiting on a futex | "I want a **lock** that another thread holds" |
| `ep_poll`, `do_epoll_wait` | waiting in epoll | an event loop, usually **idle** or waiting for a socket to be ready |
| `poll_schedule_timeout`, `do_select` | select/poll with a timeout | waiting on one or more **file descriptors** |
| `..._recvmsg`, `tcp_recvmsg` | blocked in a socket read | waiting on the **network** |
| `pipe_read`, `wait_woken` | reading a pipe / generic wait | waiting on another process or an fd |
| `(empty)` or `0` | not sleeping | it is actually running |

`syscall` gives the same answer from another angle: the number is the system
call the thread is stuck in. A few common ones on x86_64:

| syscall # | name | meaning |
|-----------|------|---------|
| 202 | `futex` | lock wait |
| 232 | `epoll_wait` | event loop wait |
| 270 / 271 | `pselect6` / `ppoll` | fd wait with timeout |
| 0 / 1 | `read` / `write` | IO |

The pattern matters more than any single number. **Many threads parked on
`futex` = lock contention or a deadlock.** That is exactly what I saw.

What this still does NOT tell you: *which* lock, and *what code path* led there.
For that you need the program's own call stack (Part D).

---

## Part D: gdb, getting the program's own call stack

`wchan` is the kernel's view ("waiting on a lock"). To learn which lock and why,
you need the **userspace backtrace**: the chain of function calls inside the
program that led to the wait. `gdb` (the GNU debugger) can read that from a live
process.

```sh
gdb -p <pid> -batch -ex 'set pagination off' -ex 'thread apply all bt'
```

Reading that command:
- `-p <pid>` attach to a running process.
- `-batch` run non-interactively and exit (good for scripting; no gdb prompt).
- `-ex '...'` run a gdb command. You can pass several.
- `thread apply all bt` for **every** thread, print its **b**ack**t**race.
- `set pagination off` stop gdb from pausing every screenful.

Things to know before you attach:
- **Attaching pauses the process** for as long as gdb is attached; it resumes
  when gdb detaches. For an already-hung process this is harmless. On a healthy
  production process it causes a brief freeze, so be deliberate.
- **Permissions.** You can normally only attach to your own processes. Some
  systems restrict even that via `/proc/sys/kernel/yama/ptrace_scope`:
  `0` = allowed, `1` = only child processes of the debugger, `2`+ = locked down.
  If attach fails with "Operation not permitted," check that value.
- **A native backtrace shows C functions**, i.e. the *interpreter's* internals
  (for Ruby/Python), not your script. That is enough to see "it is in
  `mutex_lock`" or "it is in `io_wait`," which already tells you lock vs network.
  To get your actual script's file:line, see Part E.

---

## Part E: getting a Ruby-level backtrace (the part that looked like magic)

The C backtrace from Part D shows the Ruby *interpreter's* functions, not your
`.rb` files. To see the Ruby file and line, you make the interpreter print its
own stack. The Ruby C API has a function for exactly this: `rb_backtrace()`,
which prints the current Ruby thread's Ruby-level backtrace.

Two problems and how I solved each:

**Problem 1: where does it print?** `rb_backtrace()` writes to the process's
**standard error (stderr)**, which goes to whatever terminal launched the server,
not to me. So first I redirected that process's stderr into a file.

Background you need: every process has numbered **file descriptors**. By
convention `0` = stdin, `1` = stdout, `2` = stderr. "Writing to stderr" means
"writing to fd 2." If I point fd 2 at a file, error output lands in that file.

Two syscalls do the redirect:
- `open("/tmp/bt.txt", flags, mode)` opens a file and returns a fresh fd number.
- `dup2(newfd, 2)` makes fd 2 become a copy of `newfd`. From now on, writes to
  stderr go to the file.

The magic numbers in my command were just those flags and mode as plain integers
(gdb wanted numbers, not symbols):
- `577` = `O_WRONLY | O_CREAT | O_TRUNC` = open for writing, create if missing,
  empty it first.
- `420` = octal `0644` = normal file permissions (rw-r--r--).

**Problem 2: how do I run code inside the frozen process?** gdb's `call` command
executes a function *inside the target process*. So I can literally call
`open`, `dup2`, and `rb_backtrace` in the live (paused) process.

Putting it together:

```sh
gdb -p <pid> -batch \
  -ex 'set pagination off' \
  -ex 'call (int) dup2((int) open("/tmp/bt.txt", 577, 420), 2)' \
  -ex 'thread 6'  -ex 'call (void) rb_backtrace()' \
  -ex 'thread 7'  -ex 'call (void) rb_backtrace()'
# then just read the file:
cat /tmp/bt.txt
```

Line by line:
1. Redirect the process's stderr (fd 2) to `/tmp/bt.txt`.
2. Select thread 6 (one of the stuck workers; gdb numbers threads, `thread
   apply all bt` shows the numbers).
3. Call `rb_backtrace()` so *that thread* dumps its Ruby stack into the file.
4. Repeat for other threads of interest.

That produced the human-readable chain:
`check_pending_migrations -> Mutex#synchronize -> pg connect -> wait (forever)`.

**Caveat:** calling functions inside a wedged process is mildly risky. You are
running code in a process whose locks may be held, so the call itself could hang
or, rarely, crash the process. Do it when the process is already useless to you
and about to be restarted. Do not do it casually on a healthy production server.

**The easier way, when the tool is installed.** Sampling profilers attach to a
process and print every thread's *language-level* backtrace with no gdb gymnastics:
- Ruby: `rbspy dump --pid <pid>` (or `rbtrace`)
- Python: `py-spy dump --pid <pid>`
- Java: `jstack <pid>`
- Go: send `SIGQUIT` (it prints all goroutine stacks)
- Node: `node --inspect` / `kill -SIGUSR1` then a debugger

I used gdb only because `rbspy` was not installed. If you do this kind of
debugging often, install the profiler for your language; it turns Part D and E
into one command.

---

## Part F: "listening but not answering" (Recv-Q, hang vs refuse)

A crucial network distinction:

- **Connection refused** = nothing is listening on that port. Fast, clean error.
- **Connection hangs** = something accepted the TCP connection but never answered
  at the application level. The client waits, possibly forever.

`ss` (socket statistics) shows both the listeners and their queues:

```sh
ss -tlnp        # t=tcp, l=listening, n=numeric ports, p=show process
```

For a `LISTEN` row, the two queue columns mean:
- **Recv-Q** = number of completed connections waiting for the app to `accept()`
  them (the current backlog in use).
- **Send-Q** = the maximum backlog size.

A healthy server accepts fast, so Recv-Q hovers near 0. **A nonzero, lingering
Recv-Q on a LISTEN socket means the process stopped accepting connections**: it
is alive enough to hold the port but wedged enough to ignore clients. That is the
exact fingerprint of "connects hang instead of refuse." In my case the DB port
showed a backlog of unanswered connections, which pointed straight at a wedged
database before I even looked at the container.

Related quick checks:
- `pg_isready -h HOST -p PORT` for Postgres specifically.
- A real query (`psql ... -c 'select 1'`) to prove the handshake *completes*, not
  just that the port answers. Verify with the strongest signal you can, not the
  weakest.

---

## Part G: forensics for things that already happened (journalctl)

When something crashed or got killed earlier, the live state (`free -h`, `ps`)
is useless: it shows now, not then. You need the log the system wrote *at the
time*. That is the **journal**.

```sh
# kernel messages (OOM killer, hardware, filesystem) since a time
journalctl -k --since "2026-06-16 13:00:00"

# a specific service's logs
journalctl -u docker --since "1 hour ago"
journalctl -u systemd-oomd --since "today"

# follow live
journalctl -kf
```

For an out-of-memory kill, the kernel records both who triggered it and a full
table of every process's memory at that instant:

```sh
# the headline events
journalctl -k --since "13:00" | grep -iE "invoked oom-killer|Out of memory: Killed"

# the biggest memory users at the moment of the kill (rss is in 4KB pages)
journalctl -k --since "13:50:50" --until "13:51:06" \
 | sed -n 's/.*kernel: \[ *\([0-9]*\)\] *[0-9]* *[0-9]* *[0-9]* *\([0-9]*\) .* \([^ ]*\)$/\2 \1 \3/p' \
 | sort -rn | head -12 | awk '{printf "%8.0f MB  pid %-8s %s\n", $1*4/1024, $2, $3}'
```

Two gotchas that confused me at first, worth remembering:
- **The OOM victim is not the cause.** The kernel kills the process with the
  highest "badness" score, which can be tuned per process via `oom_score_adj`.
  Some apps (Claude Code, for one) raise their own score so they get sacrificed
  first to protect your desktop. So the thing that died is often innocent; look
  at the *table* to find what actually ate the memory.
- **Memory pressure tools can kill before RAM hits zero.** On Fedora,
  `systemd-oomd` is active by default and kills a whole cgroup when **swap** use
  passes 90% or memory pressure stays high for ~30s. Also, swap here is `zram`
  (compressed swap that lives in RAM), so heavy swapping eats RAM rather than
  relieving it. Net effect: you can get killed while `free` still shows headroom.
  Check `swapon --show`, `zramctl`, `systemctl is-active systemd-oomd`.

---

## Cheat sheet

| Question | Command(s) |
|----------|-----------|
| Hang or error? Up or down? | `curl -m 5 ...`, `ps aux | grep X`, `ss -tlnp` |
| Where in the pipeline does it die? | the **logs**, especially the line that *should* come next and does not |
| Stale state or reproducible? | does a **cold restart** reproduce it on request #1? |
| Load-time or run-time? | boot the thing in isolation (`bin/rails runner`, `--version`) |
| Spinning or waiting? | `top`/`htop` CPU%, and `/proc/<pid>/task/*/stat` (R vs S vs D) |
| Waiting on what? | `/proc/.../wchan` and `/proc/.../syscall` (futex=lock, poll/epoll=fd, D=disk) |
| The exact stuck code line | `gdb -p <pid> -ex 'thread apply all bt'`; language profiler for the script-level stack |
| Listening but not answering? | `ss -tlnp` with a nonzero **Recv-Q** on a LISTEN socket |
| What happened in the past (OOM/crash) | `journalctl -k` / `journalctl -u <unit>`, not current `free` |
| What ate the memory | the kernel's OOM process table in `journalctl -k`, sorted by rss |

---

## Worked example: the incident this came from

1. **Symptom:** browser hangs on one URL. Reframed by the user: hangs on every
   page, server is "running."
2. `curl -m` + `ps`: requests hang, puma is up. -> blocks during handling.
3. Log: `Started` present, `Processing by` absent. -> dies in middleware, before
   app code. Also: every fresh boot hung on request #1. -> reproducible.
4. `bin/rails runner`: boots fine. -> request-time problem, not load-time.
5. `/proc/<pid>/task/*`: all threads `S`, parked on `futex`/`poll`, none `R`. ->
   deadlock, not a loop or a slow query.
6. `gdb ... thread apply all bt`: a worker blocked in `mutex_lock`; another in
   `io_wait` with no timeout (waiting on a socket forever).
7. `rb_backtrace()` via the dup2 trick: stuck path is `check_pending_migrations
   -> Mutex#synchronize -> PG connect -> wait`. One worker holds the migration
   mutex while its DB connect hangs; all other workers pile up on that mutex.
   -> the database is the problem.
8. `database.yml` says port 5433; `ss -tln` shows 5433 listening with a backlog
   of unanswered connections. -> something there but wedged.
9. `docker ps -a`: the Postgres container `workbench-db-1` is `Exited (255)`.
   Root cause.
10. Fix: `docker start workbench-db-1`; verify with `pg_isready`, a real `select
    1`, and Recv-Q back to 0; restart `bin/dev`.
11. Why it happened: `journalctl -k` showed the OOM-killer ran twice, taking down
    the container, triggered by several multi-GB processes filling a 30GB box
    with zram swap.

The fix was three seconds of typing. Finding it was the whole job, and the method
above is what found it.
