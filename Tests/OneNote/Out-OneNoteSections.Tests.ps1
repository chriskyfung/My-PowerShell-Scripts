<#
.SYNOPSIS
  Tests for Out-OneNoteSections.ps1
#>
Describe "Out-OneNoteSections.ps1" {

  BeforeAll {
    # Set the path to the script under test.
    $script:ScriptPath = Join-Path $PSScriptRoot "..\..\OneNote\Out-OneNoteSections.ps1"
  }

  Context "When OneNote has notebooks" {
    It "should list all notebooks and their sections" {
      $output = (& $script:ScriptPath | Out-String).Trim()
      $output | Should -Match "Archive"
      $output | Should -Match "### Ideas"
      $output | Should -Match "### Finished"
      $output | Should -Match "Test Notebook"
      $output | Should -Match "### Test Section"
    }
  }
}
