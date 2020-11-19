defmodule ExConfig.Type.Number do
  @moduledoc """
  Number type implementation.
  """
  use ExConfig.Type
  alias ExConfig.Param
  alias ExConfig.Utils.NumRange

  @type result() :: number()

  defstruct [:range]
  @type t() :: %__MODULE__{
    range: nil | NumRange.t(),
  }

  @impl true
  def validators, do: [
    range: &NumRange.validate/1,
  ]

  @impl true
  def handle(data, opts) do
    Param.until_error(data, [
      &parse/1,
      &maybe_check_range(&1, opts),
    ])
  end

  @doc false
  @spec error(:bad_data | :out_of_range, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot parse '#{inspect(data)}' as a number"}
  def error(:out_of_range, {data, range}), do: {:error, "#{data} is out of range #{NumRange.to_string(range)}"}

  @spec parse(any) :: {:ok, float} | {:error, String.t}
  defp parse(data) when is_float(data), do: {:ok, data}
  defp parse(data) when is_integer(data), do: {:ok, data / 1}
  defp parse(data) when is_binary(data) do
    case data |> String.trim() |> Float.parse() do
      {value, ""} -> {:ok, value}
      _           -> error(:bad_data, data)
    end
  end
  defp parse(data) when is_list(data), do: parse(to_string(data))
  defp parse(data), do: error(:bad_data, data)

  @doc false
  @spec maybe_check_range(number, map) :: {:ok, float} | {:error, String.t}
  def maybe_check_range(value, %{range: range}) when range != nil do
    if NumRange.in_range?(value, range),
      do: {:ok, value},
      else: error(:out_of_range, {value, range})
  end
  def maybe_check_range(value, _), do: {:ok, value}

end
