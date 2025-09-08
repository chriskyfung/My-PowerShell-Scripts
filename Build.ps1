<#
.SYNOPSIS
  Build script for the My PowerShell Scripts project.

.DESCRIPTION
  This script automates the process of running PSScriptAnalyzer and Pester tests
  to ensure code quality and correctness.

.EXAMPLE
  PS C:\> .\Build.ps1
  Runs all Pester tests and analyzes all PowerShell scripts in the project.

.NOTES
  Version:        1.1.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2025-08-02
  Last Modified:  2025-09-08
#>

param()

$ErrorActionPreference = "Stop"

try {
  #region PSScriptAnalyzer
  Write-Host "Running PSScriptAnalyzer..."
  $filesToAnalyze = Get-ChildItem -Path . -Recurse -Include *.ps1, *.psm1 | Where-Object { $_.FullName -notlike "*\.vscode\*" }
  if ($filesToAnalyze) {
    foreach ($file in $filesToAnalyze) {
      $analysisResult = Invoke-ScriptAnalyzer -Path $file.FullName -Settings PSScriptAnalyzerSettings.psd1
      if ($analysisResult) {
        Write-Host "`nIssues found in $($file.FullName):"
        $analysisResult | Format-List
      }
    }
  }
  #endregion

  #region Pester
  Write-Host "Running Pester tests..."

  # Determine the correct PowerShell executable to use for isolated processes
  $executable = ''
  if (Get-Command -Name 'pwsh' -ErrorAction SilentlyContinue) {
      $executable = 'pwsh'
  }
  elseif (Get-Command -Name 'powershell' -ErrorAction SilentlyContinue) {
      $executable = 'powershell'
  }
  else {
      Write-Error "Could not find 'pwsh' or 'powershell' executable to run isolated Pester tests."
      exit 1
  }
  Write-Host "Using '$executable' for isolated test execution."

  $testFiles = Get-ChildItem -Path . -Recurse -Filter *.Tests.ps1
  if ($testFiles) {
      $overallResult = @{ FailedCount = 0 }
      foreach ($testFile in $testFiles) {
        Write-Host "`nRunning tests in isolated process for: $($testFile.FullName)"
        # Execute Pester in a new process to ensure test isolation (e.g., for mocks).
        & $executable -NoProfile -Command "& {
            `$pesterParams = @{
                Script    = '$($testFile.FullName)'
                PassThru  = `$true
            }
            `$result = Invoke-Pester @pesterParams
            if (`$result.FailedCount -gt 0) {
                # Exit with a non-zero code to indicate failure
                exit 1
            }
            exit 0
        }"

        if ($LASTEXITCODE -ne 0) {
            $overallResult.FailedCount++
            Write-Warning "At least one test failed in $($testFile.FullName)"
        }
      }

      if ($overallResult.FailedCount -gt 0) {
        Write-Error "$($overallResult.FailedCount) test file(s) contained failures."
        exit 1
      }
  }
  else {
      Write-Host "No Pester tests found. Skipping."
  }
  #endregion

  Write-Host "Build completed successfully."
}
catch {
  Write-Error "Build failed: $_"
  exit 1
}

