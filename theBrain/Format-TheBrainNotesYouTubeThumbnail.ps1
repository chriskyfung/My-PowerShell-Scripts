<#
.SYNOPSIS
  Replaces local YouTube thumbnail links in TheBrain notes with web URLs.

.DESCRIPTION
  This script scans all 'Notes.md' files within TheBrain's data directory.
  It finds markdown links pointing to local YouTube thumbnail images and replaces them
  with direct URLs to 'maxresdefault.jpg' from YouTube's servers.
  The script automatically backs up the original 'Notes.md' file and the local image file before making any modifications.

.EXAMPLE
  PS C:\> .\Format-TheBrainNotesYouTubeThumbnail.ps1
  Scans, backs up, and modifies the notes files. Provides a summary of the changes.

.OUTPUTS
  String. The script outputs status messages and a summary of the files that were modified.

.NOTES
  Version:        1.1.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2025-08-01
  Last Modified:  2025-08-01
#>

#Requires -Version 2.0

[CmdletBinding()]

$ErrorActionPreference = "Stop"

try {
    # Look up the Notes.md files that locate under the Brain data folder and contain the YouTube thumbnail URLs.
    $BrainFolder = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
    $SubFolders = Get-ChildItem -Directory -Path $BrainFolder -Exclude 'Backup'
    $BackupFolder = Join-Path $BrainFolder 'Backup'

    $Filename = 'Notes.md'
    $FilenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($Filename)
    $FileExtension = [System.IO.Path]::GetExtension($Filename)

    Write-Host 'Scanning YouTube thumbnail URLs in Brain Notes...'

    # Regex to find the specific markdown pattern of a YouTube link with a local image
    $MatchInfo = Get-ChildItem -Path $SubFolders -Filter $Filename -Recurse | Select-String '\[\!\[(?<ALT>.*)\]\(\.data\/md-images\/(?<IMAGEFILE>.+)\.jpg(?<width>.*)\)\]\(https:\/\/youtu.be\/(?<VIDEOID>.+?)\)' -List

    # For each matching result
    Write-Host 'Backing up and modifying Brain Notes...'
    ForEach ($Match in $MatchInfo) {
      $FilePath = $Match.Path | Convert-Path # FilePath of the Notes.md file
      $ParentFolder = Split-Path -Path $FilePath -Parent # Path of the parent folder
      $BackupLocation = $ParentFolder.Replace($BrainFolder, $BackupFolder)
      # Backup the Notes.md file
      $Timestamp = (Get-Item $FilePath).LastWriteTime.ToString('yyyyMMdd_HHmmss')
      $BackupFilename = "$FilenameWithoutExtension-$Timestamp$FileExtension~"
      $BackupPath = Join-Path $BackupLocation $BackupFilename
      Copy-Item -Path $FilePath -Destination (New-Item -ItemType File -Force -Path $BackupPath) -Force
      # Backup the md-image file
      $LocalImageFile = $Match.Matches[0].Groups['IMAGEFILE'].Value
      $LocalImagePath = Convert-Path "$ParentFolder/.data/md-images/$LocalImageFile.jpg"
      $BackupImagePath = $LocalImagePath.Replace($BrainFolder, $BackupFolder)
      Move-Item -Path $LocalImagePath -Destination (New-Item -ItemType File -Force -Path $BackupImagePath) -Force
      Write-Verbose "Created --> '$BackupPath'"
      # Amend the link of the YouTube thumbnail with UTF8 encoding
      $Pattern = $Match.Matches.Value
      $AltText = $Match.Matches[0].Groups['ALT'].Value
      $VideoId = $Match.Matches[0].Groups['VIDEOID'].Value
      $NewString = '[![{0}](https://img.youtube.com/vi/{1}/maxresdefault.jpg)](https://www.youtube.com/watch?v={1})' -f $AltText, $VideoId
      (Get-Content $FilePath -Encoding UTF8).Replace($Pattern, $NewString) | Set-Content $FilePath -Encoding UTF8
      Write-Verbose "Modified --> '$FilePath'"
    }

    Write-Host ('Finished: {0} file(s) found' -f $MatchInfo.Length) # Output the number of files found

    $MatchInfo | Format-Table Path | Out-Host # Output the path of the files found

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}

Return
