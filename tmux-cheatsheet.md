# Tmux cheatsheet

Prefix is default `Ctrl-b`. Press it, release, then the key. Config lives at
`doots/tmux/.config/tmux/tmux.conf`.

## Sessions

- `tmux new -s name` — new session, run outside tmux
- `tmux attach -t name` — attach to existing
- `tmux ls` — list sessions
- prefix `d` — detach
- prefix `s` — session picker
- prefix `$` — rename session

## Windows (tabs)

- prefix `c` — new window
- prefix `,` — rename window
- prefix `n` / `p` — next / prev window
- prefix `0`-`9` — jump to window by number
- prefix `w` — window picker
- prefix `&` — kill window

## Panes

Splits are rebound in this config, not stock tmux defaults.

- prefix `|` or `%` — split vertical (side by side)
- prefix `-` or `"` — split horizontal (stacked)
- prefix arrow keys — move between panes (stock default, no vim binds anymore)
- prefix `x` — kill pane
- prefix `z` — zoom pane (toggle fullscreen, un-zoom same key)
- prefix `Ctrl`-arrow (hold prefix) — resize pane

## Popups

- prefix `g` — lazygit, floating over the current layout (90% size)
- prefix `Enter` — scratch shell, same size, persistent session in the
  background

## Copy mode

- prefix `[` — enter copy mode (scroll + select)
- `hjkl` / arrows — move
- `space` — start selection
- `enter` — copy selection, exit copy mode
- prefix `]` — paste
- `q` — exit copy mode without copying

## Config

- prefix `r` — reload `tmux.conf`
- prefix `I` — install/update TPM plugins (after adding a `set -g @plugin` line)

## Plugins in use

None right now. TPM stays in the config for whenever one gets added.
tmux-sensible's settings are inlined directly in `tmux.conf` (escape-time,
history-limit, focus-events, etc) rather than pulled in as a plugin.

## Recipes

**Start a new project session** `tmux new -s project-name` from the project dir.
Windows/panes you open stay scoped to that session; detach with prefix `d`,
reattach later with `tmux attach -t project-name`.

**Split into an editor + shell layout** prefix `|` to split vertical, land in
the new pane, run your shell command. prefix arrow keys to hop back to the
editor pane.

**Three-pane: editor left, two stacked shells right** prefix `|` to split
vertical. Move to the right pane (prefix right-arrow), then prefix `-` to
split it horizontal. Now left = editor, right = two stacked shells.

**Rename a window to match what's running in it** prefix `,`, type name, enter.
Useful once you have 4+ windows and `prefix n` cycling stops being enough to
track them.

**Temporarily blow a pane up to fullscreen to read output** prefix `z` to zoom.
Same key again un-zooms back to the split layout — nothing is actually resized
underneath.

**Reload config after editing tmux.conf** prefix `r`. No need to kill the server
or detach/reattach.

**Add a plugin** Add `set -g @plugin 'org/repo'` in `tmux.conf`, prefix `r` to
reload, then prefix `I` to fetch and install it.

**Move a pane's command without losing scrollback** There isn't one — copy
mode + copy/paste the output you need, or just don't kill the pane. Tmux has no
"detach a pane into its own window" like zellij's pane float; closest is prefix
`!` (stock tmux, not rebound here) which breaks a pane out into its own window.

**Working inside a nested tmux (e.g. SSH into a box also running tmux)**
Both tmuxes want the same prefix, so the outer one always wins and the inner
one is unreachable. `Ctrl-Space` puts the outer tmux to sleep (switches it to
an empty key table, so every key — including prefix — passes straight through
to the inner tmux). `Space` wakes the outer tmux back up. A "OFF"/"ON" message
confirms which state you're in.

**Quick scratch shell without leaving your layout** prefix `Enter` pops a 90%
floating shell over whatever you're doing. It's a real tmux session
(`scratch`) running in the background — close the popup and reopen it, you're
back where you left off, nothing lost. Same idea as prefix `g` for lazygit,
just a plain shell instead.

To close it: prefix `d` detaches — scratch session keeps running, next
`prefix Enter` picks up where you left off. Typing `exit` instead kills the
shell (and the session with it), so next open starts fresh with no history.
For the lazygit popup, just `q` to quit lazygit — different mechanism, same
result.
