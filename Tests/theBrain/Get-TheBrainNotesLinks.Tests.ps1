# Tests for Get-TheBrainNotesLinks.ps1
#
# To run these tests, run `Invoke-Pester` in the root of the repository.

Describe "Get-TheBrainNotesLinks.ps1" -Tag "DesktopOnly" {
  BeforeAll {
    # Skip this test group under PowerShell Core (7.x) because the script
    # requires #Requires -PSEdition Desktop
    $script:SkipAll = $PSEdition -eq 'Core'

    # Path to the script being tested
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\theBrain\Get-TheBrainNotesLinks.ps1"

    # # Create a temporary directory structure for testing
    # NOTE: These must be script-scoped so they are visible in the It blocks,
    # because Pester v5 BeforeAll runs in a separate scope.
    $script:tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "Test-GetTheBrainLinks") -Force
    $script:thought1Dir = New-Item -Path (Join-Path $script:tempDir "Thought1") -ItemType Directory
    $script:thought2Dir = New-Item -Path (Join-Path $script:tempDir "Thought2") -ItemType Directory
    $script:backupDir = New-Item -ItemType Directory -Path (Join-Path $script:tempDir "Backup") -Force
    $script:thought3Dir = New-Item -Path (Join-Path $script:backupDir "Thought3") -ItemType Directory

    # # Create dummy Notes.md files
    Set-Content -Path (Join-Path $script:thought1Dir "Notes.md") -Value "This note contains a [valid link](https://www.google.com). This is not a link: [invalid link](htp://invalid-url)."
    Set-Content -Path (Join-Path $script:thought2Dir "Notes.md") -Value "This note has no links."
    Set-Content -Path (Join-Path $script:thought3Dir "Notes.md") -Value "This note is in a backup folder and should be ignored: [backup link](https://www.yahoo.com)."

    # Mock Format-List to prevent UI from showing during tests
    Mock Format-List { return @( $_ ) } -Verifiable
  }

  AfterAll {
    # Clean up the temporary directory
    Remove-Item -Path $script:tempDir -Recurse -Force
  }

  Context "When searching for links" {
    It "should find 1 link in Notes.md files" -Skip:$script:SkipAll {
      $results = & $script:ScriptPath -Path $script:tempDir
      $results | Should -Not -BeNullOrEmpty
      $results.Count | Should -BeNullOrEmpty
      $results[0].LinkText | Should -Be "valid link"
      $results[0].URL | Should -Be "https://www.google.com"
    }

    It "should find 3 links in Notes.md files" -Skip:$script:SkipAll {
      # Update the Notes.md in Thought1 to have another valid link
      Set-Content -Path (Join-Path $script:thought1Dir "Notes.md") -Value "This note contains a [valid link to Google](https://www.google.com) and a [valid link to Bing](https://www.bing.com). This is not a link: [invalid link](htp://invalid-url)."
      # Add a valid link to Thought2
      Set-Content -Path (Join-Path $script:thought2Dir "Notes.md") -Value "This note contains a [valid link to Facebook](https://www.facebook.com)."

      $results = & $script:ScriptPath -Path $script:tempDir
      $results | Should -Not -BeNullOrEmpty
      $results.Count | Should -Be 3
      $results | ForEach-Object { $_.Path } | Should -Not -Contain (Join-Path $script:thought3Dir "Notes.md")
      $results[0].LinkText | Should -Be "valid link to Google"
      $results[0].URL | Should -Be "https://www.google.com"
      $results[1].LinkText | Should -Be "valid link to Bing"
      $results[1].URL | Should -Be "https://www.bing.com"
      $results[2].LinkText | Should -Be "valid link to Facebook"
      $results[2].URL | Should -Be "https://www.facebook.com"

      # Revert changes
      Set-Content -Path (Join-Path $script:thought1Dir "Notes.md") -Value "This note contains a [valid link](https://www.google.com). This is not a link: [invalid link](htp://invalid-url)."
      Set-Content -Path (Join-Path $script:thought2Dir "Notes.md") -Value "This note has no links."
    }

    It "should ignore the 'Backup' directory" -Skip:$script:SkipAll {
      $results = & $script:ScriptPath -Path $script:tempDir
      $results | Should -Not -BeNullOrEmpty
      $results | ForEach-Object { $_.Path } | Should -Not -Contain (Join-Path $script:thought3Dir "Notes.md")
      $results | ForEach-Object { $_.URL } | Should -Not -Contain "https://www.yahoo.com"
    }

    It "should return an empty result if no links are found" -Skip:$script:SkipAll {
      $emptyTempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "EmptyTestBrain") -Force
      $emptyThoughtDir = New-Item -Path (Join-Path $emptyTempDir "EmptyThought") -ItemType Directory
      Set-Content -Path (Join-Path $emptyThoughtDir "Notes.md") -Value "No links here."

      $results = & $script:ScriptPath -Path $emptyTempDir
      $results | Should -BeNullOrEmpty

      Remove-Item -Path $emptyTempDir -Recurse -Force
    }
  }

  Context "With -OutputPath parameter" {
    It "should export the results to a CSV file" -Skip:$script:SkipAll {
      $outputCsv = Join-Path $script:tempDir "links.csv"
      & $script:ScriptPath -Path $script:tempDir -OutputPath $outputCsv

      Test-Path $outputCsv | Should -Be $true
      $csvContent = Import-Csv -Path $outputCsv
      $csvContent.URL | Should -Be "https://www.google.com"

      Remove-Item -Path $outputCsv -Force
    }

    It "should sanitize fields to prevent CSV injection" -Skip:$script:SkipAll {
      $maliciousLinkText = '=HYPERLINK("cmd.exe","/c dir")'
      $maliciousURL = '+A1+B1'
      $maliciousContent = "This note contains a [$maliciousLinkText]($maliciousURL)."
      $maliciousNotesDir = New-Item -ItemType Directory -Path (Join-Path $script:tempDir "ThoughtMalicious") -Force
      $maliciousNotesFile = Join-Path $maliciousNotesDir "Notes.md"
      Set-Content -Path $maliciousNotesFile -Value $maliciousContent

      # Mock Get-ChildItem
      Mock Get-ChildItem {
            param($Path, $Filter, $Recurse, $Directory, $Exclude)
            if ($Filter -eq 'Notes.md') {
                # This is the call that searches for Notes.md files
                return @(Get-Item $maliciousNotesFile)
            }
            if ($Directory) {
                # This is the call that gets the base directory for thebrain notes
                return New-Item -ItemType Directory -Path (Join-Path $script:tempDir "ThoughtMalicious") -Force
            }
            return $null # Default for other Get-ChildItem calls
        }

      # Mock Select-String to return the malicious link
      Mock Select-String {
            [PSCustomObject]@{
                Path       = $maliciousNotesFile
                LineNumber = 1
                Matches    = @(
                    [PSCustomObject]@{ # This is a single 'Match' object
                        Groups = @(
                            [PSCustomObject]@{ Value = "$maliciousLinkText($maliciousURL)" }, # Group 0 (full match, approximate)
                            [PSCustomObject]@{ Value = $maliciousLinkText }, # Group 1
                            [PSCustomObject]@{ Value = $maliciousURL }      # Group 2
                        )
                    }
                )
            }
        } -ParameterFilter { $_.FullName -eq $maliciousNotesFile }


      $outputCsv = Join-Path $script:tempDir "malicious_links.csv"
      & $script:ScriptPath -Path $script:tempDir -OutputPath $outputCsv

      Test-Path $outputCsv | Should -Be $true
      $importedCsv = Import-Csv -Path $outputCsv

      # The first (and only) data row should be the malicious one
      $maliciousRow = $importedCsv[0]

      $maliciousRow.LinkText | Should -Be "'$maliciousLinkText"
      $maliciousRow.URL | Should -Be "'$maliciousURL"

      Remove-Item -Path $maliciousNotesFile -Force
      Remove-Item -Path $maliciousNotesDir -Force
      Remove-Item -Path $outputCsv -Force
    }
  }

  Context "Without -Path parameter" {
    It "should call Get-TheBrainDataDirectory.ps1 to get the default path" -Skip:$script:SkipAll {
      # Mock the dependency script
      Mock Invoke-SqliteQuery { return [PSCustomObject]@{ Value = """$script:tempDir""" } } -Verifiable

      & $script:ScriptPath | Out-Null
      Should -Invoke Invoke-SqliteQuery -Times 1 -Exactly
    }
  }

  Context "Error Handling" {
    It "should throw an error for an invalid path" -Skip:$script:SkipAll {
      $invalidPath = "Z:\Invalid\Path\That\Does\Not\Exist"
      { & $script:ScriptPath -Path $invalidPath } | Should -Throw
    }
  }
}
