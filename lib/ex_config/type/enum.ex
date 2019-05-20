defmodule ExConfig.Type.Enum do
  @behaviour ExConfig.Type

  @enforce_keys [:values]
  defstruct [:values]
  @type t() :: %__MODULE__{
    values: nonempty_list(atom()),
  }

  @impl true
  def init(opts) do
    enum = struct!(__MODULE__, Keyword.take(opts, [:values]))
    unless length(enum.values) > 0 do
      raise ArgumentError, "Enum values cannot be empty"
    end
    enum
  end

  @impl true
  def handle(data, %{values: values}) when byte_size(data) > 0 do
    as_atom = String.to_atom(data)
    if as_atom in values,
      do: {:ok, as_atom},
    else: {:error, "Wrong enum value '#{inspect(as_atom)}', only accept #{inspect(values)}"}
  end

  def handle(data, _), do: {:error, "Cannot handle '#{inspect(data)}' as an enum"}

end
