# Merged on top of Credo's default config.
%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          # Keep TODOs visible in the report without failing CI
          {Credo.Check.Design.TagTODO, [exit_status: 0]}
        ]
      }
    }
  ]
}
