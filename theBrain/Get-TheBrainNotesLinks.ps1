<#
.SYNOPSIS
  Finds all markdown links within your TheBrain notes.

.DESCRIPTION
  This script searches for all markdown links within the 'Notes.md' files in your TheBrain data directory.
  It then displays the results in a DataTable view and provides an option to save the results as a CSV file.

.PARAMETER Path
  The path to search for notes. If not specified, it will use the default TheBrain data directory.

.PARAMETER OutputPath
  The path to save the CSV file. If not specified, the script will not save the file.

.EXAMPLE
  PS C:\> .\Get-TheBrainNotesLinks.ps1
  Searches for links in the default TheBrain data directory and displays them in a DataTable.

.EXAMPLE
  PS C:\> .\Get-TheBrainNotesLinks.ps1 -OutputPath "C:\temp\links.csv"
  Searches for links and saves the results to a CSV file.

.OUTPUTS
  System.Data.DataTable. The script outputs a DataTable containing the found links.

.NOTES
  Version:        1.2.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2023-06-24
  Last Modified:  2025-08-01
#>

#Requires -Version 2.0
#Requires -PSEdition Desktop

param(
    [string]$Path,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

try {
    # If no path is specified, get the default TheBrain data directory
    if (-not $Path) {
        $Path = . "$PSScriptRoot\Get-TheBrainDataDirectory.ps1"
    }

    $PathToSearch = Get-ChildItem -Directory -Path $Path -Exclude 'Backup'
    # Regex to find all markdown links
    $MatchInfo = Get-ChildItem -Path $PathToSearch -Filter 'Notes.md' -Recurse | Select-String -Pattern '(?!-{)\[([^\]]+)\]\((https?://[^()]+)\)(?!}-)' -AllMatches
    $LinkList = $MatchInfo | Select-Object *, @{Name = "MarkdownLink"; Expression = { $_.Matches.Value } }, @{Name = "LinkText"; Expression = { $_.Matches.Groups[1].Value } } , @{Name = "URL"; Expression = { $_.Matches.Groups[2].Value } }

    # Output the results in DataTable view
    $LinkList | Out-DataTable

    # Save the results as a CSV file if an output path is specified
    if ($OutputPath) {
        $LinkList | Export-Csv -Path $OutputPath -Encoding UTF8 -NoTypeInformation
        Write-Host "Results saved to $OutputPath"
    }
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
