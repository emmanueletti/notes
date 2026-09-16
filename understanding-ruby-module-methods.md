# Ruby: module-level methods

A bare `def` inside a `module` is an instance method, full stop — `private` or not. It's never callable as `Module.method` on its own.

```ruby
module Foo
  def bar; "bar!"; end
end

Foo.bar
# NoMethodError: undefined method 'bar' for module Foo
```

Even with `private` above it, same result — `private` restricts access, it doesn't create a module-level method:

```ruby
module Foo
  private
  def bar; "bar!"; end
end

Foo.bar
# NoMethodError: undefined method 'bar' for module Foo
Foo.private_instance_methods(false)  # => [:bar]
```

To get `Foo.bar` to work at all, pick one of four:

## `def self.bar`

Plain, one method at a time. Fine for one or two methods, repetitive past that.

```ruby
module Foo
  def self.bar; end
end
```

## `class << self`

Opens the singleton class explicitly. Same effect as `def self.x` for every method inside, just without repeating `self.` on each one. Purely a syntax convenience — no semantic difference from a pile of `def self.x`.

```ruby
module Foo
  class << self
    def bar; end
    def baz; end
  end
end
```

## `module_function`

Makes every method defined after it both a module-level method *and* private if the module is later `include`d into a class.

```ruby
module Foo
  module_function
  def bar; end
end

Foo.bar                                    # works
Class.new { include Foo }.new.bar          # NoMethodError — private in the includer
```

## `extend self`

Makes every method defined a module-level method that stays *public* if the module is `include`d.

```ruby
module Foo
  extend self
  def bar; end
end

Foo.bar                                    # works
Class.new { include Foo }.new.bar          # works — still public
```

## Which one

- Module never gets `include`d anywhere, just called directly as a namespace: `class << self` (or `def self.x` for a method or two). Purely taste.
- Module might get `include`d and you want the methods to disappear as private plumbing there: `module_function`.
- Module might get `include`d and you want the methods to stay usable there too: `extend self`.

Confirmed all of the above against Ruby 4.0.6, not from memory — asked to double check after an initial hand-wavy answer turned out to need verifying.
