defmodule ExConfig.Type.String do
  @moduledoc """
  """
  use ExConfig.Type

  defstruct []

  @impl true
  def handle(data, _opts), do: do_handle(data)

  @doc false
  @spec error(atom, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot handle '#{inspect(data)}' as a string"}

  defp do_handle(data) when is_binary(data), do: {:ok, data}
  defp do_handle(data) when is_list(data), do: do_handle(to_string(data))
  defp do_handle(data), do: error(:bad_data, data)
end
