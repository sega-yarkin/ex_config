defmodule ExConfig.Type.List do
  @moduledoc """
  """
  use ExConfig.Type
  alias ExConfig.Type

  # @type result() :: list(any())
  @type item_def() :: {module, Keyword.t}


  defstruct item: %Type.String{},
            delim: ",",
            keep_empty?: false

  @type t() :: %__MODULE__{
    item:  Type.t(),
    delim: String.t() | Regex.t(),
    keep_empty?: boolean(),
  }

  @impl ExConfig.Type
  def init(opts) do
    opts = maybe_init_item(opts)
    struct!(__MODULE__, opts)
  end

  defp maybe_init_item(opts) when is_list(opts) do
    case Keyword.get(opts, :item) do
      nil -> opts
      {type, opts2} ->
        item = ExConfig.Param.create_type_instance(type, opts2)
        Keyword.put(opts, :item, item)
    end
  end

  @impl ExConfig.Type
  def validators, do: [
    item: &validate_item/1,
    delim: &validate_delim/1,
    keep_empty?: &ExConfig.Type.validator_boolean/1,
  ]

  @impl ExConfig.Type
  def default, do: []

  @impl ExConfig.Type
  def handle(data, opts), do: do_handle(data, opts)

  @doc false
  @spec error(:bad_data, any) :: {:error, String.t}
  def error(:bad_data, data), do: {:error, "Cannot handle '#{inspect(data)}' as an input"}


  @spec validate_item(any) :: ExConfig.Type.validator_result(item_def)
  defp validate_item(nil), do: :skip
  defp validate_item({type, opts}) when is_atom(type) and is_list(opts) do
    # {:module, _} = Code.ensure_loaded(type)
    # true = function_exported?(type, :init, 1)
    true = 1 in :proplists.get_all_values(:init, type.__info__(:functions))
    {:ok, {type, opts}}
  rescue
    _ -> :error
  end
  defp validate_item(type) when is_atom(type), do: validate_item({type, []})
  defp validate_item(_), do: :error

  @spec validate_delim(any) :: ExConfig.Type.validator_result(String.t | Regex.t)
  defp validate_delim(delim) when is_binary(delim), do: {:ok, delim}
  defp validate_delim(%Regex{} = delim), do: {:ok, delim}
  defp validate_delim([_|_] = delim) do
    if Enum.all?(delim, &is_binary/1), do: {:ok, delim}, else: :error
  end
  defp validate_delim(nil), do: :skip
  defp validate_delim(_), do: :error

  @spec do_handle(any, t) :: {:ok, any} | {:error, String.t}
  defp do_handle(data, %{delim: delim, keep_empty?: keep_empty?, item: item})
                 when is_binary(data) do
    data
    |> String.split(delim, trim: not keep_empty?)
    |> Enum.reduce_while([], &do_handle_reducer(item, &1, &2))
    |> case do
      {:error, reason}            -> {:error, reason}
      result when is_list(result) -> {:ok, Enum.reverse(result)}
    end
  end
  defp do_handle(data, opts) when is_list(data), do: do_handle(to_string(data), opts)
  defp do_handle(data, _opts), do: error(:bad_data, data)

  defp do_handle_reducer(%{__struct__: item_type} = item, elem, acc) do
    case apply(item_type, :handle, [elem, item]) do
      {:ok, parsed}    -> {:cont, [parsed | acc]}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

end
