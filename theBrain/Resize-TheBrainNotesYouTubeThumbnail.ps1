<#
.SYNOPSIS
  Resize YouTube thumbnails down to 30% in theBrain Notes

.DESCRIPTION
  Append `#$width=30p$` to the image address within the Markdown files

.PARAMETER None

.INPUTS
  None.

.OUTPUTS
  None

.EXAMPLE
  PS C:\> .\Resize-TheBrainNotesYouTubeThumbnail.ps1

.NOTES
  Version:        1.1.5
  Author:         chriskyfung
  Website:        https://chriskyfung.github.io
#>

#Requires -Version 2.0

# Enable Verbose output
[CmdletBinding()]

# Look up the Notes.md files that locate under the Brain data folder and contain the YouTube thumbnail URLs.
$BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
$MatchInfo = Get-ChildItem -Path $BrainFolder -Filter 'Notes.md' -Recurse | Select-String '\/(hq|maxres)default.jpg\)' -List

# For each matching result
ForEach ($Match in $MatchInfo) {
  $FilePath = $Match.Path | Convert-Path # FilePath of the Notes.md file
  $ParentFolder = Split-Path -Path $FilePath # Path of the parent folder
  # Check if any backup files exist in the parent folder
  $NewIndex = 1
  if (Test-Path -Path ( -join ($FilePath, '.bak*')) -PathType leaf) {
    # If true then determine the index of the last backup file
    $LastIndex = (Get-ChildItem -Path $ParentFolder -Filter '*.bak*' | Select-Object Extension -Unique |
      Sort-Object -Property Extension | Select-Object -Last 1)[0] -replace ('\D*', '')
    $NewIndex = [int]$LastIndex
    # If there are more than three backup files
    if ($NewIndex -ge 3) {
      # Remove the first backup file and re-index the rest of the backup files
      Remove-Item ( -join ($FilePath, '.bak1'))
      Rename-Item ( -join ($FilePath, '.bak2')) -NewName ( -join ($FilePath, '.bak1'))
      Rename-Item ( -join ($FilePath, '.bak3')) -NewName ( -join ($FilePath, '.bak2'))
    }
    else {
      # Else increment the index for the new backup file
      $NewIndex++
    }
  }
  $NewName = -join ($FilePath, '.bak', $NewIndex) # FilePath of the new backup file
  Copy-Item $FilePath -Destination $NewName # Backup the Notes.md file
  Write-Verbose "Created -->' $NewName"
  # Amend the link of the YouTube thumbnail with UTF8 encoding
  $Pattern = $Match.Matches.Value
  $NewString = $Pattern.Replace(')', '#$width=30p$)')
  (Get-Content $FilePath -Encoding UTF8).Replace($Pattern, $NewString) | Set-Content $FilePath -Encoding UTF8
  Write-Verbose "Modified -->' $FilePath"
}

Write-Host $MatchInfo.Length 'file(s) found' # Output the number of files found

$MatchInfo | Format-Table Path | Out-Host # Output the path of the files found

Return
