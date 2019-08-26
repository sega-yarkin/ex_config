defmodule ExConfig.Source.System do
  @behaviour ExConfig.Source

  @enforce_keys [:name]
  defstruct [:name, :default]

  @type t() :: %__MODULE__{
    name:    String.t() | [String.t()],
    default: term(),
  }

  @impl true
  def handle(%{name: name, default: default}, _) do
    names = List.wrap(name)
    data = Enum.find_value(names, default, &System.get_env/1)
    {:ok, data}
  end
end
