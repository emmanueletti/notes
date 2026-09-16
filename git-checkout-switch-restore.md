# Git: `checkout` vs `switch` vs `restore`

> TL;DR — `git checkout` is an old **overloaded** command that did two unrelated
> jobs: move between branches *and* restore file contents. Git 2.23 (2019) split it
> into two focused commands:
>
> | Job | Old (overloaded) | New (focused) |
> |---|---|---|
> | Change / create branches | `git checkout` | **`git switch`** |
> | Restore / discard file contents | `git checkout -- file` | **`git restore`** |
>
> `checkout` still works and isn't deprecated, but `switch` + `restore` each do
> *one* thing clearly, so they're the better habit. New rule of thumb:
> **`switch` for branches, `restore` for files, leave `checkout` behind.**

---

## The three places a file's content lives

Everything below makes sense once you hold this picture:

1. **HEAD** — the last commit (the committed version)
2. **the index** — the staging area (what's staged for the next commit)
3. **the working tree** — the actual files on disk you edit

`switch` moves **HEAD** (which branch you're on). `restore` copies content
between those three places.

---

## `git switch` — branches only

Moves `HEAD` to another branch and updates the working tree. It can *only* touch
branches, so it can never clobber a file by accident.

```bash
git switch main                 # go to an existing branch
git switch -c feature           # -c = create + switch (was: checkout -b)
git switch -                     # back to the previous branch (toggle)
git switch --detach abc123       # intentionally detach HEAD at a commit
git switch -c hotfix main        # create `hotfix` starting from main
```

**Safety win over checkout:** `git checkout <sha>` *silently* drops you into
"detached HEAD" (a common way to make commits that aren't on any branch).
`git switch <sha>` **refuses** unless you pass `--detach` — no accidental detach.

---

## `git restore` — file contents

**Mental model: copy *from a source → into a target*.**

- **target** — `--worktree` (`-W`, the default) and/or `--staged` (`-S`)
- **source** — `--source=<commit>`; if omitted, the default depends on the target:
  - restoring the **worktree** (default) → source is the **index**
  - using **`--staged`** → source is **HEAD**

### Common recipes

| Command | from → to | What it does |
|---|---|---|
| `git restore file` | index → worktree | **discard unstaged edits** to `file` |
| `git restore .` | index → worktree | discard *all* unstaged changes |
| `git restore --staged file` | HEAD → index | **unstage** `file` (edits on disk stay) |
| `git restore --staged --worktree file` | HEAD → index + worktree | **nuke all changes** to `file`, back to HEAD |
| `git restore --source=HEAD~2 file` | that commit → worktree | pull in `file` as it was 2 commits ago |
| `git restore -p file` | (interactive) | discard only *some* hunks |

### The two you'll use most
```bash
git restore --staged file    # un-stage (the thing `git status` suggests). SAFE.
git restore file             # throw away my unstaged edits. DESTRUCTIVE.
```

### Maps to the old commands
```bash
git restore file                  ≡  git checkout -- file          # discard worktree changes
git restore --staged file         ≡  git reset HEAD file           # unstage
git restore --source=abc123 file  ≡  git checkout abc123 -- file   # grab a file from another commit
```
So `restore` consolidates file-restoration that used to be split confusingly
between `checkout` and `reset`.

---

## `git checkout` — the legacy, overloaded command

Still works; you'll see it everywhere out of muscle memory. Equivalences:

```bash
git checkout main            ≡  git switch main
git checkout -b feature      ≡  git switch -c feature
git checkout -               ≡  git switch -
git checkout abc123          ≈  git switch --detach abc123   (but checkout detaches silently)
git checkout -- file         ≡  git restore file
git checkout abc123 -- file  ≡  git restore --source=abc123 file
```

The footgun it's famous for: `git checkout <name>` switches branches, but
`git checkout <file>` **silently discards** your changes to that file — same verb,
very different (and destructive) outcome. That ambiguity is exactly why the split
happened.

---

## Quick reference / cheat sheet

```bash
# --- move around ---
git switch <branch>              # change branch
git switch -c <branch>           # create + change
git switch -                     # previous branch

# --- staging ---
git restore --staged <file>      # unstage (keep edits)        [safe]

# --- discard changes ---
git restore <file>               # drop unstaged edits         [destructive]
git restore --staged --worktree <file>   # drop staged + unstaged, back to HEAD

# --- recover an old version of a file (without changing branch) ---
git restore --source=<commit> <file>
```

## Safety summary
- `git restore <file>` and `git restore --worktree …` **permanently** drop
  uncommitted working-tree changes — **not** recoverable via reflog. No prompt.
- `git restore --staged <file>` is **safe** — it only un-stages; your file on disk
  is untouched.
- Prefer `git switch` over `git checkout` so you can never detach HEAD or clobber a
  file by accident.

---

## See also
- [git-merge-vs-cherry-pick.md](./git-merge-vs-cherry-pick.md) — moving/integrating
  commits between branches (fast-forward merge vs cherry-pick vs rebase).
