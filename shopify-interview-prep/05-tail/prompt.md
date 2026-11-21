# tail

From the HelloInterview write-up. A candidate's Cursor agent got stuck on the optimization step, and she pulled the fix from a browser Claude session. The interviewer accepted that.

## Prompt

Build `tail`: print the last N lines of a file (default 10).

```
tail.rb -n 5 app.log
```

## Follow-ups they add

1. The file is 50 GB. Don't load it into memory. This is the main follow-up, so plan for it from the start.
2. `-f` (follow): keep printing new lines as they're appended.
3. `-c N`: the last N bytes.
4. Multiple files, with `==> name <==` headers, like the real tail.
5. Edge cases: an empty file, no trailing newline, N larger than the file, N = 0.

## Core idea

The naive version is `File.readlines(path).last(n)`. Write it first and say it's O(file size) in memory. Then optimize:

- Seek to the end, then read backwards in fixed chunks (say 4 KB), counting newline characters.
- Stop once you've seen n+1 newlines, or reached the start of the file.
- Take the bytes from the last chunks, split them, and keep the last n lines.
- Memory is now O(chunk + output), whatever the file size.

The detail people miss: if the file ends with "\n", that last newline ends the final line, it isn't an empty extra line. Handle it on purpose and test it.

For `-f`: after printing the tail, remember the file size. In a loop, sleep briefly. If the size grew, seek to the old size and print the new bytes. If the size shrank, the file was truncated or rotated, so start over from the beginning. Mention inotify as the event-driven option, and that polling is simpler and portable.

## Design

- `Tail.last_lines(io, n, chunk_size: 4096)`: takes any seekable IO, so tests can use StringIO or a tempfile. Make chunk_size small in tests to cover the case where a line spans chunks.
- `Tail.follow(io, output, poll:, stop:)`: inject the poll interval and a stop condition so it's testable.
- The CLI parses flags with OptionParser and calls these. Keep it thin.

## Senior talking points

- Bytes vs characters: seeking is in bytes, and a multibyte UTF-8 character can be split across chunks. Joining the raw bytes before decoding avoids that.
- Pipes and stdin can't be seeked. Fall back to a ring buffer of the last n lines (an array, dropping the oldest).
- Test with chunk_size of 1 and 3 so lines that cross chunk boundaries get covered.

## Test cases

- 3 lines, n = 2
- n larger than the file
- No trailing newline
- An empty file
- Lines longer than the chunk size
- Follow prints appended lines
