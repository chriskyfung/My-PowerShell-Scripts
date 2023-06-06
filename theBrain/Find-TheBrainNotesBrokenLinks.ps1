<#
.SYNOPSIS
  Resize YouTube thumbnails down to 30% in theBrain Notes

.DESCRIPTION
  Append `#$width=30p$` to the image address within the Markdown files

.OUTPUTS
  None

.NOTES
  Version:        1.1.2
  Author:         chriskyfung
  Website:        https://chriskyfung.github.io
  Creation Date:  2023-04-28
  Last Modified:  2023-05-18
#>

# Look up markdown links within the Notes.md files that locate under the folder of My Documents\Brains
$BrainFolder = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'Brains'
$MatchInfo = Get-ChildItem -Path $BrainFolder -Filter 'Notes.md' -Recurse | Select-String -Pattern '\[([^\]]+)\]\((https?://[^()]+)\)' -AllMatches | Select-Object -Last 5
$LinkList =  $MatchInfo | Select-Object *, @{Name="MarkdownLink"; Expression={$_.Matches.Value}}, @{Name="LinkText"; Expression={$_.Matches.Groups[1].Value}} , @{Name="URL"; Expression={$_.Matches.Groups[2].Value}} 

# Test each link and append the status code and description to the object array
$Responses = @{}
$LinkList | ForEach-Object {
  try {
    $response = Invoke-WebRequest -Uri $_.URL -UseBasicParsing
    $Responses.Add($_.URL, $response)
  }
  catch {
    $Responses.Add($_.URL, "Error")
  }
}
$Results = $LinkList | Select-Object *, @{Name="StatusCode"; Expression={$Responses[$_.URL].StatusCode}}, @{Name="StatusDescription"; Expression={$Responses[$_.URL].StatusDescription}}

# Output the results in grid view
$Results | Out-GridView

# Save the results as a CSV file
$csvFilePath  = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'BrainNotes-With-BrokenLinks.csv'
$Results | Export-Csv -Path $csvFilePath -NoTypeInformation
Invoke-Item $csvFilePath
