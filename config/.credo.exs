%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/"]
      },
      checks: [
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Readability.RedundantBlankLines, max_blank_lines: 2},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
      ]
    }
  ]
}
