# In-memory file system

Reported at an Apr 2026 screen. It sounds big, but it's a tree plus one helper that turns a path into a node. Get that helper right and every command is about five lines.

## Prompt

Build an in-memory file system with a current directory. Support:

- `mkdir(path)`: create a directory
- `cd(path)`: change directory. Supports absolute (`/a/b`), relative (`b`), `..` and `.`.
- `ls(path = ".")`: list names in a directory, sorted
- `add(path, content)`: create a file with content (also called `touch` or `write`)
- `rm(path)`: remove a file or directory
- `pwd`: print the current path

## Follow-ups they add

1. `mkdir -p`: create missing parent directories.
2. `rm` on a non-empty directory: error, or a recursive flag.
3. `cat`, `mv`, `cp`.
4. `find name`, or `du` (total size of a directory).
5. Turn it into a REPL/CLI that reads commands from stdin.
6. Save and load to disk (serialize the tree to JSON).

## The whole idea

- `Directory` has a name, a parent, and `children` (a Hash of name to node). `File` has a name, a parent, and content.
- The root is a Directory whose parent is nil. `cwd` starts at root.
- One helper does all the hard work: `resolve(path)`.
  1. Start at root if the path starts with `/`, otherwise at `cwd`.
  2. Split on `/` and drop empty parts.
  3. For each part: `.` stays put, `..` goes to the parent (the root's parent is root), anything else looks up the child, and fails if it's missing or is a file.
- Most commands work on a parent plus a name: `mkdir /a/b/c` means resolve `/a/b`, then add `c`. So write `split_parent(path)`, which returns the parent directory node and the last part of the path.

Once `resolve` and `split_parent` exist, each command is a few lines. Build and test those two first.

## Senior talking points

- Choose clear errors up front: `NotFound`, `NotADirectory`, `AlreadyExists`, `DirectoryNotEmpty`. Raise them with the path.
- Hash children give O(1) lookup per path segment. Sort only when running `ls`.
- `rm` on the cwd or one of its parents: block it, or move cwd to root? Ask. Never allow removing root.
- `pwd` walks up parents and joins the names. Or store the full path on each node, but then a later `mv` has to update it.
- Separate the command parser (the REPL) from the FileSystem class, so tests call methods directly.

## Test cases

- mkdir, then cd, then pwd
- cd with `..` and `.`, and `..` at the root stays at the root
- An absolute path from a nested cwd
- ls is sorted and contains both files and directories
- Errors: cd into a file, mkdir something that exists, cd to a missing path
- mkdir -p creates the whole chain
- rm on a non-empty directory without the recursive flag raises an error
