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
  Version:        1.0.0
  Author:         Gemini
  License:        GNU GPLv3 license
  Creation Date:  2025-08-02
  Last Modified:  2025-08-02
#>

param()

$ErrorActionPreference = "Stop"

try {
  #region PSScriptAnalyzer
  Write-Host "Running PSScriptAnalyzer..."
  $filesToAnalyze = Get-ChildItem -Path . -Recurse -Include *.ps1, *.psm1 | Where-Object { $_.FullName -notlike "*\.vscode\*" }
  if ($filesToAnalyze) {
    $filesToAnalyze | ForEach-Object {
      Invoke-ScriptAnalyzer -Path $_.FullName -Settings PSScriptAnalyzerSettings.psd1
    } | Format-List
  }
  #endregion

  #region Pester
  Write-Host "Running Pester tests..."
  $testFiles = Get-ChildItem -Path . -Recurse -Filter *.Tests.ps1
  if ($testFiles) {
      $testFilePaths = $testFiles | ForEach-Object { $_.FullName }
      $pesterResult = Invoke-Pester -Script $testFilePaths -PassThru
      if ($pesterResult.FailedCount -gt 0) {
        Write-Error "Pester tests failed."
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
