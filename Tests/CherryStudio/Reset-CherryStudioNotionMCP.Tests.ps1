<#
.SYNOPSIS
    Tests for Reset-CherryStudioNotionMCP.ps1

.DESCRIPTION
    Unit tests for the Cherry Studio Notion MCP OAuth reset script.
    Uses mocked directories to avoid accidentally deleting production OAuth files.
#>

Describe "Reset-CherryStudioNotionMCP.ps1" -Tag 'Unit' {

  BeforeAll {
    # Set the path to the script under test.
    $script:ScriptPath = Resolve-Path "$PSScriptRoot\..\..\CherryStudio\Reset-CherryStudioNotionMCP.ps1"

    # Mock the OAuth directory path - use TEMP to avoid touching real OAuth files
    $script:MockOauthDir = Join-Path $env:TEMP "CherryStudioTest-OAuth-$(Get-Random)"

    # Store the real OAuth directory path for verification (should never be accessed)
    $script:RealOauthDir = Join-Path $env:USERPROFILE ".cherrystudio\config\mcp\oauth"

    # Safety check: ensure mock directory is NOT the real OAuth directory
    $script:MockOauthDir | Should -Not -Be $script:RealOauthDir
  }

  BeforeEach {
    # Create mock OAuth directory
    if (Test-Path $script:MockOauthDir) {
      Remove-Item $script:MockOauthDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $script:MockOauthDir -Force | Out-Null
  }

  AfterEach {
    # Clean up mock OAuth directory
    if (Test-Path $script:MockOauthDir) {
      Remove-Item $script:MockOauthDir -Recurse -Force
    }
  }

  Context "MD5 Hash Calculation" {

    It "should calculate correct MD5 hash for Notion MCP URL" {
      $url = "https://mcp.notion.com/mcp"
      $md5 = [System.Security.Cryptography.MD5]::Create()
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
      $hashBytes = $md5.ComputeHash($bytes)
      $hashHex = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
      $expectedHash = $hashHex.ToLower()

      # The expected hash should be a valid 32-character hexadecimal string
      $expectedHash | Should -Match "^[a-f0-9]{32}$"
    }

    It "should produce consistent hash for the same URL" {
      $url = "https://mcp.notion.com/mcp"

      $md5_1 = [System.Security.Cryptography.MD5]::Create()
      $bytes_1 = [System.Text.Encoding]::UTF8.GetBytes($url)
      $hashHex_1 = [System.BitConverter]::ToString($md5_1.ComputeHash($bytes_1)) -replace '-', ''

      $md5_2 = [System.Security.Cryptography.MD5]::Create()
      $bytes_2 = [System.Text.Encoding]::UTF8.GetBytes($url)
      $hashHex_2 = [System.BitConverter]::ToString($md5_2.ComputeHash($bytes_2)) -replace '-', ''

      $hashHex_1.ToLower() | Should -Be $hashHex_2.ToLower()
    }
  }

  Context "File Operations with Mocked Directory" {

    It "should create mock OAuth file with correct hash prefix" {
      # Calculate the expected hash
      $url = "https://mcp.notion.com/mcp"
      $md5 = [System.Security.Cryptography.MD5]::Create()
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
      $hashBytes = $md5.ComputeHash($bytes)
      $hashHex = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
      $fullHash = $hashHex.ToLower()

      # Create mock file in the mock directory (NOT real OAuth directory)
      $mockFilePath = Join-Path $script:MockOauthDir "$fullHash-test.json"
      '{"token": "mock_token"}' | Set-Content -LiteralPath $mockFilePath

      # Verify the file exists in mock directory
      Test-Path $mockFilePath | Should -BeTrue

      # Safety verification: ensure file was created in mock directory, not real directory
      $mockFilePath | Should -Match "^$([regex]::Escape($script:MockOauthDir))"
      $mockFilePath | Should -Not -Match "^$([regex]::Escape($script:RealOauthDir))"
    }

    It "should find files in mock directory matching the hash pattern" {
      # Calculate the expected hash
      $url = "https://mcp.notion.com/mcp"
      $md5 = [System.Security.Cryptography.MD5]::Create()
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
      $hashBytes = $md5.ComputeHash($bytes)
      $hashHex = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
      $fullHash = $hashHex.ToLower()

      # Create mock file
      $mockFilePath = Join-Path $script:MockOauthDir "$fullHash-test.json"
      '{"token": "mock_token"}' | Set-Content -LiteralPath $mockFilePath

      # Search in mock directory only
      $targetFiles = Get-ChildItem -Path $script:MockOauthDir -Filter "$fullHash*.json" -ErrorAction SilentlyContinue
      $targetFiles | Should -Not -BeNullOrEmpty
      $targetFiles.Count | Should -Be 1
    }

    It "should not find files when no matching hash exists in mock directory" {
      # Create a file with a different hash prefix in mock directory
      $wrongHash = "00000000000000000000000000000000"
      $mockFilePath = Join-Path $script:MockOauthDir "$wrongHash-test.json"
      '{"token": "mock_token"}' | Set-Content -LiteralPath $mockFilePath

      # Calculate the correct hash (should not match)
      $url = "https://mcp.notion.com/mcp"
      $md5 = [System.Security.Cryptography.MD5]::Create()
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
      $hashBytes = $md5.ComputeHash($bytes)
      $hashHex = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
      $fullHash = $hashHex.ToLower()

      # Search in mock directory (should not find the wrong hash file)
      $targetFiles = Get-ChildItem -Path $script:MockOauthDir -Filter "$fullHash*.json" -ErrorAction SilentlyContinue
      $targetFiles | Should -BeNullOrEmpty
    }
  }

  Context "Script Execution with Mocked Environment" {

    It "should execute without errors when OAuth directory does not exist" {
      # Create a non-existent path for testing
      $nonExistentDir = Join-Path $env:TEMP "NonExistent-$(Get-Random)"

      # Script should not throw even if directory doesn't exist
      { & $script:ScriptPath -OauthDir $nonExistentDir } | Should -Not -Throw
    }

    It "should execute with mock directory parameter and not throw" {
      # Run script with mock directory parameter - should not throw
      { & $script:ScriptPath -OauthDir $script:MockOauthDir } | Should -Not -Throw
    }

    It "should report 'not found' when mock directory is empty" {
      # Ensure mock directory is empty
      (Get-ChildItem $script:MockOauthDir).Count | Should -Be 0

      # Run script with PassThru to capture result
      $result = & $script:ScriptPath -OauthDir $script:MockOauthDir -PassThru -Verbose

      # Verify result contains expected message
      $result.Message | Should -Be "No corresponding Notion MCP JSON file found."
    }
  }

  Context "File Deletion with Mocked Directory" {

    It "should delete matching OAuth file in mock directory" {
      # Calculate the expected hash
      $url = "https://mcp.notion.com/mcp"
      $md5 = [System.Security.Cryptography.MD5]::Create()
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
      $hashBytes = $md5.ComputeHash($bytes)
      $hashHex = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
      $fullHash = $hashHex.ToLower()

      # Create mock file
      $mockFilePath = Join-Path $script:MockOauthDir "$fullHash.json"
      '{"token": "mock_token"}' | Set-Content -LiteralPath $mockFilePath

      # Verify file exists before
      Test-Path $mockFilePath | Should -BeTrue

      # Run script with mock directory and PassThru
      $result = & $script:ScriptPath -OauthDir $script:MockOauthDir -PassThru -Verbose

      # Verify file was deleted
      Test-Path $mockFilePath | Should -BeFalse

      # Verify success result
      $result.Success | Should -BeTrue
      $result.FilesDeleted.Count | Should -Be 1
    }

    It "should report 'not found' when mock directory is empty" {
      # Ensure mock directory is empty
      (Get-ChildItem $script:MockOauthDir).Count | Should -Be 0

      # Run script with PassThru to capture result
      $result = & $script:ScriptPath -OauthDir $script:MockOauthDir -PassThru -Verbose

      # Verify not found message
      $result.Message | Should -Be "No corresponding Notion MCP JSON file found."
    }
  }

  Context "Error Handling" {

    It "should handle empty mock OAuth directory gracefully" {
      # Ensure the mock directory exists but is empty
      Test-Path $script:MockOauthDir | Should -BeTrue
      (Get-ChildItem $script:MockOauthDir).Count | Should -Be 0

      # Script should not throw on empty directory
      { & $script:ScriptPath -OauthDir $script:MockOauthDir } | Should -Not -Throw
    }
  }

  Context "Safety Checks" {

    It "should use isolated test directory, not production OAuth directory" {
      # Verify mock directory is in TEMP, not in USERPROFILE
      $script:MockOauthDir | Should -Match "^$([regex]::Escape($env:TEMP))"
      $script:MockOauthDir | Should -Not -Match "^$([regex]::Escape($env:USERPROFILE))"
    }

    It "should have unique test directory name to avoid conflicts" {
      # Each test run should use a unique directory
      $script:MockOauthDir | Should -Match "CherryStudioTest-OAuth-"
    }
  }
}
