<#
.SYNOPSIS
Pester tests for Export-VSCodeExtensionList.ps1

.DESCRIPTION
Validates profile discovery, extension export content, empty-profile handling,
summary output, and error handling for missing storage.json.

.NOTES
    Requires: Pester 5.x or 6.x
    Because the target script has no injectable parameters and hardcodes
    $env:APPDATA and [Environment]::GetFolderPath('MyDocuments'), these tests
    redirect $env:APPDATA to a temp path and shadow the 'code' external
    command with a PowerShell function of the same name (function resolution
    takes precedence over external executables in the same session).
#>

#Requires -Version 5.0
#Requires -Module Pester

Describe "Export-VSCodeExtensionList.ps1" {

    BeforeAll {
        $script:ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\VSCode\Export-VSCodeExtensionList.ps1"
        $script:OriginalAppData = $env:APPDATA
        $script:TestRoot = Join-Path -Path $env:TEMP -ChildPath "Export-VSCodeExtList.Tests.$([guid]::NewGuid())"
        $script:DocumentsPath = [Environment]::GetFolderPath('MyDocuments')

        New-Item -ItemType Directory -Path (Join-Path $script:TestRoot "Code\User\globalStorage") -Force | Out-Null
        $env:APPDATA = $script:TestRoot

        $script:storageJson = @{
            userDataProfiles = @(
                @{ name = "Work" },
                @{ name = "Personal" }
            )
        } | ConvertTo-Json -Depth 3
        Set-Content -Path (Join-Path $script:TestRoot "Code\User\globalStorage\storage.json") -Value $script:storageJson -Encoding UTF8

        # Shadow the 'code' external command so no real VS Code install is required.
        # PowerShell resolves functions before external executables in the same scope,
        # so this intercepts `code --list-extensions --profile <name>` calls made by the script.
        function global:code {
            param()
            $profileArgIndex = [array]::IndexOf($args, "--profile")
            $profileName = if ($profileArgIndex -ge 0) { $args[$profileArgIndex + 1] } else { $null }

            switch ($profileName) {
                "Default"  { return @("ms-python.python", "ms-vscode.powershell") }
                "Work"     { return @("github.copilot") }
                "Personal" { return @() }
                default    { return @() }
            }
        }

        # Track any real output files created in Documents so we can clean them up,
        # since the script cannot be redirected away from the real Documents folder.
        $script:ExpectedOutputFile = Join-Path -Path $script:DocumentsPath -ChildPath "vscode-profiles-export-$(Get-Date -Format 'yyyy-MM-dd').txt"
    }

    AfterAll {
        $env:APPDATA = $script:OriginalAppData
        Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $script:ExpectedOutputFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "function:global:code" -ErrorAction SilentlyContinue
    }

    Context "Profile discovery" {
        It "discovers all profiles including Default plus additional profiles from storage.json" {
            $output = (& $script:ScriptPath 2>&1 6>&1 *>&1) | Out-String
            $output | Should -Match "Found profiles: Default, Work, Personal"
        }
    }

    Context "Output file generation" {
        BeforeEach {
            Remove-Item -Path $script:ExpectedOutputFile -Force -ErrorAction SilentlyContinue
            & $script:ScriptPath | Out-Null
        }

        It "creates the timestamped output file in MyDocuments" {
            $script:ExpectedOutputFile | Should -Exist
        }

        It "writes a header with generation timestamp and machine name" {
            $content = Get-Content -Path $script:ExpectedOutputFile -Raw
            $content | Should -Match "VS Code Profile & Extension Export"
            $content | Should -Match "Generated:"
            $content | Should -Match "Machine:\s+$env:COMPUTERNAME"
        }

        It "lists extensions under each profile section with correct counts" {
            $content = Get-Content -Path $script:ExpectedOutputFile -Raw
            $content | Should -Match "Profile: Default"
            $content | Should -Match "ms-python\.python"
            $content | Should -Match "Total: 2 extension\(s\)"

            $content | Should -Match "Profile: Work"
            $content | Should -Match "github\.copilot"
            $content | Should -Match "Total: 1 extension\(s\)"
        }

        It "handles a profile with zero extensions gracefully" {
            $content = Get-Content -Path $script:ExpectedOutputFile -Raw
            $content | Should -Match "Profile: Personal"
            $content | Should -Match "\(no extensions installed\)"
        }

        It "ends the file with the closing footer" {
            $content = Get-Content -Path $script:ExpectedOutputFile -Raw
            $content | Should -Match "End of export"
        }
    }

    Context "Console summary output" {
        It "prints a per-profile extension count summary to the host" {
            $output = & $script:ScriptPath 6>&1 *>&1 | Out-String
            $output | Should -Match "Default:\s*2 extension\(s\)"
            $output | Should -Match "Work:\s*1 extension\(s\)"
            $output | Should -Match "Personal:\s*0 extension\(s\)"
        }
    }

    Context "Error handling" {
        It "throws and exits non-zero when storage.json is missing" {
            $storagePath = Join-Path $script:TestRoot "Code\User\globalStorage\storage.json"
            Rename-Item -Path $storagePath -NewName "storage.json.bak"
            try {
                { & $script:ScriptPath 2>$null } | Should -Throw "*storage.json*"
            }
            finally {
                Rename-Item -Path (Join-Path $script:TestRoot "Code\User\globalStorage\storage.json.bak") -NewName "storage.json"
            }
        }

        It "throws a descriptive error message when VS Code user directory is absent" {
            $env:APPDATA = Join-Path $script:TestRoot "nonexistent"
            try {
                { & $script:ScriptPath 2>&1 } | Should -Throw "*An error occurred*"
            }
            finally {
                $env:APPDATA = $script:TestRoot
            }
        }
    }

    Context "-WhatIf support" {
        It "does NOT create an output file when -WhatIf is specified" {
            Remove-Item -Path $script:ExpectedOutputFile -Force -ErrorAction SilentlyContinue
            & $script:ScriptPath -WhatIf | Out-Null
            $script:ExpectedOutputFile | Should -Not -Exist
        }
    }
}
