<#
.SYNOPSIS
    Tests for Get-TheBrainDataDirectory.ps1
#>
# Requires the Pester module
# You can install it via PowerShell Gallery if not already installed:

# Store and restore original environment variable to avoid side-effects
$originalAppData = $env:LOCALAPPDATA

Describe 'Get-TheBrainDataDirectory' {
  BeforeAll {
    # Path to the script being tested
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\theBrain\Get-TheBrainDataDirectory.ps1"

    $env:LOCALAPPDATA = '/tmp' # Use a predictable temp path for tests
    # Mock Invoke-SqliteQuery to return a specific path
    Get-Module -Name PSSQLite | Remove-Module
    New-Module -Name PSSQLite  -ScriptBlock {
      function Invoke-SqliteQuery {
        return [PSCustomObject]@{ Value = '"C:\Users\TestUser\Documents\TheBrain"' }
      }
    } | Import-Module -Force
  }
  AfterAll {
    $env:LOCALAPPDATA = $originalAppData
    Get-Module -Name PSSQLite | Remove-Module
    Import-Module PSSQLite
  }

  # Default mock for Get-Module to return true, can be overridden in specific tests
  BeforeEach {
    Mock Get-Module { return $true } -ParameterFilter {
      $Name -eq 'PSSQLite' -and $ListAvailable.IsPresent
    } -Verifiable
  }

  Context 'Success Scenarios' {
    BeforeEach {
      # Mock dependencies for successful execution
      Mock Test-Path {
        # This flexible mock returns true for the DB path and the final resolved path
        if ($Path -eq (Join-Path $env:LOCALAPPDATA "TheBrain\MetaDB\TheBrainMeta.db") -or $Path -eq 'C:\Users\TestUser\Documents\TheBrain' -or $Path -eq (Join-Path 'C:\Users\TestUser\Documents' -ChildPath 'Brains')) {
          return $true
        }
        return $false
      } -Verifiable
    }

    It 'should return the brain data directory from the database when available' {
      Mock Invoke-SqliteQuery {
        [PSCustomObject]@{ Value = '"C:\Users\TestUser\Documents\TheBrain"' }
      } -Verifiable

      $result = & $script:ScriptPath
      $result | Should -Be 'C:\Users\TestUser\Documents\TheBrain'
    }

    It 'should return the default "Brains" directory when the database query returns null' {
      Mock Invoke-SqliteQuery { [PSCustomObject]@{ Value = '""' } } -Verifiable
      Mock Join-Path { 'C:\Users\TestUser\Documents\Brains' } -ParameterFilter {
        $Path -eq ([Environment]::GetFolderPath('MyDocuments')) -and $ChildPath -eq 'Brains'
      } -Verifiable

      $result = & $script:ScriptPath
      $result | Should -Be (Join-Path 'C:\Users\TestUser\Documents' -ChildPath 'Brains')
    }
  }
}
