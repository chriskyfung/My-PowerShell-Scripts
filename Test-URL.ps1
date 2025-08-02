<#
.SYNOPSIS
  Tests a list of URLs to see if they are responding and returns a table of results.

.DESCRIPTION
  This script iterates through a predefined list of URLs and uses Invoke-WebRequest to check their status.
  It prints the status of each URL to the console and also returns an array of custom objects
  containing the URL and its response status, which can be formatted as a table.

.EXAMPLE
  PS C:\> .\Test-URL.ps1
  This example runs the script, checks the status of the URLs in the list,
  prints the status to the screen, and outputs a results table.

.OUTPUTS
  [PSCustomObject[]]. The script outputs an array of custom objects with 'URL' and 'Status' properties.

.NOTES
  Version:        1.2.0
  Author:         Gemini
  License:        GNU GPLv3 license
  Creation Date:  2025-08-01
  Last Modified:  2025-08-02
#>

#Requires -Version 3.0

$ErrorActionPreference = "Stop"

$urls = @("https://www.google.com", "https://www.bing.com", "https://www.yahoo.com", "https://no-such.domain")

$results = foreach ($url in $urls) {
  $status = try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
      "Up and running"
    }
    else {
      "Not responding"
    }
  }
  catch {
    "Not responding"
  }

  # Print the result to the screen
  Write-Host "$url is $status"

  # Output a custom object for the results table
  [PSCustomObject]@{
    URL    = $url
    Status = $status
  }
}

# Return the collected results, which will be formatted as a table
$results