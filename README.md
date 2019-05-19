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

# Usage
