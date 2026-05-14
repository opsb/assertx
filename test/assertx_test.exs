defmodule AssertxTest do
  use ExUnit.Case

  alias Assertx.Failed
  alias Assertx.Matchers, as: M
  import Assertx.ExUnit

  describe "match/2 — literal equality" do
    test "equal integers pin equal" do
      assert {1, 1} == Assertx.match(1, 1)
    end

    test "different integers pin different" do
      assert {1, 2} == Assertx.match(1, 2)
    end

    test "strings, atoms, tuples all pin via equality" do
      assert {"a", "a"} == Assertx.match("a", "a")
      assert {:ok, :ok} == Assertx.match(:ok, :ok)
      assert {{1, 2}, {1, 2}} == Assertx.match({1, 2}, {1, 2})
    end

    test "nil is a normal equality value" do
      assert {nil, nil} == Assertx.match(nil, nil)
      assert {nil, :something} == Assertx.match(nil, :something)
    end
  end

  describe "match/2 — predicates" do
    test "bare function returning true pins equal" do
      assert {5, 5} == Assertx.match(5, &(&1 > 0))
    end

    test "bare function returning false pins with default 'predicate' label" do
      assert {-1, %Failed{label: "predicate", actual: -1}} ==
               Assertx.match(-1, &(&1 > 0))
    end

    test "M.predicate carries a custom label into Failed" do
      assert {-1, %Failed{label: "positive", actual: -1}} ==
               Assertx.match(-1, M.predicate(&(&1 > 0), "positive"))
    end

    test "M.predicate without a label defaults to 'predicate'" do
      {_, expected} = Assertx.match(-1, M.predicate(&(&1 > 0)))
      assert %Failed{label: "predicate"} = expected
    end

    test "predicate returning truthy-but-not-true counts as a match" do
      assert {5, 5} == Assertx.match(5, fn x -> x end)
    end
  end

  describe "match/2 — maps (partial match)" do
    test "fully matching map pins equal" do
      assert {%{a: 1}, %{a: 1}} == Assertx.match(%{a: 1}, %{a: 1})
    end

    test "extra keys in actual are ignored" do
      assert {%{a: 1}, %{a: 1}} ==
               Assertx.match(%{a: 1, ignored: :keep}, %{a: 1})
    end

    test "one mismatching value is isolated to that key" do
      {actual, expected} = Assertx.match(%{a: 1, b: 2}, %{a: 1, b: 99})
      assert actual == %{a: 1, b: 2}
      assert expected == %{a: 1, b: 99}
    end

    test "missing key in actual surfaces as nil ≠ expected" do
      {actual, expected} = Assertx.match(%{}, %{a: 1})
      assert actual == %{a: nil}
      assert expected == %{a: 1}
    end

    test "nested maps compose" do
      assert {%{a: %{b: 1}}, %{a: %{b: 1}}} ==
               Assertx.match(%{a: %{b: 1}}, %{a: %{b: 1}})
    end

    test "nested mismatch only differs at the deep leaf" do
      {actual, expected} =
        Assertx.match(%{a: %{b: 1, c: 2}}, %{a: %{b: 1, c: 99}})

      assert actual == %{a: %{b: 1, c: 2}}
      assert expected == %{a: %{b: 1, c: 99}}
    end

    test "predicates inside maps work" do
      {actual, expected} =
        Assertx.match(%{age: 17}, %{age: M.predicate(&(&1 >= 18), "adult")})

      assert actual == %{age: 17}
      assert expected == %{age: %Failed{label: "adult", actual: 17}}
    end

    test "non-map actual surfaces raw values for a structural diff" do
      assert {:not_a_map, %{a: 1}} == Assertx.match(:not_a_map, %{a: 1})
    end

    test "string keys also work" do
      assert {%{"k" => 1}, %{"k" => 1}} ==
               Assertx.match(%{"k" => 1, "extra" => 2}, %{"k" => 1})
    end
  end

  describe "match/2 — lists with a single matcher (M.all/1)" do
    test "every element satisfies the matcher" do
      assert {[1, 2, 3], [1, 2, 3]} == Assertx.match([1, 2, 3], M.all(&(&1 > 0)))
    end

    test "one failing element is isolated on the expected side" do
      {actual, expected} =
        Assertx.match([1, -1, 3], M.all(M.predicate(&(&1 > 0), "positive")))

      assert actual == [1, -1, 3]
      assert expected == [1, %Failed{label: "positive", actual: -1}, 3]
    end

    test "empty list trivially matches" do
      assert {[], []} == Assertx.match([], M.all(&(&1 > 0)))
    end

    test "non-list actual surfaces raw values" do
      assert {:nope, _} = Assertx.match(:nope, M.all(&(&1 > 0)))
    end
  end

  describe "match/2 — lists element-wise (M.all([...]) or list shorthand)" do
    test "element-wise match with equal sizes" do
      assert {[1, 2], [1, 2]} == Assertx.match([1, 2], [1, 2])
    end

    test "size mismatch surfaces raw lists for a structural diff" do
      {actual, expected} = Assertx.match([1, 2, 3], [1, 2])
      assert actual == [1, 2, 3]
      assert expected == [1, 2]
    end

    test "element-wise mismatch at one position" do
      assert {[1, 99, 3], [1, 2, 3]} == Assertx.match([1, 99, 3], [1, 2, 3])
    end

    test "mixed matcher types in the element-wise list" do
      {actual, expected} =
        Assertx.match(
          [%{n: 1}, %{n: 2}],
          [%{n: 1}, %{n: M.predicate(&(&1 > 100), "big")}]
        )

      assert actual == [%{n: 1}, %{n: 2}]
      assert expected == [%{n: 1}, %{n: %Failed{label: "big", actual: 2}}]
    end
  end

  describe "Failed Inspect impl" do
    test "renders integer values" do
      assert inspect(%Failed{label: "adult", actual: 17}) == "#Failed<adult: 17>"
    end

    test "delegates value rendering to Inspect" do
      assert inspect(%Failed{label: "uuid", actual: "x"}) == ~s(#Failed<uuid: "x">)
    end

    test "renders nil values" do
      assert inspect(%Failed{label: "present", actual: nil}) == "#Failed<present: nil>"
    end
  end

  describe "assertx — passes for matching shapes" do
    test "literal equality" do
      assertx 1, 1
    end

    test "atom equality" do
      assertx :ok, :ok
    end

    test "exact map" do
      assertx %{a: 1, b: 2}, %{a: 1, b: 2}
    end

    test "partial map — extra keys ignored" do
      assertx %{a: 1, b: 2, extra: :ignored}, %{a: 1}
    end

    test "M.predicate" do
      assertx 21, M.predicate(&(&1 >= 18), "adult")
    end

    test "bare predicate function" do
      assertx 21, &(&1 >= 18)
    end

    test "nested map" do
      user = %{name: "Alice", profile: %{age: 30, country: "UK"}}
      assertx user, %{name: "Alice", profile: %{age: 30}}
    end

    test "list element-wise via shorthand" do
      assertx [1, 2, 3], [1, 2, 3]
    end

    test "list with M.all and a single predicate" do
      assertx [1, 2, 3], M.all(&(&1 > 0))
    end

    test "list with M.all and per-element matchers" do
      assertx [%{n: 1}, %{n: 2}], M.all([%{n: 1}, %{n: M.predicate(&(&1 > 0), "positive")}])
    end

    test "deeply nested combination" do
      payload = %{
        user: %{
          email: "alice@example.com",
          age: 30,
          roles: [:admin, :writer]
        },
        meta: %{request_id: "r-123"}
      }

      assertx payload, %{
        user: %{
          email: "alice@example.com",
          age: M.predicate(&(&1 >= 18), "adult"),
          roles: M.all(&is_atom/1)
        }
      }
    end
  end

  describe "assertx — failures raise ExUnit.AssertionError" do
    test "value mismatch populates left and right" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx(1, 2)
        end

      assert err.left == 1
      assert err.right == 2
    end

    test "carries the assertx label in the message" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx(1, 2)
        end

      assert err.message == "assertx failed"
    end

    test "map mismatch shows only the asserted keys on each side" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx(%{a: 1, b: 2, untouched: :ok}, %{a: 1, b: 99})
        end

      assert err.left == %{a: 1, b: 2}
      assert err.right == %{a: 1, b: 99}
      refute Map.has_key?(err.left, :untouched)
    end

    test "predicate failure surfaces a Failed sentinel on the right" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx(17, M.predicate(&(&1 >= 18), "adult"))
        end

      assert err.left == 17
      assert err.right == %Failed{label: "adult", actual: 17}
    end

    test "deeply nested mismatch isolates the failing leaf" do
      actual = %{user: %{profile: %{age: 17, country: "UK"}}}

      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx(actual, %{
            user: %{profile: %{age: M.predicate(&(&1 >= 18), "adult")}}
          })
        end

      assert err.left == %{user: %{profile: %{age: 17}}}
      assert %{user: %{profile: %{age: %Failed{label: "adult", actual: 17}}}} = err.right
    end

    test "list element-wise size mismatch surfaces raw lists" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx([1, 2, 3], [1, 2])
        end

      assert err.left == [1, 2, 3]
      assert err.right == [1, 2]
    end

    test "M.all mismatch isolates the failing element" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx([1, -1, 3], M.all(M.predicate(&(&1 > 0), "positive")))
        end

      assert err.left == [1, -1, 3]
      assert err.right == [1, %Failed{label: "positive", actual: -1}, 3]
    end

    test "missing map key shows as nil on the left" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx(%{}, %{required: :present})
        end

      assert err.left == %{required: nil}
      assert err.right == %{required: :present}
    end

    test "non-map actual against a map spec surfaces structural mismatch" do
      err =
        assert_raise ExUnit.AssertionError, fn ->
          assertx(:not_a_map, %{a: 1})
        end

      assert err.left == :not_a_map
      assert err.right == %{a: 1}
    end
  end

  describe "assertx — return value" do
    test "returns the original actual value on success" do
      user = %{a: 1, b: 2, c: 3}
      assert user == assertx(user, %{a: 1})
    end

    test "evaluates actual only once" do
      counter = :counters.new(1, [])
      bump = fn -> :counters.add(counter, 1, 1) end

      side_effect = fn ->
        bump.()
        42
      end

      assertx(side_effect.(), 42)
      assert :counters.get(counter, 1) == 1
    end
  end
end
