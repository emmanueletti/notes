# psql cheatsheet

### Find the user/database to connect with

Docker/Kamal accessory container — check what it was booted with:

`docker exec <container> env | grep POSTGRES`

Rails project — check `config/database.yml` (per environment) or `docker-compose.yml` locally (`POSTGRES_USER`/`POSTGRES_DB` env block)

Already connected, forgot what you're on — `\conninfo` inside psql

No idea, just exploring — connect to the default `postgres` maintenance db, then `\l` for databases and `\du` for roles/users


### Connect

`psql -U <user> -d <database>` — local, unix socket

`psql -h <host> -p <port> -U <user> -d <database>` — force TCP (needed when running from a container that doesn't share the target's socket)

`psql postgres://<user>:<password>@<host>:<port>/<database>` — full connection string

Exec straight into a running Docker/Kamal accessory container (uses its own local socket, no `-h` needed):

`docker exec -it <container-name> psql -U <user> -d <database>`


### List things

`\l` (or `\list`) — list databases. `\l+` for sizes/extra detail

`\dt` — list tables in current schema. `\dt+` for sizes

`\d <table>` — describe a table (columns, types, indexes, constraints)

`\d+ <table>` — same, plus storage/stats info

`\du` — list roles/users and their privileges

`\dn` — list schemas

`\di` — list indexes

`\df` — list functions


### Switch context

`\c <database>` — connect to a different database (same session)

`\c <database> <user>` — connect as a different user too

`\conninfo` — show current connection details (host, port, user, db)


### Query workflow

`\x` — toggle expanded output (one column per line instead of a wide table) — good for wide rows

`\timing` — toggle showing query execution time after each statement

`\e` — open `$EDITOR` to write/edit the current query buffer

`\i <file>` — run SQL from a file

`\watch <seconds>` — re-run the last query every N seconds


### Writing and running SQL

Just type it, end with `;`, hit enter. Multi-line is fine — psql waits for the `;` before running anything, prompt changes to `->` on continuation lines:

```sql
SELECT id, email
FROM users
WHERE created_at > now() - interval '7 days';
```

Forgot the `;`? Just type it on its own line and hit enter, or `\g` if you already hit enter.

Made a typo and the query's getting long? `\e` opens the current buffer in `$EDITOR` — write it properly, save, quit, psql runs it.

Filter/sort/join exactly like TablePlus's query tab does under the hood, e.g.:

```sql
SELECT u.email, count(o.id) AS orders
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id
ORDER BY orders DESC
LIMIT 10;
```

`\x auto` — expanded display only when a row would be too wide for the terminal (best default, leave it on)

`\pset pager always` — force long results through `less` (arrow keys/`q` to quit) instead of dumping to the terminal

In the `less` pager (also what shows `--More--`): `space`/`f` page down, `b` page back up, `d`/`u` half-page down/up, `/text` search forward, `q` quit


### Transactions — the big habit shift from a GUI

TablePlus usually asks "commit?" before writing changes stick. **psql has no such prompt** — by default every statement autocommits the instant you hit enter. An `UPDATE`/`DELETE` with no `WHERE` is immediately permanent.

Wrap anything you're not 100% sure about:

```sql
BEGIN;
UPDATE users SET plan = 'pro' WHERE id = 42;
-- check it looks right:
SELECT id, plan FROM users WHERE id = 42;
```

Then either:

`COMMIT;` — make it permanent

`ROLLBACK;` — undo everything since `BEGIN`

While inside a transaction, one failed statement (e.g. a typo, a constraint violation) puts the whole transaction in an aborted state — every command after it errors with `current transaction is aborted, commands ignored until end of transaction block` until you `ROLLBACK`. That's normal, just roll back and start the transaction over; nothing was applied.

For a genuinely risky `UPDATE`/`DELETE`, always `SELECT` the same `WHERE` clause first to see exactly which rows match before you touch them.


### Copy data in/out

`\copy (SELECT ...) TO 'file.csv' WITH CSV HEADER` — export query results to CSV, runs client-side (works even without server filesystem access)

`\copy <table> FROM 'file.csv' WITH CSV HEADER` — import CSV into a table


### Dump / restore (shell, not psql)

`pg_dump -U <user> -d <database> -F c -f backup.dump` — custom-format dump (compressed, restorable selectively)

`pg_dump -U <user> -d <database> > backup.sql` — plain SQL dump

`pg_restore -U <user> -d <database> backup.dump` — restore a custom-format dump

`psql -U <user> -d <database> < backup.sql` — restore a plain SQL dump

Inside a container: prefix with `docker exec <container> ...` and redirect on the host side, e.g. `docker exec <container> pg_dump -U <user> -d <database> > backup.sql`


### See what's running right now (load, toxic queries)

Every active connection, what it's doing, how long it's been at it:

```sql
SELECT pid, usename, datname, state, wait_event_type, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

Just the slow ones (running longer than 5s — the classic "toxic query" find):

```sql
SELECT pid, usename, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state != 'idle' AND now() - query_start > interval '5 seconds'
ORDER BY duration DESC;
```

`idle in transaction` connections — a query finished but the app never committed/rolled back. These hold locks and don't show up as "running" but are often the actual problem (usually a Rails connection leak, a debugger breakpoint mid-transaction, or a crashed process):

```sql
SELECT pid, usename, now() - state_change AS idle_for, query AS last_query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
ORDER BY idle_for DESC;
```

Connection count by state, vs `max_connections` — are you close to running out:

```sql
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;
SHOW max_connections;
```


### Kill a toxic query or connection

Cancel just the running query, connection stays open (gentler, like Ctrl-C for that backend):

```sql
SELECT pg_cancel_backend(<pid>);
```

Kill the whole connection (use when cancel doesn't work, or it's an idle-in-transaction connection holding locks):

```sql
SELECT pg_terminate_backend(<pid>);
```


### Who's blocking who (lock contention)

When something's hanging and you suspect it's waiting on a lock rather than actually slow:

```sql
SELECT blocked.pid AS blocked_pid, blocked.query AS blocked_query,
       blocking.pid AS blocking_pid, blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks ON blocked_locks.pid = blocked.pid AND NOT blocked_locks.granted
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid AND blocking_locks.granted
JOIN pg_stat_activity blocking ON blocking.pid = blocking_locks.pid;
```

The `blocking_pid` there is almost always what you actually want to `pg_terminate_backend` — killing the blocked one just leaves the real culprit sitting there.


### Common / problematic query patterns over time

Needs the `pg_stat_statements` extension (check if it's on: `SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_statements';`, enable with `CREATE EXTENSION pg_stat_statements;` if allowed on your instance — usually off by default on managed/accessory Postgres unless explicitly configured).

Most time spent in aggregate — usually your real optimization target, not the single slowest query:

```sql
SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

Slowest on average (the classic missing-index suspects):

```sql
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

Called the most (even if each one's fast, N+1s live here):

```sql
SELECT query, calls FROM pg_stat_statements ORDER BY calls DESC LIMIT 10;
```


### Table health — sequential scans, cache hit ratio

Tables getting hammered with sequential scans instead of index scans — likely a missing index:

```sql
SELECT relname, seq_scan, idx_scan, seq_scan - idx_scan AS diff
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY diff DESC
LIMIT 10;
```

Cache hit ratio — should be well above 99% for a healthy instance; low means the working set doesn't fit in memory:

```sql
SELECT sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0) AS cache_hit_ratio
FROM pg_statio_user_tables;
```

Biggest tables (including indexes/toast), where bloat/vacuum problems tend to show up first:

```sql
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
```


### Misc

`\q` — quit

`\?` — help on meta-commands (the backslash ones)

`\h <SQL command>` — help on SQL syntax, e.g. `\h CREATE TABLE`

`\!` — drop to a shell without leaving psql

`\g` — re-run the last query (like pressing enter again)
