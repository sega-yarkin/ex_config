defmodule ExConfig.Resource do
  @callback _all(ExConfig.Mod.t()) :: module() | map() | Keyword.t()

  @spec __using__(Keyword.t()) :: Macro.t()
  defmacro __using__(opts) do
    opts = Keyword.merge([otp_app: nil], opts)

    quote do
      use ExConfig.Mod, unquote(opts)
    end
  end
end
