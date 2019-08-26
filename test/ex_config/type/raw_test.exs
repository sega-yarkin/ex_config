defmodule ExConfig.Type.RawTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.Raw

  defp instance(opts \\ []),
    do: ExConfig.Param.create_type_instance(Raw, opts)

  test "init/1" do
    assert %Raw{} == instance()
  end

  test "handle" do
    assert Raw.handle(:any, instance()) == {:ok, :any}
  end
end
