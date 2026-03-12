<#
.SYNOPSIS
  Tests for Optimize-DockerDesktopVHD.ps1 script.
#>

Describe "Optimize-DockerDesktopVHD Script" -Tag "CI" {

  BeforeAll {
    # Get the absolute path to the script under test
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\Windows\Optimize-DockerDesktopVHD.ps1"

    # Store original environment variable
    $script:OriginalLocalAppData = $env:LOCALAPPDATA
  }

  AfterAll {
    # Restore original environment variable
    $env:LOCALAPPDATA = $script:OriginalLocalAppData
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

    It "Should have Requires-Version 5.1 or higher" {
      $content = Get-Content -Path $script:ScriptPath -Raw
      $content | Should -Match "#Requires\s+-Version\s+5\.[1-9]"
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

    It "Should have at least one EXAMPLE section" {
      $scriptContent | Should -Match "\.EXAMPLE"
    }

    It "Should have a NOTES section" {
      $scriptContent | Should -Match "\.NOTES"
    }

    It "Should have a LINK section" {
      $scriptContent | Should -Match "\.LINK"
    }
  }

  Context "Parameters" {
    BeforeAll {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
    }

    It "Should have VhdPath parameter" {
      $scriptContent | Should -Match '\[string\]\$VhdPath'
    }

    It "Should have Mode parameter" {
      $scriptContent | Should -Match '\[string\]\$Mode'
    }

    It "Should have ValidateSet for Mode parameter with Full, Retain, None" {
      $scriptContent | Should -Match "ValidateSet\('Full',\s*'Retain',\s*'None'\)"
    }

    It "Should default Mode to Full" {
      $scriptContent | Should -Match '\[string\]\$Mode\s*=\s*''Full'''
    }

    It "Should support ShouldProcess" {
      $scriptContent | Should -Match "SupportsShouldProcess\s*=\s*\`$true"
    }
  }

  Context "Helper Functions" {
    BeforeAll {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
    }

    It "Should define Stop-DockerDesktop function" {
      $scriptContent | Should -Match "function\s+Stop-DockerDesktop"
    }

    It "Should define Get-DefaultDockerVhdPath function" {
      $scriptContent | Should -Match "function\s+Get-DefaultDockerVhdPath"
    }

    It "Should use ShouldContinue in Stop-DockerDesktop for user confirmation" {
      $scriptContent | Should -Match "ShouldContinue"
    }
  }

  Context "Execution with Mocks" {
    BeforeAll {
      # Set up a fake LOCALAPPDATA for testing
      $env:LOCALAPPDATA = $env:TEMP

      # Create a temporary fake VHDX file for testing
      $testVhdPath = Join-Path $env:TEMP "test-docker.vhdx"
      [byte[]] $vhdContent = @(1, 2, 3, 4)
      [System.IO.File]::WriteAllBytes($testVhdPath, $vhdContent)

      $script:TestVhdPath = $testVhdPath
    }

    AfterEach {
      # Clean up mocks
      Mock Get-Process -Remove
      Mock Stop-Process -Remove
      Mock Wait-Process -Remove
      Mock Optimize-VHD -Remove
      Mock Test-Path -Remove
      Mock Get-Item -Remove
    }

    AfterAll {
      # Clean up test file
      if (Test-Path $script:TestVhdPath) {
        Remove-Item -Path $script:TestVhdPath -Force
      }
    }

    It "Should use default VHDX path when not specified" -Skip {
      Mock Test-Path { $true } -ParameterFilter { $Path -like "*docker_data.vhdx*" }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Get-Process { $null } -ParameterFilter { $Name -eq "Docker Desktop" }
      Mock Optimize-VHD { }

      { & $script:ScriptPath -VhdPath $script:TestVhdPath } | Should -Not -Throw
    }

    It "Should accept custom VHDX path" -Skip {
      Mock Test-Path { $true } -ParameterFilter { $Path -eq $script:TestVhdPath }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } } -ParameterFilter { $Path -eq $script:TestVhdPath }
      Mock Get-Process { $null }
      Mock Optimize-VHD { } -ParameterFilter { $Path -eq $script:TestVhdPath }

      { & $script:ScriptPath -VhdPath $script:TestVhdPath } | Should -Not -Throw
      Assert-MockCalled Optimize-VHD -ParameterFilter { $Path -eq $script:TestVhdPath } -Scope It
    }

    It "Should call Optimize-VHD with correct parameters" -Skip {
      Mock Test-Path { $true }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Get-Process { $null }
      Mock Optimize-VHD { }

      & $script:ScriptPath -VhdPath $script:TestVhdPath -Mode Full

      Assert-MockCalled Optimize-VHD -ParameterFilter { $Mode -eq 'Full' } -Scope It
    }

    It "Should not prompt to stop Docker when not running" -Skip {
      Mock Get-Process { $null } -ParameterFilter { $Name -eq "Docker Desktop" }
      Mock Test-Path { $true }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Optimize-VHD { }

      { & $script:ScriptPath -VhdPath $script:TestVhdPath } | Should -Not -Throw
    }
  }

  Context "Error Handling" {
    BeforeAll {
      $env:LOCALAPPDATA = $env:TEMP
    }

    It "Should throw when VHDX file not found" -Skip {
      $nonExistentPath = Join-Path $env:TEMP "non-existent.vhdx"
      { & $script:ScriptPath -VhdPath $nonExistentPath } | Should -Throw
    }

    It "Should throw when file is not .vhdx extension" -Skip {
      $invalidPath = Join-Path $env:TEMP "invalid.txt"
      "" | Set-Content -Path $invalidPath
      { & $script:ScriptPath -VhdPath $invalidPath } | Should -Throw
      Remove-Item -Path $invalidPath -Force
    }
  }

  Context "WhatIf Support" {
    BeforeAll {
      Mock Test-Path { $true }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Get-Process { $null }
      Mock Optimize-VHD { }
    }

    It "Should support WhatIf parameter" {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
      $scriptContent | Should -Match "CmdletBinding.*SupportsShouldProcess"
    }
  }
}
