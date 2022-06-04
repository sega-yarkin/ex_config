defmodule ExConfig.Source.FS.FileContent do
  @behaviour ExConfig.Source

  @enforce_keys [:path]
  defstruct [:path, :default]

  @type t() :: %__MODULE__{
    path:    String.t() | [String.t()],
    default: binary() | nil,
  }

  @impl ExConfig.Source
  def handle(%{path: path, default: default}, _) do
    data = Enum.find_value(List.wrap(path), default, &get_file/1)
    {:ok, data}
  end

  @spec get_file(String.t) :: binary | nil
  defp get_file(path) do
    case File.read(path) do
      {:ok, data} -> data
      _           -> nil
    end
  end
end
