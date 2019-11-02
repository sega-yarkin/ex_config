defmodule ExConfig.Source.FS.Glob do
  @behaviour ExConfig.Source

  @enforce_keys [:expr]
  defstruct [:expr, match_dot: false]

  @type t() :: %__MODULE__{
    expr:      String.t() | [String.t()],
    match_dot: boolean(),
  }

  @impl true
  def handle(%{expr: expr, match_dot: match_dot}, _) do
    opts = [match_dot: match_dot]
    data =
      expr
      |> List.wrap()
      |> Enum.map(&Path.wildcard(&1, opts))
      |> Enum.concat()

    {:ok, data}
  end

end
