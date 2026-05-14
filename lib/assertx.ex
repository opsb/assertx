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

  defp do_render(%Match{value: value}, ctx), do: do_render_value(value, ctx, :match)
  defp do_render(%Mismatch{value: value}, ctx), do: do_render_value(value, ctx, :mismatch)

  defp do_render_value({:eq, left, right}, _ctx, :match) do
    leaf(:match, "#{inspect(left)} == #{inspect(right)}")
  end

  defp do_render_value({:neq, left, right}, _ctx, :mismatch) do
    leaf(:mismatch, "#{inspect(left)} != #{inspect(right)}")
  end

  defp do_render_value({left, right}, _ctx, :match) when is_function(right) do
    leaf(:match, "#{inspect(left)} matches predicate")
  end

  defp do_render_value({left, right}, _ctx, :mismatch) when is_function(right) do
    leaf(:mismatch, "#{inspect(left)} does not match predicate")
  end

  defp do_render_value(map, ctx, _kind) when is_map(map) and not is_struct(map) do
    render_map(map, ctx)
  end

  defp do_render_value(list, ctx, _kind) when is_list(list) do
    render_list(list, ctx)
  end

  defp leaf(:match, body), do: [IO.ANSI.green(), body, IO.ANSI.reset()]
  defp leaf(:mismatch, body), do: [IO.ANSI.red(), body, IO.ANSI.reset()]

  defp render_map(map, ctx) do
    inner_ctx = RenderContext.indent(ctx)

    entries =
      map
      |> Enum.sort_by(fn {key, _} -> key end)
      |> Enum.map(fn {key, result} ->
        [render_indent(inner_ctx), render_key(key), do_render(result, inner_ctx)]
      end)
      |> Enum.intersperse(",\n")

    ["%{\n", entries, "\n", render_indent(ctx), "}"]
  end

  defp render_list(list, ctx) do
    inner_ctx = RenderContext.indent(ctx)

    entries =
      list
      |> Enum.map(fn result -> [render_indent(inner_ctx), do_render(result, inner_ctx)] end)
      |> Enum.intersperse(",\n")

    ["[\n", entries, "\n", render_indent(ctx), "]"]
  end

  defp render_key(key) when is_atom(key), do: "#{key}: "
  defp render_key(key), do: "#{inspect(key)} => "

  defp render_indent(%{indent_level: 0}), do: ""

  defp render_indent(%{indent_level: level, indent: indent}) do
    String.duplicate(indent, level)
  end
end
