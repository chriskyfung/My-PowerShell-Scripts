<#
.SYNOPSIS
  Finds OneNote pages that contain the specified text.

.DESCRIPTION
  This script searches for a given string across all open OneNote notebooks and returns the pages where the string is found.
  It uses the OneNote COM Application object to perform the search and formats the output with clickable hyperlinks to the pages.

.PARAMETER Query
  The text to search for within OneNote pages. This parameter is mandatory.

.EXAMPLE
  PS C:\> .\Find-OneNotePages.ps1 -Query "My important note"
  Searches for "My important note" in all OneNote pages and displays the results.

.OUTPUTS
  String. The script outputs a formatted list of notebooks, sections, and pages containing the query, with clickable hyperlinks.

.NOTES
  Version:        1.1.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2023-05-18
  Last Modified:  2025-08-01
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Query
)

$ErrorActionPreference = "Stop"

# Powershell Clickable Hyperlinks (https://lucyllewy.com/powershell-clickable-hyperlinks/)
function Format-Hyperlink {
  param(
    [Parameter(ValueFromPipeline = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [Uri] $Uri,

    [Parameter(Mandatory = $false, Position = 1)]
    [string] $Label
  )

  if (($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) -and -not $Env:WT_SESSION) {
    # Fallback for Windows users not inside Windows Terminal
    if ($Label) {
      return "$Label ($Uri)"
    }
    return "$Uri"
  }

  if ($Label) {
    return "`e]8;;$Uri`e\$Label`e]8;;`e\"
  }

  return "$Uri"
}

try {
    $OneNote = New-Object -ComObject OneNote.Application
    [xml]$Hierarchy = ""
    $OneNote.FindPages("", $Query, [ref]$Hierarchy)

    if ($Hierarchy.Notebooks.Notebook.Count -eq 0) {
        Write-Warning "No pages found containing the query: '$Query'"
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
        foreach ($page in $section.Page) {
          #    $page |fl *
          $link = ""
          $OneNote.GetHyperlinkToObject($page.Id, "", [ref]$link)
          Write-Output "#### $(Format-Hyperlink -Uri $link -Label $page.Name)"

        }
      }
    }
} catch {
    Write-Error "An error occurred while communicating with OneNote: $($_.Exception.Message)"
    Write-Error "Please ensure OneNote is running."
    exit 1
}