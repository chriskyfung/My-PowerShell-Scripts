<#
.SYNOPSIS
  Retrieves the user's TheBrain data directory from its metadata database.

.DESCRIPTION
  This script queries the TheBrainMeta.db SQLite database to find the configured user data directory.
  It requires the PSSQLite module to be installed. If the database value is not found, it defaults to the standard 'Brains' folder in 'My Documents'.
  The script will stop if the PSSQLite module is not installed or if the final directory path does not exist.

.EXAMPLE
  PS C:\> .\Get-TheBrainDataDirectory.ps1
  C:\Users\JohnDoe\Documents\TheBrain

.OUTPUTS
  System.String. The script returns the absolute path to the user's TheBrain data directory.

.NOTES
  Version:        1.1.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2025-11-10
  Last Modified:  2025-08-01
#>

#Requires -Version 2.0
#Requires -Modules PSSQLite

$ErrorActionPreference = "Stop"

try {
    # Check if PSSQLite module is available
    if (-not (Get-Module -ListAvailable -Name PSSQLite)) {
        throw "The 'PSSQLite' module is required but not installed. Please run 'Install-Module -Name PSSQLite'."
    }

    $theBrainMetaDatabase = Join-Path $env:LOCALAPPDATA "TheBrain\MetaDB\TheBrainMeta.db"
    if (-not (Test-Path -Path $theBrainMetaDatabase)) {
        throw "TheBrain metadata database was not found at '$theBrainMetaDatabase'."
    }

    $query = "SELECT Value FROM MetaSettings WHERE Name='preferences.userbraindatadirectory'"

    $result = Invoke-SqliteQuery -DataSource $theBrainMetaDatabase -Query $query
    $brainDataDirectory = $result.Value.Trim('"').Replace('\\', '\')

    if ($null -eq $brainDataDirectory) {
      $brainDataDirectory = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'Brains'
    }

    # Check if the folder exists
    if (-not (Test-Path -Path $brainDataDirectory)) {
      throw "TheBrain data directory was not found at '$brainDataDirectory'."
    }

    return $brainDataDirectory
} catch {
    Write-Error "An error occurred while trying to get TheBrain data directory: $($_.Exception.Message)"
    exit 1
}
