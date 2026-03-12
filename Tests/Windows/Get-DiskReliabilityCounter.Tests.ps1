<#
.SYNOPSIS
  Tests for Get-DiskReliabilityCounter.ps1 script.
#>

Describe "Get-DiskReliabilityCounter Script" -Tag "CI" {

  BeforeAll {
    # Get the absolute path to the script under test
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\Windows\Get-DiskReliabilityCounter.ps1"
  }

  Context "Script Structure" {
    It "Should exist" {
      Test-Path -Path $script:ScriptPath -PathType Leaf | Should -Be $true
    }

    It "Should contain valid PowerShell syntax" {
      $errors = $null
      $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $script:ScriptPath -Raw), [ref]$errors)
      $errors.Count | Should -Be 0
    }

    It "Should have Requires-RunAsAdministrator directive" {
      $content = Get-Content -Path $script:ScriptPath -Raw
      $content | Should -Match "#Requires\s+-RunAsAdministrator"
    }
  }

  Context "Help Documentation" {
    BeforeAll {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
    }

    It "Should have a SYNOPSIS section" {
      $scriptContent | Should -Match "\.SYNOPSIS"
    }

    It "Should have a DESCRIPTION section" {
      $scriptContent | Should -Match "\.DESCRIPTION"
    }

    It "Should have an EXAMPLE section" {
      $scriptContent | Should -Match "\.EXAMPLE"
    }

    It "Should have a NOTES section" {
      $scriptContent | Should -Match "\.NOTES"
    }
  }

  Context "Execution" {
    It "Should execute without throwing" {
      $isAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
      if (-not $isAdministrator) {
        Write-Warning "Skipping integration test that requires Administrator privileges."
        return # Exit the test block if not running as Administrator
      }
      { & $script:ScriptPath } | Should -Not -Throw
    }
  }

  Context "Error Handling" {
    BeforeAll {
      # Mock Get-Disk to throw an error
      Mock Get-Disk {
        throw "Simulated disk error"
      }
    }

    It "Should handle errors gracefully" {
      { & $script:ScriptPath } | Should -Throw
    }
  }
}
