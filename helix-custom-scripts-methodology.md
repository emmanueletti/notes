# Building custom Helix navigation/action scripts

Methodology from building Rails-aware keybindings in Helix (test<->file toggle, render->partial jump, i18n key->locale entry, test runner with split output, model<->schema/factory jumps, view->Stimulus controller jump, controller action->route lookup). Applies to any future "I miss this from VSCode" feature request for Helix.

## Why this needs custom scripts at all

Helix has real gaps worth knowing up front, so you don't go looking for a config flag that doesn't exist:

- No codeLens support at all, client-side. Confirmed by searching helix-term/helix-lsp source for "codeLens" - zero hits outside the vendored, unused lsp-types crate. Any LSP feature that depends on codeLens (e.g. ruby-lsp-rails' controller->route/view links) is dead on Helix no matter the config.
- No custom named typable commands (a `:go-to-test` you define yourself). This is tracked as helix-editor/helix PR #12320, unmerged as of this writing. Check its state again before assuming it's still true: `gh pr view 12320 --repo helix-editor/helix --json state,mergedAt`.
- No way to give a submap or a leaf keybinding a friendly display name in the which-key popup. Confirmed at the source level in `helix-term/src/keymap.rs`: submaps are always built with a hardcoded empty name (`KeyTrieNode::new("", ...)`), and leaf bindings only ever deserialize from a plain string or array of strings - no struct-with-a-name variant exists. The popup just echoes the raw command text.
- `%sh{...}` shell expansion in typable commands is real and already shipped (unlike the two items above). This is the mechanism everything below is built on.

## The core mechanism

A keybinding's value is one of: a plain command name, a typable `:command args` string, an array of either (a sequence, all run in order), or a nested table (a submap). Leaf values are parsed via `MappableCommand::FromStr` - this matters because inside a *sequence*, typable commands need their leading colon (`":reload"`, not `"reload"`) since the bare name only resolves against the static command registry, not the typable-command registry. Static commands (`"goto_file_start"` etc) don't need a colon anywhere.

`%sh{...}` runs its contents through the shell and substitutes the result into the outer command's argument. Nested `%{var}` references inside a `%sh{}` block are substituted first, so `%sh{echo '%{buffer_name}:%{cursor_line}'}` really does run `echo 'app/models/foo.rb:12'`.

Variables available: `buffer_name` (workspace-relative path), `cursor_line` / `cursor_column` (1-indexed numbers, not text), `selection` (primary selection's text - a single character if nothing is explicitly selected), `selection_line_start` / `selection_line_end`, `language`, `line_ending`. There is no "current line text" variable - if a script needs the line under the cursor, pipe it in yourself: `sed -n "%{cursor_line}p" %{buffer_name} | script.sh`, or just read the file from disk inside the script using `buffer_name` + `cursor_line` as args (simpler when the script is already reading the file for other reasons, e.g. scanning for an enclosing method).

Scripts read the file **off disk**, not Helix's in-memory buffer. Unsaved edits are invisible to them. Auto-save-on-delay (if enabled in config.toml) makes this a non-issue in practice; otherwise it's a real caveat worth stating to the user.

## Useful command behaviors, confirmed by live testing (not assumed)

- `:open path` switches to a file, creating an empty unsaved buffer if it doesn't exist - handy for "jump to where this test/partial *should* be" even when it isn't written yet.
- `:open` on an **already-open** buffer does NOT reload from disk - it shows stale cached content. If a script's output file changes between runs (e.g. a test-results log), the keybinding must chain `":reload"` after the open, as a sequence: `["...open...", ":reload"]`.
- `:open path:line` jumps straight to a line number.
- Saving into a directory that doesn't exist yet fails ("parent directory does not exist") unless you use `:w!`, which creates it. Plain `:w` refuses. Good to know before promising "just save and go" to a user creating a new test file in a new directory.
- `:vsplit path` / `:hsplit path` always open a **new** split, even if that exact buffer is already visible somewhere. Repeated invocation stacks splits indefinitely. Fix: close any existing view of the target first with `:buffer-close! path` (the `!` variant, so it also discards unsaved state) before splitting. `buffer-close!` on a path that isn't open just errors harmlessly ("cannot close non-existent buffers") - confirmed this does **not** abort the rest of a keybinding sequence, so `[":buffer-close! path", ":vsplit %sh{...}"]` is safe to fire on the very first run too.
- After a `:vsplit`, focus does not move to the new pane - confirmed by running the same "jump to test + vsplit" keybinding twice in a row from the code pane and getting correct results both times.

## Workflow for adding a new script-backed action

1. Write the logic as a standalone script first, decoupled from Helix entirely. Bash is fine for pure path/string transforms with no line-context needed (the test<->file toggle). Default to Ruby for anything else, and don't hesitate to convert a bash script to Ruby later if it turns out easier - reach for it when there's real parsing involved (YAML with line-number tracking via `Psych.parse_stream(...).children` giving nodes with `.start_line`; scanning a file for an enclosing method/block by indentation), when a stdlib gem does the hard part for free (`active_support/inflector` for `.pluralize`/`.singularize` - loads standalone in well under a second, no full Rails boot needed), or when the script needs the cursor line's own text: a Ruby script can just `File.readlines(caller_path)[cursor_line - 1]` itself, whereas a bash script needs the line piped in externally from the keybinding (`sed -n "%{cursor_line}p" %{buffer_name} | script.sh`), which leaks complexity into `config.toml` instead of keeping it in the script. Converting `rails-render-to-partial.sh` to `.rb` for exactly this reason dropped the `sed` pipe from its keybinding entirely - a concrete sign a script wants to be Ruby: the keybinding needs a shell pipe just to hand it data it could fetch itself. This project already runs Ruby, so it's a natural fit, not an extra dependency.
2. Unit-test the script directly from the shell against **real files in the actual project**, not just synthetic scratch examples. Several real bugs only showed up against real code: a controller namespaced under a module has 4-space `def` indentation, not the 2-space assumed from a flat class; nested nested partial paths (`application/uniform/svg_icons/cross`); multiple different `t()` call shapes. Grep the real codebase for actual usage patterns before assuming a convention.
3. Find a free keybinding slot by checking the **actual Rust source**, not a doc summary. Doc-page paraphrases (via WebFetch) were wrong or incomplete more than once this session - a key reported as "unbound" turned out to be a real default. The reliable way:
   - `hx --version` to get the exact installed commit hash.
   - `gh api "repos/helix-editor/helix/git/trees/<commit>?recursive=true" --jq '.tree[].path' | grep -i keymap` to find `helix-term/src/keymap/default.rs`.
   - `curl -s "https://raw.githubusercontent.com/helix-editor/helix/<commit>/helix-term/src/keymap/default.rs"` and read the actual table for the mode you care about (`"g" => { "Goto" ... }`, `"space" => { "Space" ... }`, etc).
   - Also check the user's own `config.toml` for prior custom bindings in the same namespace - those won't appear in the upstream defaults file.
   - Prefer nesting new actions under `space` (Helix's own leader-key convention) or under a dedicated custom submap inside `space`, rather than raw mode letters like `g` - core modes get new upstream bindings over time and will eventually collide. Even `space` itself has plenty of defaults taken (`f F e E b j s S d D g a G w y Y p P R k r h c C ?` as of this commit) - don't assume a letter is free without checking.
4. Wire the keybinding into `config.toml`, then verify it **live**, end to end, through the real `hx` binary - never assume a script that works standalone will work once wired in. The one technique that carried this entire effort:
   ```
   tmux new-session -d -s hxtest -x 220 -y 55 "hx <file>"
   sleep 1.5
   tmux send-keys -t hxtest "<keys>"
   sleep 1  # longer for anything that shells out (LSP boot, test runs)
   tmux capture-pane -t hxtest -p | tail -n
   tmux kill-session -t hxtest
   ```
   This caught real bugs that reading the script or the docs would not have: a missing YAML root-descent step, the indentation assumption above, a `TOML parse error` from an unprefixed `reload` inside a sequence, stale buffer content, and split-stacking. If a live test fails in a confusing way, first rule out a config parse error before debugging logic: `hx <file> < /dev/null 2>&1 | head` prints `Bad config: ...` immediately if the TOML or a command name is invalid, which looks different from a silent no-op.
5. If a feature turns out to depend on ambiguous LSP/tool capability (does this language server actually support X), don't trust marketing copy or a project's landing page - grep the actual source. `gh api -X GET search/code -f q='<term> repo:<owner>/<repo>'` is fast and settled several "is this even possible" questions directly (herb-lsp has zero `definition` handlers despite roadmap language suggesting otherwise; ruby-lsp-rails' addon activates silently with no log line, so "no log = not working" was a false alarm that live-testing `gd` disproved).

## Starting a new script

Every script here follows the same shape: take the buffer path plus whatever position info it needs, decide on a target, print one line to stdout. Helix substitutes that line into the bound command. Nothing is written back to the editor except through that one printed string.

The contract is worth stating plainly, because it is the whole interface:

- Input arrives as plain ARGV, from `%{...}` variables in the keybinding.
- Output is a single line on stdout: either `path`, or `path:line`, or a message if you bound it to `:echo`.
- On any failure or unrecognised input, print the caller's own path and exit cleanly. That makes the bound `:open` a harmless no-op instead of an error that aborts the rest of a sequence.

Template to copy:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# One-line statement of what this jumps from and to.
caller_path = ARGV[0]
cursor_line = ARGV[1].to_i

# Bail out early on anything this script doesn't handle. Echo the input back
# so the caller just reopens the current file.
unless caller_path.start_with?("app/models/") && caller_path.end_with?(".rb")
  puts caller_path
  exit
end

target = "..." # derive from caller_path, or read the file and parse

if target && File.exist?(target)
  puts target        # or "#{target}:#{line_no}" to land on a line
else
  puts caller_path
end
```

Then `chmod +x`, and bind it:

```toml
[keys.normal.space.t]
x = ':open %sh{ruby ~/.config/helix/scripts/rails-<verb>-<noun>.rb %{buffer_name} %{cursor_line}}'
```

Three variants of that last line, depending on the action:

- Navigation: `:open %sh{...}` as above.
- No sensible file target (a lookup, a status answer): `:echo %sh{...}`.
- The script rewrites the current file: `[':open %sh{...}', ":reload"]`, or the buffer shows stale content.
- Output goes to a scratch file that changes between runs (test output): `[":buffer-close! tmp/helix_test.log", ':vsplit %sh{...}']`, or splits stack and content goes stale.

Start bash only if the whole job is path and string rewriting with no file reading. The moment it needs the cursor line's text, real parsing, or `active_support/inflector`, it wants to be Ruby, and converting later is cheap. The tell that a script should have been Ruby: its keybinding needs a shell pipe just to hand it data it could have read itself.

## Conventions settled on for this project's scripts

- Location: `~/.config/helix/scripts/`, one file per action.
- Naming: `rails-<verb>-<noun>.sh` / `.rb`. Specific enough that the raw command string shown in the which-key popup (see the "no friendly names" gap above) is still legible. Current set, all under `space t` in `config.toml`:
  - `rails-file-to-test.sh` (`f`) - toggle app/**/x.rb <-> test/**/x_test.rb
  - `rails-render-to-partial.rb` (`p`) - jump from a `render "x"` call to the partial
  - `rails-i18n-key-to-entry.rb` (`i`) - jump from `t(".key")`/`t("full.key")` to its line in `config/locales/en.yml`, resolving Rails' lazy-lookup scope from the view/controller path
  - `rails-run-test-at-cursor.rb` / `rails-run-test-file.sh` (`t` / `T`) - run one test or a whole file, output in a split
  - `rails-model-to-schema.rb` (`s`) - jump from a model to its `create_table` block in `db/schema.rb`
  - `rails-view-to-stimulus.rb` (`j`) - jump from `data-controller="x"` to its Stimulus controller file
  - `rails-model-to-factory.rb` (`c`) - toggle model <-> FactoryBot factory
  - `rails-action-to-route.rb` (`r`) - show a controller action's route (verb + path) in the statusline, via `:echo` rather than `:open` - no navigation since routes.rb is a DSL, not data, so there's no reliable "line that declared this route" without evaluating it
  - `rails-extract-partial.rb` (`e`) - extract the selected lines into a new partial and replace them with a `render` call. The only script driven by a *selection* rather than the cursor, so it takes `%{selection_line_start} %{selection_line_end}` and is bound in select mode as well as normal. Line-based, whole selected lines only. Dedents to the block's own common indentation and writes the strict-locals header. Since there's no way to prompt for a name, it defaults to `_partial.html.erb` (numbered on collision) and you rename after. Must chain `":reload"` after the `:open`, since it rewrites the file you're sitting in
- One script per distinct behavior rather than a single script branching on an optional arg - split `rails-run-test.sh` into a whole-file variant and a validating at-cursor variant once their logic diverged (the at-cursor version needed real indentation-aware parsing to avoid Rails' `file:line` runner silently reporting a false "0 failures" pass when the line isn't actually inside a test block).
- Scripts that don't recognize their input (wrong file type, no match found) echo the input path back unchanged / print a clear message to a result file, rather than raising - keeps the bound `:open`/`:vsplit` command from erroring out mid-sequence. For actions with no sensible file target at all (the route lookup), bind to `:echo` instead of `:open`/`:vsplit` and just print a message - don't force every action into the navigation-shaped mold.
- Fallback search (glob/grep for the real file when the naive convention-based guess misses) is worth the extra code only when the underlying convention genuinely isn't enforced by any tool - FactoryBot file layout is pure team convention, so `rails-model-to-factory.rb` falls back to grepping all factory files for `factory :name do` when the guessed path doesn't exist. It's *not* worth it for a one-off naming mismatch that's really a bug in the app rather than a real convention variance - `rails-view-to-stimulus.rb` stayed a plain best-effort guess (no fallback) after finding one view whose `data-controller` attribute didn't match its controller's actual file path; chasing that would have added real complexity to paper over what's arguably a bug to fix in the app, not the script.
- `chmod +x` every script; invoke bash ones directly (`~/.config/helix/scripts/foo.sh`), Ruby ones via `ruby ~/.config/helix/scripts/foo.rb` (the shebang alone isn't enough inside `%sh{}` in every case tested here, calling `ruby` explicitly was more reliable).
