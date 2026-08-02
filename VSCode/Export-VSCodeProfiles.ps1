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
    Author:         Chris KY Fung, Claude Sonnet 4.6, Laguna M.1
    License:        GNU GPLv3 license
    Creation Date:  2026-06-01
    Last Modified:  2026-07-21
    Prerequisite:   PowerShell 5.0+
    Requirements:   VS Code CLI ('code' command) must be in PATH
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$WhatIf
)

#Requires -Version 5.0

# Script-level error handling
$ErrorActionPreference = 'Stop'

#region Constants
$VSCodeUserDir = Join-Path -Path $env:APPDATA -ChildPath 'Code\User'
$StorageJson = Join-Path -Path $VSCodeUserDir -ChildPath 'globalStorage\storage.json'
$Timestamp = Get-Date -Format 'yyyy-MM-dd'
$OutputDir = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "vscode-export-$Timestamp"
$ManifestPath = Join-Path -Path $OutputDir -ChildPath 'manifest.json'
$SettingsFiles = @('settings.json', 'keybindings.json')
#endregion

#region Helper Functions
function Write-Step {
    <#
    .SYNOPSIS
        Displays formatted status messages for script steps.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "  $Message" -ForegroundColor Gray
}

function Write-Success {
    <#
    .SYNOPSIS
        Displays success messages with checkmark.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Info {
    <#
    .SYNOPSIS
        Displays informational messages.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Cyan', 'Green', 'Yellow', 'Red', 'Gray')]
        [string]$Color = 'Cyan'
    )

    Write-Host $Message -ForegroundColor $Color
}
#endregion

#region Validate Prerequisites
function Test-Prerequisites {
    <#
    .SYNOPSIS
        Validates that required tools and paths are available.
    #>

    Write-Info "`n=== Validating Prerequisites ===" -Color Cyan

    # Check VS Code user directory
    if (-not (Test-Path $VSCodeUserDir)) {
        throw "VS Code user directory not found at: $VSCodeUserDir"
    }

    # Check storage.json
    if (-not (Test-Path $StorageJson)) {
        throw "storage.json not found at: $StorageJson. Ensure VS Code is installed and profiles are configured."
    }

    # Check VS Code CLI
    try {
        $codeVersion = code --version 2>&1
        if (-not $codeVersion) {
            throw "VS Code CLI not found in PATH"
        }
    }
    catch {
        throw "VS Code CLI ('code' command) is not available. Install it via Command Palette: 'Shell Command: Install `code` command in PATH'"
    }

    Write-Success "Prerequisites validated"
}

function Get-VSCodeProfiles {
    <#
    .SYNOPSIS
        Discovers all VS Code profiles from storage.json.
    #>
    [OutputType([string[]])]

    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$StoragePath
    )

    try {
        $null = Get-Content -Path $StoragePath -ErrorAction Stop | ConvertFrom-Json
        $json = Get-Content -Path $StoragePath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Failed to parse storage.json: $_"
    }

    # Get profile names, defaulting to 'Default' if none found
    $profileNames = @('Default')
    if ($json.userDataProfiles) {
        $userProfiles = $json.userDataProfiles | Select-Object -ExpandProperty name -ErrorAction SilentlyContinue
        if ($userProfiles) {
            $profileNames += $userProfiles
        }
    }

    return $profileNames
}
#endregion

#region Export Functions
function Initialize-ExportDirectory {
    <#
    .SYNOPSIS
        Creates the output directory structure.
    #>

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$WhatIf
    )

    $extensionsDir = Join-Path -Path $Path -ChildPath 'extensions'

    if ($WhatIf) {
        Write-Host "[WHATIF] Would create directory: $Path"
        Write-Host "[WHATIF] Would create directory: $extensionsDir"
        return
    }

    try {
        New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
        New-Item -ItemType Directory -Path $extensionsDir -Force -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Failed to create output directories: $_"
    }
}

function Export-ProfileExtensions {
    <#
    .SYNOPSIS
        Exports extensions for each VS Code profile.
    #>
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Profiles,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [switch]$WhatIf
    )

    $manifest = @{ profiles = @() }
    $extensionsDir = Join-Path -Path $OutputDirectory -ChildPath 'extensions'

    foreach ($profileName in $Profiles) {
        $safeName = $profileName -replace '[\s/\\]', '_'
        $outFile = Join-Path -Path $extensionsDir -ChildPath "$safeName.txt"

        Write-Info "  Exporting: $profileName" -Color Gray

        if ($WhatIf) {
            Write-Host "[WHATIF] Would list extensions for profile: $profileName"
            Write-Host "[WHATIF] Would write to: $outFile"
            continue
        }

        try {
            # List extensions for this profile
            $extensions = code --list-extensions --profile $profileName 2>$null

            if ($null -eq $extensions) {
                $extensions = @()
            }

            # Export to file
            $extensions | Out-File -FilePath $outFile -Encoding UTF8 -ErrorAction Stop

            Write-Host "    $($extensions.Count) extensions found" -ForegroundColor Gray

            # Add to manifest
            $manifest.profiles += @{
                name            = $profileName
                extension_count = $extensions.Count
                extensions      = $extensions
            }
        }
        catch {
            Write-Warning "Failed to export extensions for profile '$profileName': $_"
        }
    }

    return $manifest.profiles
}

function Export-Settings {
    <#
    .SYNOPSIS
        Copies global VS Code settings files.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$VSCodeUserDir,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [switch]$WhatIf
    )

    Write-Info "`nSaving global settings..." -Color Cyan

    foreach ($fileName in $SettingsFiles) {
        $sourcePath = Join-Path -Path $VSCodeUserDir -ChildPath $fileName
        $destPath = Join-Path -Path $OutputDirectory -ChildPath $fileName

        if ($WhatIf) {
            if (Test-Path $sourcePath) {
                Write-Host "[WHATIF] Would copy: $fileName"
            }
            continue
        }

        if (Test-Path $sourcePath) {
            try {
                Copy-Item -Path $sourcePath -Destination $destPath -ErrorAction Stop
                Write-Success $fileName
            }
            catch {
                Write-Warning "Failed to copy $fileName : $_"
            }
        }
        else {
            Write-Host "  [i] $fileName not found (skipped)" -ForegroundColor Yellow
        }
    }

    # Export snippets folder
    $snippetsSource = Join-Path -Path $VSCodeUserDir -ChildPath 'snippets'
    $snippetsDest = Join-Path -Path $OutputDirectory -ChildPath 'snippets'

    if ($WhatIf) {
        if (Test-Path $snippetsSource) {
            Write-Host "[WHATIF] Would copy snippets/ folder"
        }
        return
    }

    if (Test-Path $snippetsSource) {
        try {
            Copy-Item -Path $snippetsSource -Destination $snippetsDest -Recurse -ErrorAction Stop
            Write-Success 'snippets/'
        }
        catch {
            Write-Warning "Failed to copy snippets folder: $_"
        }
    }
    else {
        Write-Host "  [i] snippets/ folder not found (skipped)" -ForegroundColor Yellow
    }
}

function New-ManifestFile {
    <#
    .SYNOPSIS
        Generates the manifest.json file.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable[]]$ProfileData,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [switch]$WhatIf
    )

    if ($WhatIf) {
        Write-Host "`n[WHATIF] Would generate manifest.json with $($ProfileData.Count) profile(s)"
        return
    }

    try {
        $manifest = @{ profiles = $ProfileData }
        $manifest | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8 -ErrorAction Stop
        Write-Success 'Generated manifest.json'
    }
    catch {
        Write-Warning "Failed to generate manifest.json: $_"
    }
}
#endregion

#region Main Script
function Main {
    <#
    .SYNOPSIS
        Main script execution flow.
    #>

    try {
        # Display welcome message
        Write-Info "=== VS Code Profile Export ===" -Color Cyan
        Write-Info "Output: $OutputDir`n" -Color Cyan

        # Validate prerequisites
        Test-Prerequisites

        # Initialize output directory
        Initialize-ExportDirectory -Path $OutputDir -WhatIf:$WhatIf

        if (-not $WhatIf) {
            # Step 1: Save storage.json
            Copy-Item -Path $StorageJson -Destination (Join-Path $OutputDir 'storage.json') -ErrorAction Stop
            Write-Success 'Saved storage.json'
        }
        else {
            Write-Host "[WHATIF] Would save storage.json" -ForegroundColor Yellow
        }

        # Step 2: Discover profiles
        Write-Info '`nDiscovering profiles...' -Color Cyan
        $profiles = Get-VSCodeProfiles -StoragePath $StorageJson
        Write-Success "Found profiles: $($profiles -join ', ')"

        # Step 3: Export extensions per profile
        Write-Info '`nExporting extensions...' -Color Cyan
        $manifestData = Export-ProfileExtensions -Profiles $profiles -OutputDirectory $OutputDir -WhatIf:$WhatIf

        # Step 4: Export global settings
        Export-Settings -VSCodeUserDir $VSCodeUserDir -OutputDirectory $OutputDir -WhatIf:$WhatIf

        # Step 5: Generate manifest
        New-ManifestFile -ProfileData $manifestData -OutputPath $ManifestPath -WhatIf:$WhatIf

        # Display summary
        if (-not $WhatIf) {
            Write-Info '`n=== Summary ===' -Color Green
            foreach ($profile in $manifestData) {
                Write-Host "  $($profile.name): $($profile.extension_count) extensions" -ForegroundColor Green
            }
            Write-Host "`nExport complete: $OutputDir" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Script failed: $_"
        exit 1
    }
}

# Execute main function
Main
