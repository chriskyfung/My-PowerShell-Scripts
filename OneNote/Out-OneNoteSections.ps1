<#
.SYNOPSIS
  Outputs a list of all OneNote notebooks and their sections.

.DESCRIPTION
  This script retrieves and displays a hierarchical view of all open OneNote notebooks, including their sections and section groups.
  It uses the OneNote COM Application object to get the hierarchy.

.EXAMPLE
  PS C:\> .\Out-OneNoteSections.ps1
  Displays a formatted list of all notebooks and sections.

.OUTPUTS
  String. The script outputs a formatted string representing the notebook hierarchy.

.NOTES
  Version:        1.1.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2023-05-18
  Last Modified:  2025-08-01
#>

$ErrorActionPreference = "Stop"

try {
    $OneNote = New-Object -ComObject OneNote.Application
    [xml]$Hierarchy = ""
    $OneNote.GetHierarchy("", [Microsoft.Office.InterOp.OneNote.HierarchyScope]::hsPages, [ref]$Hierarchy)

    if ($Hierarchy.Notebooks.Notebook.Count -eq 0) {
        Write-Warning "No notebooks found."
        return
    }

    foreach ($notebook in $Hierarchy.Notebooks.Notebook ) {
      " "
      $notebook.Name
      "=============="
      foreach ($sectiongroup in $notebook.SectionGroup) {
        if ($sectiongroup.isRecycleBin -ne 'true') {
          "## " + $sectiongroup.Name
        }
      }
      "## #"
      foreach ($section in $notebook.Section) {
        #    $section |fl *
        "### " + $section.Name
      }
    }
} catch {
    Write-Error "An error occurred while communicating with OneNote: $($_.Exception.Message)"
    Write-Error "Please ensure OneNote is running."
    exit 1
}