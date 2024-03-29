<#
.SYNOPSIS
  Find all markdown links within your theBrain Notes

.DESCRIPTION
  Search for all markdown links within your theBrain Notes and show them in DataTable view

.OUTPUTS
  None

.NOTES
  Version:        1.1.4
  Author:         chriskyfung
  License:        GNU GPLv3 license
#>

#Requires -Version 2.0
#Requires -PSEdition Desktop

# Look up markdown links within the Notes.md files that locate under the Brain data folder
$BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
$PathToSearch = Get-ChildItem -Directory -Path $BrainFolder -Exclude 'Backup'
$MatchInfo = Get-ChildItem -Path $PathToSearch -Filter 'Notes.md' -Recurse | Select-String -Pattern '(?!-\{)\[([^\]]+)\]\((https?://[^()]+)\)(?!}-)' -AllMatches
$LinkList = $MatchInfo | Select-Object *, @{Name = "MarkdownLink"; Expression = { $_.Matches.Value } }, @{Name = "LinkText"; Expression = { $_.Matches.Groups[1].Value } } , @{Name = "URL"; Expression = { $_.Matches.Groups[2].Value } }

# Output the results in DataTable view
$LinkList | Out-DataTable

# Save the results as a CSV file
#$csvFilePath  = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'BrainNotes-With-BrokenLinks.csv'
#$LinkList | Export-Csv -Path $csvFilePath -Encoding UTF8 -NoTypeInformation
#Invoke-Item $csvFilePath
