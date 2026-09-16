# Parsing from First Principles: Lexers, Parsers, ASTs

Written 2026-09-10. A companion to `systems-from-first-principles.md`. That one
is "what happens underneath when a program runs." This one is "how text becomes
something a program can reason about."

The whole subject is one move, repeated: **take a form built for humans or for
transmission, and turn it into a form built for reasoning.**

---

## The pipeline

```
raw input
  -> lexer       segment and label        -> flat token list
  -> parser      find structure           -> tree (AST)
  -> semantics   check meaning, annotate  -> validated tree
  -> backend     execute, emit, transform -> output
```

Each layer trusts the one below it, so no layer solves two problems at once.
That trust is the entire reason for the split.

---

## Tokenizing

Tokenizing means chopping a raw stream into meaningful chunks and labelling each
chunk by kind.

Input: an undifferentiated sequence (chars, bytes, audio samples).
Output: a list of tokens, each one a `(type, value)` pair.

```
"x = 42 + y"
-> [IDENT("x"), EQUALS, NUMBER(42), PLUS, IDENT("y")]
```

Whitespace is gone. `42` is now one thing, not two characters. Each piece is
tagged.

Why it exists: it separates two hard problems. The tokenizer answers "where do
units begin and end, and what kind is each" (local, regex-level, no memory). The
parser answers "how do these units relate" (structural, needs a stack). A parser
working on raw characters would have to re-solve boundary-finding inside every
single rule.

Tokenizing is lossy on purpose. It discards whitespace and exact spacing. Tools
that must reprint the source exactly (formatters, autofixing linters) need a
lossless variant that keeps trivia tokens.

---

## Lexer vs parser

Lexer is flat. Parser is nested.

```
"a = (b + 1)"

lexer  -> IDENT EQUALS LPAREN IDENT PLUS NUMBER RPAREN     flat

parser -> Assign
            |- Ident a
            `- Add
               |- Ident b
               `- Num 1
```

The real distinction is formal, not conventional:

- Lexer is a regular grammar. Finite state machine. Fixed memory. Cannot count.
- Parser is a context-free grammar. Needs a stack. Can count.

A lexer *cannot* match balanced parentheses. That needs unbounded counting. This
is the actual line between them.

What each catches:

- Lexer error: `@#$`, not a legal character sequence.
- Parser error: `a = = b`, legal tokens, illegal arrangement.

|              | lexer               | parser          |
|--------------|---------------------|-----------------|
| input        | chars, bytes        | tokens          |
| output       | token list          | tree            |
| scope        | one token at a time | whole nesting   |
| state        | current position    | stack           |
| discards     | whitespace, comments| nothing         |

Blurry cases exist. Some designs skip the lexer entirely (scannerless parsing,
PEG). Some need parser feedback in the lexer: C's `x * y` is ambiguous until you
know whether `x` names a type. That coupling is called the lexer hack, and it is
the sign that the clean split leaks.

---

## AST

Abstract Syntax Tree. A tree of what the code *means*, not how it was typed.

"Abstract" means it discards syntax that carried no meaning. Parens, semicolons,
whitespace, comments. They did their job of telling the parser the shape, then
got dropped. The shape now lives in the tree structure itself.

```
"2 * (3 + 4)"

Mul
|- Num 2
`- Add
   |- Num 3
   `- Num 4
```

No paren nodes. The nesting *is* the parens.

Contrast with a parse tree or CST (concrete syntax tree), which keeps every
grammar rule it passed through. Verbose, mirrors the grammar rather than the
meaning. Formatters, autofixing linters and IDE refactoring need a CST or an AST
with trivia attached. Compilers only need the AST.

Each node is a type tag plus children plus a source position. Position is kept
so errors can point back at line and column even though the raw text is gone.

---

## Worked example

```
let total = price * 2 + 1;
```

**Stage 1, lexer.** Chars to flat labelled tokens.

```
LET "let"  IDENT "total"  EQUALS  IDENT "price"  STAR  NUMBER 2
PLUS  NUMBER 1  SEMICOLON  EOF
```

Fails here on `let tot@l = 2;` since `@` matches no token rule.

**Stage 2, parser.** Tokens to tree.

```
VarDecl "total"
`- BinaryOp +
   |- BinaryOp *
   |  |- Ident price
   |  `- Num 2
   `- Num 1
```

`let`, `=` and `;` are consumed and gone. They steered which shape got built,
then were discarded.

Fails here on `let total = * 2;` since `*` needs a left operand.

**Stage 3, semantics.** Walk the tree, check meaning, annotate.

- `price` resolves in scope, type `number`
- `number * number` is legal, so the `*` node is `number`
- `total` gets declared, type inferred as `number`, assigned a storage slot

Fails here on `let total = pryce * 2;` (grammar perfect, name undefined) or
`let total = "hi" * 2;` (grammar perfect, types illegal).

Note this stage also *adds* information. Slot numbers and inferred types did not
exist in the tree before.

**Stage 4, backend.** Walk the annotated tree, emit.

```
LOAD_LOCAL 3
PUSH_CONST 2
MUL
PUSH_CONST 1
ADD
STORE_LOCAL 7
```

Post-order walk. Children emit first, then the parent emits its op. That
ordering is exactly why the tree existed.

The backend never rechecks whether `price` exists or whether `*` is legal.
Stage 3 already vouched.

---

## Implementation in Ruby

Grammar first. Always write the grammar before the parser.

```
program    -> statement*
statement  -> "let" IDENT "=" expr ";"
expr       -> term (("+" | "-") term)*
term       -> factor (("*" | "/") factor)*
factor     -> NUMBER | STRING | IDENT | "(" expr ")"
```

### Lexer

```ruby
require "strscan"

Token = Data.define(:kind, :value, :line, :col)

KEYWORDS = ["let"].freeze

SYMBOLS = {
  "=" => :EQUALS, "+" => :PLUS, "-" => :MINUS, "*" => :STAR,
  "/" => :SLASH, "(" => :LPAREN, ")" => :RPAREN, ";" => :SEMICOLON
}.freeze

WHITESPACE = /[ \t\r]+/
NEWLINE    = /\n/
NUMBER     = /[0-9]+/
WORD       = /[a-zA-Z_][a-zA-Z0-9_]*/
STRING     = /"([^"\n]*)"/
SYMBOL     = /[-+*\/=();]/

class Lexer
  def initialize(source)
    @scanner = StringScanner.new(source)
    @line = 1
    @line_start = 0
    @tokens = []
  end

  def tokenize
    until @scanner.eos?
      start_col = col

      if @scanner.skip(WHITESPACE)
        next
      elsif @scanner.skip(NEWLINE)
        @line += 1
        @line_start = @scanner.pos
      elsif (text = @scanner.scan(NUMBER))
        emit(:NUMBER, text.to_i, start_col)
      elsif (text = @scanner.scan(WORD))
        emit(KEYWORDS.include?(text) ? :LET : :IDENT, text, start_col)
      elsif @scanner.scan(STRING)
        emit(:STRING, @scanner[1], start_col)
      elsif (text = @scanner.scan(SYMBOL))
        emit(SYMBOLS.fetch(text), text, start_col)
      else
        raise SyntaxError,
          "unexpected #{@scanner.peek(1).inspect} at #{@line}:#{start_col}"
      end
    end

    emit(:EOF, nil, col)
    @tokens
  end

  private

  def col
    @scanner.pos - @line_start + 1
  end

  def emit(kind, value, col)
    @tokens << Token.new(kind: kind, value: value, line: @line, col: col)
  end
end
```

Notes on the lexer:

- `StringScanner#scan` is **anchored**. It matches only at the current position
  and never searches forward. No `\A` needed. That anchoring is exactly the
  guarantee a lexer wants, and exactly what `String#match` will not give you.
- `skip` is `scan` that discards the match. Right for whitespace.
- `@scanner[1]` reads capture group 1 of the last match. That is how the string
  literal drops its quotes.
- **Rule order matters.** First match wins, so a longer or more specific pattern
  must be tried before a shorter one that would match its prefix. The moment you
  add `==` or `<=`, they go above the single-char `SYMBOL` rule, or you will lex
  `==` as two `EQUALS`.
- StringScanner tracks `pos` only, no line awareness. Hence `@line` and
  `@line_start`, with `col` computed as arithmetic. Capture `start_col` before
  scanning, since `pos` has already moved by the time you emit.

The hand-rolled alternative is a `while` loop over characters with an `if` chain
on the first character, and `advance while` loops for each token kind. More
visible bookkeeping, same result. Every `advance while` collapses into one
`scan`.

### Parser

Recursive descent. One method per grammar rule. The methods call each other
exactly as the rules reference each other.

```ruby
VarDecl  = Data.define(:name, :init, :line)
BinaryOp = Data.define(:op, :left, :right)
Ident    = Data.define(:name, :line)
Num      = Data.define(:value)
Str      = Data.define(:value)

class Parser
  def initialize(tokens)
    @tokens = tokens
    @pos = 0
  end

  def parse_program
    statements = []
    statements << parse_statement while peek.kind != :EOF
    statements
  end

  private

  def peek
    @tokens[@pos]
  end

  def match(*kinds)
    return nil if !kinds.include?(peek.kind)

    token = peek
    @pos += 1
    token
  end

  def expect(kind)
    token = match(kind)
    return token if token

    got = peek
    raise SyntaxError, "expected #{kind}, got #{got.kind} at #{got.line}:#{got.col}"
  end

  def parse_statement
    let = expect(:LET)
    name = expect(:IDENT)
    expect(:EQUALS)
    init = parse_expr
    expect(:SEMICOLON)
    VarDecl.new(name: name.value, init: init, line: let.line)
  end

  def parse_expr
    node = parse_term
    while (token = match(:PLUS, :MINUS))
      node = BinaryOp.new(op: token.value, left: node, right: parse_term)
    end
    node
  end

  def parse_term
    node = parse_factor
    while (token = match(:STAR, :SLASH))
      node = BinaryOp.new(op: token.value, left: node, right: parse_factor)
    end
    node
  end

  def parse_factor
    if (token = match(:NUMBER))
      return Num.new(value: token.value)
    end

    if (token = match(:STRING))
      return Str.new(value: token.value)
    end

    if (token = match(:IDENT))
      return Ident.new(name: token.value, line: token.line)
    end

    if match(:LPAREN)
      node = parse_expr
      expect(:RPAREN)
      return node
    end

    got = peek
    raise SyntaxError, "unexpected #{got.kind} at #{got.line}:#{got.col}"
  end
end
```

Four things in there worth naming.

**`match` vs `expect`.** `match` is "take it if present, else nil, no harm."
`expect` is "must be present or the input is broken." Optional versus required.
That distinction is most of a parser.

**Precedence comes from the call chain.** `parse_expr` calls `parse_term` calls
`parse_factor`. Lower in the chain binds tighter. Parsing `2 + 3 * 4`,
`parse_expr` takes `2`, sees `+`, hands the right side to `parse_term`, which
swallows `3 * 4` whole before returning. So `*` lands deeper in the tree. Nobody
wrote a precedence table. The nesting of the methods *is* the table.

**Left-associativity comes from the loop.** `node = BinaryOp.new(left: node, ...)`
reassigns `node` to a new parent each pass, burying the previous tree as the
left child. `1 - 2 - 3` becomes `((1-2)-3)`, which is correct. Recursing instead
of looping would give `(1-(2-3))`, which is wrong.

**The paren case builds no node.** `parse_factor` on `LPAREN` returns the inner
expression directly. Parens never reach the tree. They only steered which method
got control. That is the "abstract" in AST, in one line of code.

### How the tree actually gets built

This is the part that trips people up. There is no `Tree` class, no `add_child`,
no edge list. **The edge is a field.** `BinaryOp` has `left:` and `right:`, and
what goes in them is another node. Nesting of objects *is* the tree.

`parse_program` returns an array, but that array is only the top level, a list
of statements. Each *element* of it is a tree root.

Trace `price * 2 + 1`, watching the local variable `node`:

```
parse_term:  node = Ident("price")
             sees *, so:
             node = BinaryOp("*", Ident("price"), Num(2))
```

The reassignment is the crux. The old value of `node` was not replaced, it was
**swallowed**. It is still there, one level down.

```
parse_expr:  node = BinaryOp("*", Ident("price"), Num(2))
             sees +, so:
             node = BinaryOp("+",
                      BinaryOp("*", Ident("price"), Num(2)),
                      Num(1))
```

Two mechanisms are doing the work. `node = BinaryOp.new(left: node, ...)` inside
a loop grows the tree downward on the left, and is where left-associativity
comes from. `right: parse_factor` grows it downward on the right via a fresh
recursive call whose return value lands as a child. Ruby's call stack holds the
partially-built parents while the children get built. **Stack depth during
parsing equals tree depth in the result.**

If `pp` output looks flat, that is just line wrapping. `Data#inspect` prints
nested nodes inline as `left=#<data BinaryOp ...>`. Use
`JSON.pretty_generate(node.to_h)` to see the indentation.

### Semantic analysis

```ruby
class Scope
  attr_reader :parent

  def initialize(parent = nil)
    @parent = parent
    @symbols = {}
  end

  def declare(name, type, slot)
    @symbols[name] = { type: type, slot: slot }
  end

  def declared_here?(name)
    @symbols.key?(name)
  end

  def lookup(name)
    @symbols[name] || @parent&.lookup(name)
  end
end

class Analyzer
  attr_reader :errors, :types

  def initialize
    @scope = Scope.new
    @next_slot = 0
    @errors = []
    @types = {}
  end

  def analyze(statements)
    statements.each { |statement| visit(statement) }
    self
  end

  def ok?
    @errors.empty?
  end

  private

  def error(message, line)
    @errors << "#{line}: #{message}"
  end

  def visit(node)
    type =
      case node
      when VarDecl  then visit_var_decl(node)
      when BinaryOp then visit_binary_op(node)
      when Ident    then visit_ident(node)
      when Num      then :number
      when Str      then :string
      else raise "no visitor for #{node.class}"
      end

    @types[node.object_id] = type
    type
  end

  def visit_var_decl(node)
    type = visit(node.init)

    if @scope.declared_here?(node.name)
      error("#{node.name} already declared", node.line)
      return type
    end

    @scope.declare(node.name, type, @next_slot)
    @next_slot += 1
    type
  end

  def visit_ident(node)
    entry = @scope.lookup(node.name)

    if !entry
      error("undefined variable #{node.name}", node.line)
      return :unknown
    end

    entry[:type]
  end

  def visit_binary_op(node)
    left = visit(node.left)
    right = visit(node.right)

    return :unknown if left == :unknown || right == :unknown

    if left == :number && right == :number
      :number
    elsif node.op == "+" && left == :string && right == :string
      :string
    else
      error("cannot apply #{node.op} to #{left} and #{right}", line_of(node))
      :unknown
    end
  end

  def line_of(node)
    case node
    when Ident then node.line
    when BinaryOp then line_of(node.left)
    else 0
    end
  end
end
```

Run it:

```ruby
source = <<~SRC
  let price = 10;
  let total = price * 2 + 1;
  let label = "cost" + "s";
SRC

ast = Parser.new(Lexer.new(source).tokenize).parse_program
analyzer = Analyzer.new.analyze(ast)
```

Three failures, all of which the parser accepted happily:

```
let total = pryce * 2;      1: undefined variable pryce
let x = 1; let x = 2;       1: x already declared
let bad = "hi" * 2;         1: cannot apply * to string and number
```

Five things worth naming.

**It is a fold, not a scan.** Every `visit` returns a type. A parent asks its
children for theirs, then decides its own. `visit_binary_op` cannot know its
type until both children report. Bottom-up. That is why this recursion returns a
*value*, where the parser's recursion returned a *node*.

**It collects errors instead of raising.** Lexer and parser die on the first
problem, because once the structure is wrong everything after is garbage.
Semantics has a complete tree, so a bad node does not poison its siblings.
Report them all in one pass.

**`:unknown` is the poison-stopper.** Once a node errors it returns `:unknown`,
and `visit_binary_op` bails early on seeing one. Otherwise `pryce * 2` reports
"undefined variable" *and* "cannot apply * to unknown and number", two messages
for one mistake. Every real type checker has this, usually called an error type
or `any`.

**It enriches, not just validates.** Slot numbers are new information that did
not exist in the tree. Codegen needs `LOAD_LOCAL 0`, and this is where `price`
becomes `0`. Same for `total`'s type, which nobody wrote in the source.

**Scope has an unused parent pointer.** This language has no blocks, so there is
one flat scope. Add `{ }` and it becomes `@scope = Scope.new(@scope)` on entry
and `@scope = @scope.parent` on exit. `lookup` walking that chain is exactly
what makes an inner variable shadow an outer one.

One wart in the above: `@types[node.object_id]`. Ruby `Data` is immutable and
compares by value, so two separate `Num(2)` nodes are `==`. You cannot key a
hash by the node itself, nor write the type onto it. Real implementations either
make AST nodes mutable so the type lands on the node, or thread annotations
through as a new tree via `node.with(...)`. The side table is the quick version.

---

## What is the point of an AST

Worth stating the honest version first: **you can skip it.** Have the parser
compute instead of build.

```ruby
  def parse_term
    value = parse_factor
    while (token = match(:STAR, :SLASH))
      value = token.value == "*" ? value * parse_factor : value / parse_factor
    end
    value
  end
```

That is a working calculator. No tree, no second pass. This is called
syntax-directed translation, and for a config parser, a CSV reader, a
calculator, or JSON, it is the right call. The AST would be dead weight.

It breaks the moment you need any of four things.

**1. To look at something twice.** Tokens are a stream, consumed once and gone.
Forward references, mutual recursion, hoisted functions, a method calling one
defined below it: all need the whole program in hand before you can answer
questions about any part. A tree persists. Walk it as many times as you have
questions.

**2. To rewrite.** Constant folding `2 * 3` into `6` on a tree is: match
`BinaryOp(op: "*", left: Num, right: Num)`, replace with `Num`. Structural,
local, safe. On text it is string surgery, and you will get it wrong inside a
string literal. Every optimization, every autofixing linter, every codemod is
subtree replacement.

**3. To have more than one backend.** `Lexer -> Parser -> Analyzer` stays fixed.
Swap only the last walker:

- walk and evaluate: interpreter
- walk and emit bytecode: compiler
- walk and emit JS: transpiler
- walk and reprint: formatter
- walk and pattern-match: linter
- walk and answer "what is at line 4, col 12": IDE go-to-definition

Six tools, one front end.

**4. To separate "is it shaped right" from "does it mean anything."** The
analyzer needed the tree. `visit_binary_op` asks both children for their types
and then decides. Mid-parse the right child does not exist yet.

### The bigger sense

**An AST is where notation becomes data.** Before it, a program is a string, a
picture of an idea. After it, the program *is* an object with parts you can
address, count, compare and rewrite.

**It makes the implicit explicit.** In `2 + 3 * 4`, precedence is real but
invisible. It lives in a convention shared between writer and reader, and
nowhere in the characters. Parsing pins it to an edge in a graph. Nothing new
was added; something already true was made *addressable*.

**Consequence: programs become programmable.** Once meaning is a data structure,
tools operate on meaning rather than on characters. Rename a variable across 400
files without touching a same-named string. Detect a pattern regardless of
spacing. Generate code by building nodes rather than concatenating text. Lisp
took this to the limit: the AST *is* the syntax, so macros are just functions on
trees.

**It is a canonical form.** `2+3`, `2 + 3`, `2 /* hi */ + 3` and `(2) + (3)` all
collapse to `Add(2, 3)`. Everything downstream reasons about one thing instead
of infinite variations. That collapsing is *why* it is lossy, and the loss is
the feature. You deliberately discard the dimensions that do not matter to the
question you are about to ask.

**The real principle: surface form and structure change for different reasons.**
Syntax serves humans, meaning readability, familiarity, taste. Structure serves
machines, meaning analysis and transformation. Bolt them together and every
syntax tweak breaks the evaluator. Split them and a language grows new notation
without the semantics noticing, and gains new backends without the notation
noticing.

**Same shape everywhere, different names:**

| surface        | structure            |
|----------------|----------------------|
| HTML text      | DOM                  |
| SQL string     | query plan           |
| source code    | AST, then IR         |
| wire bytes     | protobuf message     |
| URL string     | routing table match  |
| audio waveform | phoneme token lattice|

Always a serialized form built for transmission or for humans, and a structured
form built for reasoning. The parse step between them is the same step every
time.

Speech recognition is this pattern with a noisier front end. Waveform is
surface, the recognized token sequence is structure, and everything downstream
(intent parsing, commands, transcript cleanup) works on the structure. Same
reason: you cannot reason about meaning while still holding samples.

---

## Where to learn this properly

**Start here, it is not close.**

**Crafting Interpreters**, Robert Nystrom. Free at craftinginterpreters.com,
paid print and ebook available. Builds two complete language implementations:
first a tree-walking interpreter (exactly the above, taken all the way), then a
bytecode VM. Every line of code is in the book and explained. The prose is
genuinely the best in the field. It picks up precisely where this note stops.

Do the first half. Type it, do not just read it. Skipping the C half still
leaves most of the value.

**After, or instead if shorter is better.**

**Writing an Interpreter in Go**, Thorsten Ball. Half the length, test-driven,
more brisk. Sequel is *Writing a Compiler in Go*. Less depth than Nystrom,
faster to finish. Good if a 600-page book kills momentum.

**Nand2Tetris**, free course plus the book *The Elements of Computing Systems*.
Logic gates to CPU to assembler to VM to compiler to OS. Widens the axis: you
learn what the compiler is compiling *to*. Twelve projects, genuinely
finishable.

**Ruby-specific.**

**Ruby Under a Microscope**, Pat Shaughnessy. How Ruby itself tokenizes, parses
and compiles to YARV bytecode. Turns the theory into "so that is what happens
when I hit enter."

Poke at real parsers from `irb`:

```ruby
require "ripper"
pp Ripper.sexp("total = price * 2 + 1")
```

Ruby hands you its own AST. Compare it to the one above. Then read **Prism**,
Ruby's current parser: readable C, well documented, actively maintained.

**Later, depth over breadth.**

**SICP**. Free online. The metacircular evaluator chapter is this idea in its
purest form. Heavy, Scheme, months of work. Worth it eventually, wrong as a
starting point.

**CSAPP** (*Computer Systems: A Programmer's Perspective*). Different
fundamentals: memory, linking, caches, how a process actually runs. Pairs well
with compiler work because it is the other half of the picture. Overlaps with
`systems-from-first-principles.md`.

**Skip for now.** The Dragon Book. It is a reference, not a teacher. People buy
it, read 40 pages, and conclude compilers are inaccessible.

**Ordering advice.** One book finished beats four started. Crafting Interpreters,
front half, typed not read.
