defmodule ExConfig.Cache.PersistentTerm do
  @moduledoc """
  OTP 21.2+
  """
  @behaviour ExConfig.Cache

  @impl true
  @spec wrap(module, Keyword.t) :: {:ok, map}
  def wrap(module, opts \\ []) do
    cache = get_config_data(module)
    :persistent_term.put(get_pt_id(opts), cache)
    {:ok, cache}
  end

  @impl true
  @spec get(Keyword.t) :: map
  def get(opts \\ []) do
    :persistent_term.get(get_pt_id(opts))
  end

  defmacro config(opts \\ []) do
    pt_id = get_pt_id(opts)
    quote do
      :persistent_term.get(unquote(pt_id))
    end
  end


  @spec get_pt_id(Keyword.t) :: {module, atom}
  defp get_pt_id(opts) do
    id = Keyword.get(opts, :id, :default)
    {__MODULE__, id}
  end

  @spec get_config_data(module) :: map
  defp get_config_data(module) do
    meta = module.__meta__()
    data = module._all()

    parameters =
      meta
      |> Keyword.fetch!(:parameters)
      |> Enum.map(fn {name, _} -> {name, data[name]} end)

    keywords =
      meta
      |> Keyword.fetch!(:keywords)
      |> Enum.map(fn {name, mod} -> {name, get_config_data(mod)} end)

    resources =
      meta
      |> Keyword.fetch!(:resources)
      |> Enum.map(fn {_name, %{one: one, all: all}} ->
        data = apply(module, all, [])
        [{one, data}, {all, data}]
      end)

    Map.new(parameters ++ keywords ++ List.flatten(resources))
  end
end
