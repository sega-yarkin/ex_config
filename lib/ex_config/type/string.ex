defmodule ExConfig.Type.String do
  @moduledoc """
  """
  use ExConfig.Type
  @type result() :: String.t()
  defstruct []

  @doc """
  Helper to transform Elixir string value to Erlang string.
  """
  @spec to_charlist(ExConfig.Param.t()) :: ExConfig.Param.t()
  def to_charlist(%{data: data} = param) when is_binary(data) do
    %{param | data: String.to_charlist(data)}
  end
  def to_charlist(param), do: param

  @doc """
  Converts all characters in the string to lowercase.
  """
  @spec transform_downcase(ExConfig.Param.t()) :: ExConfig.Param.t()
  def transform_downcase(%{data: data} = param) when is_binary(data) do
    %{param | data: String.downcase(data)}
  end
  def transform_downcase(param), do: param

  @doc """
  Converts all characters in the string to uppercase.
  """
  @spec transform_upcase(ExConfig.Param.t()) :: ExConfig.Param.t()
  def transform_upcase(%{data: data} = param) when is_binary(data) do
    %{param | data: String.upcase(data)}
  end
  def transform_upcase(param), do: param

  @impl ExConfig.Type
  def handle(data, _opts), do: do_handle(data)

  @doc false
  @spec error(:bad_data, any()) :: {:error, String.t()}
  def error(:bad_data, data), do: {:error, "Cannot handle '#{inspect(data)}' as a string"}

  defp do_handle(data) when is_binary(data), do: {:ok, data}
  defp do_handle(data), do: error(:bad_data, data)
end
