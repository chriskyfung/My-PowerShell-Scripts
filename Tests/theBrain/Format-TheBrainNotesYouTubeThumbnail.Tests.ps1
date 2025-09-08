# Test for Format-TheBrainNotesYouTubeThumbnail.ps1
# Requires -Modules Pester

BeforeAll {
  # Path to the script being tested
  $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\theBrain\Format-TheBrainNotesYouTubeThumbnail.ps1"

  # Set up a temporary file system structure to simulate TheBrain's data
  $script:TestDrive = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "TestBrain") -Force
  $script:BrainFolder = $script:TestDrive.FullName
  $script:BackupFolder = Join-Path $BrainFolder 'Backup'
  $script:NoteFolder = Join-Path $BrainFolder 'TestNote'
  $script:MdImagesFolder = Join-Path $NoteFolder '.data\md-images'
  $script:NotesFile = Join-Path $NoteFolder 'Notes.md'
  $script:ImageFile = Join-Path $MdImagesFolder 'thumbnail123.jpg'

  # Create the directories and a dummy image file
  New-Item -Path $script:BackupFolder -ItemType Directory | Out-Null
  New-Item -Path $script:NoteFolder -ItemType Directory | Out-Null
  New-Item -Path $script:MdImagesFolder -ItemType Directory | Out-Null
  New-Item -Path $script:ImageFile -ItemType File | Out-Null

  # Define the content that the script will look for
  $script:OriginalContent = '[![Test Alt Text](.data/md-images/thumbnail123.jpg)](https://youtu.be/VIDEO123)'
  Set-Content -Path $script:NotesFile -Value $script:OriginalContent -Encoding UTF8

  # Mock the external script dependency to return a temporary path
  Mock Invoke-SqliteQuery { return [PSCustomObject]@{ Value = """$script:TestDrive""" } } -Verifiable
}

AfterAll {
  # Clean up the temporary directory
  Remove-Item -Path $script:TestDrive.FullName -Recurse -Force
}

Describe 'Format-TheBrainNotesYouTubeThumbnail.ps1' {

  BeforeEach {
    # Reset all mocks before each test to ensure isolation
    Mock Get-ChildItem -Verifiable
    Mock Select-String -Verifiable
    Mock Copy-Item -Verifiable
    Mock Move-Item -Verifiable
    Mock Set-Content -Verifiable
    Mock Write-Host -Verifiable
    Mock Write-Verbose
    Mock New-Item -Verifiable
    Mock Get-Content -Verifiable
    Mock Convert-Path { return $Path } -Verifiable
  }

  It 'should find, back up, and replace a YouTube thumbnail link' {
    # Arrange
    # This object simulates the output of Select-String with a found match
    $MatchObject = @(
      [pscustomobject]@{
        Path    = $script:NotesFile
        Matches = @(
          [pscustomobject]@{
            Value  = $script:OriginalContent
            Groups = @{
              'ALT'       = [pscustomobject]@{ Value = 'Test Alt Text' }
              'IMAGEFILE' = [pscustomobject]@{ Value = 'thumbnail123' }
              'VIDEOID'   = [pscustomobject]@{ Value = 'VIDEO123' }
            }
          }
        )
      }
    )

    # Mock the commands to return our simulated objects and control behavior
    Mock Get-ChildItem { return Get-Item $script:NoteFolder } -Verifiable
    Mock Select-String { return $MatchObject } -Verifiable
    Mock Get-Content { return $script:OriginalContent.Split([System.Environment]::NewLine) } -Verifiable
    Mock New-Item { return [pscustomobject]@{ FullName = $Path[0] } } -Verifiable

    # Act
    . $script:ScriptPath

    # Assert
    $ExpectedNewString = '[![Test Alt Text](https://img.youtube.com/vi/VIDEO123/maxresdefault.jpg)](https://www.youtube.com/watch?v=VIDEO123)'

    # Verify that the backup file for Notes.md was created
    Should -Invoke Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter {
      $Path -eq $script:NotesFile -and $Destination -like "$script:BackupFolder\TestNote\Notes-*.md~"
    }

    # Verify that the local image file was moved to the backup location
    Should -Invoke Move-Item -Times 1 -Exactly -Scope It -ParameterFilter {
      $Path -eq "$script:NoteFolder\.data\md-images\thumbnail123.jpg" -and $Destination -like "$script:BackupFolder\TestNote\.data\md-images\thumbnail123.jpg"
    }

    # Verify that the Notes.md file was updated with the new string
    Should -Invoke Set-Content -Times 1 -Exactly -Scope It -ParameterFilter {
      $Path -eq $script:NotesFile -and $Value -eq $ExpectedNewString -and $Encoding -eq 'UTF8'
    }

    # Verify the final status message
    Should -Invoke Write-Host -Times 1 -Exactly -Scope It -ParameterFilter {
      $Object -like 'Finished: * file(s) found'
    }
  }

  It 'should do nothing if no matching links are found' {
    # Arrange
    # Mock Select-String to return no matches
    Mock Get-ChildItem -Verifiable
    Mock Select-String { return $null } -Verifiable

    # Act
    . $script:ScriptPath

    # Assert
    # Ensure no file operations were attempted
    Should -Not -Invoke -CommandName Copy-Item
    Should -Not -Invoke -CommandName Move-Item
    Should -Not -Invoke -CommandName Set-Content

    # Verify the final status message indicates no files were found
    Should -Invoke Write-Host -Times 1 -Exactly -Scope It -ParameterFilter {
      $Object -eq 'Finished: 0 file(s) found'
    }
  }

  It 'should handle errors during file operations' {
    # Arrange
    # Simulate a match being found, same as the happy path test
    $MatchObject = @(
      [pscustomobject]@{
        Path    = $script:NotesFile
        Matches = @(
          [pscustomobject]@{
            Value  = $script:OriginalContent
            Groups = @{
              'ALT'       = [pscustomobject]@{ Value = 'Test Alt Text' }
              'IMAGEFILE' = [pscustomobject]@{ Value = 'thumbnail123' }
              'VIDEOID'   = [pscustomobject]@{ Value = 'VIDEO123' }
            }
          }
        )
      }
    )
    Mock Get-ChildItem { Get-Item $script:NoteFolder } -Verifiable
    Mock Select-String { return $MatchObject } -Verifiable
    Mock New-Item { return [pscustomobject]@{ FullName = $Path } } -Verifiable

    # Mock Copy-Item to throw an error
    Mock Copy-Item { throw "Access Denied" } -Verifiable

    # Act & Assert
    # Verify that the script throws the expected exception
    { . $script:ScriptPath } | Should -Throw "An error occurred: *"

    # Verify that subsequent operations were not performed
    Should -Not -Invoke -CommandName Move-Item
    Should -Not -Invoke -CommandName Set-Content
  }
}
