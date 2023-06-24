<#
.SYNOPSIS
  Output a list of all OneNote Notebooks and Sections

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

$OneNote = New-Object -ComObject OneNote.Application
[xml]$Hierarchy = ""
$OneNote.GetHierarchy("", [Microsoft.Office.InterOp.OneNote.HierarchyScope]::hsPages, [ref]$Hierarchy)
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
