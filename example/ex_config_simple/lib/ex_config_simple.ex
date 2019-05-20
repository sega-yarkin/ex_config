defmodule ExConfigSimple do
  use Application

  def start(_type, _args) do
    System.put_env("SERVER_ID", "one")
    # IO.inspect(ExConfigSimple.Config._all)
    Supervisor.start_link([], strategy: :one_for_one,
                              name: __MODULE__)
  end
end
