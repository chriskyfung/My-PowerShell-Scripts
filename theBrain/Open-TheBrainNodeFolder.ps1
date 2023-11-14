<#
.SYNOPSIS
  Open the theBrain node folder by passing a node ID

.DESCRIPTION
  Find the folder name matching the node ID and then open it with File Explorer

.OUTPUTS
  None

.EXAMPLE
  PS C:\> .\Open-TheBrainNodeFolder.ps1

.NOTES
  Version:        1.0.2
  Author:         chriskyfung
  Website:        https://chriskyfung.github.io
#>

#Requires -Version 2.0

# Enable Verbose output
[CmdletBinding()]

# Prompt user to input the mecha name
[ValidatePattern('^[a-zA-Z0-9-]+$')]$NodeId = Read-Host "Please enter the theBrain node ID"

# Look up the Notes.md files that locate under the Brain data folder and contain the YouTube thumbnail URLs.
$BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
$Folder = Get-ChildItem -Path $BrainFolder -Filter $NodeId -Recurse

explorer.exe $Folder.FullName
