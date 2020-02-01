defmodule ExConfig.Cache.InModule do
  @moduledoc """
  """
  @behaviour ExConfig.Cache
  alias ExConfig.Mod

  @impl true
  @spec wrap(module, Keyword.t) :: {:ok, module}
  def wrap(source, target: target), do: compile_module(source, target)

  @impl true
  @spec get(Keyword.t) :: module
  def get(target: target), do: target


  @spec compile_module(module, module) :: {:ok, module}
  defp compile_module(source, target) do
    meta = source.__meta__()
    data = source._all()

    parameters =
      meta
      |> Keyword.fetch!(:parameters)
      |> Enum.map(fn {name, _} ->
        quote do
          def unquote(name)(), do: unquote(Macro.escape(data[name]))
        end
      end)

    meta
    |> Keyword.fetch!(:keywords)
    |> Enum.each(fn {name, mod} ->
      mod_target = Mod.child_mod_name(target, name)
      {:ok, _} = compile_module(mod, mod_target)
    end)

    resources =
      meta
      |> Keyword.fetch!(:resources)
      |> Enum.map(fn {_name, %{one: one, all: all}} ->
        instances = apply(source, all, [])
        quote do
          def unquote(all)(), do: unquote(Macro.escape(instances))
          def unquote(one)(name), do: unquote(all)()[name]
        end
      end)

    all =
      quote do
        def _all(), do: unquote(Macro.escape(data))
      end

    content = List.flatten([parameters, all, resources])
    {:module, module, _, _} =
        Module.create(target, content, Macro.Env.location(__ENV__))
    {:ok, module}
  end
end
