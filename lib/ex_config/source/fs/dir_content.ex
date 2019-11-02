defmodule ExConfig.Source.FS.DirContent do
  @behaviour ExConfig.Source

  @enforce_keys [:path]
  defstruct [:path, :default]

  @type t() :: %__MODULE__{
    path:    String.t() | [String.t()],
    default: binary() | nil,
  }

  @impl true
  def handle(%{path: path, default: default}, _) do
    data = Enum.find_value(List.wrap(path), default, &get_dir_content/1)
    {:ok, data}
  end

  @spec get_dir_content(String.t) :: [String.t] | nil
  defp get_dir_content(path) do
    case File.ls(path) do
      {:ok, data} -> data
      _           -> nil
    end
  end
end
