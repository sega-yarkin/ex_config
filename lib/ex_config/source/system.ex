defmodule ExConfig.Source.System do
  @behaviour ExConfig.Source

  @enforce_keys [:name]
  defstruct [:name, :default]

  @type t() :: %__MODULE__{
    name:    String.t() | [String.t()],
    default: String.t() | nil,
  }

  @impl true
  def handle(%{name: name, default: default}, _) do
    data = Enum.find_value(List.wrap(name), default, &System.get_env/1)
    {:ok, data}
  end
end
