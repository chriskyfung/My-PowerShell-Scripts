<#
.SYNOPSIS
  Tests a list of URLs to see if they are responding.

.DESCRIPTION
  This script iterates through a predefined list of URLs and uses Invoke-WebRequest to check their status. It then outputs whether each URL is up and running or not.

.EXAMPLE
  PS C:\> .\Test-URL.ps1
  This example runs the script and checks the status of the URLs in the list.

.OUTPUTS
  String. The script outputs a string to the console indicating the status of each URL.

.NOTES
  Version:        1.1.0
  Author:         Gemini
  License:        GNU GPLv3 license
  Creation Date:  2025-08-01
  Last Modified:  2025-08-01
#>

#Requires -Version 3.0

$ErrorActionPreference = "Stop"

$urls = @("https://www.google.com", "https://www.bing.com", "https://www.yahoo.com", "https://www.example.com")

foreach ($url in $urls) {
  try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($response.StatusCode -eq 200) {
      Write-Host "$url is up and running"
    }
    else {
      Write-Host "$url is not responding"
    }
  }
  catch {
    Write-Host "$url is not responding"
  }
}