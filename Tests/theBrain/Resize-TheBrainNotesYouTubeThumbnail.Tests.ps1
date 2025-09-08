<#
.SYNOPSIS
  Tests for Resize-TheBrainNotesYouTubeThumbnail.ps1
#>

Describe 'Resize-TheBrainNotesYouTubeThumbnail.ps1' {
  BeforeAll {
    # Path to the script being tested, resolved relative to this test script's location
    $script:ScriptPath = Resolve-Path -Path "$PSScriptRoot\..\..\theBrain\Resize-TheBrainNotesYouTubeThumbnail.ps1"
    $script:GetDataDirectoryScriptPath = Resolve-Path -Path "$PSScriptRoot\..\..\theBrain\Get-TheBrainDataDirectory.ps1"

    # Set up a temporary directory to simulate TheBrain's data folder
    $script:TestDrive = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "TestBrain") -Force
    $script:TestBrainDataDir = $script:TestDrive.FullName
    $script:TestThoughtDir = Join-Path $script:TestBrainDataDir 'TestThought'
    $script:TestBackupDir = Join-Path $script:TestBrainDataDir 'Backup'
    $script:TestNotesFile = Join-Path $script:TestThoughtDir 'Notes.md'
    New-Item -Path $script:TestThoughtDir -ItemType Directory -Force | Out-Null

    # Mock the external script dependency to return a temporary path
    Mock Invoke-SqliteQuery { return [PSCustomObject]@{ Value = """$script:TestDrive""" } } -Verifiable
  }

  AfterAll {
    # Clean up the temporary directory
    Remove-Item -Path $script:TestDrive -Recurse -Force
  }

  BeforeEach {
    # Clean up any files from previous tests
    if (Test-Path $script:TestThoughtDir) {
      Get-ChildItem -Path $script:TestThoughtDir -Recurse | Remove-Item -Recurse -Force
    }
    if (Test-Path $script:TestBackupDir) {
      Get-ChildItem -Path $script:TestBackupDir -Recurse | Remove-Item -Recurse -Force
    }
  }

  Context "when ImageType is 'default'" {
    It 'should resize a default thumbnail to 50% width by default' {
      # Arrange
      $content = 'Some text before ![Image](https://i.ytimg.com/vi/video123/hqdefault.jpg) and after.'
      Set-Content -Path $script:TestNotesFile -Value $content -Encoding UTF8

      # Act
      . $script:ScriptPath

      # Assert
      $newContent = Get-Content -Path $script:TestNotesFile -Encoding UTF8
      $newContent | Should -Be 'Some text before ![Image](https://i.ytimg.com/vi/video123/hqdefault.jpg#$width=50p$) and after.'
    }

    It 'should resize a default thumbnail to a specified NewWidth' {
      # Arrange
      $content = 'Another note with a thumbnail [](https://i.ytimg.com/vi/video456/maxresdefault.jpg).'
      Set-Content -Path $script:TestNotesFile -Value $content -Encoding UTF8

      # Act
      . $script:ScriptPath -NewWidth 75

      # Assert
      $newContent = Get-Content -Path $script:TestNotesFile -Encoding UTF8
      $newContent | Should -Be 'Another note with a thumbnail [](https://i.ytimg.com/vi/video456/maxresdefault.jpg#$width=75p$).'
    }

    It 'should create a backup of the modified file' {
      # Arrange
      $content = '![Image](https://i.ytimg.com/vi/video123/hqdefault.jpg)'
      Set-Content -Path $script:TestNotesFile -Value $content -Encoding UTF8

      # Act
      . $script:ScriptPath

      # Assert
      $backupDirForThought = Join-Path $script:TestBackupDir 'TestThought'
      $backupFile = Get-ChildItem -Path $backupDirForThought -Filter '*.md~'
      $backupFile | Should -Not -BeNull
      (Get-Content $backupFile.FullName) | Should -Be $content
    }
  }

  Context "when ImageType is 'resized'" {
    It 'should resize a thumbnail from a specified CurrentWidth to a NewWidth' {
      # Arrange
      $content = 'Resizing this: ![Image](https://i.ytimg.com/vi/video789/hqdefault.jpg#$width=30p$)'
      Set-Content -Path $script:TestNotesFile -Value $content -Encoding UTF8

      # Act
      . $script:ScriptPath -ImageType resized -CurrentWidth 30 -NewWidth 80

      # Assert
      $newContent = Get-Content -Path $script:TestNotesFile -Encoding UTF8
      $newContent | Should -Be 'Resizing this: ![Image](https://i.ytimg.com/vi/video789/hqdefault.jpg#$width=80p$)'
    }

    It 'should not modify a thumbnail if its width does not match CurrentWidth' {
      # Arrange
      $content = 'Do not resize: ![Image](https://i.ytimg.com/vi/videoABC/hqdefault.jpg#$width=50p$)'
      Set-Content -Path $script:TestNotesFile -Value $content -Encoding UTF8

      # Act
      . $script:ScriptPath -ImageType resized -CurrentWidth 30 -NewWidth 80

      # Assert
      $newContent = Get-Content -Path $script:TestNotesFile -Encoding UTF8
      $newContent | Should -Be $content
      $backupDirForThought = Join-Path $script:TestBackupDir 'TestThought'
      Test-Path (Join-Path $backupDirForThought '*.md~') | Should -Be $false
    }
  }

  Context 'when no matching thumbnails are found' {
    It 'should not modify any files' {
      # Arrange
      $content = 'This file has no YouTube thumbnails.'
      Set-Content -Path $script:TestNotesFile -Value $content -Encoding UTF8

      # Act
      . $script:ScriptPath

      # Assert
      (Get-Content -Path $script:TestNotesFile -Encoding UTF8) | Should -Be $content
      $backupDirForThought = Join-Path $script:TestBackupDir 'TestThought'
      Test-Path (Join-Path $backupDirForThought '*.md~') | Should -Be $false
    }
  }

  Context 'Error Handling' {
    It 'should call Write-Error when Get-TheBrainDataDirectory.ps1 fails' {
      # Arrange
      # This mock will cause the script's try/catch block to fail
      Mock Get-Module { return $null } -ParameterFilter { $Name -eq 'PSSQLite' } -Verifiable

      # Mock Write-Error to verify the catch block is executed
      Mock Write-Error -Verifiable

      # Act
      # The script should not throw an unhandled exception because it has a catch block
      { . $script:ScriptPath } | Should -Not -Throw

      # Assert
      # Verify that the script's catch block called Write-Error
      Should -Invoke Write-Error -ParameterFilter {
        $Message -eq "An error occurred while trying to get TheBrain data directory: The 'PSSQLite' module is required but not installed. Please run 'Install-Module -Name PSSQLite'."
      }
    }
  }
}
