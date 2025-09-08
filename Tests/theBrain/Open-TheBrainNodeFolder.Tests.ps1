# Tests for Open-TheBrainNodeFolder.ps1
#
# Description:
#   This script contains Pester tests for Open-TheBrainNodeFolder.ps1.
#   It verifies that the script correctly opens the node folder when it exists,
#   handles cases where the folder is not found, and manages errors gracefully.
#
# Author: chriskyfung, Gemini
# License: GNU GPLv3
# Version: 1.0.0
#

BeforeAll {
  # Resolve full paths to the scripts at the start
  $script:ScriptPath = Resolve-Path -Path "$PSScriptRoot/../../theBrain/Open-TheBrainNodeFolder.ps1"
  $script:GetDataDirectoryScriptPath = Resolve-Path -Path "$PSScriptRoot/../../theBrain/Get-TheBrainDataDirectory.ps1"

  # Create a temporary directory to simulate TheBrain's data folder structure
  $script:TempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "Test-OpenTheBrainNode")
  $script:fakeBrainDataDir = Join-Path $script:TempDir.FullName "TheBrain"
  $null = New-Item -ItemType Directory -Path $script:fakeBrainDataDir

  # Create a fake node folder for testing the success case
  $script:fakeNodeId = "abc-123-def-456"
  $script:fakeNodeFolderPath = Join-Path $script:fakeBrainDataDir $script:fakeNodeId
  $null = New-Item -ItemType Directory -Path $script:fakeNodeFolderPath

  # Create a fake backup folder to ensure it is correctly excluded by the script
  $null = New-Item -ItemType Directory -Path (Join-Path $script:fakeBrainDataDir "Backup")
}

AfterAll {
  # Clean up the temporary directory
  if (Test-Path $script:TempDir.FullName) {
    Remove-Item -Path $script:TempDir.FullName -Recurse -Force
  }
}

Describe "Open-TheBrainNodeFolder.ps1" {
  BeforeEach {
    # Mock the Get-TheBrainDataDirectory.ps1 script to return our temp path.
    # This is the correct Pester v5 syntax for mocking a script that is dot-sourced.
    Mock $script:GetDataDirectoryScriptPath {
      return $script:fakeBrainDataDir
    } -Verifiable

    # Mock explorer.exe to prevent it from actually opening a window
    Mock explorer.exe {
      # This space intentionally left blank
    } -Verifiable

    # Mock Write-Warning to capture its output for verification
    Mock Write-Warning {
      param($Message)
      $script:WarningMessage = $Message
    } -Verifiable
  }

  Context "when the node folder exists" {
    It "should find the folder and call explorer.exe with the correct path" {

      Mock Get-ChildItem { return @(Get-Item $script:fakeNodeFolderPath) } -Verifiable

      # Run the script with the NodeId of the folder we created
      . $script:ScriptPath -NodeId $script:fakeNodeId

      # Verify that explorer.exe was called exactly once with the correct full path
      Should -Invoke "explorer.exe" -Times 1 -Exactly -ParameterFilter { $script:fakeNodeFolderPath }
      # Verify that no warning was issued
      Should -Not -Invoke "Write-Warning"
    }
  }

  Context "when the node folder does not exist" {
    It "should call Write-Warning with the appropriate message" {
      $nonExistentNodeId = "xyz-789-uvw-101"

      # Run the script with a NodeId that does not correspond to any folder
      . $script:ScriptPath -NodeId $nonExistentNodeId

      # Verify that Write-Warning was called exactly once
      Should -Invoke "Write-Warning" -Exactly 1
      # Check if the warning message is correct
      $script:WarningMessage | Should -Be "Could not find a folder for Node ID: $nonExistentNodeId"

      # Verify that explorer.exe was not called
      Should -Not -Invoke "explorer.exe"
    }
  }

  Context "when an error occurs" {
    It "should call Write-Error when Get-TheBrainDataDirectory fails" {
      # Mock Get-Module to simulate that PSSQLite is not found, causing Get-TheBrainDataDirectory to fail
      Mock Get-Module {
        throw "Failed to find TheBrain data directory"
      } -ParameterFilter {
        $Name -eq "PSSQLite"
      } -Verifiable

      # Mock Write-Error to verify it's called
      Mock Write-Error

      # Run the script. The script's try/catch should handle the error and not throw.
      { . $script:ScriptPath -NodeId $script:fakeNodeId } | Should -Not -Throw

      # Verify that Write-Error was called because the catch block should execute
      Should -Invoke "Write-Error" -Times 1 -Exactly
    }
  }

  Context "with invalid parameters" {
    It "should throw a ParameterBindingValidationException for a NodeId with invalid characters" {
      # An invalid NodeId with special characters not allowed by the ValidatePattern attribute
      $invalidNodeId = "node-id-with-@!#"

      # Expect a ParameterBindingValidationException because the input does not match the pattern
      { . $script:ScriptPath -NodeId $invalidNodeId } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }
  }
}
