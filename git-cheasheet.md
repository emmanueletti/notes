# Git cheatsheet

### Unstage staged files without deleting them

`git restore --staged .`


### Fast forward main to the HEAD of a feature branch

Intead of merging in the branch to main. Useful when you want to keep a clean git history and the feature branch has not diverged from main.

`git switch main && git merge --ff-only <branch-name>`

`--ff-only `: refuse (error, no-op) if a fast-forward isn't possible

or one-liner

`git update-ref refs/heads/main <branch-name>`


### Switch a remote from HTTPS to SSH

Edits local `.git/config` only; no commits touched, nothing on GitHub changes.

`git remote set-url origin git@github.com:<owner>/<repo>.git`

Changes the URL of the existing origin remote. Same remote name, different protocol


### Align a markdown table

Escape any literal `|` inside a cell with `\|`, otherwise it is read as a column separator and breaks the row.

Align in Helix with the `&` (align_selections) operator:

1. `mip` — select the whole table paragraph
2. `s\|<ret>` — select on `\|`, one cursor per pipe (pipe escaped in the regex prompt)
3. `&` — align all cursors, padding cells so pipes line up

Fix the separator row after aligning:

1. `,` — drop the multi-selection
2. move to the separator row, `x` — select the line
3. `s <ret>` — select on space
4. `r-` — replace each space with `-`

`s\|` here is Helix's select-on-regex, unrelated to the `\|` you escape inside a table cell — both just happen to escape the pipe.


### Change every occurrence of a word (Helix)

1. `%` — select the whole file
2. `s` — select on regex, type the word, `<ret>` — one cursor per match
3. `c` — delete matches and drop into insert, type replacement, `<esc>`

Fast alt: put cursor on the word, `*` to load it as the search pattern, `%s<C-r>/<ret>` to select every match, then `c`.

Shell alt (no editor): `sed -i 's/old/new/g' <file>`


### Create multiple cursors (Helix)

- `C` — add cursor on line below (`Alt-C` for above)
- `s<regex><ret>` — split selection into one cursor per match
- `S<regex><ret>` — split selection on the regex (cursors between matches, e.g. `,` to split a list)
- `%` then `s` — select whole file, then a cursor per match across it
- `*` then `n` — set search to selection, `n` extends to next; add each hit

Manage the set:

- `,` — collapse back to a single cursor
- `Alt-,` — remove the primary cursor only
- `(` / `)` — rotate which cursor is primary
- `Alt-(` / `Alt-)` — rotate the selection contents under the cursors


### Add cursors up and down (Helix)

- `C` — add a cursor on the line below
- `Alt-C` — add a cursor on the line above

Repeat to stack more. Cursors keep the same column. `,` collapses back to one cursor. Handy for editing aligned columns or list items.


### Step through matches one by one (Helix)

Load a word into the search register, then walk its matches.

1. select the word — `miw` (or `w`)
2. `*` — put selection into search register `/`
3. `n` — jump forward to next match, `N` — jump back to previous

Each `n`/`N` moves the single selection to that match (replace, not add). Use this to eyeball hits one at a time.

Want to grow one big selection spanning matches instead? Enter extend mode first: `v`, then `n`/`N` extend rather than jump.

Want a cursor on every match at once (not one by one)? `%` then `s<C-r>/<ret>`, or after `*` use `s` inside a `%` selection.
