defmodule ExConfig.Type.Number do
  @moduledoc """
  Number type implementation.
  """
  use ExConfig.Type
  alias ExConfig.Utils.NumRange

  @type result() :: number()

  defstruct [:range]
  @type t() :: %__MODULE__{
    range: nil | NumRange.t(),
  }

  @impl ExConfig.Type
  def validators, do: [
    range: &NumRange.validate/1,
  ]

  @impl ExConfig.Type
  def handle(data, %{} = opts) when is_float(data) do
    maybe_check_range(data, opts)
  end

  def handle(data, %{} = opts) when is_integer(data) do
    maybe_check_range(data / 1, opts)
  end

  def handle(data, %{} = opts) do
    case do_parse(data) do
      :error -> error(:bad_data, data)
      value when is_float(value) -> handle(value, opts)
    end
  end

  @doc false
  @spec error(:bad_data | :out_of_range, any()) :: {:error, String.t()}
  def error(:bad_data, data), do: {:error, "Cannot parse '#{inspect(data)}' as a number"}
  def error(:out_of_range, {data, range}), do: {:error, "#{data} is out of range #{NumRange.to_string(range)}"}


  defp do_parse(data) when is_binary(data) do
    case Float.parse(String.trim(data)) do
      {value, ""} -> value
      _           -> :error
    end
  end
  defp do_parse(_), do: :error

  @doc false
  @spec maybe_check_range(number, map) :: {:ok, float} | {:error, String.t}
  def maybe_check_range(value, %{range: range}) when range != nil do
    if NumRange.in_range?(value, range),
      do: {:ok, value},
      else: error(:out_of_range, {value, range})
  end
  def maybe_check_range(value, _), do: {:ok, value}

end
