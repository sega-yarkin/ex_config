defmodule ExConfig.Util.NumRange do
  @moduledoc """
  """

  @type t() :: {min :: number(), max :: number()}
             | {:gt | :ge | :lt | :le, number()}

  @spec validate(any) :: ExConfig.Type.validator_result(t)
  def validate(nil), do: :skip

  def validate(%Range{first: first, last: last}) do
    range = if first > last, do: {last, first}, else: {first, last}
    {:ok, range}
  end

  def validate({min, max}) when is_number(min) and is_number(max) do
    range = if min < max, do: {min, max}, else: {max, min}
    {:ok, range}
  end

  def validate({op, num}) when op in [:gt, :ge, :lt, :le] and is_number(num),
    do: {:ok, {op, num}}

  def validate(_), do: :error


  @spec in_range?(number, t) :: bool
  def in_range?(value, {:gt, num}), do: value > num
  def in_range?(value, {:ge, num}), do: value >= num
  def in_range?(value, {:lt, num}), do: value < num
  def in_range?(value, {:le, num}), do: value <= num
  def in_range?(value, {min, max}), do: min <= value and value <= max

  @spec to_string(t) :: String.t
  def to_string({:gt, num}), do: "(#{num}, inf)"
  def to_string({:ge, num}), do: "[#{num}, inf)"
  def to_string({:lt, num}), do: "(-inf, #{num})"
  def to_string({:le, num}), do: "(-inf, #{num}]"
  def to_string({min, max}), do: "[#{min}, #{max}]"
end
