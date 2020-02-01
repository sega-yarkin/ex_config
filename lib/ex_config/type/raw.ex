defmodule ExConfig.Type.Raw do
  @moduledoc """
  """
  use ExConfig.Type
  @type result() :: any()

  defstruct []

  @impl true
  def handle(data, _), do: {:ok, data}
end
