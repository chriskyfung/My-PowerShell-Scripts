<#
.SYNOPSIS
  Find OneNote Pages that contain the specified text

.DESCRIPTION
  

.OUTPUTS
  None

.NOTES
  Version:        1.0.0
  Author:         chriskyfung
  Website:        https://chriskyfung.github.io
  Creation Date:  2023-05-18
  Last Modified:  2023-05-18
#>

$query = "your-query"

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

$OneNote = New-Object -ComObject OneNote.Application
[xml]$Hierarchy = ""
$OneNote.FindPages("", $query, [ref]$Hierarchy)
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
