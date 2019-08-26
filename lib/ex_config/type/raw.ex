defmodule ExConfig.Type.Raw do
  @moduledoc """
  """
  use ExConfig.Type

  defstruct []

  @impl true
  def handle(data, _), do: {:ok, data}
end
