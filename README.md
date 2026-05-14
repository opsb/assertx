# Assertx

Composable matchers for ExUnit assertions, inspired by [Hamcrest](https://hamcrest.org/).

Rather than writing a separate `assert` for every field of a value, you describe
the *shape* you expect with a tree of matchers and let ExUnit's diff engine
render the failure. The expected shape is plain data — literals, predicates, and
nested matchers — so it can be built programmatically, reused across tests, and
composed.

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  import Assertx.ExUnit
  alias Assertx.Matchers, as: M

  test "registered user has the right shape" do
    {:ok, user} = MyApp.register("a@b.c")

    assert_match user, %{
      email: "a@b.c",
      age:   M.predicate(&(&1 >= 18), "adult"),
      roles: M.all(&is_atom/1),
      profile: %{
        created_at: M.predicate(&match?(%DateTime{}, &1), "DateTime")
      }
    }
  end
end
```

Three things to notice:

1. The expected shape is **plain data**. Build it programmatically, pass it
   around, store it in a fixture module.
2. Keys you don't list (`id`, `inserted_at`, anything else on `user`) are
   ignored — partial-match semantics.
3. Predicates carry an optional label that surfaces in failure output.

## How failures look

`assert_match` raises `ExUnit.AssertionError` with `:left` and `:right`
populated, so failures render through ExUnit's native diff engine — same
colourisation and structural diffing you get from any `assert ==`. Only the
mismatching leaves and the keys you actually asserted on appear in the diff;
the rest of the original value stays out of your way.

For a `user` that's 17 with a string in its `roles`, the failure for the
example above looks roughly like:

```
assert_match failed
left:  %{user: %{age: 17,
                 email: "a@b.c",
                 profile: %{...},
                 roles: [:admin, "writer"]}}
right: %{user: %{age: #Failed<adult: 17>,
                 email: "a@b.c",
                 profile: %{...},
                 roles: [:admin, #Failed<predicate: "writer">]}}
```

ExUnit highlights only the leaves that differ.

## Matcher reference

```elixir
alias Assertx.Matchers, as: M

# Equality (the default for literals)
assert_match 1, 1
assert_match 1, M.eq(1)

# Predicates
assert_match 5, &(&1 > 0)                          # bare function
assert_match 5, M.predicate(&(&1 > 0), "positive") # with label

# Maps — partial match, extra keys ignored
assert_match %{a: 1, b: 2, extra: :ok}, %{a: 1, b: 2}

# Lists — element-wise (sizes must agree)
assert_match [1, 2], [1, 2]
assert_match [1, 2], M.all([1, 2])

# Lists — every element against the same matcher
assert_match [1, 2, 3], M.all(&(&1 > 0))

# Compose freely
assert_match users, M.all(%{id: &is_binary/1, age: M.predicate(&(&1 >= 18), "adult")})
```

## Installation

Add `assertx` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:assertx, "~> 0.1.0", only: :test}
  ]
end
```
