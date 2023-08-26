defmodule ExConfig.Utils.NumRange do
  @moduledoc """
  """

  @type t() :: {min :: number(), max :: number()}
             | {:gt | :ge | :lt | :le, number()}

  @spec validate(any()) :: ExConfig.Type.validator_result(t())
  def validate(nil), do: :skip

  # `step` in Range is since Elixir 1.12
  def validate(%{__struct__: Range, step: step}) when step not in [1, -1], do: :error

  def validate(%Range{first: first, last: last}), do: validate({first, last})

  def validate({min, max}) when is_number(min) and is_number(max) do
    range = if min < max, do: {min, max}, else: {max, min}
    {:ok, range}
  end

  def validate({op, num}) when op in [:gt, :ge, :lt, :le] and is_number(num) do
    {:ok, {op, num}}
  end

  def validate(str) when is_binary(str) do
    with {op, str_number} <- split_str_range(str),
         {:ok, number} <- parse_number(String.trim(str_number)) do
      {:ok, {op, number}}
    end
  end

  def validate(_), do: :error

  @spec split_str_range(String.t()) :: {atom(), String.t()} | :error
  defp split_str_range(">=" <> number), do: {:ge, number}
  defp split_str_range(">"  <> number), do: {:gt, number}
  defp split_str_range("<=" <> number), do: {:le, number}
  defp split_str_range("<"  <> number), do: {:lt, number}
  defp split_str_range(_), do: :error

  @spec parse_number(String.t()) :: {:ok, number()} | :error
  defp parse_number(str) do
    case Integer.parse(str) do
      {number, ""} -> {:ok, number}

      _ ->
        case Float.parse(str) do
          {number, ""} -> {:ok, number}
          _ -> :error
        end
    end
  end


  @spec in_range?(number(), t()) :: boolean()
  def in_range?(value, {:gt, num}), do: value > num
  def in_range?(value, {:ge, num}), do: value >= num
  def in_range?(value, {:lt, num}), do: value < num
  def in_range?(value, {:le, num}), do: value <= num
  def in_range?(value, {min, max}), do: min <= value and value <= max

  @spec to_string(t()) :: String.t()
  def to_string({:gt, num}), do: "(#{num}, inf)"
  def to_string({:ge, num}), do: "[#{num}, inf)"
  def to_string({:lt, num}), do: "(-inf, #{num})"
  def to_string({:le, num}), do: "(-inf, #{num}]"
  def to_string({min, max}), do: "[#{min}, #{max}]"
end
