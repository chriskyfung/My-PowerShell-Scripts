<#
.SYNOPSIS
  Tests for Find-OneNotePages.ps1
#>

Describe "Find-OneNotePages.ps1" {

  BeforeAll {
    # Set the path to the script under test.
    $script:ScriptPath = Join-Path $PSScriptRoot "..\..\OneNote\Find-OneNotePages.ps1"
  }

  # This is an integration test that requires a running OneNote instance.
  It "should return formatted output when pages are found" -Tag 'Integration' {
    $output = (& $script:ScriptPath -Query "MyNote" | Out-String).Trim()
    $output | Should -Match "Test Notebook"
    $output | Should -Match " > Test Section"
    $output | Should -Match " > MyNote"
    $output | Should -Match "onenote:https://d.docs.live.net/"
    $output | Should -Match "Notebook     : Test Notebook"
    $output | Should -Match "Section      : Test Section"
    $output | Should -Match "Page         : MyNote"
    $output | Should -Match "URI          : "
  }

  It "should return a warning when no pages are found" {
    $output = (& $script:ScriptPath -Query "NonExistentPage" | Out-String).Trim()
    $output | Should -BeNullOrEmpty
    $output = (& $script:ScriptPath -Query "NonExistentPage" 3>&1 | Out-String).Trim()
    $output | Should -Match "No pages found containing the query: 'NonExistentPage'"
  }
}
