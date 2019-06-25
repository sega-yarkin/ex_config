defmodule ExConfig.Cache.PersistentTerm do
  # OTP 21.2+
  @behaviour ExConfig.Cache

  @spec wrap(module, keyword) :: {:ok, map}
  def wrap(module, opts \\ []) do
    cache = get_config_data(module)
    :persistent_term.put(get_pt_id(opts), cache)
    {:ok, cache}
  end

  @spec get(keyword) :: map
  def get(opts \\ []) do
    :persistent_term.get(get_pt_id(opts))
  end

  @spec get_pt_id(keyword) :: any
  defp get_pt_id(opts) do
    id = Keyword.get(opts, :id, :default)
    {__MODULE__, id}
  end

  @spec get_config_data(module) :: map
  defp get_config_data(module) do
    meta = module.__meta__()
    data = module._all()

    parameters =
      for {name, _} <- meta[:parameters], do: {name, data[name]}

    keywords =
      for {name, mod} <- meta[:keywords], do: {name, get_config_data(mod)}

    resources =
      for {_name, %{one: one, all: all}} <- meta[:resources] do
        data = apply(module, all, [])
        [{one, data}, {all, data}]
      end

    Map.new(parameters ++ keywords ++ List.flatten(resources))
  end
end
