<#
.SYNOPSIS
  Optimizes WSL distro virtual hard disks (VHDX) to reclaim unused space.

.DESCRIPTION
  This script shrinks WSL distro VHDX files by compacting them with the Optimize-VHD cmdlet.
  It requires the Hyper-V PowerShell module and administrator privileges.

  The script performs the following steps:
  1. Discovers installed WSL distros via `wsl --list`
  2. Locates each distro's VHDX file (ext4.vhdx) via the registry or common paths
  3. Stops the target distro using `wsl --terminate`
  4. Uses Optimize-VHD cmdlet to compact the VHDX file

.EXAMPLE
  PS C:\> .\Optimize-WslDistroVHD.ps1
  Optimizes a WSL distro interactively (lists all distros and prompts for selection).

.EXAMPLE
  PS C:\> .\Optimize-WslDistroVHD.ps1 -DistroName "Ubuntu-20.04"
  Optimizes the specified WSL distro without interactive selection.

.EXAMPLE
  PS C:\> .\Optimize-WslDistroVHD.ps1 -VhdPath "D:\WSL\Ubuntu\ext4.vhdx"
  Optimizes a custom VHDX file location directly.

.EXAMPLE
  PS C:\> .\Optimize-WslDistroVHD.ps1 -Mode Retain
  Optimizes using Retain mode (faster but less thorough than Full).

.EXAMPLE
  PS C:\> .\Optimize-WslDistroVHD.ps1 -WhatIf
  Shows what the script would do without actually running it.

.OUTPUTS
  System.Object. The script outputs status messages and optimization results for each distro.

.NOTES
  Version:        1.0.0
  Author:         chriskyfung
  License:        GNU GPLv3 license
  Creation Date:  2026-08-01
  Last Modified:  2026-08-01
  Requirements:   - Windows 10/11 Pro/Enterprise/Server (for Optimize-VHD)
                  - Hyper-V PowerShell module
                  - Administrator privileges
                  - WSL 2 distros

.LINK
  https://docs.microsoft.com/en-us/powershell/module/hyper-v/optimize-vhd
  https://docs.microsoft.com/en-us/windows/wsl/
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$DistroName,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) {
                return $true
            }
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "VHDX file not found: $_"
            }
            if ([System.IO.Path]::GetExtension($_) -ne '.vhdx') {
                throw "File must be a .vhdx file"
            }
            return $true
        })]
    [string]$VhdPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Full', 'Retain', 'None')]
    [string]$Mode = 'Full'
)

$ErrorActionPreference = "Stop"

#region Helper Functions

function Invoke-WslCommand {
    <#
    .SYNOPSIS
      Executes the WSL command-line tool with the provided arguments.
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    return wsl.exe @Arguments
}

function Get-WslDistroList {
    <#
    .SYNOPSIS
      Retrieves a list of installed WSL distro names.
    #>
    [OutputType([string[]])]
    param ()

    Write-Verbose "Discovering WSL distros..."
    $wslOutput = Invoke-WslCommand -Arguments @('--list', '--quiet') 2>&1

    if ($LASTEXITCODE -ne 0 -or $null -eq $wslOutput) {
        Write-Warning "WSL may not be installed or no distros found."
        return @()
    }

    $distros = @()
    foreach ($line in $wslOutput) {
        # Strip NUL bytes: wsl.exe may output UTF-16 with null bytes between characters
        $trimmed = $line -replace '\x00', '' | ForEach-Object { $_.Trim() }
        if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
            $distros += $trimmed
        }
    }

    return $distros
}

function Get-WslDistroVhdPath {
    <#
    .SYNOPSIS
      Locates the VHDX file for a given WSL distro.
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DistroName
    )

    # Ensure DistroName is a plain string
    $DistroName = [string]$DistroName

    Write-Verbose "Locating VHDX for distro: $DistroName"

    # Try registry lookup first
    try {
        $lxssPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
        $subKeys = Get-ChildItem -Path $lxssPath -ErrorAction Stop
        foreach ($subKey in $subKeys) {
            $distro = Get-ItemProperty -Path $subKey.PSPath -ErrorAction SilentlyContinue
            if ($distro.DistributionName -eq $DistroName) {
                $basePath = $distro.BasePath
                if (-not [string]::IsNullOrEmpty($basePath)) {
                    $vhdxPath = Join-Path -Path $basePath -ChildPath "ext4.vhdx"
                    if (Test-Path -Path $vhdxPath -PathType Leaf) {
                        Write-Verbose "Found VHDX via registry: $vhdxPath"
                        return $vhdxPath
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "Registry lookup failed: $($_.Exception.Message)"
    }

    # Fallback: search common locations
    Write-Verbose "Falling back to common locations..."
    $commonPaths = @(
        (Join-Path -Path $env:LOCALAPPDATA -ChildPath "Packages\*\LocalState\ext4.vhdx"),
        (Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\WindowsApps\$DistroName\ext4.vhdx")
    )

    foreach ($pattern in $commonPaths) {
        $resolved = Resolve-Path -Path $pattern -ErrorAction SilentlyContinue
        if ($resolved) {
            Write-Verbose "Found VHDX via fallback: $resolved"
            return $resolved.Path
        }
    }

    throw "Could not locate VHDX file for distro '$DistroName' via registry or common locations."
}

function Select-WslDistro {
    <#
    .SYNOPSIS
      Presents an interactive numbered list of WSL distros for user selection.
    #>
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Distros
    )

    Write-Host "`nDiscovered WSL Distros:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Distros.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $Distros[$i])
    }
    Write-Host ""

    do {
        $userInput = Read-Host "Enter the numbers of the distros to optimize (comma-separated, e.g. 1,3,5)"
        $selectedIndices = @()
        $valid = $true

        foreach ($part in $userInput -split ',') {
            $part = $part.Trim()
            if (-not [int]::TryParse($part, [ref]$null)) {
                Write-Warning "Invalid input: '$part'. Please enter numbers only."
                $valid = $false
                break
            }
            $num = [int]$part
            if ($num -lt 1 -or $num -gt $Distros.Count) {
                Write-Warning "Number '$num' is out of range. Valid range: 1-$($Distros.Count)"
                $valid = $false
                break
            }
            $selectedIndices += ($num - 1)
        }

        if (-not $valid) {
            continue
        }

        if ($selectedIndices.Count -eq 0) {
            Write-Warning "No distros selected. Please enter at least one number."
            continue
        }

        break
    } while ($true)

    $selectedDistros = @()
    foreach ($idx in $selectedIndices) {
        $selectedDistros += $Distros[$idx]
    }

    return $selectedDistros
}

function Stop-WslDistro {
    <#
    .SYNOPSIS
      Stops a WSL distro if it is running.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DistroName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $state = Invoke-WslCommand -Arguments @('--list', '--verbose') 2>&1 | Where-Object { $_ -match [regex]::Escape($DistroName) }

    if ($state -and $state -match 'Running') {
        $caption = "Stop WSL Distro"
        $message = "WSL distro '$DistroName' is currently running.`n`nIt must be stopped before optimizing the VHDX file.`n`nDo you want to continue?"

        if ($Force -or $PSCmdlet.ShouldContinue($message, $caption)) {
            if ($PSCmdlet.ShouldProcess("WSL distro: $DistroName", "Terminate")) {
                Write-Verbose "Terminating WSL distro: $DistroName"
                Invoke-WslCommand -Arguments @('--terminate', $DistroName) | Out-Null

                # Wait briefly for termination
                Start-Sleep -Seconds 2

                $verifyState = Invoke-WslCommand -Arguments @('--list', '--verbose') 2>&1 | Where-Object { $_ -match [regex]::Escape($DistroName) }
                if ($verifyState -and $verifyState -match 'Running') {
                    Write-Warning "Distro '$DistroName' may still be running. Continuing anyway..."
                }
                else {
                    Write-Host "WSL distro '$DistroName' has been stopped."
                }
            }
        }
        else {
            Write-Host "Operation cancelled by user. Distro '$DistroName' remains running."
            return $false
        }
    }
    else {
        Write-Verbose "WSL distro '$DistroName' is not running."
    }

    return $true
}

#endregion

function Start-WslDistroVhdOptimization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$DistroName,
        [switch]$Force,
        [ValidateScript({
                if ([string]::IsNullOrWhiteSpace($_)) {
                    return $true
                }
                if (-not (Test-Path -Path $_ -PathType Leaf)) {
                    throw "VHDX file not found: $_"
                }
                if ([System.IO.Path]::GetExtension($_) -ne '.vhdx') {
                    throw "File must be a .vhdx file"
                }
                return $true
            })]
        [string]$VhdPath,
        [ValidateSet('Full', 'Retain', 'None')]
        [string]$Mode = 'Full'
    )

    # Normalize $Force to a plain boolean
    if ($PSBoundParameters.ContainsKey('Force')) {
        $Force = [bool]$Force
    }
    else {
        $Force = $false
    }

    try {
        # Determine VHDX path(s) to optimize
        $targets = @()

        if ($VhdPath) {
            # Manual override: optimize the specified VHDX directly
            Write-Verbose "Using manual VHDX path: $VhdPath"
            $targets += [PSCustomObject]@{
                DistroName = [System.IO.Path]::GetFileNameWithoutExtension($VhdPath)
                VhdPath    = $VhdPath
            }
        }
        else {
            # Auto-discover WSL distros
            $allDistros = Get-WslDistroList

            if ($allDistros.Count -eq 0) {
                Write-Warning "No WSL distros were found. Ensure WSL is installed and has at least one distro."
                return
            }

            # Filter by DistroName if specified
            if ($DistroName) {
                $filtered = $allDistros | Where-Object { $_ -eq $DistroName }
                if ($filtered.Count -eq 0) {
                    throw "Distro '$DistroName' not found. Available distros: $($allDistros -join ', ')"
                }
                $selected = @($filtered)
            }
            else {
                # Interactive selection
                $selected = @(Select-WslDistro -Distros $allDistros)
            }

            foreach ($name in $selected) {
                $vhdxPath = Get-WslDistroVhdPath -DistroName $name
                $targets += [PSCustomObject]@{
                    DistroName = $name
                    VhdPath    = $vhdxPath
                }
            }
        }

        # Optimize each target
        foreach ($target in $targets) {
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host ("Optimizing: {0}" -f $target.DistroName) -ForegroundColor Cyan
            Write-Host ("VHDX Path: {0}" -f $target.VhdPath) -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan

            # Validate VHDX file exists
            if (-not (Test-Path -Path $target.VhdPath -PathType Leaf)) {
                Write-Warning "VHDX file not found at: $($target.VhdPath). Skipping."
                continue
            }

            # Get initial file size
            $initialSize = (Get-Item -Path $target.VhdPath).Length
            $initialSizeMB = [math]::Round($initialSize / 1MB, 2)
            Write-Host "Initial VHDX file size: $initialSizeMB MB"

            # Stop the distro if running
            $stopped = Stop-WslDistro -DistroName $target.DistroName -Force:$Force
            if ($stopped -eq $false) {
                Write-Warning "Cannot optimize '$($target.DistroName)' because it is still running. Skipping."
                continue
            }

            # Optimize VHDX
            if ($PSCmdlet.ShouldProcess("VHDX file: $($target.VhdPath)", "Optimize")) {
                Write-Host "Optimizing VHDX file in $Mode mode..."
                Write-Verbose "Running: Optimize-VHD -Path '$($target.VhdPath)' -Mode $Mode"

                $optimizeParams = @{
                    Path = $target.VhdPath
                    Mode = $Mode
                }

                Optimize-VHD @optimizeParams

                # Get final file size
                $finalSize = (Get-Item -Path $target.VhdPath).Length
                $finalSizeMB = [math]::Round($finalSize / 1MB, 2)
                $spaceSaved = [math]::Round(($initialSize - $finalSize) / 1MB, 2)
                $percentSaved = [math]::Round((($initialSize - $finalSize) / $initialSize) * 100, 2)

                Write-Host "Final VHDX file size:   $finalSizeMB MB"
                Write-Host "Space reclaimed:        $spaceSaved MB ($percentSaved%)"
                Write-Host "Optimization completed for '$($target.DistroName)'."
            }
        }

        Write-Host "`nAll selected WSL distro VHDX optimizations completed." -ForegroundColor Green
    }
    catch {
        throw "An error occurred while optimizing WSL distro VHDX files: $($_.Exception.Message)"
    }
}

# When executed directly, delegate to Start-WslDistroVhdOptimization using the script parameters.
if ($MyInvocation.InvocationName -ne '.') {
    Start-WslDistroVhdOptimization -DistroName $DistroName -Force:$Force.IsPresent -VhdPath $VhdPath -Mode $Mode
}

# Note: This script is intended to be dot-sourced or called via Start-WslDistroVhdOptimization.
