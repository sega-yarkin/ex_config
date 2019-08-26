defmodule ExConfig.Source do
  @type handle_result() :: %ExConfig.Param{}
                         | {:ok, data :: any()}
                         | {:error, reason :: any()}

  @callback __struct__(any) :: any
  @callback handle(source :: struct,
                   param :: %ExConfig.Param{}) :: handle_result
end
