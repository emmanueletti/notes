# Writing Helix snippets

How snippets actually work in Helix, how to write your own, and the gotchas that cost time.

## Helix has no snippet engine

Helix itself does not read snippet files. It only knows how to *render* a snippet that arrives over LSP, as part of a completion response. So a snippet has to be served by a language server.

The server doing that here is `hx-lsp`. Its whole job is to read JSON snippet files off disk and serve them as completions. That is the only reason `~/.config/helix/snippets/*.json` does anything.

Two consequences worth internalising:

- A snippet only appears if `hx-lsp` is attached to that language in `languages.toml`. Creating the JSON file is half the job.
- Snippets appear in the normal completion menu, mixed in with whatever the real language server is suggesting. They are not a separate expansion mechanism with their own trigger key.

## Wiring it up

Two files, both under `~/.config/helix/`.

The snippet file, named after the language: `snippets/ruby.json`, `snippets/erb.json`, `snippets/bash.json`. The name must match Helix's language name, not the file extension.

Then attach `hx-lsp` to that language in `languages.toml`:

```toml
[language-server.hx-lsp]
command = "hx-lsp"

[[language]]
name = "erb"
language-servers = ["herb", "emmet-lsp", "hx-lsp"]
```

`hx-lsp` sits alongside the real language servers rather than replacing them. Order in the list does not control priority.

Restart Helix after changing `languages.toml`. `hx --health <lang>` confirms the attachment.

## The file format

VS Code's snippet format. An object of named snippets:

```json
{
  "Method definition": {
    "prefix": "def",
    "description": "def method_name ... end",
    "body": [
      "def ${1:method_name}",
      "  $0",
      "end"
    ]
  }
}
```

The outer key is a human label. `prefix` is what you type. `body` is a string for one line, or an array of strings, one per line. `description` shows in the completion menu.

## Snippet syntax

This is TextMate syntax, which LSP adopted wholesale. The entire language:

```
$1, $2        tabstops, visited in order
$0            final cursor position, always last
${1:default}  placeholder, prefilled and selected so typing replaces it
${1|a,b,c|}   choice, offers a dropdown
\$            literal dollar sign
```

Reusing a number mirrors it. Both spots update as you type:

```json
"body": [
  "def initialize(${1:arg})",
  "  @${1:arg} = ${1:arg}",
  "end"
]
```

That is essentially all of it. There is a transform syntax (`${1/regex/replace/}`) but it is rarely worth the trouble.

## Prefixes must be word characters

Confirmed in the hx-lsp source (`encoding.rs`), not inferred:

```rust
pub fn char_is_word(ch: char) -> bool {
    ch.is_alphanumeric() || ch == '_'
}
```

`get_current_word` walks backward from the cursor over word characters only, and that captured word is what gets matched against your prefixes.

Two things follow.

A prefix starting with `<`, `%` or `#` never fires. This is why the ERB snippets are `erb`, `erbo`, `erbc` and not `<%`. You cannot make `<%` autoclose into `<% %>` with a snippet at all. That would need either an editor-level autopair (Helix's `auto-pairs` is single-character only, so it cannot pair a two-character token) or LSP `onTypeFormatting`, which Helix does not implement client-side.

Separators inside a prefix must be underscores, never dashes. `test_file_model` works; `test-file-model` does not. The failure is subtle rather than silent: typing `test-file-model` captures only `model` as the current word, and since hx-lsp builds items with `insert_text` and no `text_edit` range (`snippet.rs`), accepting the completion replaces only that word. You end up with `test-file-` stranded in front of the expansion.

## Matching is fuzzy

hx-lsp runs a fuzzy match, not a prefix match, so you do not have to type the prefix in order or in full. `tfm` surfaces `testfilemodel`. `tuc` surfaces `testunitclassm`.

Worth knowing before optimising for short prefixes: long descriptive names cost nothing to type, and they make the completion menu readable. It also means a prefix is discoverable by any word inside it, which is a reason to name for the thing you would think to type. `moduleconcern` rather than `concern`, so reaching for `module` finds it.

## Check the formatter does not undo your snippet

The one that actually bit. If the language has `auto-format = true`, the formatter runs on every save, and it can rewrite whatever your snippet inserted.

For ERB with `herb` as formatter, a multiline comment:

```erb
<%#
  line one
  line two
%>
```

is valid in both stdlib ERB and Erubi, and gets collapsed by `herb format` to `<%#  line one  line two%>` on save. Still a valid comment, but the shape is gone every time.

Worse, the Ruby-comment variant is actively unsafe once collapsed:

```erb
<%
  # line one
%>
```

becomes `<%  # line one%>`, and the generated Ruby ends up as `# line one; _erbout << "\nrest of template"` on a single line, so the trailing comment swallows the rest of the file. Silent content loss.

And `=begin`/`=end`, the idiom for commenting out a region of markup, fails differently. It works as written, but `herb format` inlines it to `<% =begin %>`, and `=begin` is only a comment marker at column 0. Both engines then raise `SyntaxError: unexpected '='`. At least that one fails loudly.

So before committing to a snippet, run the formatter over its output and render the result. For ERB the surviving forms are stacked single-line comments (`<%# line %>` per line) and `<% if false %> ... <% end %>` for skipping a block of markup.

The general lesson: snippet correct in the language does not mean snippet survives your toolchain.

## Testing a snippet

Standalone, before wiring it up: write the expected output to a scratch file, run the project's formatter over it, and render or parse it. For ERB that is `herb format file.html.erb` then evaluating with Erubi (what Rails uses) rather than assuming stdlib ERB behaves identically. It did not, in one of the cases above.

Live: open a file of that language, type the prefix, confirm the completion appears and the tabstops land where expected.

## Current snippets

`~/.config/helix/snippets/`.

`ruby.json`, test file skeletons. Each hardcodes the parent class rather than leaving it a placeholder, taken from what the workbench suite actually uses:

| prefix | class |
|---|---|
| `testfilemodel` | `ActiveSupport::TestCase` |
| `testfilecontroller` | `ActionDispatch::IntegrationTest` |
| `testfilemailer` | `ActionMailer::TestCase` |
| `testfileview` | `ActionView::TestCase` |

Concerns use `testfilemodel`, since a concern test is a plain `ActiveSupport::TestCase` and a separate snippet would be identical.

All four open with `# frozen_string_literal: true` then `require "test_helper"`, and name the class `${1:Name}Test` / `...ControllerTest` / `...MailerTest` / `...HelperTest` so only the base name gets typed.

`ruby.json`, test blocks:

- `testunit` — plain `test "description" do`
- `testunitinstancem` — `test "#method handles ..." do`
- `testunitclassm` — `test ".method handles ..." do`

`ruby.json`, everything else: `def`, `defa`, `class`, `moduleconcern`, `error`, `data`, `job`, `respond`.

`erb.json`: `erb`, `erbo`, `erbc`, `locals`, `erbif`, `erbeach`, `erbdo`.

Also `javascript.json`, `bash.json`.

Languages with `hx-lsp` attached: ruby, erb, javascript, bash, markdown.

## Related

- `helix-custom-scripts-methodology.md` — for actions that need real logic (jump to test, run test at cursor). Snippets are for text expansion only; anything that has to read the file, shell out, or navigate belongs there.
