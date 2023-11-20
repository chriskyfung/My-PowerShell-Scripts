<#
.SYNOPSIS
  Resize YouTube thumbnails down to 30% in theBrain Notes

.DESCRIPTION
  Scan all Markdown files in the user's Brain data directory, and apends `#$width=30p$`
  to the image URL of embedded YouTube thumbnails within the Markdown files, and backs
  up the original notes to the Backup folder before changing the Markdown file content.

.PARAMETER None

.INPUTS
  None.

.OUTPUTS
  None

.EXAMPLE
  PS C:\> .\Resize-TheBrainNotesYouTubeThumbnail.ps1

.NOTES
  Version:        2.0.0
  Author:         chriskyfung
  License:        GNU GPLv3 license
  Original from:  https://gist.github.com/chriskyfung/ff65df9a60a7a544ff12aa8f810d728a/
#>

#Requires -Version 2.0

# Enable Verbose output
[CmdletBinding()]

$ErrorActionPreference = "Stop"

# Look up the Notes.md files that locate under the Brain data folder and contain the YouTube thumbnail URLs.
$BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
$BackupFolder = Join-Path $BrainFolder 'Backup'

$Filename = 'Notes.md'
$FilenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Filename)
$FileExtension = [System.IO.Path]::GetExtension($Filename)

Write-Host 'Scanning YouTube thumbnail URLs in Brain Notes...'
$MatchInfo = Get-ChildItem -Path $BrainFolder -Exclude $BackupFolder -Filter $Filename -Recurse | Select-String '\/(hq|maxres)default.jpg\)' -List

# For each matching result
Write-Information 'Backing up and modifying Brain Notes...'
ForEach ($Match in $MatchInfo) {
  $FilePath = $Match.Path | Convert-Path # FilePath of the Notes.md file
  $ParentFolder = Split-Path -Path $FilePath -Parent # Path of the parent folder
  $Timestamp = (Get-Item $FilePath).LastWriteTime.ToString('yyyyMMdd_HHmmss')
  $BackupFilename = "$FilenameWithoutExtension-$Timestamp$FileExtension~"
  $BackupPath = Join-Path $ParentFolder.Replace($BrainFolder, $BackupFolder) $BackupFilename
  # Backup the Notes.md file
  Copy-Item -Path $FilePath -Destination (New-Item -ItemType File -Force -Path $BackupPath) -Force
  Write-Verbose "Created --> '$BackupPath'"
  # Amend the link of the YouTube thumbnail with UTF8 encoding
  $Pattern = $Match.Matches.Value
  $NewString = $Pattern.Replace(')', '#$width=30p$)')
  (Get-Content $FilePath -Encoding UTF8).Replace($Pattern, $NewString) | Set-Content $FilePath -Encoding UTF8
  Write-Verbose "Modified --> '$FilePath'"
}

Write-Host 'Finished: ' $MatchInfo.Length 'file(s) found' # Output the number of files found

$MatchInfo | Format-Table Path | Out-Host # Output the path of the files found

Return
