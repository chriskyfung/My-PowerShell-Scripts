@{
  Severity = @('Error', 'Warning')
  Rules = @{
    PSUseCompatibleCmdlets = @{
      Compatibility = @(
        'desktop-5.1-windows'
        'core-7.4-windows'
      )
    }
    PSUseCompatibleSyntax = @{
      TargetedVersions = @(
        '5.1',
        '7.4'
      )
    }
  }
  ExcludeRules = @('PSAvoidUsingWriteHost')
}
