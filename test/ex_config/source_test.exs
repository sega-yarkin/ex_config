defmodule ExConfig.SourceTest do
  use ExUnit.Case, async: false

  alias ExConfig.Source

  test "get_source_occurrences" do
    filter = fn _ -> true end
    source = __MODULE__

    assert [] == Source.get_source_occurrences(source, filter, [])

    assert [] == Source.get_source_occurrences(source, filter, [
      app1: [
        env1: {Source, [name: :test1]},
      ],
    ])

    assert [
      {ExConfig.SourceTest, [name: :test2]},
    ] == Source.get_source_occurrences(source, filter, [
      app1: [
        env1: {Source, [name: :test1]},
        env2: {source, [name: :test2]},
      ],
    ])

    assert [
      {ExConfig.SourceTest, [name: :test2]},
      {ExConfig.SourceTest, [name: :test3]},
      {ExConfig.SourceTest, [name: :test4]},
    ] == Enum.sort(Source.get_source_occurrences(source, filter, [
      app1: [
        env1: {Source, [name: :test1]},
        env2: [
          {source, [name: :test2]},
          %{"key" => {source, [name: :test3]}},
          {source, [%{key: {source, [name: :test4]}}]},
        ],
      ],
    ]))

    filter2 = fn
      ([name: :test2]) -> true
      (_) -> false
    end
    assert [
      {ExConfig.SourceTest, [name: :test2]},
    ] == Enum.sort(Source.get_source_occurrences(source, filter2, [
      app1: [
        env1: {Source, [name: :test1]},
        env2: [
          {source, [name: :test2]},
          %{"key" => {source, [name: :test3]}},
        ],
      ],
    ]))
  end

  test "get_source_occurrences/2" do
    assert [] == Source.get_source_occurrences(__MODULE__)
  end
end
