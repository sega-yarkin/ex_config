defmodule ExConfig.Utils do
  @moduledoc """
  """

  @spec get_all_env() :: Keyword.t()
  def get_all_env() do
    for {name, _, _} <- Application.loaded_applications() do
      {name, Application.get_all_env(name)}
    end
  end

end
