<#
.SYNOPSIS
  Open the theBrain node folder by passing a node ID

.DESCRIPTION
  Find the folder name matching the node ID and then open it with File Explorer

.OUTPUTS
  None

.NOTES
  Version:        1.0.0
  Author:         chriskyfung
  Website:        https://chriskyfung.github.io
  Creation Date:  2023-07-01
#>

# Enable Verbose output
[CmdletBinding()]

# Prompt user to input the mecha name
[ValidatePattern('^[a-zA-Z0-9-]+$')]$NodeId = Read-Host "Please enter the theBrain node ID"

# Look up the Notes.md files that locate under the folder of My Documents\Brains and contain the YouTube thumbnail URLs.
$BrainFolder = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'Brains'
$Folder = Get-ChildItem -Path $BrainFolder -Filter $NodeId -Recurse

explorer.exe $Folder.FullName
