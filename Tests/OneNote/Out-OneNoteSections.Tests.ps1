<#
.SYNOPSIS
  Tests for Out-OneNoteSections.ps1
#>

# Must be top-level: Pester Discovery evaluates -Skip: before BeforeAll runs.
$script:SkipAll = [bool]$env:CI

Describe "Out-OneNoteSections.ps1" -Tag "Integration" {
  BeforeAll {
    # Set the path to the script under test.
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\OneNote\Out-OneNoteSections.ps1"
  }

  Context "When OneNote has notebooks" {
    It "should list all notebooks and their sections" -Skip:$script:SkipAll {
      $output = (& $script:ScriptPath | Out-String).Trim()
      $output | Should -Match "Archive"
      $output | Should -Match "### Ideas"
      $output | Should -Match "### Finished"
      $output | Should -Match "Test Notebook"
      $output | Should -Match "### Test Section"
    }
  }
}
