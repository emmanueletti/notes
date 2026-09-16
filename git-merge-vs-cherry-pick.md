# Git: integrating branches — fast-forward merge vs cherry-pick

> The recurring question: *"I have a feature branch with N commits — how do I get
> them onto `main`?"* The answer depends on whether you want to **move** the branch
> (keep the same commits) or **copy** commits (make new ones). See also
> [git-checkout-switch-restore.md](./git-checkout-switch-restore.md).

---

## First, check the relationship

```bash
git merge-base --is-ancestor main HEAD && echo "ff possible" || echo "diverged"
```

- If `main` **is an ancestor** of your branch (main hasn't moved since you branched)
  → a **fast-forward** is possible. This is the common, clean case.
- If they've **diverged** (commits landed on main meanwhile) → no fast-forward; you
  need a real merge or a rebase.

---

## Fast-forward merge — move the branch, linear history

When `main` is an ancestor of the branch, git doesn't create a merge commit — it
just **slides `main`'s pointer up to the branch tip**. Same commits, **same SHAs**,
one straight line.

```bash
git switch main
git merge --ff-only refactor/my-branch
```

`--ff-only` is also a **safety flag**: it *refuses* (errors out) if a fast-forward
isn't possible, instead of silently creating a merge commit. Use it whenever you
specifically want linear history.

**Result is a single linear chain — looks like the work was done directly on main:**
```
* 0ff7349  last commit        (main)
* ...
* 0882589  first commit
* 62f5b97  (previous main)
```

### "Without a branch"
The commit graph is fully linear after a fast-forward — nothing records that a
branch ever existed. But the branch **ref/label** still points at the same tip
until you delete it:
```bash
git branch -d refactor/my-branch                 # local
git push origin --delete refactor/my-branch      # remote (if it was pushed)
```

---

## `--no-ff` — force a merge commit (the "bubble")

Some teams *want* a merge commit to mark "this was a feature/PR":
```bash
git merge --no-ff refactor/my-branch
```
```
*   9a1b2c3  Merge branch 'refactor/my-branch'   (main)
|\
| * 0ff7349  last commit
| * 0882589  first commit
|/
* 62f5b97
```
Trade-off: preserves the branch boundary + groups the work, at the cost of a
non-linear graph.

---

## Cherry-pick — copy commits (new SHAs)

`cherry-pick` **replays** commits as **brand-new commits** (new SHAs; it keeps the
original *author* but a new committer/date). The originals stay where they were, so
you get *duplicates*. It supports **bulk ranges** — no need to go one-by-one:

```bash
git switch main
git cherry-pick 0882589^..0ff7349        # all commits from first..last, inclusive
git cherry-pick main..refactor/my-branch # shorthand: everything on the branch not on main
```

### ⚠️ The gotcha: `A..B` excludes A (start is exclusive)
```bash
git cherry-pick 0882589..0ff7349    # ⚠️ SKIPS 0882589 — picks one too few
git cherry-pick 0882589^..0ff7349   # ✅ `^` = parent, shifts start to INCLUDE 0882589
```
`main..branch` "just works" because `main` is already the excluded base.

### If a conflict hits mid-range
```bash
# fix files, then:
git add -A
git cherry-pick --continue   # resume the rest of the range
# git cherry-pick --abort     # undo the whole thing
# git cherry-pick --skip      # drop just the current commit
```

### Useful flags
- `-x` → appends `(cherry picked from commit <sha>)` to each message (traceability
  for backports).
- `-n` / `--no-commit` → apply the whole range to the index **without committing**,
  so you can collapse it into one commit: `git cherry-pick -n main..branch && git commit`.

---

## When to use which

| Goal | Tool |
|---|---|
| Move a whole branch that's **already based on** the target — no duplicates | `git merge --ff-only` (or rebase, then ff) |
| Copy **specific** commits / backport to another branch / branch has **diverged** | `git cherry-pick A^..B` |
| Want a merge-commit marker for the PR | `git merge --no-ff` |
| Collapse the branch into **one** commit | `git merge --squash` then `git commit` (or GitHub "Squash and merge") |

**Rule of thumb:** cherry-pick is for *copying* commits; merge/rebase is for *moving*
a branch. Reaching for cherry-pick to "move" a branch that's already on main just
creates duplicate commits with new SHAs — usually not what you want.

---

## Rebase (the third option, briefly)

Replays your branch's commits onto a new base — linear, but **new SHAs** (like
cherry-pick, but for the whole branch + it moves the branch ref):
```bash
git rebase main refactor/my-branch     # re-base the branch onto current main
# then fast-forward main onto it:
git switch main && git merge --ff-only refactor/my-branch
```
Use when main moved and you still want a **linear** history (no merge bubble).

---

## GitHub's three merge buttons map to all of this
- **Create a merge commit** = `--no-ff` (bubble, keeps all commits)
- **Squash and merge** = collapse the branch into **one** new commit on main
- **Rebase and merge** = replay commits onto main, linear, **new SHAs**

---

## Cheat sheet
```bash
# move a branch onto main, clean & linear (main hasn't moved):
git switch main && git merge --ff-only <branch>
git branch -d <branch>                       # tidy up the label

# copy a range of commits somewhere (note the ^ to include the first):
git cherry-pick <first>^..<last>

# main moved and you want linear anyway:
git rebase main <branch> && git switch main && git merge --ff-only <branch>
```
