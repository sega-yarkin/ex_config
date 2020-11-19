defmodule ExConfig.Source do
  @moduledoc """
  Interface for pluggable modules to get data from external sources.

  It is very often case when parameter value is dynamic and is based on
  something from outside an application, like OS environment variables,
  file system objects, etc. When a parameter is read and it's value
  matches pattern `{module(), Keyword.t()}`, ExConfig tries to treat it
  as `Source` behaviour implementation. For example:

      {ExConfig.Source.System, name: "ENV_NAME", default: "is not defined"}

  An implementation has to define struct and `handle/2` function.
  """

  @type value() :: {module(), Keyword.t()}

  @type handle_result() :: %ExConfig.Param{}
                         | {:ok, data :: any()}
                         | {:error, reason :: any()}

  @callback __struct__(any) :: any
  @callback handle(source :: struct,
                   param :: %ExConfig.Param{}) :: handle_result


  @spec get_source_occurrences(module, (Keyword.t -> boolean)) :: [value]
  def get_source_occurrences(source, filter \\ fn _ -> true end)
                             when is_atom(source)
                              and is_function(filter, 1) do
    get_source_occurrences(source, filter, ExConfig.Utils.get_all_env())
  end

  @doc false
  @spec get_source_occurrences(module, function, Keyword.t) :: [value]
  def get_source_occurrences(source, filter, all_envs) do
    Enum.reduce(all_envs, [], fn ({_app, envs}, acc) ->
      deep_source_search(source, filter, envs, acc)
    end)
  end


  @spec deep_source_search(module, function, any, list) :: [value]
  defp deep_source_search(source, filter, envs, acc)
                          when is_list(envs) or is_map(envs) do
    Enum.reduce(envs, acc, &deep_source_search(source, filter, &1, &2))
  end
  defp deep_source_search(source, filter, {source, options}, acc) when is_list(options) do
    if Keyword.keyword?(options) do
      if filter.(options) do
        [{source, options} | acc]
      else
        acc
      end
    else
      deep_source_search(source, filter, options, acc)
    end
  end
  defp deep_source_search(source, filter, {_key, value}, acc) do
    deep_source_search(source, filter, value, acc)
  end
  defp deep_source_search(_, _, _, acc), do: acc

end
