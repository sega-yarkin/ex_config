defmodule ExConfig.Cache do
  @callback wrap(module :: module, options :: keyword) :: {:ok, any}
  @callback get(options :: keyword) :: any
end
