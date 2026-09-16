# lf cheatsheet

Config: `doots/lf/.config/lf/lfrc`. Previewer: `doots/lf/.config/lf/scripts/preview.sh`. Edit with `configdoots`.

Plain `lf` is a zsh function (`doots/zsh/.zshrc`) — quitting `cd`s the shell to wherever you ended up.

## Navigation

- `hjkl` / arrows — left (updir), down, up, right (open)
- `gg` / `G` / `ge` — top / bottom / bottom (helix-style alias)
- `<pgup>`/`<pgdn>`, `Ctrl-b`/`Ctrl-f` — page up/down
- `Ctrl-u`/`Ctrl-d` — half-page up/down
- `g` — movement leader, self-documenting (lf shows continuations as you type)
- `` ` `` + letter — jump to bookmark; `m` + letter sets one
- left-click select, right-click open, scroll move, `Ctrl`+scroll faster (added)
- `/` `?` `n` `N` — search fwd/back, next/prev match (current dir only)
- `f` `F` `;` — incremental find fwd/back, repeat
- `.` — toggle hidden (added)

## Selection

- `space` — toggle mark
- `v` — invert marks in current dir (not a visual range)
- `u` — clear marks

## File ops

- `y` / `d`,`x` / `p` / `c`,`C` — copy / cut / paste / clear buffer (internal, not OS clipboard)
- `D`, `<delete>`, `<backspace>` — confirm, then `trash-put` (added, no permanent delete)
- `Y` — copy path to system clipboard via `box-clipboard-copy` (added)
- `a` — actions leader, self-documenting (extract, compress, mkfile, mkdir, etc)
- mkdir/touch: no lf command — `w` for `$SHELL`, then `Ctrl-r` to reload

## Open

`<enter>`/`l`/`<right>` -> `cmd open`: text/json `$EDITOR`, pdf `zathura`, else `xdg-open` (all detached). Directories handled by lf before `cmd open` runs.

## Editor / shell / pager (stock)

- `e` — `$EDITOR` directly
- `w` — `$SHELL` in cwd
- `i` — `$PAGER`

## Shell prefixes

`$` sync · `%` sync, output to statline · `!` sync, wait for keypress · `&` async. `${{ }}` = multi-line `$`.

## Preview pane

`preview.sh`: dir `eza -la` · text/json `bat` · pdf `pdftotext` · archives `ouch list` · images `chafa` · else `file -b`.

## Reload

`Ctrl-r` / `:reload` — reload listing. `q` — quit.

## Recipes

**Trash several files**: mark with `space`/`v`, then `D`. Recover with `trl`/`trr`.

**Move a file**: `d` to cut, navigate, `p` to paste.

**Preview a PDF without opening it**: just hover it.

**Jump to a stale directory**: zoxide under the `a` leader — type, enter.

**Find a file by name**: fuzzy-find under the `a` leader — filter, enter.

**Copy a path for chat**: cursor on file, `Y`.

**Unhide after clutter**: `.`.

**Extract**: cursor/marks, extract under the `a` leader.

**Compress**: marks, compress under the `a` leader, type name+extension.

**Copy between lf instances**: `y` in one, `p` in the other — shared buffer, no clipboard involved.

**Rename**: `r` (stock), prefilled.

## References

- https://www.youtube.com/watch?v=2oWqD3JCXuI
