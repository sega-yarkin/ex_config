defmodule ExConfig.Type.Boolean do
  @behaviour ExConfig.Type

  defstruct []

  @impl true
  def init(_), do: %__MODULE__{}

  @impl true
  def handle(data, _opts), do: do_handle(data)


  defp do_handle(data) when is_boolean(data), do: {:ok, data}

  defp do_handle(data) when is_binary(data) do
    case String.downcase(data) do
      "true"  -> {:ok, true}
      "false" -> {:ok, false}
      _       -> {:error, "Cannot handle '#{inspect(data)}' as a boolean"}
    end
  end

  defp do_handle(data) when is_list(data),
    do: do_handle(to_string(data))

  defp do_handle(data),
    do: {:error, "Cannot handle '#{inspect(data)}' as a boolean"}

end
