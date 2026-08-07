<#
.SYNOPSIS
  Tests for the Optimize-BluestacksVEthernet.ps1 script.
#>

Describe "Optimize-BluestacksVEthernet" -Tags "CI", "DesktopOnly" {

  BeforeAll {
    # Skip this test group under PowerShell Core (7.x) because the script
    # requires #Requires -PSEdition Desktop.
    # Also skip in CI: GitHub-hosted runners run as admin, and the script under
    # test calls many unmocked cmdlets (Disable-NetAdapter, Disable-NetAdapterBinding,
    # etc.) that would execute against real network adapters and could disrupt the
    # runner's network connectivity. This is a destructive integration test that
    # must only run in a controlled, local environment.
    $script:SkipAll = ($PSEdition -eq 'Core') -or [bool]$env:CI

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
