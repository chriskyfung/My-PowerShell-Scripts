# Tests for Get-TheBrainNotesLinks.ps1
#
# To run these tests, run `Invoke-Pester` in the root of the repository.

Describe "Get-TheBrainNotesLinks.ps1" {
  BeforeAll {
    # Path to the script being tested
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\theBrain\Get-TheBrainNotesLinks.ps1"

    # # Create a temporary directory structure for testing
    $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "TestBrain") -Force
    $thought1Dir = New-Item -Path (Join-Path $tempDir "Thought1") -ItemType Directory
    $thought2Dir = New-Item -Path (Join-Path $tempDir "Thought2") -ItemType Directory
    $backupDir = New-Item -Path (Join-Path $tempDir "Backup") -ItemType Directory
    $thought3Dir = New-Item -Path (Join-Path $backupDir "Thought3") -ItemType Directory

    # # Create dummy Notes.md files
    Set-Content -Path (Join-Path $thought1Dir "Notes.md") -Value "This note contains a [valid link](https://www.google.com). This is not a link: [invalid link](htp://invalid-url)."
    Set-Content -Path (Join-Path $thought2Dir "Notes.md") -Value "This note has no links."
    Set-Content -Path (Join-Path $thought3Dir "Notes.md") -Value "This note is in a backup folder and should be ignored: [backup link](https://www.yahoo.com)."

    # Mock Format-List to prevent UI from showing during tests
    Mock Format-List { return @($_) } -Verifiable
  }

  AfterAll {
    # Clean up the temporary directory
    Remove-Item -Path $tempDir -Recurse -Force
  }

  Context "When searching for links" {
    It "should find 1 link in Notes.md files" {
      $results = & $script:ScriptPath -Path $tempDir
      $results | Should -Not -BeNullOrEmpty
      $results.Count | Should -BeNullOrEmpty
      $results[0].LinkText | Should -Be "valid link"
      $results[0].URL | Should -Be "https://www.google.com"
    }

    It "should find 3 links in Notes.md files" {
      # Update the Notes.md in Thought1 to have another valid link
      Set-Content -Path (Join-Path $thought1Dir "Notes.md") -Value "This note contains a [valid link to Google](https://www.google.com) and a [valid link to Bing](https://www.bing.com). This is not a link: [invalid link](htp://invalid-url)."
      # Add a valid link to Thought2
      Set-Content -Path (Join-Path $thought2Dir "Notes.md") -Value "This note contains a [valid link to Facebook](https://www.facebook.com)."

      $results = & $script:ScriptPath -Path $tempDir
      $results | Should -Not -BeNullOrEmpty
      $results.Count | Should -Be 3
      $results | ForEach-Object { $_.Path } | Should -Not -Contain (Join-Path $thought3Dir "Notes.md")
      $results[0].LinkText | Should -Be "valid link to Google"
      $results[0].URL | Should -Be "https://www.google.com"
      $results[1].LinkText | Should -Be "valid link to Bing"
      $results[1].URL | Should -Be "https://www.bing.com"
      $results[2].LinkText | Should -Be "valid link to Facebook"
      $results[2].URL | Should -Be "https://www.facebook.com"

      # Revert changes
      Set-Content -Path (Join-Path $thought1Dir "Notes.md") -Value "This note contains a [valid link](https://www.google.com). This is not a link: [invalid link](htp://invalid-url)."
      Set-Content -Path (Join-Path $thought2Dir "Notes.md") -Value "This note has no links."
    }

    It "should ignore the 'Backup' directory" {
      $results = & $script:ScriptPath -Path $tempDir
      $results | Should -Not -BeNullOrEmpty
      $results | ForEach-Object { $_.Path } | Should -Not -Contain (Join-Path $thought3Dir "Notes.md")
      $results | ForEach-Object { $_.URL } | Should -Not -Contain "https://www.yahoo.com"
    }

    It "should return an empty result if no links are found" {
      $emptyTempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "EmptyTestBrain") -Force
      $emptyThoughtDir = New-Item -Path (Join-Path $emptyTempDir "EmptyThought") -ItemType Directory
      Set-Content -Path (Join-Path $emptyThoughtDir "Notes.md") -Value "No links here."

      $results = & $script:ScriptPath -Path $emptyTempDir
      $results | Should -BeNullOrEmpty

      Remove-Item -Path $emptyTempDir -Recurse -Force
    }
  }

  Context "With -OutputPath parameter" {
    It "should export the results to a CSV file" {
      $outputCsv = Join-Path $tempDir "links.csv"
      & $script:ScriptPath -Path $tempDir -OutputPath $outputCsv

      Test-Path $outputCsv | Should -Be $true
      $csvContent = Import-Csv -Path $outputCsv
      $csvContent.URL | Should -Be "https://www.google.com"

      Remove-Item -Path $outputCsv -Force
    }
  }

  Context "Without -Path parameter" {
    It "should call Get-TheBrainDataDirectory.ps1 to get the default path" {
      # Mock the dependency script
      Mock Invoke-SqliteQuery { return [PSCustomObject]@{ Value = """$tempDir""" } } -Verifiable

      & $script:ScriptPath | Out-Null
      Should -Invoke Invoke-SqliteQuery -Times 1 -Exactly
    }
  }

  Context "Error Handling" {
    It "should throw an error for an invalid path" {
      $invalidPath = "Z:\Invalid\Path\That\Does\Not\Exist"
      { & $script:ScriptPath -Path $invalidPath } | Should -Throw
    }
  }
}
