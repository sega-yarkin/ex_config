defmodule ExConfig.Param.TypeOptionError do
  alias __MODULE__

  defexception message: "Type option error",
               type: nil, name: nil, value: nil

  def message(%TypeOptionError{type: type, name: name, value: value})
              when type != nil and name != nil and value != nil do
    "Wrong value '#{inspect(value)}' for option #{type}::#{name}"
  end

  def message(err), do: err.message
end
