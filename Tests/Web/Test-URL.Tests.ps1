<#
.SYNOPSIS
  Tests for the Test-URL.ps1 script.
#>

# Get the absolute path to the script under test
$scriptPath = Join-Path $PSScriptRoot "..\..\Test-URL.ps1"

Describe "Test-URL Script" -Tags "CI" {
    It "Should produce a table with correct status for each URL" {
        # Mock Invoke-WebRequest to simulate web responses.
        # This mock will return a success status code for most URLs,
        # but throw an error for a specific invalid domain.
        Mock Invoke-WebRequest -MockWith {
            param($Uri)
            if ($Uri -eq 'https://no-such.domain') {
                throw "Simulated error: Host not found"
            } else {
                return [pscustomobject]@{ StatusCode = 200 }
            }
        }

        # Execute the script and capture its output object
        $results = & $scriptPath

        # Assert the structure of the output
        $results | Should Not Be $null
        $results.Count | Should Be 4

        # Assert the status of a successful URL
        ($results | Where-Object { $_.URL -eq 'https://www.google.com' }).Status | Should Be "Up and running"

        # Assert the status of the failing URL
        ($results | Where-Object { $_.URL -eq 'https://no-such.domain' }).Status | Should Be "Not responding"
    }
}
