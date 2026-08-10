<#
.SYNOPSIS
  Tests for Optimize-WslDistroVHD.ps1 script.
#>

#Requires -PSEdition Desktop
$script:SkipAll = $PSEdition -eq 'Core'

Describe "Optimize-WslDistroVHD Script" -Tag "CI" {

  BeforeAll {
    if ($script:SkipAll) { return }

    # Get the absolute path to the script under test
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\Windows\Optimize-WslDistroVHD.ps1"

    # Store original environment variables
    $script:OriginalLocalAppData = $env:LOCALAPPDATA

    # Dot-source the script so helper functions and Start-WslDistroVhdOptimization are available
    . $script:ScriptPath
  }

  AfterAll {
    # Restore original environment variables
    $env:LOCALAPPDATA = $script:OriginalLocalAppData
  }

  Context "Script Structure" {
    It "Should exist" -Skip:$script:SkipAll {
      Test-Path -Path $script:ScriptPath -PathType Leaf | Should -Be $true
    }

    It "Should contain valid PowerShell syntax" -Skip:$script:SkipAll {
      $errors = $null
      $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $script:ScriptPath -Raw), [ref]$errors)
      $errors.Count | Should -Be 0
    }

    It "Should have Requires-Version 5.1 or higher" -Skip:$script:SkipAll {
      $content = Get-Content -Path $script:ScriptPath -Raw
      $content | Should -Match "#Requires\s+-Version\s+5\.[1-9]"
    }
  }

  Context "Help Documentation" {
    BeforeAll {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
    }

    It "Should have a SYNOPSIS section" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "\.SYNOPSIS"
    }

    It "Should have a DESCRIPTION section" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "\.DESCRIPTION"
    }

    It "Should have at least one EXAMPLE section" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "\.EXAMPLE"
    }

    It "Should have a NOTES section" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "\.NOTES"
    }

    It "Should have a LINK section" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "\.LINK"
    }
  }

  Context "Parameters" {
    BeforeAll {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
    }

    It "Should have DistroName parameter" -Skip:$script:SkipAll {
      $scriptContent | Should -Match '\[string\]\$DistroName'
    }

    It "Should have VhdPath parameter" -Skip:$script:SkipAll {
      $scriptContent | Should -Match '\[string\]\$VhdPath'
    }

    It "Should have Mode parameter" -Skip:$script:SkipAll {
      $scriptContent | Should -Match '\[string\]\$Mode'
    }

    It "Should have ValidateSet for Mode parameter with Full, Retain, None" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "ValidateSet\('Full',\s*'Retain',\s*'None'\)"
    }

    It "Should default Mode to Full" -Skip:$script:SkipAll {
      $scriptContent | Should -Match '\[string\]\$Mode\s*=\s*''Full'''
    }

    It "Should support ShouldProcess" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "SupportsShouldProcess\s*=\s*\`$true"
    }
  }

  Context "Helper Functions" {
    BeforeAll {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
    }

    It "Should define Get-WslDistroList function" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "function\s+Get-WslDistroList"
    }

    It "Should define Get-WslDistroVhdPath function" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "function\s+Get-WslDistroVhdPath"
    }

    It "Should define Select-WslDistro function" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "function\s+Select-WslDistro"
    }

    It "Should define Stop-WslDistro function" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "function\s+Stop-WslDistro"
    }

    It "Should use ShouldContinue in Stop-WslDistro for user confirmation" -Skip:$script:SkipAll {
      $scriptContent | Should -Match "ShouldContinue"
    }
  }

  Context "Execution with Mocks" {
    BeforeAll {
      # Set up a fake LOCALAPPDATA for testing
      $env:LOCALAPPDATA = $env:TEMP

      # Create a temporary fake VHDX file for testing
      # (zero-byte placeholder — New-VHD requires Hyper-V, which isn't available on CI runners)
      $testVhdPath = Join-Path $env:TEMP "test-wsl-distro.vhdx"
      if (-not (Test-Path -Path $testVhdPath)) {
        $null | Set-Content -Path $testVhdPath -Encoding Byte
      }

      $script:TestVhdPath = $testVhdPath
    }

    AfterAll {
      # Clean up test file
      if (Test-Path $script:TestVhdPath) {
        Remove-Item -Path $script:TestVhdPath -Force
      }
    }

    It "Should optimize a VHDX when -VhdPath is provided directly" -Skip:$script:SkipAll {
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Test-Path { $true }
      Mock Optimize-VHD { }
      Mock Invoke-WslCommand { }
      Mock Read-Host { "1" }

      $OriginalWhatIfPreference = $WhatIfPreference
      $WhatIfPreference = $false
      try {
        { Start-WslDistroVhdOptimization -VhdPath $script:TestVhdPath -Mode Full } | Should -Not -Throw
      }
      finally {
        $WhatIfPreference = $OriginalWhatIfPreference
      }

      Assert-MockCalled Optimize-VHD -Times 1 -Scope It
    }

    It "Should accept custom VHDX path" -Skip:$script:SkipAll {
      Mock Test-Path { $true } -ParameterFilter { $Path -eq $script:TestVhdPath }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } } -ParameterFilter { $Path -eq $script:TestVhdPath }
      Mock Optimize-VHD { }
      Mock Invoke-WslCommand { }
      Mock Read-Host { "1" }

      $OriginalWhatIfPreference = $WhatIfPreference
      $WhatIfPreference = $false
      try {
        { Start-WslDistroVhdOptimization -VhdPath $script:TestVhdPath -Mode Full } | Should -Not -Throw
      }
      finally {
        $WhatIfPreference = $OriginalWhatIfPreference
      }

      Assert-MockCalled Optimize-VHD -Times 1 -Scope It
    }

    It "Should call Optimize-VHD with correct parameters" -Skip:$script:SkipAll {
      Mock Test-Path { $true }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Optimize-VHD { }
      Mock Invoke-WslCommand { }
      Mock Read-Host { "1" }

      Start-WslDistroVhdOptimization -VhdPath $script:TestVhdPath -Mode Full

      Assert-MockCalled Optimize-VHD -ParameterFilter { $Mode -eq 'Full' } -Scope It
    }

    It "Should not stop WSL distro when not running" -Skip:$script:SkipAll {
      Mock Test-Path { $true }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Optimize-VHD { }
      Mock Invoke-WslCommand { }
      Mock Read-Host { "1" }

      { Start-WslDistroVhdOptimization -VhdPath $script:TestVhdPath -Mode Full } | Should -Not -Throw
    }
  }

  Context "Error Handling" {
    BeforeAll {
      $env:LOCALAPPDATA = $env:TEMP
    }

    It "Should throw when VHDX file not found" -Skip:$script:SkipAll {
      $nonExistentPath = Join-Path $env:TEMP "non-existent.vhdx"
      { Start-WslDistroVhdOptimization -VhdPath $nonExistentPath } | Should -Throw
    }

    It "Should throw when file is not .vhdx extension" -Skip:$script:SkipAll {
      $invalidPath = Join-Path $env:TEMP "invalid.txt"
      "" | Set-Content -Path $invalidPath
      { Start-WslDistroVhdOptimization -VhdPath $invalidPath } | Should -Throw
      Remove-Item -Path $invalidPath -Force
    }
  }

  Context "WhatIf Support" {
    BeforeAll {
      Mock Test-Path { $true }
      Mock Get-Item { [PSCustomObject]@{ Length = 1048576 } }
      Mock Optimize-VHD { }
      Mock Invoke-WslCommand { }
      Mock Read-Host { "1" }
    }

    It "Should support WhatIf parameter" -Skip:$script:SkipAll {
      $scriptContent = Get-Content -Path $script:ScriptPath -Raw
      $scriptContent | Should -Match "SupportsShouldProcess\s*=\s*\`$true"
    }

    It "Should not call Optimize-VHD when -WhatIf is used" -Skip:$script:SkipAll {
      Start-WslDistroVhdOptimization -VhdPath $script:TestVhdPath -Mode Full -WhatIf
      Should -Invoke Optimize-VHD -Times 0 -Scope It
    }
  }
}
