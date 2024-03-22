<#
.SYNOPSIS
  Resize YouTube thumbnails in TheBrain Notes.

.DESCRIPTION
  Scan all Markdown files in the user's Brain data directory, and apends `#$width=50p$`
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
  Version:        2.1.0
  Author:         chriskyfung
  License:        GNU GPLv3 license
  Original from:  https://gist.github.com/chriskyfung/ff65df9a60a7a544ff12aa8f810d728a/
#>

#Requires -Version 2.0

# Enable Verbose output
[CmdletBinding()]

$ErrorActionPreference = "Stop"

<#
.PARAMETERS
  Depending on the $ImageType parameter, it either finds the default YouTube
  thumbnails or the resized ones. If the $ImageType is 'resized', it also takes
  into account the $CurrentWidth parameter to find thumbnails of a specific width.
#>
$ImageType = 'default'  # [ValidateSet('default', 'resized')]
$CurrentWidth = 30  # [ValidateRange(1,100)]
$NewWidth = 50  # [ValidateRange(1,100)]

# Look up the Notes.md files that locate under the Brain data folder and contain the YouTube thumbnail URLs.
$BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
$SubFolders = Get-ChildItem -Directory -Path $BrainFolder -Exclude 'Backup'
$BackupFolder = Join-Path $BrainFolder 'Backup'

$Filename = 'Notes.md'
$FilenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Filename)
$FileExtension = [System.IO.Path]::GetExtension($Filename)

Write-Host 'Scanning YouTube thumbnail URLs in Brain Notes...'

if ($ImageType -eq 'default') {
  $MatchInfo = Get-ChildItem -Path $SubFolders -Filter $Filename -Recurse | Select-String '\/(hq|maxres)default.jpg\)' -List
} else {
  $MatchInfo = Get-ChildItem -Path $SubFolders -Filter $Filename -Recurse | Select-String ('\/(hq|maxres)default.jpg#\$width={0}p\$\)' -f $CurrentWidth) -List
}

# For each matching result
Write-Host 'Backing up and modifying Brain Notes...'
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
  if ($ImageType -eq 'default') {
  $NewString = $Pattern.Replace(')', '#$width={0}p$)' -f $NewWidth)
  } else {
    $NewString = $Pattern.Replace('#$width=30p$)', '#$width={0}p$)' -f $NewWidth)
  }
  (Get-Content $FilePath -Encoding UTF8).Replace($Pattern, $NewString) | Set-Content $FilePath -Encoding UTF8
  Write-Verbose "Modified --> '$FilePath'"
}

Write-Host ('Finished: {0} file(s) found' -f $MatchInfo.Length) # Output the number of files found

$MatchInfo | Format-Table Path | Out-Host # Output the path of the files found

Return
