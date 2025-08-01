<#
.SYNOPSIS
  Opens the folder for a specific TheBrain node.

.DESCRIPTION
  This script finds the folder associated with a given TheBrain node ID and opens it in File Explorer.
  It searches within the TheBrain data directory for a folder matching the node ID.

.PARAMETER NodeId
  The ID of the TheBrain node to open. This parameter is mandatory.

.EXAMPLE
  PS C:\> .\Open-TheBrainNodeFolder.ps1 -NodeId "abc-123-def-456"
  Finds the folder for the specified node and opens it.

.OUTPUTS
  None.

.NOTES
  Version:        1.1.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2023-07-01
  Last Modified:  2025-08-01
#>

#Requires -Version 2.0

param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9-]+$')]
    [string]$NodeId
)

$ErrorActionPreference = "Stop"

try {
    $BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
    $PathToSearch = Get-ChildItem -Directory -Path $BrainFolder -Exclude 'Backup'
    $Folder = Get-ChildItem -Path $PathToSearch -Directory -Filter $NodeId -Recurse

    if ($Folder) {
        explorer.exe $Folder.FullName
    } else {
        Write-Warning "Could not find a folder for Node ID: $NodeId"
    }
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
