defmodule ExConfig.Type do
  @callback __struct__(any) :: any
  @callback init(options :: keyword) :: struct
  @callback handle(data :: any, opts :: struct) :: {:ok, any} | {:error, String.t}
end
