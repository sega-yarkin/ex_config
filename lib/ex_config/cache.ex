defmodule ExConfig.Cache do
  @callback wrap(module :: module(), options :: Keyword.t()) :: {:ok, any()}
  @callback get(options :: Keyword.t()) :: any()
end
