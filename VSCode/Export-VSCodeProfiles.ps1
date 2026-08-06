<#
.SYNOPSIS
Exports all VS Code profiles, extensions, settings, keybindings, and snippets to a structured backup folder.

.DESCRIPTION
Performs a comprehensive backup of all Visual Studio Code user profiles. The script exports:
- Profile metadata (storage.json)
- Installed extensions per profile
- Global settings (settings.json, keybindings.json)
- Code snippets
- A machine-readable manifest.json for restore automation

.PARAMETER OutputDirectory
Specifies the destination folder for the export. Defaults to a timestamped folder in the user's Documents directory. Must not contain invalid Windows path characters (< > " | ? * or control characters).

.PARAMETER VSCodeUserDataPath
Specifies the VS Code user data directory. Defaults to the standard location for the current user.

.PARAMETER CodeCommand
Specifies the VS Code CLI command to use. Defaults to 'code'. Override this for testing or when the CLI is installed under a different name.

.EXAMPLE
.\Export-VSCodeProfiles.ps1

Exports all VS Code profiles to a timestamped folder in Documents.

.EXAMPLE
.\Export-VSCodeProfiles.ps1 -OutputDirectory "C:\Backups\VSCode"

Exports all profiles to the specified directory.

.EXAMPLE
.\Export-VSCodeProfiles.ps1 -WhatIf

Previews the export operation without creating any files.

.NOTES
    Version:        1.0.0
    Author:         chriskyfung, Claude Sonnet 4.6, Laguna M.1
    License:        GNU GPLv3 license
    Creation Date:  2026-07-21
    Last Modified:  2026-07-21
    Prerequisite:   PowerShell 5.0+
    Requirements:   VS Code CLI ('code' command) must be in PATH
#>

#Requires -Version 5.0
#Requires -PSEdition Desktop

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateScript({
        if ($_ -match '[<>"|?*\x00-\x1F]') {
            throw "OutputDirectory contains invalid path characters: '$_'"
        }
        $true
    })]
    [string]$OutputDirectory,

    [Parameter(Mandatory = $false)]
    [string]$VSCodeUserDataPath = "$env:APPDATA\Code\User",

    [Parameter(Mandatory = $false)]
    [string]$CodeCommand = "code"
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $storageJsonPath = Join-Path -Path $VSCodeUserDataPath -ChildPath "globalStorage\storage.json"
    $timestamp = Get-Date -Format 'yyyy-MM-dd'
    $settingsFiles = @("settings.json", "keybindings.json")
}

process {
    try {
        #region Validate Prerequisites
        if (-not (Test-Path $VSCodeUserDataPath -PathType Container)) {
            throw "VS Code user data directory not found: $VSCodeUserDataPath"
        }

        if (-not (Test-Path $storageJsonPath -PathType Leaf)) {
            throw "VS Code storage.json not found at '$storageJsonPath'. Is VS Code installed and have profiles been created?"
        }

        if (-not (Get-Command $CodeCommand -ErrorAction SilentlyContinue)) {
            throw "VS Code CLI ('$CodeCommand') is not available in PATH. Install it via VS Code Command Palette: 'Shell Command: Install code command in PATH'."
        }

        $outputDir = if ($OutputDirectory) {
            [System.IO.Path]::GetFullPath($OutputDirectory)
        }
        else {
            $documentsPath = [Environment]::GetFolderPath('MyDocuments')
            Join-Path -Path $documentsPath -ChildPath "vscode-export-$timestamp"
        }

        $extensionsDir = Join-Path -Path $outputDir -ChildPath "extensions"
        #endregion

        #region Initialize Output Directory
        if ($PSCmdlet.ShouldProcess($outputDir, "Create export directory")) {
            New-Item -ItemType Directory -Path $extensionsDir -Force | Out-Null
            Write-Host "=== VS Code Profile Export ===" -ForegroundColor Cyan
            Write-Host "Output: $outputDir`n"
        }
        #endregion

        #region Step 1: Save Profile Metadata
        if ($PSCmdlet.ShouldProcess($storageJsonPath, "Copy profile metadata")) {
            Copy-Item -Path $storageJsonPath -Destination (Join-Path $outputDir "storage.json") -Force
            Write-Host "[✓] Saved storage.json"
        }
        #endregion

        #region Step 2: Discover Profiles
        $profileData = Get-Content -Path $storageJsonPath -Raw | ConvertFrom-Json
        $userProfiles = @()
        if ($profileData.PSObject.Properties['userDataProfiles']) {
            $userProfiles = @($profileData.userDataProfiles | Select-Object -ExpandProperty name | Where-Object { $_ -ne "Default" })
        }
        $profiles = @("Default") + $userProfiles

        if ($userProfiles.Count -eq 0) {
            Write-Warning "No additional profiles found in storage.json. Exporting 'Default' profile only."
        }

        Write-Host "[✓] Found profiles: $($profiles -join ', ')"
        Write-Host ""
        #endregion

        #region Step 3: Export Extensions Per Profile
        $manifest = @{ profiles = @() }

        foreach ($profileName in $profiles) {
            $safeProfileName = $profileName -replace '[\s/\\]', '_'
            $outputFilePath = Join-Path -Path $extensionsDir -ChildPath "$safeProfileName.txt"

            if ($PSCmdlet.ShouldProcess("Exporting extensions for profile '$profileName'")) {
                Write-Host "  Exporting: $profileName"

                try {
                    $extensions = @(& $CodeCommand --list-extensions --profile $profileName 2>$null)
                    if ($LASTEXITCODE -ne 0) {
                        throw "code exited with code $LASTEXITCODE"
                    }
                }
                catch {
                    Write-Warning "Failed to list extensions for profile '$profileName'. Skipping: $_"
                    continue
                }

                $extensions | Out-File -FilePath $outputFilePath -Encoding UTF8
                $extensionCount = $extensions.Count
                Write-Host "    $extensionCount extensions found"

                $manifest.profiles += @{
                    name            = $profileName
                    extension_count = $extensionCount
                    extensions      = $extensions
                }
            }
        }
        #endregion

        #region Step 4: Save Global Settings
        if ($PSCmdlet.ShouldProcess("Saving global settings")) {
            Write-Host ""
            Write-Host "Saving global settings..."

            foreach ($fileName in $settingsFiles) {
                $sourcePath = Join-Path -Path $VSCodeUserDataPath -ChildPath $fileName
                $destinationPath = Join-Path -Path $outputDir -ChildPath $fileName

                if (Test-Path -Path $sourcePath -PathType Leaf) {
                    Copy-Item -Path $sourcePath -Destination $destinationPath -Force
                    Write-Host "  [✓] $fileName"
                }
                else {
                    Write-Verbose "File not found, skipping: $sourcePath"
                }
            }

            $snippetsSourcePath = Join-Path -Path $VSCodeUserDataPath -ChildPath "snippets"
            if (Test-Path -Path $snippetsSourcePath -PathType Container) {
                Copy-Item -Path $snippetsSourcePath -Destination (Join-Path $outputDir "snippets") -Recurse -Force
                Write-Host "  [✓] snippets/"
            }
            else {
                Write-Verbose "Snippets folder not found, skipping."
            }
        }
        #endregion

        #region Step 5: Generate Manifest
        if ($PSCmdlet.ShouldProcess("Generating manifest.json")) {
            $manifestPath = Join-Path -Path $outputDir -ChildPath "manifest.json"
            $manifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $manifestPath -Encoding UTF8
            Write-Host ""
            Write-Host "[✓] Generated manifest.json"
        }
        #endregion

        #region Summary
        if ($PSCmdlet.ShouldProcess("Displaying summary")) {
            Write-Host ""
            Write-Host "=== Summary ===" -ForegroundColor Green
            foreach ($entry in $manifest.profiles) {
                Write-Host "  $($entry.name): $($entry.extension_count) extensions"
            }
            Write-Host ""
            Write-Host "Export complete: $outputDir"
        }
        #endregion
    }
    catch {
        Write-Error "Export failed: $_" -ErrorAction Continue
        throw
    }
}
