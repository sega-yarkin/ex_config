defmodule ExConfig.Resource.EctoPostgresTest do
  use ExUnit.Case, async: false

  @otp_app ExConfigTestApp
  @mod_name ExConfig.EctoPostgresTestModule
  defp mod_create(content),
    do: Module.create(@mod_name, content, Macro.Env.location(__ENV__))

  test "ecto_postgres" do
    repo_mod = @mod_name.Repo
    content =
      quote do
        use ExConfig, otp_app: unquote(@otp_app)
        alias ExConfig.Resource.EctoPostgres

        dyn :ecto_repos, do: [unquote(repo_mod)]
        resource :ecto_repo, :ecto_repos, use: EctoPostgres
      end

    {:module, @mod_name, _, _} = mod_create(content)

    assert @mod_name.get_ecto_repo(repo_mod) ==
            [adapter: Ecto.Adapters.Postgres, port: 5432]

    Application.put_env(@otp_app, repo_mod, [
      hostname: "127.0.0.1",
      port: "5433",
      database: "example",
      username: "postgres",
      password: {ExConfig.Source.System, name: "PGPASSWORD"},
    ])
    System.put_env("PGPASSWORD", "PA$$W0RD")

    assert @mod_name.get_ecto_repo(repo_mod) == [
              adapter: Ecto.Adapters.Postgres,
              database: "example",
              hostname: "127.0.0.1",
              password: "PA$$W0RD",
              port: 5433,
              username: "postgres"
            ]

    # Trigger 100% coverage for EctoPostgres
    ExConfig.Resource.EctoPostgres.database()

    :code.purge(@mod_name)
    :code.delete(@mod_name)
  end
end
