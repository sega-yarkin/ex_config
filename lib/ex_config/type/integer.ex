defmodule ExConfig.Type.Integer do
  @behaviour ExConfig.Type
  alias ExConfig.Param
  alias ExConfig.Type.Number

  defstruct base: 10,
            range: nil
  @type t() :: %__MODULE__{
    base: 2..36,
    range: nil | Number.range(),
  }

  @impl true
  def init(opts) do
    struct!(__MODULE__, Keyword.take(opts, [:base, :range]))
  end

  @impl true
  def handle(data, opts) do
    Param.until_error(data, [
      &parse(&1, opts),
      &Number.maybe_check_range(&1, opts),
    ])
  end

  defp parse(data, _) when is_integer(data), do: data
  defp parse(data, opts) when is_list(data), do: parse(to_string(data), opts)
  defp parse(data, opts) when is_binary(data) do
    case Integer.parse(data, opts.base) do
      {value, _} -> {:ok, value}
      :error     -> {:error, "Cannot parse '#{inspect(data)}' as an integer"}
    end
  end
  defp parse(data, _), do: {:error, "Cannot parse '#{inspect(data)}' as an integer"}
end
