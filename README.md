# ExConfig

Yet another Elixir app configuration package for fun and profit.


The Mix provides a way to manage your app config, but it works only at compile
time (so helps you to develop and test the app), once a build is made
Mix.Config no longer takes any action.
For new Elixir versions (1.9+) the Config module is moved into Elixir core,
but it still gives a very basic functionality.

There are already few packages in [Hex](https://hex.pm) which help you get
parameters from external sources, like OS level environment variables, or even
can populate system configuration storage at start time (so applications can
continue use `Application.get_env/2-3`).


The idea behind this package is to use a regular Elixir module to store and
get application parameters. The package provides a set of macros and helpers
to easily express configuration your application needs.

## Installation

The package can be installed by adding `ex_config` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:ex_config, "~> 0.1.0"}]
end
```

# Usage

A simple example can look like:

```elixir
# lib/my_app/config.ex
defmodule MyApp.Config do
  # Inject useful macros 
  use ExConfig, otp_app: :my_app

  # Add shorthands for types
  alias ExConfig.Type.{Integer, String}

  # Define config parameters
  env :port, Integer, range: 1..65535, default: 3000
  env :addr, String, default: "*"
  # Define dynamic parameter (just a function)
  dyn :listen_on, do: "#{addr()}:#{port()}"
end
```

And example how to use it from other modules:

```elixir
# lib/my_app.ex
defmodule MyApp do
  def start(_, _) do
    HttpServer.start(MyApp.Config.listen_on)
  end
end
```

Additional examples can be found in `example` directory.
