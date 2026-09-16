# Helix cheatsheet

## Goto line

- `<n>G` — jump to absolute line n (e.g. `123G`). Wrapping never affects it.
- `gg` — first line
- `G` — last line
- `:<n>` or `:goto <n>` — same as `<n>G`

Read the absolute line number, type `<n>G`. No counting from cursor.

## Line numbers

- Set in config: `line-number = "absolute"` or `"relative"`.
- Helix numbers logical lines only. No visual/wrapped-line numbering option.
- Relative gutter counts logical lines; visual motion (`j`/`k` default) counts
  visual lines. On wrapped files the two disagree.

## Vertical motion: visual vs logical

- Default `j`/`k` and `down`/`up` = `move_visual_line_down/up` (respects wrap).
- `gj`/`gk` = `move_line_down/up` (logical, ignores wrap).
- To make relative-line counts (e.g. `40k`) match the gutter, rebind to logical:

```toml
[keys.normal]
j = "move_line_down"
k = "move_line_up"
```

Trade-off: logical motion jumps whole wrapped paragraphs; visual motion makes
relative counts undershoot. Can't have both. For code, prefer logical.

## Text width

- `text-width = 80` in `[editor]` sets the target column.
- `[editor.soft-wrap]` `enable = true` + `wrap-at-text-width = true` wraps at it
  on-screen only — no newlines baked into the file. Pastes clean into Docs.

## Format / wrap current file

Bound to `space t w`:

```toml
w = ["select_all", ":pipe fmt -w 80", "collapse_selection", "keep_primary_selection"]
```

- `fmt -w 80` reflows paragraphs (merge + split) to 80 cols, inserting real
  newlines. Good for prose/comments; breaks code.
- `fold -w 80 -s` hard-wraps at spaces without reflow.
- Hard wrap bakes `\n` into the file — pastes ragged into Google Docs. For
  Docs-bound text, don't hard-wrap; use soft-wrap display instead.

## CLI text width tools

- `fmt -w 72 file` — reflow to width (default 75). Merges + splits paragraphs.
- `fold -w 72 -s file` — dumb hard wrap at width; `-s` breaks at spaces.

## Keybinding menu grouping

Array (multi-command) bindings all render as `[Multiple commands]` and collapse
into one row in the `space`-menu. No per-binding label in stable Helix. Single
commands show their name.

## Insert the same character multiple times

Type it once, `Esc`, then `<n>.` — e.g. `-<Esc>` then `40.` for 40 dashes.

`<n>i` does NOT multiply the insertion like vim. `.` repeats the last
insert-mode change; prefixing it with a count runs that repeat n times.
