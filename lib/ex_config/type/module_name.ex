defmodule ExConfig.Type.ModuleName do
  @behaviour ExConfig.Type

  defstruct should_exist?: true

  @impl true
  def init(opts) do
    struct!(__MODULE__, Keyword.take(opts, [:should_exist?]))
  end

  @impl true
  def handle(data, opts) do
    with {:ok, name} <- maybe_convert(data),
         :ok         <- valid?(name, opts),
      do: {:ok, name}
  end


  defp maybe_convert(name) when is_atom(name),
    do: {:ok, name}

  defp maybe_convert(name) when byte_size(name) > 0 do
    name =
      case name do
        <<":"      , _ :: binary>> -> name # Erlang module
        <<"Elixir.", _ :: binary>> -> name # Elixir one
        _ -> "Elixir.#{name}" # By default Elixir module without prefix
      end
    {:ok, String.to_atom(name)}
  end

  defp maybe_convert(name) when is_list(name),
    do: maybe_convert(to_string(name))

  defp maybe_convert(name),
    do: {:error, "Cannot convert #{inspect(name)} to module name"}


  defp valid?(module, %{should_exist?: true}) do
    try do
      apply(module, :module_info, [:module])
      :ok
    rescue
      _ -> {:error, "Module #{module} is not available"}
    end
  end
  defp valid?(_module, _), do: :ok
end
