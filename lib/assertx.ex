defmodule Assertx do
  alias Assertx.Matchers, as: M

  defmodule Match do
    @keys [:value]
    @enforce_keys @keys
    defstruct @keys

    def new(value) do
      %Match{value: value}
    end
  end

  defmodule Mismatch do
    @keys [:value]
    @enforce_keys @keys
    defstruct @keys

    def new(value) do
      %Mismatch{value: value}
    end
  end

  #### MATCH ####

  def match(left, right) when not is_function(right) do
    match(left, default_matcher(right))
  end

  def match(left, right) when is_function(right) do
    case right.(left) do
      result when is_boolean(result) -> lift_boolean(result, left, right)
      result -> result
    end
  end

  defp default_matcher(right) when is_map(right), do: M.map(right)
  defp default_matcher(right) when is_list(right), do: M.all(right)
  defp default_matcher(right), do: M.eq(right)

  defp lift_boolean(result, left, right) when is_boolean(result) and is_function(right) do
    case result do
      true -> Match.new({left, right})
      false -> Mismatch.new({left, right})
    end
  end

  #### RENDER ####

  defmodule RenderContext do
    defstruct indent_level: 0, indent: "  "

    def indent(render_ctx) do
      %{render_ctx | indent_level: render_ctx.indent_level + 1}
    end
  end

  def render(value) do
    value
    |> do_render(%RenderContext{})
    |> IO.iodata_to_binary()
  end

  defp do_render(%Match{value: {:eq, left, right}}, _ctx) do
    [IO.ANSI.green(), "#{left} == #{right}", IO.ANSI.reset()]
  end

  defp do_render(%Mismatch{value: {:neq, left, right}}, _ctx) do
    [IO.ANSI.red(), "#{left} != #{right}", IO.ANSI.reset()]
  end

  defp do_render(%Match{value: {left, right}}, _ctx) when is_function(right) do
    [IO.ANSI.green(), "#{inspect(left)} matches #{inspect(right)}", IO.ANSI.reset()]
  end

  defp do_render(%Mismatch{value: {left, right}}, _ctx) when is_function(right) do
    [IO.ANSI.red(), "#{inspect(left)} does not match #{inspect(right)}", IO.ANSI.reset()]
  end

  defp do_render(%Match{value: map}, ctx) when is_map(map) and not is_struct(map) do
    render_map(map, ctx, IO.ANSI.green())
  end

  defp do_render(%Mismatch{value: map}, ctx) when is_map(map) and not is_struct(map) do
    render_map(map, ctx, IO.ANSI.red())
  end

  defp do_render(%Match{value: list}, ctx) when is_list(list) do
    render_list(list, ctx, IO.ANSI.green())
  end

  defp do_render(%Mismatch{value: list}, ctx) when is_list(list) do
    render_list(list, ctx, IO.ANSI.red())
  end

  defp render_map(map, ctx, color) do
    inner_ctx = RenderContext.indent(ctx)

    entries =
      Enum.map(map, fn {key, result} ->
        [render_indent(inner_ctx), color, "#{key}: ", do_render(result, inner_ctx), "\n"]
      end)

    [color, "%{\n", entries, render_indent(ctx), color, "}", IO.ANSI.reset()]
  end

  defp render_list(list, ctx, color) do
    inner_ctx = RenderContext.indent(ctx)

    entries =
      Enum.map(list, fn result ->
        [render_indent(inner_ctx), do_render(result, inner_ctx), "\n"]
      end)

    [color, "[\n", entries, render_indent(ctx), color, "]", IO.ANSI.reset()]
  end

  defp render_indent(%{indent_level: 0}), do: ""

  defp render_indent(%{indent_level: level, indent: indent}) do
    String.duplicate(indent, level)
  end
end
