<#
.SYNOPSIS
    重置 Cherry Studio 的 Notion MCP OAuth 快取

.DESCRIPTION
    清除 Notion MCP (https://mcp.notion.com/mcp) 的雜湊命名 OAuth JSON 檔案
    重啟後自動觸發重新授權流程

.EXAMPLE
    .\Reset-CherryStudioNotionMCP.ps1
#>

[CmdletBinding()]
param()

# Notion MCP 伺服器 URL，Cherry Studio 使用此 URL 的 MD5 雜湊作為 OAuth 檔案名稱
$url = "https://mcp.notion.com/mcp"

# 計算 URL 的 MD5 雜湊值，用於識別對應的 OAuth 快取檔案
$md5 = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($url)
$hashBytes = $md5.ComputeHash($bytes)
$hashHex = [System.BitConverter]::ToString($hashBytes) -replace '-', ''

$fullHash = $hashHex.ToLower()
# Cherry Studio 儲存 OAuth token 的目錄路徑
$oauthDir = Join-Path $env:USERPROFILE ".cherrystudio\config\mcp\oauth"

Write-Host ""
Write-Host "Notion MCP URL: $url"
Write-Host "計算出的雜湊前綴: $fullHash"
Write-Host "搜尋資料夾: $oauthDir"
Write-Host ""

# 搜尋符合雜湊前綴的 OAuth JSON 檔案
$targetFiles = Get-ChildItem -Path $oauthDir -Filter "$fullHash*.json" -ErrorAction SilentlyContinue

if ($targetFiles) {
  Write-Host "找到以下檔案：" -ForegroundColor Yellow
  $targetFiles | ForEach-Object { Write-Host " - $($_.Name)" }

  # 刪除找到的 OAuth 快取檔案
  $targetFiles | Remove-Item -Force

  Write-Host ""
  Write-Host "已刪除 Notion MCP 的授權快取檔。" -ForegroundColor Green
  Write-Host "請重新啟動 Cherry Studio，系統應會自動打開瀏覽器重新授權。"
}
else {
  Write-Host "找不到對應的 Notion MCP JSON 檔。" -ForegroundColor Red
  Write-Host "請確認你曾在這台電腦上成功授權過 Notion MCP。"
}
