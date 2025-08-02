<#
.SYNOPSIS
  Tests for the Test-URL.ps1 script.
#>

# Get the absolute path to the script under test
$scriptPath = Join-Path $PSScriptRoot "..\..\Test-URL.ps1"

Describe "Test-URL Script" -Tag "CI" {
    BeforeAll {
        # Mock Invoke-WebRequest to simulate web responses.
        # This mock will return a success status code for most URLs,
        # but throw an error for a specific invalid domain.
        Mock 'Invoke-WebRequest' {
            param($Uri)
            if ($Uri -eq 'https://no-such.domain') {
                throw "Simulated error: Host not found"
            } else {
                return [pscustomobject]@{ StatusCode = 200 }
            }
        }
    }

    It "Should produce a table with correct status for each URL" {
        # Execute the script and capture its output object
        $results = & $scriptPath

        # Assert the structure of the output
        $results | Should -BeOfType [PSCustomObject]
        $results | Should -Not -BeNullOrEmpty

        # Assert the status of a successful URL
        ($results | Where-Object { $_.URL -eq 'https://www.google.com' }).Status | Should -Be "Up and running"

        # Assert the status of the failing URL
        ($results | Where-Object { $_.URL -eq 'https://no-such.domain' }).Status | Should -Be "Not responding"
    }
}
