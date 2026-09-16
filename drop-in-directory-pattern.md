# Drop-In Directory Pattern (the `.d` / dispatcher pattern)

A way to compose configuration or behavior out of many small files instead of
one long file. A small dispatcher iterates a directory and runs/sources each
fragment in lexicographic order.

Concrete example built in workbench: `.githooks/pre-commit` is a dispatcher
that iterates `.githooks/pre-commit.d/*.sh` (standardrb, herb, biome,
bundler-audit, importmap-audit). Adding a new check means dropping a new file
in the directory; no editing of the dispatcher.

## What it's called

Knowing the vocabulary makes it searchable.

- Drop-in directory (most common name)
- `.d` directory (after the trailing `.d` naming convention)
- Config fragments / snippet directory
- Modular configuration
- `run-parts` pattern (after the Debian utility)

## See it in the wild on Linux

Your machine already runs this pattern in dozens of places.

```
ls /etc/cron.d/              # one file per cron job
ls /etc/cron.daily/          # scripts run by cron via run-parts
ls /etc/sudoers.d/           # sudo rules in fragments
ls /etc/profile.d/           # bash sources every *.sh on login
ls /etc/logrotate.d/         # one rotation policy per package
ls /etc/apt/sources.list.d/  # one repo per file
ls /etc/systemd/system/      # look for *.d/ override directories
```

`/etc/profile.d/` is the closest analogue to the workbench pre-commit hook.
The for-loop in `/etc/profile` that sources every `*.sh` in `profile.d/` is
about 5 lines of bash. Read `/etc/profile` to see the dispatcher.

## Canonical implementation: `run-parts`

Debian and Ubuntu ship `run-parts`, the textbook reference dispatcher. It
powers `cron.daily`, `cron.weekly`, etc.

- `man run-parts` is short and excellent
- Source: `/usr/bin/run-parts` (a small Perl script worth reading)

Things `run-parts` does that any drop-in dispatcher should consider:

- Sorts under `LANG=C` to force POSIX lexicographic order. This is why people
  use `00-`, `10-`, `20-` numeric prefixes; without forced locale, sort order
  can vary by system.
- Skips backup files (`*~`, `*.bak`, `*.dpkg-old`).
- Honors a "disabled" convention so you can park a fragment without deleting
  it (e.g. add a `.disabled` suffix the glob skips).

`man systemd.unit` has the best modern treatment. Search for "Drop-In" to read
about override directories (`<unit>.d/`), priority resolution, and merge
semantics.

## Design principle

This is the Open/Closed Principle applied to configuration:

- **Open for extension**: drop a new file
- **Closed for modification**: do not edit existing files

Same idea as plugin architectures, expressed in the filesystem instead of in
code.

Three properties make a good drop-in system:

1. **Lexicographic ordering by filename.** Predictable and visible. Numeric
   prefixes (`10-`, `20-`) leave room to wedge new things in later without
   renaming.
2. **Isolation.** Each fragment should make sense on its own. The dispatcher
   may give fragments shared context (in workbench: `$STAGED`, `$RUBY`,
   `$ERB`, etc.) but fragments should not depend on what earlier fragments
   did.
3. **Discoverability via filename.** The filename should tell you what is
   inside. `40-bundler-audit.sh` is better than `40-security.sh`.

## When to reach for it

- You have 5+ stable items being dispatched, OR
- You add/remove items frequently, OR
- Different items might be owned/modified by different people

Below that threshold, one file is usually clearer.

For pre-commit hooks specifically: this pattern is also exactly what tools
like Lefthook and Overcommit give you for free, expressed in YAML, plus
parallelism and per-check config. If you find yourself building more
dispatcher infrastructure (parallel execution, conditional skip rules, file
globs), that is the signal to adopt one of those frameworks.

## Reading

- `man run-parts` (canonical dispatcher)
- `man systemd.unit` (search "Drop-In")
- Debian Policy Manual section 10.7 (conffile and snippet conventions)
- *The Art of Unix Programming* by Eric S. Raymond, Chapter 4 (modularity).
  Free online.

## Hands-on exercise

Write a one-off `/etc/cron.d/` entry. Example: a job that empties `~/tmp`
nightly. You experience the pattern from the *other* side: you write the
fragment, the system supplies the dispatcher. Doing it from both sides makes
it click.

## Reference: the workbench dispatcher

`.githooks/pre-commit` (~25 lines):

```bash
#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")"
source "$DIR/lib/staged.sh"
compute_staged

# early exit if nothing relevant staged
if [ -z "$RUBY" ] && [ -z "$ERB" ] && [ -z "$WEB" ] && \
   [ -z "$GEMFILE_LOCK" ] && [ -z "$IMPORTMAP" ]; then
  exit 0
fi

# safety net so linters only see staged content
if ! git diff --quiet; then
  git stash push --keep-index --include-untracked --quiet --message "pre-commit-hook"
  trap 'git stash pop --quiet 2>/dev/null || echo "..."' EXIT
fi

for script in "$DIR/pre-commit.d/"*.sh; do
  [ -r "$script" ] || continue
  source "$script"
done

echo "$STAGED" | xargs git add
```

Each fragment in `pre-commit.d/` follows the same shape:

```bash
# 10-standardrb.sh
[ -n "$RUBY" ] || return 0
echo "→ standardrb"
echo "$RUBY" | xargs bundle exec standardrb --fix
```

Note the `return 0` (not `exit 0`): in a sourced script, `exit` would kill
the dispatcher. `return` only exits the source statement.
