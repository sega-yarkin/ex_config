defmodule ExConfig.Type.Integer do
  @moduledoc """
  Integer type implementation.
  """
  use ExConfig.Type
  alias ExConfig.Param
  alias ExConfig.Type.Number
  alias ExConfig.Utils.NumRange

  @type result() :: integer()

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
  def handle(data, %{} = opts) do
    Param.until_error(data, [
      &parse(&1, opts),
      &Number.maybe_check_range(&1, opts),
    ])
  end

  @doc false
  @spec error(:bad_data, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot parse '#{inspect(data)}' as an integer"}

  @spec validate_base(any) :: ExConfig.Type.validator_result(2..36)
  defp validate_base(nil), do: :skip
  defp validate_base(base) when base in 2..36, do: {:ok, base}
  defp validate_base(_), do: :error

  @spec parse(any, map) :: {:ok, integer} | {:error, String.t}
  defp parse(data, _) when is_integer(data), do: {:ok, data}
  defp parse(data, %{} = opts) do
    case do_parse(data, opts) do
      :error -> error(:bad_data, data)
      value when is_integer(value) -> {:ok, value}
    end
  end

  defp do_parse(data, opts) when is_list(data), do: do_parse(to_string(data), opts)
  defp do_parse(<<"0b", num :: binary>>, %{base: 2} = opts), do: do_parse_str(num, opts)
  defp do_parse(<<"0o", num :: binary>>, %{base: 8} = opts), do: do_parse_str(num, opts)
  defp do_parse(<<"0x", num :: binary>>, %{base: 16} = opts), do: do_parse_str(num, opts)
  defp do_parse(data, opts) when is_binary(data), do: do_parse_str(data, opts)
  defp do_parse(_, _), do: :error

  defp do_parse_str(str, %{base: base}) do
    case Integer.parse(String.trim(str), base) do
      {value, ""} -> value
      _           -> :error
    end
  end

end
