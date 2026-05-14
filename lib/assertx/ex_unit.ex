defmodule Assertx.ExUnit do
  @moduledoc """
  ExUnit glue for Assertx. `import Assertx.ExUnit` in your test module to get
  `assertx/2`.
  """

  @doc """
  Asserts that `actual` matches the shape described by `expected`.

  On failure, raises `ExUnit.AssertionError` with `:left` and `:right`
  populated so ExUnit's diff engine renders the mismatch the same way it
  renders any other `assert ==` failure.

  Returns the original `actual` on success, so the assertion composes inside
  pipelines or `=` bindings.

  ## Example

      assertx user, %{
        name: "Alice",
        age:  M.predicate(&(&1 >= 18), "adult"),
        roles: M.all(&is_atom/1)
      }
  """
  defmacro assertx(actual, expected) do
    quote do
      actual_val = unquote(actual)
      {pinned_actual, pinned_expected} = Assertx.match(actual_val, unquote(expected))

      if pinned_actual != pinned_expected do
        raise ExUnit.AssertionError,
          left: pinned_actual,
          right: pinned_expected,
          message: "assertx failed"
      end

      actual_val
    end
  end
end
