<#
.SYNOPSIS
  This script retrieves the user's Brain data directory from the TheBrainMeta.db database.

.DESCRIPTION
  The script imports the PSSQLite module and uses it to query the MetaSettings table in the TheBrainMeta.db database.
  The query retrieves the value of the preferences.userbraindatadirectory setting, which specifies the location of the
  user's Brain data directory.

.PARAMETER None

.INPUTS
  None.

.OUTPUTS
  System.String. The script returns the path of the user's Brain data directory.

.EXAMPLE
  PS C:\> .\Get-TheBrainDataDirectory.ps1
  C:\Users\JohnDoe\Documents\TheBrain

  This example retrieves the path of the user's Brain data directory.

.NOTES
  Version:  1.0.0
  Date:     2023-11-10
  Author:   chriskyfung
  Website:  https://chriskyfung.github.io
#>

Import-Module PSSQLite

$theBrainMetaDatabase = Join-Path $env:LOCALAPPDATA "TheBrain\MetaDB\TheBrainMeta.db"
$query = "SELECT Value FROM MetaSettings WHERE Name='preferences.userbraindatadirectory'"

$result = Invoke-SqliteQuery -DataSource $theBrainMetaDatabase -Query $query -OutVariable System.String
$brainDataDirectory = $result.Value.Trim('"').Replace('\\', '\')

if ($null -eq $brainDataDirectory) {
  $brainDataDirectory = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'Brains'
}

# Check if the folder exists
if (-not (Test-Path -Path $brainDataDirectory)) {
  Write-Error "Files not found. The folder '$brainDataDirectory' doesn't exist." -Category ObjectNotFound -ErrorAction Stop
}

return $brainDataDirectory
