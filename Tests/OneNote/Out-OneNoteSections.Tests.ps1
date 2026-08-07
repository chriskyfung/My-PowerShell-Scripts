<#
.SYNOPSIS
  Tests for Out-OneNoteSections.ps1
#>

Describe "Out-OneNoteSections.ps1" -Tag "Integration" {

  BeforeAll {
    # Skip this test group in CI because it requires a running OneNote instance
    # with the expected notebooks ("Archive", "Ideas", "Test Notebook").
    $script:SkipAll = [bool]$env:CI

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
