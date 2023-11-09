<#
.SYNOPSIS
  Find all markdown links within your theBrain Notes

.DESCRIPTION
  Search for all markdown links within your theBrain Notes and show them in grid view

.OUTPUTS
  None

.NOTES
  Version:        1.1.3
  Author:         chriskyfung
  Website:        https://chriskyfung.github.io
  Creation Date:  2023-05-25
  Last Modified:  2023-11-10
#>

# Look up markdown links within the Notes.md files that locate under the Brain data folder
$BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
$MatchInfo = Get-ChildItem -Path $BrainFolder -Filter 'Notes.md' -Recurse | Select-String -Pattern '(?!-\{)\[([^\]]+)\]\((https?://[^()]+)\)(?!}-)' -AllMatches
$LinkList =  $MatchInfo | Select-Object *, @{Name="MarkdownLink"; Expression={$_.Matches.Value}}, @{Name="LinkText"; Expression={$_.Matches.Groups[1].Value}} , @{Name="URL"; Expression={$_.Matches.Groups[2].Value}}

# Output the results in grid view
$LinkList | Out-GridView

# Save the results as a CSV file
#$csvFilePath  = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'BrainNotes-With-BrokenLinks.csv'
#$LinkList | Export-Csv -Path $csvFilePath -Encoding UTF8 -NoTypeInformation
#Invoke-Item $csvFilePath
