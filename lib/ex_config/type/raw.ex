defmodule ExConfig.Type.Raw do
  @moduledoc """
  """
  use ExConfig.Type
  @type result() :: any()

  defstruct []

  @impl ExConfig.Type
  def preserve_charlist?, do: true

  @impl ExConfig.Type
  def handle(data, _), do: {:ok, data}
end
