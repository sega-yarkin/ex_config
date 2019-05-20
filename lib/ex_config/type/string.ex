defmodule ExConfig.Type.String do
  @behaviour ExConfig.Type

  defstruct []

  @impl true
  def init(_), do: %__MODULE__{}

  @impl true
  def handle(data, _opts) when is_binary(data), do: {:ok, data}

  def handle(data, opts) when is_list(data),
    do: handle(to_string(data), opts)

  def handle(data, _opts),
    do: {:error, "Cannot handle '#{inspect(data)}' as a string"}

end
