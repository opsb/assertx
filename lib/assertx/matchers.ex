defmodule Assertx.Matchers do
  @moduledoc """
  Matcher combinators. Each returns a 1-arity function that takes an `actual`
  value and produces a `{pinned_actual, pinned_expected}` pair — the contract
  `Assertx.match/2` expects.

  All combinators compose recursively via `Assertx.match/2`, so map values can
  themselves be predicates, lists can hold maps, and so on.
  """

  alias Assertx.Failed

  @doc """
  Equality matcher. Pinned pair is always `{actual, expected}` — equal iff the
  values are equal.
  """
  def eq(expected) do
    fn actual -> {actual, expected} end
  end

  @doc """
  Predicate matcher. If `fun.(actual)` is truthy the pair pins equal; otherwise
  the expected side becomes a `%Failed{}` carrying the optional `label`.
  """
  def predicate(fun, label \\ "predicate") when is_function(fun, 1) do
    fn actual ->
      if fun.(actual),
        do: {actual, actual},
        else: {actual, %Failed{label: label, actual: actual}}
    end
  end

  @doc """
  Partial map matcher. Walks each key in `spec` against `actual`, ignoring keys
  in `actual` that aren't named in `spec`. Missing keys surface as `nil` on the
  actual side.
  """
  def map(spec) when is_map(spec) and not is_struct(spec) do
    fn
      actual when is_map(actual) ->
        spec
        |> Enum.map(fn {key, matcher} ->
          {pa, pe} = Assertx.match(Map.get(actual, key), matcher)
          {key, pa, pe}
        end)
        |> Enum.reduce({%{}, %{}}, fn {key, pa, pe}, {la, le} ->
          {Map.put(la, key, pa), Map.put(le, key, pe)}
        end)

      actual ->
        {actual, spec}
    end
  end

  @doc """
  List matcher.

    * `all(matcher)` — every element of `actual` is matched against the single
      `matcher`.
    * `all(matchers_list)` — element-wise match; sizes must agree, otherwise
      both raw lists are surfaced for ExUnit to diff.
  """
  def all(matchers) when is_list(matchers) do
    fn
      actual when is_list(actual) and length(actual) == length(matchers) ->
        actual
        |> Enum.zip(matchers)
        |> Enum.map(fn {a, m} -> Assertx.match(a, m) end)
        |> Enum.unzip()

      actual ->
        {actual, matchers}
    end
  end

  def all(matcher) do
    fn
      actual when is_list(actual) ->
        actual
        |> Enum.map(&Assertx.match(&1, matcher))
        |> Enum.unzip()

      actual ->
        {actual, matcher}
    end
  end
end
