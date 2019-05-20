defmodule ExConfig.Type.Raw do
  @behaviour ExConfig.Type

  defstruct []

  @impl true
  def init(_), do: %__MODULE__{}

  @impl true
  def handle(data, _), do: {:ok, data}
end
