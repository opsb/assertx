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
    IO.iodata_to_binary(
      do_render(%RenderContext{}, value)
      |> IO.inspect(label: "render components")
    )
  end

  def do_render(_render_ctx, {:match, {:eq, left, right}}) do
    [IO.ANSI.green(), "#{left} == #{right}"]
  end

  def do_render(_render_ctx, {:mismatch, {:neq, left, right}}) do
    [IO.ANSI.red(), "#{left} != #{right}"]
  end

  def do_render(render_ctx, {:match, map}) when is_map(map) do
    [
      IO.ANSI.green(),
      ["%{", "\n"],
      Enum.map(map, &do_render_entry(RenderContext.indent(render_ctx), &1)),
      [render_indent(render_ctx), "}"]
    ]
  end

  def do_render_entry(render_ctx, {k, result = {:match, _}}) do
    [render_indent(render_ctx), [IO.ANSI.green(), "#{k}: ", do_render(render_ctx, result)], "\n"]
  end

  def render_indent(%{indent_level: 0}) do
    ""
  end

  def render_indent(render_ctx) do
    1..render_ctx.indent_level
    |> Enum.map(fn _ -> render_ctx.indent end)
    |> Enum.join()
  end
end
