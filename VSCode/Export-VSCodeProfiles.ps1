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
Specifies the destination folder for the export. Defaults to a timestamped folder in the user's Documents directory.

.PARAMETER VSCodeUserDataPath
Specifies the VS Code user data directory. Defaults to the standard location for the current user.

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
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateScript({ if ($_ -match '[\\/:*?"<>|]') { throw "Output directory path contains invalid characters." }; $_ })]
    [string]$OutputDirectory,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ if (-not (Test-Path $_ -PathType Container)) { throw "VS Code user data directory not found: $_" } })]
    [string]$VSCodeUserDataPath = "$env:APPDATA\Code\User"
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $script:StorageJsonPath = Join-Path -Path $VSCodeUserDataPath -ChildPath "globalStorage\storage.json"
    $script:Timestamp = Get-Date -Format 'yyyy-MM-dd'
}

process {
    try {
        #region Validate Prerequisites
        if (-not (Test-Path $script:StorageJsonPath -PathType Leaf)) {
            throw "VS Code storage.json not found at '$script:StorageJsonPath'. Is VS Code installed and have profiles been created?"
        }

        if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
            throw "VS Code CLI ('code') is not available in PATH. Install it via VS Code Command Palette: 'Shell Command: Install code command in PATH'."
        }

        $script:OutputDir = if ($OutputDirectory) {
            [System.IO.Path]::GetFullPath($OutputDirectory)
        }
        else {
            $documentsPath = [Environment]::GetFolderPath('MyDocuments')
            Join-Path -Path $documentsPath -ChildPath "vscode-export-$($script:Timestamp)"
        }

        $script:ExtensionsDir = Join-Path -Path $script:OutputDir -ChildPath "extensions"
        #endregion

        #region Initialize Output Directory
        if ($PSCmdlet.ShouldProcess($script:OutputDir, "Create export directory")) {
            New-Item -ItemType Directory -Path $script:ExtensionsDir -Force | Out-Null
            Write-Host "=== VS Code Profile Export ===" -ForegroundColor Cyan
            Write-Host "Output: $script:OutputDir`n"
        }
        #endregion

        #region Step 1: Save Profile Metadata
        if ($PSCmdlet.ShouldProcess($script:StorageJsonPath, "Copy profile metadata")) {
            Copy-Item -Path $script:StorageJsonPath -Destination (Join-Path $script:OutputDir "storage.json") -Force
            Write-Host "[✓] Saved storage.json"
        }
        #endregion

        #region Step 2: Discover Profiles
        if ($PSCmdlet.ShouldProcess("Discovering VS Code profiles")) {
            $profileData = Get-Content -Path $script:StorageJsonPath -Raw | ConvertFrom-Json
            $script:Profiles = @("Default") + ($profileData.userDataProfiles | Select-Object -ExpandProperty name | Where-Object { $_ -ne "Default" })

            if (-not $script:Profiles -or $script:Profiles.Count -eq 0) {
                Write-Warning "No profiles found in storage.json."
                return
            }

            Write-Host "[✓] Found profiles: $($script:Profiles -join ', ')"
            Write-Host ""
        }
        #endregion

        #region Step 3: Export Extensions Per Profile
        $script:Manifest = @{ profiles = @() }

        foreach ($profile in $script:Profiles) {
            $safeProfileName = $profile -replace '[\s/\\]', '_'
            $outputFilePath = Join-Path -Path $script:ExtensionsDir -ChildPath "$safeProfileName.txt"

            if ($PSCmdlet.ShouldProcess("Exporting extensions for profile '$profile'")) {
                Write-Host "  Exporting: $profile"

                $extensions = @(code --list-extensions --profile $profile 2>$null)

                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Failed to list extensions for profile '$profile'. Skipping."
                    continue
                }

                $extensions | Out-File -FilePath $outputFilePath -Encoding UTF8
                $extensionCount = $extensions.Count
                Write-Host "    $extensionCount extensions found"

                $script:Manifest.profiles += @{
                    name            = $profile
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

            $settingsFiles = @("settings.json", "keybindings.json")
            foreach ($fileName in $settingsFiles) {
                $sourcePath = Join-Path -Path $VSCodeUserDataPath -ChildPath $fileName
                $destinationPath = Join-Path -Path $script:OutputDir -ChildPath $fileName

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
                Copy-Item -Path $snippetsSourcePath -Destination (Join-Path $script:OutputDir "snippets") -Recurse -Force
                Write-Host "  [✓] snippets/"
            }
            else {
                Write-Verbose "Snippets folder not found, skipping."
            }
        }
        #endregion

        #region Step 5: Generate Manifest
        if ($PSCmdlet.ShouldProcess("Generating manifest.json")) {
            $manifestPath = Join-Path -Path $script:OutputDir -ChildPath "manifest.json"
            $script:Manifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $manifestPath -Encoding UTF8
            Write-Host ""
            Write-Host "[✓] Generated manifest.json"
        }
        #endregion

        #region Summary
        if ($PSCmdlet.ShouldProcess("Displaying summary")) {
            Write-Host ""
            Write-Host "=== Summary ===" -ForegroundColor Green
            foreach ($profile in $script:Manifest.profiles) {
                Write-Host "  $($profile.name): $($profile.extension_count) extensions"
            }
            Write-Host ""
            Write-Host "Export complete: $script:OutputDir"
        }
        #endregion
    }
    catch {
        Write-Error "Export failed: $_"
        exit 1
    }
}

end {
    # Cleanup if needed
}
