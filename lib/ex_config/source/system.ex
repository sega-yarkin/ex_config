defmodule ExConfig.Source.System do
  @behaviour ExConfig.Source
  alias ExConfig.Param

  @enforce_keys [:name]
  defstruct [:name, :default]

  @type t() :: %__MODULE__{
    name:    String.t() | [String.t()],
    default: term(),
  }

  @impl true
  def handle(param, %__MODULE__{name: name} = opts) do
    names = List.wrap(name)
    data = Enum.find_value(names, opts.default, &System.get_env/1)
    case data do
      nil  -> %Param{param | data: nil, exist?: false}
      data -> %Param{param | data: data, exist?: true}
    end
  end
end
