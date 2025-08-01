<#
.SYNOPSIS
  Resizes YouTube thumbnails embedded in TheBrain notes.

.DESCRIPTION
  This script scans all 'Notes.md' files in the user's TheBrain data directory.
  It appends a width parameter to the image URL of embedded YouTube thumbnails to control their size.
  The script backs up the original notes before making any changes.

.PARAMETER NewWidth
  The new width (as a percentage) to apply to the thumbnails. Defaults to 50.

.PARAMETER ImageType
  Specifies whether to target default thumbnails or already resized ones.
  - 'default': Finds thumbnails without a width parameter.
  - 'resized': Finds thumbnails that already have a width parameter.

.PARAMETER CurrentWidth
  When ImageType is 'resized', this specifies the current width of the thumbnails to target.

.EXAMPLE
  PS C:\> .\Resize-TheBrainNotesYouTubeThumbnail.ps1
  Resizes all default YouTube thumbnails to 50% width.

.EXAMPLE
  PS C:\> .\Resize-TheBrainNotesYouTubeThumbnail.ps1 -NewWidth 75
  Resizes all default YouTube thumbnails to 75% width.

.EXAMPLE
  PS C:\> .\Resize-TheBrainNotesYouTubeThumbnail.ps1 -ImageType resized -CurrentWidth 30 -NewWidth 75
  Finds all thumbnails currently at 30% width and resizes them to 75%.

.OUTPUTS
  String. The script outputs status messages and a summary of the files that were modified.

.NOTES
  Version:        2.2.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2023-11-14
  Last Modified:  2025-08-01
#>

#Requires -Version 2.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$NewWidth = 50,

    [Parameter(Mandatory = $false)]
    [ValidateSet('default', 'resized')]
    [string]$ImageType = 'default',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$CurrentWidth = 30
)

$ErrorActionPreference = "Stop"

try {
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

    Write-Host 'Backing up and modifying Brain Notes...'
    ForEach ($Match in $MatchInfo) {
      $FilePath = $Match.Path | Convert-Path
      $ParentFolder = Split-Path -Path $FilePath -Parent
      $Timestamp = (Get-Item $FilePath).LastWriteTime.ToString('yyyyMMdd_HHmmss')
      $BackupFilename = "$FilenameWithoutExtension-$Timestamp$FileExtension~"
      $BackupPath = Join-Path $ParentFolder.Replace($BrainFolder, $BackupFolder) $BackupFilename
      Copy-Item -Path $FilePath -Destination (New-Item -ItemType File -Force -Path $BackupPath) -Force
      Write-Verbose "Created --> '$BackupPath'"

      $Pattern = $Match.Matches.Value
      if ($ImageType -eq 'default') {
        $NewString = $Pattern.Replace(')', ("#`$width={0}p`$)" -f $NewWidth))
      } else {
        $NewString = $Pattern.Replace(("#`$width={0}p`$)" -f $CurrentWidth), ("#`$width={0}p`$)" -f $NewWidth))
      }
      (Get-Content $FilePath -Encoding UTF8).Replace($Pattern, $NewString) | Set-Content $FilePath -Encoding UTF8
      Write-Verbose "Modified --> '$FilePath'"
    }

    Write-Host ('Finished: {0} file(s) found' -f $MatchInfo.Length)
    $MatchInfo | Format-Table Path | Out-Host

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
