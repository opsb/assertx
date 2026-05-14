# Assertx

Composable matchers for ExUnit assertions, inspired by [Hamcrest](https://hamcrest.org/) matchers
from the JVM/Ruby world.

Rather than writing a separate `assert` for every field of a value, you describe the *shape* you
expect with a tree of matchers and get back a structured result that records which parts matched
and which did not. Matchers nest naturally — `map/1` composes with `eq/1`, `all/1` composes with
`map/1`, and any plain value or predicate function can stand in as a matcher via convenient
shortcuts.

```elixir
import Assertx
alias Assertx.Matchers, as: M

# Equality
match(1, M.eq(1))
match(1, 1)                              # shortcut for M.eq/1

# Predicates
match(5, &(&1 > 3))

# Maps (only the keys you specify are checked)
match(%{a: 1, b: 2}, %{a: M.eq(1)})
match(%{a: 1, b: 2}, %{a: 1})            # shortcut: values become M.eq/1

# Lists — every element against the same matcher…
match([1, 2, 3], M.all(&(&1 > 0)))

# …or element-wise
match([%{a: 1}, %{a: 2}], M.all([%{a: 1}, %{a: 2}]))
```

Each call returns either an `%Assertx.Match{}` or `%Assertx.Mismatch{}` whose `:value` records
the matched/mismatched sub-results, so failures point at the exact leaf that didn't match instead
of dumping two whole structs side-by-side.

## Installation

Add `assertx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:assertx, "~> 0.1.0"}
  ]
end
```
