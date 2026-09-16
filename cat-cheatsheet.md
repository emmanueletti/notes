# cat cheatsheet

`cat` = con**cat**enate. It streams whatever it's given — files, stdin, a
heredoc — to stdout, joined together. "Print a file" is the common case, not
the whole feature.

## Basics

- `cat file` — print a file's contents
- `cat file1 file2` — print both, one after another (the actual "concat")
- `cat file1 file2 > combined` — concatenate into a new file
- `cat -n file` — number every line
- `cat -s file` — squeeze repeated blank lines into one
- `cat -A file` — reveal invisible characters: tabs as `^I`, line endings as
  `$`. Good for catching trailing whitespace or mixed CRLF/LF.

## Reading from stdin

- `cat` alone (no args) — reads stdin until `Ctrl-D`, echoes it back. Quick
  way to see what's coming down a pipe.
- `cat > newfile` — type text interactively, `Ctrl-D` saves. Poor-man's
  editor for a quick file.
- `some-command | cat` — `cat` doesn't care whether its input is a real
  file, your keyboard, or a pipe. It's all just stdin.

## Heredocs

```
cat <<'EOF'
literal text here, no $expansion or `backticks` evaluated
because the delimiter is quoted
EOF
```

- `<<EOF` (unquoted delimiter) — variables and command substitution inside
  the block DO get expanded
- `<<'EOF'` (quoted delimiter) — block is completely literal, nothing
  expanded. Use this by default unless you specifically want expansion.
- Beats `echo` for multi-line static text — no `\n` escaping, no `-e` flag,
  real newlines just work. Used this way in `doots/lf/.config/lf/lfrc` at
  one point for a multi-line help popup.

## Reading things that aren't ordinary files

- `cat /proc/cpuinfo`, `/proc/meminfo`, `/proc/uptime` — not real files, the
  kernel exposing live system info through a virtual filesystem. `cat` is
  just the simplest way to read them.
- `cat < /dev/tcp/host/80` (bash-only) — bash treats `/dev/tcp/host/port` as
  a special file; `cat` can read/write a raw socket with zero extra tools,
  a poor-man's netcat for a quick reachability check.
- `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 20` — quick random string,
  streaming the kernel's entropy source through filters.

## Siblings

- `tac` — cat spelled backwards, prints lines in reverse order. Last line
  first.
- `zcat` / `xzcat` / `bzcat` — transparently decompress gzip/xz/bzip2 while
  streaming, no separate extract step: `zcat log.gz | grep ERROR`.

## Gotcha

`cat file1 file2 > file1` looks like it should append file2 onto file1, but
the shell truncates `file1` (via `>`) before `cat` ever reads it — file1's
original content is gone. `cat` has no idea, it just gets handed an already-
empty file descriptor to read from.

## The "useless use of cat" thing

`cat file | grep x` does the same thing as `grep x file` — the `cat` adds
nothing functionally. Harmless, and arguably more readable left-to-right in
a longer pipeline, but purists will point it out. Worth knowing the term so
it doesn't read as ignorance when someone mentions it.
