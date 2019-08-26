defmodule ExConfig.Type.Integer do
  @moduledoc """
  Integer type implementation.
  """
  use ExConfig.Type
  alias ExConfig.Param
  alias ExConfig.Type.Number
  alias ExConfig.Util.NumRange

  defstruct base: 10,
            range: nil
  @type t() :: %__MODULE__{
    base: 2..36,
    range: nil | NumRange.t(),
  }

  @impl true
  def validators, do: [
    range: &NumRange.validate/1,
    base: &validate_base/1,
  ]

  @impl true
  def handle(data, opts) do
    Param.until_error(data, [
      &parse(&1, opts),
      &Number.maybe_check_range(&1, opts),
    ])
  end

  @doc false
  @spec error(atom, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot parse '#{inspect(data)}' as an integer"}

  @spec validate_base(any) :: ExConfig.Type.validator_result(2..36)
  defp validate_base(nil), do: :skip
  defp validate_base(base) when base in 2..36, do: {:ok, base}
  defp validate_base(_), do: :error

  @spec parse(any, map) :: {:ok, integer} | {:error, String.t}
  defp parse(data, _) when is_integer(data), do: {:ok, data}
  defp parse(data, opts) when is_list(data), do: parse(to_string(data), opts)
  defp parse(<<"0b", num :: binary>>, %{base: 2} = opts), do: parse(num, opts)
  defp parse(<<"0o", num :: binary>>, %{base: 8} = opts), do: parse(num, opts)
  defp parse(<<"0x", num :: binary>>, %{base: 16} = opts), do: parse(num, opts)
  defp parse(data, opts) when is_binary(data) do
    case data |> String.trim() |> Integer.parse(opts.base) do
      {value, ""} -> {:ok, value}
      _           -> error(:bad_data, data)
    end
  end
  defp parse(data, _), do: error(:bad_data, data)

end
