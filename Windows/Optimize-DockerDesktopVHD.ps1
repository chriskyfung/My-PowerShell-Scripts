<#
.SYNOPSIS
  Optimizes the Docker Desktop virtual hard disk (VHDX) to reclaim unused space.

.DESCRIPTION
  This script shrinks the Docker Desktop VHDX file by compacting it to remove unused blocks.
  It requires Docker Desktop to be stopped before running, and administrator privileges.

  The script performs the following steps:
  1. Checks if Docker Desktop (Docker Desktop.exe) is running and stops it if necessary
  2. Locates the Docker VHDX file in the default location (%LocalAppData%\Docker\wsl\disk\docker_data.vhdx)
  3. Uses Optimize-VHD cmdlet to compact the VHDX file in Full mode

.EXAMPLE
  PS C:\> .\Optimize-DockerDesktopVHD.ps1
  Optimizes the Docker Desktop VHDX file using default settings.

.EXAMPLE
  PS C:\> .\Optimize-DockerDesktopVHD.ps1 -VhdPath "D:\Docker\docker_data.vhdx"
  Optimizes a custom VHDX file location.

.EXAMPLE
  PS C:\> .\Optimize-DockerDesktopVHD.ps1 -WhatIf
  Shows what the script would do without actually running it.

.OUTPUTS
  System.Object. The script outputs status messages and optimization results.

.NOTES
  Version:        1.0.0
  Author:         chriskyfung
  License:        GNU GPLv3 license
  Creation Date:  2026-03-12
  Last Modified:  2026-03-12

.LINK
  https://docs.microsoft.com/en-us/powershell/module/hyper-v/optimize-vhd
#>

#Requires -Version 5.1
#Requires -PSEdition Desktop

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [ValidateScript({
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
function Stop-DockerDesktop {
    <#
    .SYNOPSIS
      Stops Docker Desktop application if it is running.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param ()

    $dockerDesktopProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue

    if ($dockerDesktopProcess) {
        $caption = "Stop Docker Desktop"
        $message = "Docker Desktop is currently running. It must be stopped before optimizing the VHDX file.`n`nProcess: Docker Desktop`nPID: $($dockerDesktopProcess.Id)`n`nDo you want to continue?"

        if ($PSCmdlet.ShouldContinue($message, $caption)) {
            if ($PSCmdlet.ShouldProcess("Docker Desktop process (PID: $($dockerDesktopProcess.Id))", "Stop")) {
                Write-Verbose "Stopping Docker Desktop..."
                Stop-Process -Id $dockerDesktopProcess.Id -Force
                Wait-Process -Id $dockerDesktopProcess.Id -Timeout 30 -ErrorAction SilentlyContinue
                Write-Host "Docker Desktop has been stopped."
            }
        }
        else {
            Write-Host "Operation cancelled by user. Docker Desktop remains running."
            return $false
        }
    }
    else {
        Write-Verbose "Docker Desktop is not running."
    }

    return $true
}

function Get-DefaultDockerVhdPath {
    <#
    .SYNOPSIS
      Returns the default Docker Desktop VHDX file path.
    #>
    [OutputType([string])]
    param ()

    $defaultPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Docker\wsl\disk\docker_data.vhdx"
    return $defaultPath
}
#endregion

try {
    # Determine VHDX path
    if (-not $VhdPath) {
        $VhdPath = Get-DefaultDockerVhdPath
        Write-Verbose "Using default Docker VHDX path: $VhdPath"
    }

    # Validate VHDX file exists
    if (-not (Test-Path -Path $VhdPath -PathType Leaf)) {
        throw "Docker VHDX file not found at: $VhdPath`nEnsure Docker Desktop is installed and has created the virtual disk."
    }

    # Get initial file size
    $initialSize = (Get-Item -Path $VhdPath).Length
    $initialSizeMB = [math]::Round($initialSize / 1MB, 2)
    Write-Host "Initial VHDX file size: $initialSizeMB MB"

    # Stop Docker Desktop if running
    $dockerStopped = Stop-DockerDesktop
    if ($dockerStopped -eq $false) {
        Write-Warning "Cannot proceed while Docker Desktop is running. Exiting."
        exit 0
    }

    # Optimize VHDX
    if ($PSCmdlet.ShouldProcess("VHDX file: $VhdPath", "Optimize")) {
        Write-Host "Optimizing VHDX file in $Mode mode..."
        Write-Verbose "Running: Optimize-VHD -Path '$VhdPath' -Mode $Mode"

        $optimizeParams = @{
            Path = $VhdPath
            Mode = $Mode
        }

        Optimize-VHD @optimizeParams

        # Get final file size
        $finalSize = (Get-Item -Path $VhdPath).Length
        $finalSizeMB = [math]::Round($finalSize / 1MB, 2)
        $spaceSaved = [math]::Round(($initialSize - $finalSize) / 1MB, 2)
        $percentSaved = [math]::Round((($initialSize - $finalSize) / $initialSize) * 100, 2)

        Write-Host "Final VHDX file size:   $finalSizeMB MB"
        Write-Host "Space reclaimed:        $spaceSaved MB ($percentSaved%)"
        Write-Host "Docker Desktop VHDX optimization completed successfully."
    }
}
catch {
    Write-Error "An error occurred while optimizing the Docker VHDX file: $($_.Exception.Message)"
    exit 1
}
