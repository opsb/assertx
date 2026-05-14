defmodule Assertx do
  @moduledoc """
  Composable matchers for ExUnit assertions.

  The library walks an `expected` shape against an `actual` value and produces a
  `{pinned_actual, pinned_expected}` pair where the two halves compare equal iff
  every matcher in the tree succeeded. On failure, `Assertx.ExUnit.assertx/2`
  hands the pair to `ExUnit`'s diff engine so the failure renders like any other
  `assert ==` mismatch.

  See `Assertx.ExUnit.assertx/2` for the typical entry point and
  `Assertx.Matchers` for the matcher combinators (`eq/1`, `predicate/2`,
  `map/1`, `all/1`).
  """

  alias Assertx.Matchers

  @typedoc "The pair returned by every matcher — two values that diff equal iff the match succeeded."
  @type matcher_result :: {term(), term()}

  @typedoc "A function returned by every combinator in `Assertx.Matchers` — call it with an `actual` value to get a `t:matcher_result/0`."
  @type matcher_fun :: (term() -> matcher_result())

  @typedoc "A user predicate. Truthy values are treated as a match, `false`/`nil` as a mismatch."
  @type predicate_fun :: (term() -> as_boolean(term()))

  defmodule Failed do
    @moduledoc """
    Sentinel placed on the `expected` side of a pinned pair whenever a predicate
    fails. Its custom `Inspect` impl makes failures render as
    `#Failed<label: actual>` inside ExUnit's diff output.
    """

    @type t :: %__MODULE__{label: String.t() | atom(), actual: term()}

    @enforce_keys [:label, :actual]
    defstruct [:label, :actual]

    defimpl Inspect do
      import Inspect.Algebra

      def inspect(%{label: label, actual: actual}, opts) do
        concat(["#Failed<", to_string(label), ": ", Inspect.inspect(actual, opts), ">"])
      end
    end
  end

  @doc """
  Walks `expected` against `actual` and returns `{pinned_actual, pinned_expected}`.

  The pair compares equal exactly when the match succeeds, so it can be handed
  straight to `assert ==` (or to ExUnit's diff engine via `Assertx.ExUnit.assertx/2`).

  `expected` may be:

    * a literal — equality check
    * a plain map — partial-match against `actual` (extra keys ignored)
    * a list — element-wise match against `actual`
    * a 1-arity function — treated as a predicate
    * a matcher built with `Assertx.Matchers.*` — invoked directly
  """
  @spec match(term(), term()) :: matcher_result()
  def match(actual, expected) when is_function(expected, 1) do
    case expected.(actual) do
      {_, _} = pair -> pair
      falsy when falsy in [false, nil] -> {actual, %Failed{label: "predicate", actual: actual}}
      _truthy -> {actual, actual}
    end
  end

  def match(actual, expected) when is_map(expected) and not is_struct(expected) do
    Matchers.map(expected).(actual)
  end

  def match(actual, expected) when is_list(expected) do
    Matchers.all(expected).(actual)
  end

  def match(actual, expected) do
    Matchers.eq(expected).(actual)
  end
end
