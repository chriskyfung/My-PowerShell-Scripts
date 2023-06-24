<#
.SYNOPSIS
  List the temperature, errors, wear and age of all drives on the operating system

.DESCRIPTION
  A shorthand for running the Get-Disk and StorageReliabilityCounter cmdlets to get disk drive health information.

.OUTPUTS
  None

.NOTES
  Version:        1.0.0
  Author:         chriskyfung
  Website:        https://chriskyfung.github.io
  Creation Date:  2023-06-24
  Last Modified:  2023-06-24
#>

#Requires -RunAsAdministrator

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
