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
