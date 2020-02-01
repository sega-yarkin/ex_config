defmodule ExConfig do
  @spec __using__(Keyword.t) :: Macro.t
  defmacro __using__(opts) do
    unless Keyword.get(opts, :otp_app),
      do: raise ArgumentError, "'otp_app' option is required"

    quote do
      use ExConfig.Mod, unquote(opts)
    end
  end
end
