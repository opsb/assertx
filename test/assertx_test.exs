defmodule AssertxTest do
  use ExUnit.Case

  alias Assertx.Matchers, as: M
  alias Assertx.Match
  alias Assertx.Mismatch
  import Assertx

  describe "match" do
    test "matching values" do
      assert Match.new({:eq, 1, 1}) == match(1, M.eq(1))
    end

    test "matching values - shortcut" do
      assert Match.new({:eq, 1, 1}) == match(1, 1)
    end

    test "mismatching values" do
      assert Mismatch.new({:neq, 1, 2}) == match(1, M.eq(2))
    end

    test "matching predicate" do
      predicate = M.predicate(&(&1 > 3))
      assert Match.new({5, predicate}) == match(5, predicate)
    end

    test "matching predicate - shortcut" do
      predicate = &(&1 > 3)
      assert Match.new({5, predicate}) == match(5, predicate)
    end

    test "matching map" do
      assert Match.new(%{a: Match.new({:eq, 1, 1})}) == match(%{a: 1}, M.map(%{a: M.eq(1)}))
    end

    test "matching map - shortcut" do
      assert Match.new(%{a: Match.new({:eq, 1, 1})}) == match(%{a: 1}, %{a: M.eq(1)})
    end

    test "all matching function" do
      predicate = M.predicate(&(&1 > 0))

      assert Match.new([
               Match.new({1, predicate}),
               Match.new({2, predicate}),
               Match.new({3, predicate})
             ]) ==
               match([1, 2, 3], M.all(predicate))
    end

    test "matching all maps" do
      match([%{a: 1}, %{a: 2}], M.all([M.map(%{a: M.eq(1)}), M.map(%{a: M.eq(2)})]))
    end

    test "all values matching" do
      match([1, 2], M.all([1, 2]))
    end

    test "all maps matching - shortcut" do
      match([%{a: 1}, %{a: 2}], M.all([%{a: 1}, %{a: 2}]))
    end

    test "matching map entries" do
      assert Match.new(%{a: Match.new({:eq, 2, 2}), b: Match.new({:eq, 3, 3})}) ==
               match(%{a: 2, b: 3}, M.map(%{a: M.eq(2), b: M.eq(3)}))
    end

    test "mismatching map entries" do
      assert Mismatch.new(%{a: Mismatch.new({:neq, 7, 8}), b: Match.new({:eq, 3, 3})}) ==
               match(%{a: 7, b: 3}, M.map(%{a: M.eq(8), b: M.eq(3)}))
    end

    test "matching nested map" do
      assert Match.new(%{a: Match.new({:eq, 3, 3}), b: Match.new(%{c: Match.new({:eq, 10, 10})})}) ==
               match(%{a: 3, b: %{c: 10}}, M.map(%{a: M.eq(3), b: M.map(%{c: M.eq(10)})}))
    end
  end

  describe "render" do
    test "matching value" do
      assert render(Match.new({:eq, 1, 1})) ==
               "#{IO.ANSI.green()}1 == 1#{IO.ANSI.reset()}"
    end

    test "mismatching value" do
      assert render(Mismatch.new({:neq, 1, 2})) ==
               "#{IO.ANSI.red()}1 != 2#{IO.ANSI.reset()}"
    end

    test "matching predicate" do
      predicate = fn x -> x > 0 end

      assert render(Match.new({5, predicate})) ==
               "#{IO.ANSI.green()}5 matches #{inspect(predicate)}#{IO.ANSI.reset()}"
    end

    test "mismatching predicate" do
      predicate = fn x -> x > 0 end

      assert render(Mismatch.new({-1, predicate})) ==
               "#{IO.ANSI.red()}-1 does not match #{inspect(predicate)}#{IO.ANSI.reset()}"
    end

    test "matching map" do
      result = match(%{a: 1}, %{a: M.eq(1)})

      assert render(result) ==
               """
               #{IO.ANSI.green()}%{
                 #{IO.ANSI.green()}a: #{IO.ANSI.green()}1 == 1#{IO.ANSI.reset()}
               #{IO.ANSI.green()}}#{IO.ANSI.reset()}\
               """
    end

    test "mismatching map entry colours the wrapper red" do
      result = match(%{a: 7}, %{a: M.eq(8)})

      assert render(result) ==
               """
               #{IO.ANSI.red()}%{
                 #{IO.ANSI.red()}a: #{IO.ANSI.red()}7 != 8#{IO.ANSI.reset()}
               #{IO.ANSI.red()}}#{IO.ANSI.reset()}\
               """
    end

    test "matching list" do
      result = match([1, 2], M.all([1, 2]))

      assert render(result) ==
               """
               #{IO.ANSI.green()}[
                 #{IO.ANSI.green()}1 == 1#{IO.ANSI.reset()}
                 #{IO.ANSI.green()}2 == 2#{IO.ANSI.reset()}
               #{IO.ANSI.green()}]#{IO.ANSI.reset()}\
               """
    end

    test "nested map renders with indentation" do
      result = match(%{a: 3, b: %{c: 10}}, %{a: M.eq(3), b: %{c: M.eq(10)}})

      rendered = render(result)

      assert rendered =~ "a: #{IO.ANSI.green()}3 == 3"
      assert rendered =~ "b: #{IO.ANSI.green()}%{"
      assert rendered =~ "    #{IO.ANSI.green()}c: #{IO.ANSI.green()}10 == 10"
    end
  end
end
