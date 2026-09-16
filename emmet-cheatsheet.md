# Emmet cheatsheet

Emmet abbreviation syntax, for use with `emmet-language-server` wired into Helix for `.erb`/`.html` files. Trigger completion with `Ctrl-x`, type the abbreviation, expand.

## Core syntax

- `div` -> `<div></div>`
- `.foo` -> `<div class="foo"></div>` (bare class defaults to div)
- `#foo` -> `<div id="foo"></div>`
- `ul.list` -> `<ul class="list"></ul>` (tag + class combine)
- `div.foo#bar` -> `<div id="bar" class="foo"></div>` (class + id combine)

## Nesting

- `>` — child: `div>ul>li` -> nested `<div><ul><li></li></ul></div>`
- `+` — sibling: `div+p` -> two siblings at the same level
- `^` — climb up one level, then continue: `div>p>span^bq` -> `bq` becomes a sibling of `p`, not `span`
- `()` — grouping, for branching nested structures: `div>(header>ul>li*2)+footer>p`

## Multiplication

- `*` — repeat: `li*3` -> three `<li></li>`
- `$` — numbering placeholder inside a repeat: `li.item$*3` -> `item1`, `item2`, `item3`
- `$$` (more `$`s) — zero-padded: `li.item$$*3` -> `item01`, `item02`, `item03`

## Attributes

- `[attr]` -> `<div attr=""></div>`
- `[attr=value]` -> `<div attr="value"></div>`
- `[attr1 attr2=value]` — space-separated for multiple
- `a[href=# target=_blank]` -> `<a href="#" target="_blank"></a>`

## Text content

- `{text}` -> inserts literal text as the element's content: `p{Hello}` -> `<p>Hello</p>`
- Combine with nesting: `ul>li{Item $}*3`

## Common shortcuts

- `!` -> full HTML boilerplate (`<!DOCTYPE html>` + head/body skeleton)
- `a:link` -> `<a href="http://"></a>`
- `img` -> `<img src="" alt="">`
- `input:text` -> `<input type="text" name="" id="">`
- `form:post` -> `<form action="" method="post"></form>`

## Rails/ERB note

Emmet doesn't know about ERB tags (`<%= %>`) at all - it only expands plain HTML. Use it for markup scaffolding, then hand-add the ERB interpolation inside. It also won't know about your `.field`/`.input` house classes or `data-controller` Stimulus conventions - those still come from the Ruby/ERB snippets already set up (`~/.config/helix/snippets/`), not Emmet.

## Wrap / expand in Helix

The `emmet-wrap` / `emmet-expand` pipe commands (VSCode's "Wrap with Abbreviation" rebuilt for Helix) live in helix-editor-cheatsheet.md.
