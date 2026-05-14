defmodule Assertx.ExamplesTest do
  @moduledoc """
  Failing examples that demonstrate the failure output produced by
  `Assertx.ExUnit.assertx/2` across common scenarios. These tests are
  deliberately failing — they are excluded from normal runs and only execute
  via `mix examples`.

  Run them with:

      mix examples
  """

  use ExUnit.Case, async: false

  @moduletag :examples

  alias Assertx.Matchers, as: M
  import Assertx.ExUnit

  test "1. simple value mismatch" do
    assertx 1, 2
  end

  test "2. partial map — one key wrong, untouched keys hidden" do
    user = %{name: "Alice", age: 30, email: "a@b.c", id: "u-1"}
    assertx user, %{name: "Bob", age: 30}
  end

  test "3. predicate failure with a custom label" do
    assertx 17, M.predicate(&(&1 >= 18), "adult")
  end

  test "4. predicate failure without a label (bare function)" do
    assertx -5, &(&1 > 0)
  end

  test "5. list element-wise — one position wrong" do
    assertx [1, 2, 3], [1, 99, 3]
  end

  test "6. list element-wise — size mismatch" do
    assertx [1, 2, 3, 4], [1, 2, 3]
  end

  test "7. M.all — one element fails the predicate" do
    assertx [1, 2, -3, 4], M.all(M.predicate(&(&1 > 0), "positive"))
  end

  test "8. deeply nested map — a single mismatch isolated to the failing leaf" do
    payload = %{
      user: %{
        profile: %{age: 17, country: "UK", city: "London"},
        email: "alice@example.com"
      },
      meta: %{trace_id: "t-456"}
    }

    assertx payload, %{
      user: %{
        email: "alice@example.com",
        profile: %{
          age: M.predicate(&(&1 >= 18), "adult"),
          country: "UK"
        }
      }
    }
  end

  test "9. multiple mismatches in the same shape are reported together" do
    user = %{name: "Bob", age: 17, email: "not-an-email", roles: [:admin, "writer"]}

    assertx user, %{
      name: "Alice",
      age: M.predicate(&(&1 >= 18), "adult"),
      email: M.predicate(&String.contains?(&1, "@"), "email"),
      roles: M.all(&is_atom/1)
    }
  end

  test "10. missing required key in actual surfaces as nil" do
    assertx %{name: "Alice"},
                 %{name: "Alice", age: M.predicate(&is_integer/1, "integer")}
  end

  test "11. non-map actual against a map spec — structural mismatch" do
    assertx :error, %{ok: true}
  end

  test "12. M.all over a list of maps — only the offending row is highlighted" do
    users = [
      %{id: "u-1", age: 25},
      %{id: "u-2", age: 14},
      %{id: "u-3", age: 30}
    ]

    assertx users,
                 M.all(%{id: &is_binary/1, age: M.predicate(&(&1 >= 18), "adult")})
  end
end
