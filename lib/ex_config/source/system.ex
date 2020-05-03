defmodule ExConfig.Source.System do
  @behaviour ExConfig.Source

  @enforce_keys [:name]
  defstruct [:name, :default, sensitive: false]

  @type t() :: %__MODULE__{
    name:      String.t() | [String.t()],
    default:   String.t() | nil,
    sensitive: boolean(),
  }

  @impl true
  def handle(%{name: name, default: default}, _) do
    data = Enum.find_value(List.wrap(name), default, &System.get_env/1)
    {:ok, data}
  end

  @doc """
  Returns a list of all environment variables which are marked as a sensitive.
  Useful to form an exclude list of environment variables for `Port.open/2`.
  """
  @spec get_all_sensitive_envs() :: [String.t]
  def get_all_sensitive_envs() do
    all_envs =
      for {app, _, _} <- Application.loaded_applications() do
        Application.get_all_env(app)
      end

    get_all_sensitive_envs(all_envs)
  end

  @doc false
  @spec get_all_sensitive_envs([Keyword.t]) :: [String.t]
  def get_all_sensitive_envs(all_envs) do
    sensitive_envs =
      for app_envs  <- all_envs,
          env       <- app_envs,
          {_, opts} <- List.flatten(find_self_in_envs(env)),
          Keyword.get(opts, :sensitive) == true
      do
        Keyword.get(opts, :name, [])
      end

    sensitive_envs
    |> List.flatten()
    |> Enum.sort()
    |> Enum.uniq()
  end

  defp find_self_in_envs({__MODULE__, [_|_]} = kw), do: [kw]
  defp find_self_in_envs({_key, value}), do: find_self_in_envs(value)
  defp find_self_in_envs([_|_] = envs ), do: Enum.map(envs, &find_self_in_envs/1)
  defp find_self_in_envs(%{}   = envs ), do: Enum.map(envs, &find_self_in_envs/1)
  defp find_self_in_envs(_), do: []
end
