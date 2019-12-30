defmodule Assertx.Matchers do
  alias Assertx.Match
  alias Assertx.Mismatch

  def eq(value) do
    fn left ->
      if left == value do
        Match.new({:eq, left, value})
      else
        Mismatch.new({:neq, left, value})
      end
    end
  end

  def all(right) when is_list(right) do
    fn left when is_list(left) ->
      do_all(left, right)
    end
  end

  def all(right) do
    fn left when is_list(left) ->
      expanded_right = Enum.map(left, fn _ -> right end)
      do_all(left, expanded_right)
    end
  end

  def do_all(left, right) when is_list(left) and is_list(right) do
    results =
      Enum.zip(left, right)
      |> Enum.map(fn {left, right} ->
        Assertx.match(left, right)
      end)

    aggregate(:all, results)
  end

  def map(right) when is_map(right) do
    fn left when is_map(left) ->
      entry_results =
        right
        |> Map.keys()
        |> Map.new(fn key ->
          {key, map_entry(left, right, key)}
        end)

      aggregate(:all, entry_results)
    end
  end

  def map_entry(left, right, key) when is_map(left) and is_map(right) do
    Assertx.match(Map.get(left, key), Map.get(right, key))
  end

  def predicate(cb) do
    cb
  end

  defp aggregate(:all, results) when is_list(results) do
    agg_result =
      Enum.all?(results, fn
        %Match{} -> true
        %Mismatch{} -> false
      end)

    if agg_result do
      Match.new(results)
    else
      Mismatch.new(results)
    end
  end

  defp aggregate(:all, results) when is_map(results) do
    agg_result =
      Enum.all?(Map.values(results), fn
        %Match{} -> true
        %Mismatch{} -> false
      end)

    if agg_result do
      Match.new(results)
    else
      Mismatch.new(results)
    end
  end
end
