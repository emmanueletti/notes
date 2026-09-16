# Helix editor cheatsheet

## Actions

> Notation: `C-` Ctrl · `A-` Alt · `S-` Shift · capital letter = Shift+letter
>
> These are Helix defaults. Custom shortcuts live in `config.toml`.

### Line open and edit

| Key           | Action                                   |
| ------------- | ---------------------------------------- |
| `o` / `O`     | open auto-indented line below / above    |
| `x`           | select line; repeat extends line-by-line |
| `J`           | join lines                               |
| `>` / `<`     | indent / dedent selection                |
| `=`           | format selection (LSP)                   |
| `c`           | change (delete + insert)                 |
| `R`           | replace selection with yank reg          |
| `C-a` / `C-x` | increment / decrement number             |

### Multiple cursors

| Key         | Action                                            |
| ----------- | ------------------------------------------------- |
| `C` / `A-C` | add cursor next / prev line                       |
| `s`         | select regex in selection -> one cursor each      |
| `S`         | split selection on regex (keeps the between-bits) |
| `%`         | select whole file                                 |
| `A-s`       | split selection into one cursor per line          |
| `K` / `A-K` | keep / remove selections matching regex           |
| `&`         | align cursors                                     |
| `,`         | drop secondary cursors (keep primary)             |
| `;` / `A-;` | collapse selection to cursor / flip anchor        |
| `*`         | set search from selection                         |
| `n` / `N`   | next / prev match                                 |

### Tree-sitter selection

Structural (grow/shrink/hop by syntax node). To _select_ a whole
function/arg/type, use the textobjects in [Match mode](#match-mode-m).

| Key           | Action                                   |
| ------------- | ----------------------------------------- |
| `A-o` / `A-i` | expand / shrink selection to syntax node |
| `A-n` / `A-p` | select next / prev sibling node          |
| `]f` / `[f`   | goto next / prev function                |
| `]a` / `[a`   | goto next / prev argument / parameter    |
| `]t` / `[t`   | goto next / prev type (class)            |
| `]c` / `[c`   | goto next / prev comment                 |
| `]T` / `[T`   | goto next / prev test                    |

Spam `A-o` to climb: word -> argument -> call -> statement -> block.

### Match mode `m`

Textobjects (`mi` = inside, `ma` = around) are tree-sitter powered — they select
whole functions, args, and types, not just brackets.

| Key           | Action                                    |
| ------------- | ------------------------------------------ |
| `mi(` / `ma(` | inside / around brackets (also `{ [ < "`) |
| `miw` / `mip` | word / paragraph                          |
| `mif` / `maf` | inside / around function                  |
| `mia` / `maa` | inside / around argument / parameter      |
| `mit` / `mat` | inside / around type (class)              |
| `mic` / `miT` | comment / test                            |
| `mm`          | jump to matching bracket                  |
| `ms(`         | surround selection with `()`              |
| `md(`         | delete surround                           |
| `mr(){`       | replace surround `(` with `{`             |

### Space menu (LSP and pickers)

| Key                   | Action                            |
| --------------------- | ---------------------------------- |
| `Space f`             | file picker                       |
| `Space b`             | buffer picker                     |
| `Space /`             | global search (ripgrep)           |
| `Space k`             | hover docs                        |
| `Space r`             | rename symbol                     |
| `Space a`             | code action                       |
| `Space s` / `Space S` | symbol picker / workspace symbols |
| `Space d`             | diagnostics picker                |
| `Space y` / `Space p` | system clipboard yank / paste     |

### Goto and jumplist

| Key                 | Action                                          |
| ------------------- | ------------------------------------------------ |
| `gd` `gr` `gy` `gi` | definition / references / type / implementation |
| `gg` / `ge`         | file top / bottom                               |
| `gh` / `gl`         | line start / end                                |
| `C-o` / `C-i`       | jump back / forward                             |
| `gf`                | goto file under cursor                          |

### Windows

Splits, plus opening picker results into a split. All native `C-w` — use the
Helix defaults (no custom split binds).

| Key               | Action                             |
| ----------------- | ------------------------------------ |
| `C-w v` / `C-w s` | vertical / horizontal split        |
| `C-w q`           | close split                        |
| `C-w h/j/k/l`     | move between splits                |
| `C-v` (in picker) | open selection in vertical split   |
| `C-s` (in picker) | open selection in horizontal split |
| `C-t` (in picker) | toggle preview                     |

### Case, repeat, macro

| Key                 | Action                |
| ------------------- | ---------------------- |
| `~`                 | toggle case           |
| `` ` `` / `` A-` `` | to lower / upper case |
| `.`                 | repeat last insert    |
| `A-.`               | repeat last `f` / `t` |
| `Q` / `q`           | record / replay macro |

### Shell outs

Each key is the quick form of a typable `:` command. Run per selection.

| Key    | `:` command      | Action                                             |
| ------ | ---------------- | ---------------------------------------------------- |
| `\|`   | `:pipe`          | pipe selection through cmd, replace with stdout    |
| `A-\|` | `:pipe-to`       | pipe selection to cmd, discard output (keep text)  |
| `!`    | `:insert-output` | run cmd (no stdin), insert output before selection |
| `A-!`  | `:append-output` | run cmd, insert output after selection             |

(`:sh` runs a command and touches the buffer not at all.)

Examples: select lines, `\|` `sort` `Enter` — replace with sorted. `!` `date`
`Enter` — drop today's date before the cursor.

### Must-have LSPs

Mirrors `languages.toml`. Install these so `gd`, completion, format, and
diagnostics actually work.

| Server                   | Handles                            | Install                                 |
| ------------------------ | ------------------------------------ | ------------------------------------------ |
| `ruby-lsp`               | Ruby: nav, completion, format      | `gem install ruby-lsp`                  |
| `standardrb`             | Ruby: lint / style                 | `gem install standard`                  |
| `herb-language-server`   | ERB (HTML + Ruby)                  | `npm i -g @herb-tools/language-server`  |
| `emmet-language-server`  | HTML / ERB expansions              | `npm i -g @olrtg/emmet-language-server` |
| `marksman`               | Markdown: links, TOC, `gd`         | `brew install marksman`                 |
| `efm-langserver`         | generic lint bridge (markdownlint) | `brew install efm-langserver`           |
| `markdownlint-cli2`      | Markdown lint (fed via efm)        | `npm i -g markdownlint-cli2`            |
| `prettier`               | Markdown / web format              | `mise use -g npm:prettier`              |
| `hx-lsp`                 | snippets + custom code actions     | `cargo install hx-lsp`                  |
| `docker-language-server` | Dockerfile                         | see docker-language-server releases     |
| `sourcekit-lsp`          | Swift                              | bundled with Xcode / Command Line Tools |

Check what Helix sees for the current file with `:lsp-workspace-command` /
`hx --health <lang>`.

### Notes

- Motions **select** — `w` `b` `e` `f` `t` all extend a selection, so no need to
  prefix a verb. Chain: `f;` selects to next `;`, then `d`.
- Plain `y` / `p` use Helix's internal register, NOT the system clipboard. Use
  `Space y` / `Space p` for the macOS clipboard.
- After `gd` (goto def), bounce back with `C-o`.
- `,` removes secondary cursors; `A-,` removes the _primary_ one.

## Workflow

### Recipes

#### Select with a motion, skip `v`

Helix has no vim-style "press `v` to start selecting" step — motions extend a
selection on their own.

1. `f;` — selects from cursor up to and including next `;` (no `v` needed)
2. `d` — delete it

Same deal for `t`, `w`, `b`, `e`, etc. Selection collapses back to a cursor
after the next edit or `Esc`.

#### Jump straight to a line number

- `23G` — go to line 23 (count + `G`)
- `23gg` — same (count + `gg`)
- `G` / `gg` — last line / first line (no count)
- `:23` `Enter` — typable-command form
- `zz` after landing — center the line in view

#### Split a block into per-line cursors

1. Select the lines (`x` repeat, or `%` for whole file)
2. `A-s` — one cursor per line
3. Edit — applies to every line at once

(Break a single line in two: `a` then `Enter`.)

#### Rename every occurrence of a word in a file

Dumb text (regex):

1. `%` — select whole file
2. `s` `foo` `Enter` — cursor on every `foo`
3. `c` `bar` `Esc` — change all
4. `,` — collapse cursors

Semantic (LSP-aware, respects scope): cursor on symbol, `Space r`, type new
name.

#### Rename every occurrence within a selection

Same as above, but scope the region instead of the whole file:

1. Select the region (`mif` fn body, `mip` paragraph, `x` for lines, or manual)
2. `s` `foo` `Enter` — cursor on every `foo` in the selection
3. `c` `bar` `Esc` — change all
4. `,` — collapse cursors

#### Align a markdown table

1. Select the table rows (`x` repeat over them)
2. `s` `\|` `Enter` — selection on every `|`
3. `&` — align them into columns

#### Picking a repeat: dot, alt-dot, or macro

| Want to repeat...                                        | Use                          |
| ---------------------------------------------------------- | ------------------------------ |
| just the last insert (typed text)                        | `.`                          |
| the last `f` / `t` / `F` / `T` jump                      | `A-.`                        |
| a multi-step sequence (motion + edit + motion + edit...) | macro (`Q` record, `q` play) |

`.` and `A-.` only ever replay ONE thing each, no setup needed. Macro is for
chaining several actions together, at the cost of recording it first.

#### Record and play a macro

1. `Q` — start recording (do edits + a motion to the next target)
2. `Q` — stop recording
3. `q` — replay once; `5q` replays 5x

#### Append text to the end of every line

1. Select the lines (`x` repeat)
2. `A-s` — one cursor per line
3. `A` — insert at each line end
4. Type the text, `Esc`

#### Change inside quotes and brackets

1. `mi"` (or `mi(`, `mi{`, `mi[`) — select inside
2. `c` — change it, type replacement

#### Wrap a selection in brackets and quotes

1. Select the text (motion, `miw`, `x`, ...)
2. `ms)` — wrap in `()` (`ms"` quotes, `ms}` braces)

#### Comment out a block

1. Select the lines (`x` repeat)
2. `C-c` — toggle comments (default; remapped to `C-/` in this config)

#### Sort selected lines

1. Select the lines (`x` repeat)
2. `:sort` — alphabetical (`:sort -r` reverse)

#### Prepend to every line

1. Select the lines (`x` repeat)
2. `A-s` — one cursor per line
3. `I` — insert at each line start
4. Type the text, `Esc`

#### Change or delete a whole function

1. Put the cursor inside the function
2. `mif` — select the body (`maf` includes the signature)
3. `c` to rewrite, or `d` to delete

#### Reflow a paragraph

1. Select the paragraph (`mip`)
2. `:reflow` — wrap to `text-width` (or `80:reflow` for a one-off width)

#### Filter cursors by pattern

1. Make a multi-selection (`s` split, or per-line `A-s`)
2. `K` — keep only cursors matching a regex
3. `A-K` — or remove the ones matching

#### Search and replace across the repo

Helix has no native project-wide search-and-replace. Options:

- `Space /` global search, jump to each hit, edit by hand
- Install `scooter.hx` (the TODO in `config.toml`) for interactive project SnR

## Emmet wrap / expand (pipe commands)

VSCode's "Wrap with Abbreviation" and force-expand, rebuilt as pipe scripts because `emmet-language-server` is completion-only (no wrap, protocol gap — LSP can't prompt). Both read the selection, replace it with markup.

Workflow: select text -> `|` (shift-\) -> type command -> Enter.

- `emmet-wrap 'ABBR'` — selection is the CONTENT, ABBR wraps it.
  - select `click me` -> `emmet-wrap 'a[href=#]'` -> `<a href="#">click me</a>`
  - `*` repeat spreads one selected LINE per element (the VSCode trick):
    select 3 lines -> `emmet-wrap 'ul>li.nav*'` -> `<ul>` + one `<li>` per line.
  - Quote the abbreviation — protects `>` `*` `#` from the shell.

- `emmet-expand` — selection IS the abbreviation, no arg.
  - select `ul>li*3` -> `emmet-expand` -> full list.
  - Escape hatch for when the LSP completion menu doesn't fire (non-erb file, mid-line, markdown). Normal case: just use the completion menu.

Difference: wrap treats selection as content, expand treats selection as the abbreviation.

Repeat last wrap on a new selection with `.`. Output indents with tabs; `herb format` fixes on save.

Scripts: `~/.config/helix/scripts/emmet-{wrap,expand}.js`, symlinked onto PATH via `~/.local/bin/`. Dep: `npm i -g emmet` (scripts self-locate it from node's global modules, survives mise node upgrades). Abbreviation syntax lives in emmet-cheatsheet.md; build pattern in helix-custom-scripts-methodology.md.

## "Missing" and unlearnt features

- Moving to the end of a line
- Searching for a string and excluding or including tests 
- Open a file from the picker into a vertical or horizontal split
- De-selecting by 1 character when i over select
- Adding multiple cursor in a line
- Adding multiple cursors on a select snippet (without having to use % first to select the whole file content)
- LSP suggestions in the file
- LSP errors in the file
- LSP code actions in the file
- How to copy a snippet and paste it over another selection. (e.g copying the classes from one element and replacing the classes of another element)
