defmodule ExConfig.Type.String do
  @moduledoc """
  """
  use ExConfig.Type
  @type result() :: String.t()
  defstruct []

  @doc """
  Helper to transform Elixir string value to Erlang string.
  """
  @spec to_charlist(ExConfig.Param.t) :: ExConfig.Param.t
  def to_charlist(%{data: data} = param) when is_binary(data) do
    %{param | data: String.to_charlist(data)}
  end
  def to_charlist(param), do: param

  @impl true
  def handle(data, _opts), do: do_handle(data)

  @doc false
  @spec error(:bad_data, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot handle '#{inspect(data)}' as a string"}

  defp do_handle(data) when is_binary(data), do: {:ok, data}
  defp do_handle(data) when is_list(data), do: do_handle(to_string(data))
  defp do_handle(data), do: error(:bad_data, data)
end
