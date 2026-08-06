<#
.SYNOPSIS
    Exports all VS Code profiles and their extensions to a text file.

.DESCRIPTION
    This script automatically discovers all VS Code user profiles and exports the list
    of installed extensions for each profile to a single text file in your My Documents
    folder.

    The output file is named 'vscode-profiles-export-<date>.txt' and contains:
    - Generation timestamp and machine name
    - Profile names discovered from storage.json
    - Extension lists with counts for each profile
    - A summary section at the end

.PARAMETER WhatIf
    Shows what would happen if the cmdlet runs without actually exporting anything.

.EXAMPLE
    PS C:\> .\Export-VSCodeExtensionList.ps1
    Exports all VS Code profiles and extensions to a timestamped text file.

.EXAMPLE
    PS C:\> .\Export-VSCodeExtensionList.ps1 -WhatIf
    Displays the profiles and extension counts without creating an output file.

.OUTPUTS
    Text file containing profile and extension information.

.NOTES
    Version:        1.1.0
    Author:         @chriskyfung, Claude Sonnet 4.6, DeepSeek V4 Flash, Laguna M.1, Step 3.7 Flash
    License:        GNU GPLv3 license
    Creation Date:  2026-06-01
    Last Modified:  2026-08-07
#>

#Requires -Version 5.0

[CmdletBinding(SupportsShouldProcess)]
param()

# Script-level error handling
$ErrorActionPreference = "Stop"

try {
    $VSCodeUserDir = "$env:APPDATA\Code\User"
    $StorageJson = "$VSCodeUserDir\globalStorage\storage.json"
    $OutputFile = "$([Environment]::GetFolderPath('MyDocuments'))\vscode-profiles-export-$(Get-Date -Format 'yyyy-MM-dd').txt"

    Write-Host "=== VS Code Profile Export ===" -ForegroundColor Cyan
    Write-Host "Output file: $OutputFile`n"

    # --- Auto-discover profile names from storage.json ---
    $json = Get-Content $StorageJson -Raw | ConvertFrom-Json
    $VSCodeProfiles = @("Default") + ($json.userDataProfiles | Select-Object -ExpandProperty name)

    Write-Host "[✓] Found profiles: $($VSCodeProfiles -join ', ')`n"

    # --- Build all content in memory, write once (no intermediate files) ---
    $lines = [System.Collections.Generic.List[string]]::new()

    $lines.Add("VS Code Profile & Extension Export")
    $lines.Add("Generated: $(Get-Date)")
    $lines.Add("Machine:   $env:COMPUTERNAME")
    $lines.Add("==================================================")

    foreach ($VSCodeProfile in $VSCodeProfiles) {
        $lines.Add("")
        $lines.Add("--------------------------------------------------")
        $lines.Add("Profile: $VSCodeProfile")
        $lines.Add("--------------------------------------------------")

        $Exts = @(code --list-extensions --profile $VSCodeProfile 2>$null)

        if (-not $Exts) {
            $lines.Add("(no extensions installed)")
        }
        else {
            foreach ($ext in $Exts) { $lines.Add($ext) }
            $lines.Add("")
            $lines.Add("Total: $($Exts.Count) extension(s)")
        }
    }

    $lines.Add("")
    $lines.Add("==================================================")
    $lines.Add("End of export")

    # --- Single write to disk (honors -WhatIf) ---
    if ($PSCmdlet.ShouldProcess($OutputFile, "Export VS Code profiles and extensions")) {
        $lines | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "[✓] Export complete: $OutputFile`n"
    }
    else {
        Write-Host "[i] WhatIf: Output file would be written to $OutputFile`n"
    }

    # --- Print summary to terminal ---
    Write-Host "=== Summary ===" -ForegroundColor Green
    foreach ($VSCodeProfile in $VSCodeProfiles) {
        $count = @(code --list-extensions --profile $VSCodeProfile 2>$null).Count
        Write-Host "  ${VSCodeProfile}: $count extension(s)"
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
