defmodule ExConfig.Type.Number do
  @behaviour ExConfig.Type
  alias ExConfig.Param

  @type range() :: %Range{}
                 | {min :: number(), max :: number()}
                 | {:gt | :ge | :lt | :le, number()}

  defstruct [:range]
  @type t() :: %__MODULE__{
    range: nil | range(),
  }

  @impl true
  def init(opts) do
    struct!(__MODULE__, Keyword.take(opts, [:range]))
  end

  @impl true
  def handle(data, opts) do
    Param.until_error(data, [
      &parse/1,
      &maybe_check_range(&1, opts),
    ])
  end

  defp parse(data) when is_float(data), do: data
  defp parse(data) when is_integer(data), do: data / 1
  defp parse(data) when is_binary(data) do
    case data |> String.trim() |> Float.parse() do
      {value, ""} -> {:ok, value}
      _           -> {:error, "Cannot parse '#{inspect(data)}' as a number"}
    end
  end
  defp parse(data) when is_list(data), do: parse(to_string(data))
  defp parse(data), do: {:error, "Cannot parse '#{inspect(data)}' as a number"}


  def maybe_check_range(value, %{range: range}) when range != nil do
    range = maybe_transform_range(range)
    if in_range?(value, range),
      do: {:ok, value},
    else: {:error, "#{value} is out of range #{range_to_string(range)}"}
  end
  def maybe_check_range(value, _), do: {:ok, value}

  defp maybe_transform_range(%Range{first: first, last: last}),
    do: if first > last, do: {last, first}, else: {first, last}
  defp maybe_transform_range(range),
    do: range

  defp in_range?(value, {:gt, num}), do: value > num
  defp in_range?(value, {:ge, num}), do: value >= num
  defp in_range?(value, {:lt, num}), do: value < num
  defp in_range?(value, {:le, num}), do: value <= num
  defp in_range?(value, {min, max}), do: min <= value and value <= max

  defp range_to_string({:gt, num}), do: "(#{num}, inf)"
  defp range_to_string({:ge, num}), do: "[#{num}, inf)"
  defp range_to_string({:lt, num}), do: "(-inf, #{num})"
  defp range_to_string({:le, num}), do: "(-inf, #{num}]"
  defp range_to_string({min, max}), do: "[#{min}, #{max}]"

end
