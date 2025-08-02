<#
.SYNOPSIS
  Lists temperature, errors, wear, and age of all disk drives.

.DESCRIPTION
  This script provides a summary of disk drive health by combining the Get-Disk and Get-StorageReliabilityCounter cmdlets.
  It requires administrator privileges to run.

.EXAMPLE
  PS C:\> .\Get-DiskReliabilityCounter.ps1
  Displays a table with reliability information for all connected disks.

.OUTPUTS
  System.Object. The script outputs a formatted table containing disk reliability information.

.NOTES
  Version:        1.1.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2023-06-24
  Last Modified:  2025-08-01
#>

#Requires -Version 3.0
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

try {
    Get-Disk | ForEach-Object {
      ($Disk = $_) | Get-StorageReliabilityCounter |
          Select-Object DeviceId,
                        @{
                          Name="FriendlyName";
                          Expression={$Disk.FriendlyName}
                        },
                        Temperature,
                        ReadErrorsUncorrected,
                        Wear,
                        PowerOnHours
      } | Format-Table
} catch {
    Write-Error "An error occurred while retrieving disk reliability information: $($_.Exception.Message)"
    exit 1
}
