defmodule ExConfig.Source do
  @callback __struct__(any) :: any
  @callback handle(value :: %ExConfig.Param{},
                   source :: struct()) :: %ExConfig.Param{}
end
