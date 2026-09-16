# xdg-mime cheatsheet

Config lives at `doots/xdg/.config/mimeapps.list`. Edit with `configdoots`.
Sourced by `xdg-open`, which lf's `cmd open` falls back to for anything not
special-cased (text, pdf are hardcoded to `$EDITOR`/`zathura` directly in
`lfrc`, bypassing this entirely).

## How it resolves

1. `xdg-open` gets a mimetype from the file (via `file`/shared-mime-info)
2. looks it up in `~/.config/mimeapps.list` under `[Default Applications]`
3. falls back to `/usr/share/applications/mimeapps.list` (system defaults)
   if the user file has no entry
4. the value is a `.desktop` file's id, found in
   `~/.local/share/applications/` or `/usr/share/applications/`

`[Added Associations]` is a separate, longer list GNOME apps maintain
(secondary/fallback apps offered in "Open With" menus). Not what controls the
actual default — that's `[Default Applications]` only.

## Commands

- `xdg-mime query filetype somefile.pdf` — what mimetype a file resolves to
- `xdg-mime query default application/pdf` — current default for a mimetype
- `xdg-mime default org.pwmt.zathura.desktop application/pdf` — set the
  default (writes into `mimeapps.list`)
- `ls /usr/share/applications/ | grep -i <name>` — find a `.desktop` file's
  exact id when you don't know it

## Recipes

**Find out what app opens a given file type right now** `xdg-mime query
default application/pdf`. If nothing's set, you get no output — falls
through to whatever the system default list has, or nothing at all.

**Change the default PDF viewer** `xdg-mime default
org.pwmt.zathura.desktop application/pdf`. Confirm the `.desktop` id exists
first: `ls /usr/share/applications/ | grep -i zathura`.

**A file type opens the wrong app and you don't know why** check both files —
`~/.config/mimeapps.list` wins if it has an entry; only checks
`/usr/share/applications/mimeapps.list` when it doesn't.

**Reset a mimetype back to system default** delete its line from
`~/.config/mimeapps.list` (i.e. `doots/xdg/.config/mimeapps.list`) — no
`xdg-mime` subcommand for "unset", just edit the file directly.

**Figure out a file's mimetype before setting anything** `xdg-mime query
filetype path/to/file` — matches what `file --mime-type` reports, since both
read the same shared-mime-info database.

**No GUI for this beyond GNOME Settings' handful of app categories** — for
anything not in that short list (PDF, images, video, etc), the CLI above is
the only lever. Nautilus's right-click > Open With > "Set as default" is the
one GUI escape hatch, per-extension only.
