# Cherry Studio PowerShell Scripts

本目錄包含用於管理 [Cherry Studio](https://cherry.ai/) 的 PowerShell 工具腳本。

## 腳本清單

### Reset-CherryStudioNotionMCP.ps1

重置 Cherry Studio 的 Notion MCP OAuth 快取。

**用途：**
- 清除 Notion MCP (`https://mcp.notion.com/mcp`) 的雜湊命名 OAuth JSON 檔案
- 重啟 Cherry Studio 後自動觸發重新授權流程

**使用情境：**
- Notion MCP 授權失效或過期
- 需要切換 Notion 帳號
- OAuth token 損壞導致連接問題

**使用方法：**
```powershell
.\Reset-CherryStudioNotionMCP.ps1
```

**執行流程：**
1. 計算 Notion MCP URL 的 MD5 雜湊值
2. 在 `~/.cherrystudio/config/mcp/oauth` 目錄中搜尋對應的 JSON 檔案
3. 刪除找到的 OAuth 快取檔案
4. 重新啟動 Cherry Studio 以觸發重新授權

## 系統要求

- PowerShell 5.1 或更高版本
- Cherry Studio v1.8.4（已測試版本）
- Windows 作業系統

**相容性說明：**
- Cherry Studio 從 v1.2.5+ 開始支援 MCP 功能
- 本腳本基於 v1.8.4 的 OAuth 資料儲存結構開發
- 其他版本的 OAuth 檔案路徑或命名規則可能有所不同

## 注意事項

- 執行腳本前請確保已關閉 Cherry Studio
- 刪除 OAuth 快取後，需要重新進行 Notion 授權流程
- 建議在執行前備份重要的授權資訊
