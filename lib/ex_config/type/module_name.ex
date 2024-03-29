defmodule ExConfig.Type.ModuleName do
  @moduledoc """
  """
  use ExConfig.Type
  @type result() :: atom()

  defstruct should_exist?: true

  @impl ExConfig.Type
  def validators, do: [
    should_exist?: &ExConfig.Type.validator_boolean/1,
  ]

  @impl ExConfig.Type
  def handle(data, opts) do
    with {:ok, name} <- maybe_convert(data),
         :ok         <- ensure_valid(name, opts),
      do: {:ok, name}
  end

  @doc false
  @spec error(:bad_data | :not_available, any()) :: {:error, String.t()}
  def error(:bad_data, name), do: {:error, "Cannot convert #{inspect(name)} to module name"}
  def error(:not_available, name), do: {:error, "Module #{name} is not available"}


  defp maybe_convert(name) when is_atom(name), do: {:ok, name}
  defp maybe_convert(name) when byte_size(name) > 0 do
    # TODO: Add RegExp name matching/validation
    name =
      case name do
        <<":"      , name :: binary>> -> name # Erlang module
        <<"Elixir.", _any :: binary>> -> name # Elixir one
        _ -> "Elixir.#{name}" # By default Elixir module without prefix
      end

    {:ok, String.to_atom(name)}
  end
  defp maybe_convert(name), do: error(:bad_data, name)


  defp ensure_valid(module, %{should_exist?: true}) do
    _ = module.module_info(:module)
    :ok
  rescue
    _ -> error(:not_available, module)
  end
  defp ensure_valid(_module, _), do: :ok
end
