# ExConfig

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/sega-yarkin/ex_config/Elixir%20Tests?style=flat-square)](https://github.com/sega-yarkin/ex_config/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_config.svg?style=flat-square)](https://hex.pm/packages/ex_config)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg?style=flat-square)](https://hexdocs.pm/ex_config/)
[![Coveralls](https://img.shields.io/coveralls/github/sega-yarkin/ex_config?style=flat-square)](https://coveralls.io/github/sega-yarkin/ex_config?branch=master)
[![codebeat badge](https://codebeat.co/badges/da6d58c1-6461-4190-96d1-96a808c708e3)](https://codebeat.co/projects/github-com-sega-yarkin-ex_config-master)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

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
to easily express configuration your application needs. It also helps
to aggregate configuration releated code/parameters into a single place.

## Installation

The package can be installed by adding `ex_config` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [{:ex_config, "~> 0.2"}]
end
```

# Usage

A simple example can look like:

```elixir
# config/config.exs
use Mix.Config
alias ExConfig.Source.System
config :my_app,
  port: {System, name: "PORT"},
  addr: "127.0.0.1"


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
