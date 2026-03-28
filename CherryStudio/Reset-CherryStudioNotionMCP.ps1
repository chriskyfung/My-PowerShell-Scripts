<#
.SYNOPSIS
    Reset Cherry Studio's Notion MCP OAuth cache

.DESCRIPTION
    Clear the hash-named OAuth JSON file for Notion MCP (https://mcp.notion.com/mcp)
    Automatically triggers re-authorization flow after restart

.PARAMETER OauthDir
    Optional. Override the default OAuth directory path.
    Default: $env:USERPROFILE\.cherrystudio\config\mcp\oauth

.PARAMETER PassThru
    Optional. Return the result as an object instead of writing to host.

.EXAMPLE
    .\Reset-CherryStudioNotionMCP.ps1

.EXAMPLE
    .\Reset-CherryStudioNotionMCP.ps1 -OauthDir "C:\Temp\TestOAuth"

.EXAMPLE
    $result = .\Reset-CherryStudioNotionMCP.ps1 -PassThru
#>

[CmdletBinding()]
param(
    # Override the default OAuth directory path (for testing purposes)
    [string]$OauthDir = (Join-Path $env:USERPROFILE ".cherrystudio\config\mcp\oauth"),

    # Return result as object for testing
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

# Notion MCP server URL, Cherry Studio uses the MD5 hash of this URL as the OAuth filename
$url = "https://mcp.notion.com/mcp"

# Calculate MD5 hash of the URL to identify the corresponding OAuth cache file
$md5 = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
$hashBytes = $md5.ComputeHash($bytes)
$hashHex = [System.BitConverter]::ToString($hashBytes) -replace '-', ''

$fullHash = $hashHex.ToLower()

# Build output messages
$messages = @()
$messages += "Notion MCP URL: $url"
$messages += "Calculated hash prefix: $fullHash"
$messages += "Searching directory: $OauthDir"

if ($PassThru) {
    Write-Verbose ($messages -join "`n")
} else {
    Write-Host ""
    $messages | ForEach-Object { Write-Host $_ }
    Write-Host ""
}

# Search for OAuth JSON files matching the hash prefix
$targetFiles = Get-ChildItem -Path $OauthDir -Filter "$fullHash*.json" -ErrorAction SilentlyContinue

$result = @{
    Success = $false
    FilesDeleted = @()
    Message = ""
}

if ($targetFiles) {
    $foundMsg = "Found the following files:"
    if ($PassThru) {
        Write-Verbose $foundMsg
    } else {
        Write-Host $foundMsg -ForegroundColor Yellow
    }

    $targetFiles | ForEach-Object {
        if ($PassThru) {
            Write-Verbose " - $($_.Name)"
        } else {
            Write-Host " - $($_.Name)"
        }
    }

    # Delete the found OAuth cache files
    $deletedFiles = @()
    $targetFiles | ForEach-Object {
        $deletedFiles += $_.Name
        Remove-Item $_.FullName -Force
    }

    $successMsg = "Notion MCP OAuth cache file has been deleted."
    if ($PassThru) {
        Write-Verbose $successMsg
    } else {
        Write-Host ""
        Write-Host $successMsg -ForegroundColor Green
        Write-Host "Please restart Cherry Studio, the system should automatically open the browser for re-authorization."
    }

    $result.Success = $true
    $result.FilesDeleted = $deletedFiles
    $result.Message = $successMsg
}
else {
    $notFoundMsg = "No corresponding Notion MCP JSON file found."
    if ($PassThru) {
        Write-Verbose $notFoundMsg
    } else {
        Write-Host $notFoundMsg -ForegroundColor Red
        Write-Host "Please confirm that you have successfully authorized Notion MCP on this computer before."
    }

    $result.Message = $notFoundMsg
}

if ($PassThru) {
    return $result
}
