defmodule ExConfig.Type.Boolean do
  @moduledoc """
  Boolean type implementation.

  Supported case-insensitive values:
  * `"true"`, `"yes"` -> `true`
  * `"false"`, `"no"` -> `false`
  """
  use ExConfig.Type

  defstruct []

  @impl true
  def handle(data, _opts), do: do_handle(data)

  @doc false
  @spec error(atom, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot parse '#{inspect(data)}' as a boolean"}

  defp do_handle(data) when is_boolean(data), do: {:ok, data}
  defp do_handle(data) when is_binary(data) do
    case String.downcase(data) do
      "true"  -> {:ok, true}
      "yes"   -> {:ok, true}
      "false" -> {:ok, false}
      "no"    -> {:ok, false}
      _       -> error(:bad_data, data)
    end
  end
  defp do_handle(data) when is_list(data), do: do_handle(to_string(data))
  defp do_handle(data), do: error(:bad_data, data)

end
