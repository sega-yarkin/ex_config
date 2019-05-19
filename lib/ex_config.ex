defmodule ExConfig do
  @spec __using__(keyword) :: Macro.t
  defmacro __using__(opts) do
    quote do
      use ExConfig.Mod, unquote(opts)
    end
  end
end
