defmodule ExConfig.Type.Enum do
  @moduledoc """
  """
  use ExConfig.Type
  @type result() :: atom()

  @enforce_keys [:values]
  defstruct [:values]
  @type t() :: %__MODULE__{
    values: nonempty_list(atom()),
  }

  @impl true
  def validators, do: [
    values: &validate_values/1,
  ]

  @impl true
  def handle(data, opts), do: do_handle(data, opts)

  @doc false
  @spec error(:bad_data | :wrong_value, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot handle '#{inspect(data)}' as an enum value"}
  def error(:wrong_value, {data, values}), do: {:error, "Wrong enum value '#{inspect(data)}', only accept #{inspect(values)}"}

  @spec validate_values(any) :: ExConfig.Type.validator_result(list(atom))
  defp validate_values([_|_] = values) do
    if Enum.all?(values, &is_atom/1), do: {:ok, values}, else: :error
  end
  defp validate_values(_), do: :error


  defp do_handle(data, %{values: values}) when is_atom(data) do
    if data in values,
      do: {:ok, data},
      else: error(:wrong_value, {data, values})
  end

  defp do_handle(data, opts) when byte_size(data) > 0 do
    do_handle(String.to_existing_atom(data), opts)
  rescue
    _ -> error(:wrong_value, {data, opts.values})
  end

  defp do_handle(data, _), do: error(:bad_data, data)

end
