<#
.SYNOPSIS
  Tests for the Optimize-BluestacksVEthernet.ps1 script.
#>

# Must be top-level: Pester Discovery evaluates -Skip: before BeforeAll runs.
$script:SkipAll = ($PSEdition -eq 'Core') -or [bool]$env:CI

Describe "Optimize-BluestacksVEthernet" -Tags "CI", "DesktopOnly" {
  BeforeAll {
    # Get the absolute path to the script under test
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\Bluestacks\Optimize-BluestacksVEthernet.ps1"
  }

  It "Should run without errors" -Skip:($script:SkipAll -or -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Code that requires admin permissions
    Write-Host "Running test with administrative privileges..." -ForegroundColor Green
    Mock Get-NetAdapter {
      return @([pscustomobject]@{ Name = 'vEthernet (Default Switch)'; ifIndex = 1 })
    } -Verifiable
    Mock Set-NetIPInterface { return $true } -Verifiable
    & $script:ScriptPath | Should Not Throw
  }
}
