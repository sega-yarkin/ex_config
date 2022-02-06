defmodule ExConfig.Source.System do
  @behaviour ExConfig.Source

  @enforce_keys [:name]
  defstruct [:name, :default, sensitive: false, expand: false]

  @type name() :: String.t()

  @type t() :: %__MODULE__{
    name:      name() | [name()],
    default:   String.t() | nil,
    sensitive: boolean(),
    expand:    boolean(),
  }

  @impl true
  def handle(%{name: name, default: default, expand: expand}, param) do
    find_fn = case expand do
      true  -> &get_env_by_pattern(&1, param)
      false -> &System.get_env/1
    end

    data = Enum.find_value(List.wrap(name), default, find_fn)
    {:ok, data}
  end

  defp get_env_by_pattern(pattern, %{name: name} = _param) do
    name = name |> Atom.to_string() |> String.upcase()
    pattern
    |> String.replace("${name}", name)
    |> System.get_env()
  end

  @doc """
  Returns a list of all environment variables which are marked as a sensitive.
  Useful to form an exclude list of environment variables for `Port.open/2`.
  """
  @spec get_all_sensitive_envs() :: [String.t]
  def get_all_sensitive_envs() do
    __MODULE__
    |> ExConfig.Source.get_source_occurrences(&Keyword.get(&1, :sensitive))
    |> get_all_sensitive_envs()
  end

  @doc false
  @spec get_all_sensitive_envs([Keyword.t]) :: [String.t]
  def get_all_sensitive_envs(matched_envs) do
    {patterns, raw} =
      matched_envs
      |> Enum.map(fn {_, opts} -> opts end)
      |> Enum.split_with(&Keyword.get(&1, :expand, false))

    get_env_names = fn (opts) ->
      opts
      |> Keyword.get(:name, [])
      |> List.wrap()
      |> Enum.filter(&(is_binary(&1) and byte_size(&1) > 0))
    end

    raw = Enum.flat_map(raw, get_env_names)

    by_patterns =
      patterns
      |> Enum.flat_map(get_env_names)
      |> find_envs_by_patterns()

    (raw ++ by_patterns) |> Enum.uniq() |> Enum.sort()
  end

  @spec find_envs_by_patterns([String.t]) :: [String.t]
  defp find_envs_by_patterns(patterns) do
    patterns =
      patterns
      |> Enum.map(&env_pattern_mask!/1)
      |> Enum.reject(&match?(:error, &1))

    any_pattern? = fn env -> Enum.any?(patterns, &Regex.match?(&1, env)) end

    System.get_env()
    |> Map.keys()
    |> Enum.filter(any_pattern?)
  end

  @spec env_pattern_mask!(String.t) :: Regex.t | no_return
  defp env_pattern_mask!(pattern) do
    to_replace = Regex.escape("${name}")
    pattern =
      pattern
      |> Regex.escape()
      |> String.replace(to_replace, "([A-Z0-9_]+)", global: false)
      |> String.replace(to_replace, "\\1")

    Regex.compile!("^" <> pattern <> "$")
  end

end
