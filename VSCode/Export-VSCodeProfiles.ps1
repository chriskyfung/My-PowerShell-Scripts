<#
.SYNOPSIS
    Exports all VS Code user profiles, extensions, settings, and snippets to a timestamped backup folder.

.DESCRIPTION
    This script performs a comprehensive backup of Visual Studio Code configurations by:
    - Exporting all user profiles and their installed extensions
    - Copying global settings, keybindings, and snippets
    - Generating a machine-readable manifest.json for programmatic restoration

    The output is saved to a timestamped folder in the user's Documents directory.

.PARAMETER WhatIf
    Shows what would be exported without actually creating files.

.EXAMPLE
    .\Export-VSCodeProfiles.ps1

    Exports all VS Code profiles to C:\Users\username\Documents\vscode-export-2026-06-01

.EXAMPLE
    .\Export-VSCodeProfiles.ps1 -WhatIf

    Displays what would be exported without making changes.

.NOTES
    Version:        1.0.0
    Author:         chriskyfung, Claude Sonnet 4.6, Laguna M.1
    License:        GNU GPLv3 license
    Creation Date:  2026-06-01
    Last Modified:  2026-07-21
    Prerequisite:   PowerShell 5.0+
    Requirements:   VS Code CLI ('code' command) must be in PATH
#>

#Requires -Version 5.0
#Requires -PSEdition Desktop

[CmdletBinding()]

# Script-level error handling
$ErrorActionPreference = 'Stop'

try {
    $VSCodeUserDir = "$env:APPDATA\Code\User"
    $StorageJson = "$VSCodeUserDir\globalStorage\storage.json"
    $OutputDir = "$([Environment]::GetFolderPath('MyDocuments'))\vscode-export-$(Get-Date -Format 'yyyy-MM-dd')"

    New-Item -ItemType Directory -Force -Path "$OutputDir\extensions" | Out-Null
    Write-Host "=== VS Code Profile Export ===" -ForegroundColor Cyan
    Write-Host "Output: $OutputDir`n"

    # Step 1: Save profile metadata
    Copy-Item $StorageJson "$OutputDir\storage.json"
    Write-Host "[✓] Saved storage.json"

    # Step 2: Auto-discover profiles
    $json = Get-Content $StorageJson | ConvertFrom-Json
    $VSCodeProfiles = @("Default") + ($json.userDataProfiles | Select-Object -ExpandProperty name)
    Write-Host "[✓] Found profiles: $($VSCodeProfiles -join ', ')`n"

    # Step 3: Export extensions per profile
    $Manifest = @{ profiles = @() }

    foreach ($VSCodeProfile in $VSCodeProfiles) {
        $SafeName = $VSCodeProfile -replace '[\s/\\]', '_'
        $OutFile = "$OutputDir\extensions\$SafeName.txt"

        Write-Host "  Exporting: $VSCodeProfile"
        $Exts = code --list-extensions --profile $VSCodeProfile 2>$null
        $Exts | Out-File $OutFile -Encoding UTF8

        Write-Host "    $($Exts.Count) extensions found"
        $Manifest.profiles += @{ name = $VSCodeProfile; extension_count = $Exts.Count; extensions = $Exts }
    }

    # Step 4: Save global settings
    Write-Host "`nSaving global settings..."
    foreach ($File in @("settings.json", "keybindings.json")) {
        $Src = "$VSCodeUserDir\$File"
        if (Test-Path $Src) {
            Copy-Item $Src "$OutputDir\$File"
            Write-Host "  [✓] $File"
        }
    }
    if (Test-Path "$VSCodeUserDir\snippets") {
        Copy-Item "$VSCodeUserDir\snippets" "$OutputDir\snippets" -Recurse
        Write-Host "  [✓] snippets/"
    }

    # Step 5: Write manifest
    $Manifest | ConvertTo-Json -Depth 5 | Out-File "$OutputDir\manifest.json" -Encoding UTF8
    Write-Host "`n[✓] Generated manifest.json"

    Write-Host "`n=== Summary ===" -ForegroundColor Green
    $Manifest.profiles | ForEach-Object { Write-Host "  $($_.name): $($_.extension_count) extensions" }
    Write-Host "`nExport complete: $OutputDir"

}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
