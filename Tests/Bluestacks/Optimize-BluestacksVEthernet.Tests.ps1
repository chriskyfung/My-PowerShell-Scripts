<#
.SYNOPSIS
  Tests for the Optimize-BluestacksVEthernet.ps1 script.
#>

Describe "Optimize-BluestacksVEthernet" -Tags "CI" {

  BeforeAll {
    # Get the absolute path to the script under test
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\Bluestacks\Optimize-BluestacksVEthernet.ps1"
  }

  It "Should run without errors" {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
      Write-Host "Skipping test: Administrative privileges are required." -ForegroundColor Yellow
      return  # Exit the script or skip the test
    }

    # Code that requires admin permissions
    Write-Host "Running test with administrative privileges..." -ForegroundColor Green
    Mock -CommandName Get-NetAdapter -MockWith { return @([pscustomobject]@{ Name = 'vEthernet (Default Switch)'; ifIndex = 1 }) }
    Mock -CommandName Set-NetIPInterface -MockWith { return $true }
    & $script:ScriptPath | Should Not Throw
  }
}
