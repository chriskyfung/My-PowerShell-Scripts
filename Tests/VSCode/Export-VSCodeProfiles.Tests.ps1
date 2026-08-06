<#
.SYNOPSIS
Pester tests for Export-VSCodeProfiles.ps1

.DESCRIPTION
Validates parameter handling, prerequisite checks, profile discovery,
extension export, settings backup, manifest generation, and WhatIf behavior.

.NOTES
    Version:        1.0.0
    Author:         chriskyfung
    License:        GNU GPLv3 license
#>

#Requires -Version 5.0
#Requires -Module Pester

Describe "Export-VSCodeProfiles.ps1" {
    BeforeAll {
        # Use a temp directory to avoid polluting the user's Documents folder
        $testRoot = Join-Path -Path $env:TEMP -ChildPath "Export-VSCodeProfiles.Tests.$([guid]::NewGuid)"
        $script:TestRoot = $testRoot
        $script:ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\VSCode\Export-VSCodeProfiles.ps1"

        # Create test directories
        New-Item -ItemType Directory -Path (Join-Path $testRoot "User\globalStorage") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $testRoot "User\snippets") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $testRoot "code") -Force | Out-Null

        # Create a fake storage.json
        $script:storageJson = @{
            userDataProfiles = @(
                @{ name = "Work" },
                @{ name = "Personal" }
            )
        } | ConvertTo-Json -Depth 3
        Set-Content -Path (Join-Path $testRoot "User\globalStorage\storage.json") -Value $script:storageJson -Encoding UTF8

        # Create fake settings files
        Set-Content -Path (Join-Path $testRoot "User\settings.json") -Value '{"editor.fontSize": 14}' -Encoding UTF8
        Set-Content -Path (Join-Path $testRoot "User\keybindings.json") -Value '[]' -Encoding UTF8
    }

    AfterAll {
        if ($script:TestRoot -and (Test-Path $script:TestRoot)) {
            Remove-Item -Path $script:TestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Parameter validation" {
        It "accepts a custom OutputDirectory" {
            { & $script:ScriptPath -OutputDirectory (Join-Path $script:TestRoot "out") -VSCodeUserDataPath (Join-Path $script:TestRoot "User") -WhatIf } | Should -Not -Throw
        }

        It "accepts a custom VSCodeUserDataPath" {
            { & $script:ScriptPath -OutputDirectory (Join-Path $script:TestRoot "out2") -VSCodeUserDataPath (Join-Path $script:TestRoot "User") -WhatIf } | Should -Not -Throw
        }

        It "throws for invalid OutputDirectory characters" {
            { & $script:ScriptPath -OutputDirectory "C:\bad|path" -WhatIf } |
                Should -Throw "*OutputDirectory contains invalid path characters*"
        }
    }

    Context "Prerequisite checks" {
        It "throws when VSCodeUserDataPath does not exist" {
            { & $script:ScriptPath -VSCodeUserDataPath "C:\nonexistent\path" -WhatIf } | Should -Throw "VS Code user data directory not found:*"
        }

        It "throws when storage.json is missing" {
            Remove-Item -Path (Join-Path $script:TestRoot "User\globalStorage\storage.json") -Force
            try {
                { & $script:ScriptPath -VSCodeUserDataPath (Join-Path $script:TestRoot "User") -WhatIf } | Should -Throw "VS Code storage.json not found*"
            }
            finally {
                $script:storageJson | Set-Content -Path (Join-Path $script:TestRoot "User\globalStorage\storage.json") -Encoding UTF8
            }
        }

        It "throws when 'code' CLI is not in PATH" {
            { & $script:ScriptPath -VSCodeUserDataPath (Join-Path $script:TestRoot "User") `
                -CodeCommand "nonexistent_code_binary_xyz" -WhatIf } |
                Should -Throw "VS Code CLI*not available*"
        }
    }

    Context "Profile discovery" {
        It "discovers profiles from storage.json" {
            $outputDir = Join-Path $script:TestRoot "out_discover"
            $output = (& $script:ScriptPath -OutputDirectory $outputDir -VSCodeUserDataPath (Join-Path $script:TestRoot "User") -WhatIf 6>&1) | Out-String

            $output | Should -Match "Found profiles: Default, Work, Personal"
            $outputDir | Should -Not -Exist
        }
    }

    Context "Extension export" {
        It "exports extensions and manifest using a custom CodeCommand" {
            $outputDir = Join-Path $script:TestRoot "out_export"
            $codePath = Join-Path $script:TestRoot "code\code.cmd"
            Set-Content -Path $codePath -Value '@echo off
echo ext1.vscode
echo ext2.vscode' -Encoding ASCII

            & $script:ScriptPath -OutputDirectory $outputDir -VSCodeUserDataPath (Join-Path $script:TestRoot "User") -CodeCommand $codePath

            $outputDir | Should -Exist
            $manifest = Get-Content (Join-Path $outputDir "manifest.json") -Raw | ConvertFrom-Json
            $manifest.profiles.name | Should -Contain "Default"
            $manifest.profiles[0].extensions | Should -Contain "ext1.vscode"
        }
    }

    Context "WhatIf behavior" {
        It "does not create output files when -WhatIf is specified" {
            $outputDir = Join-Path $script:TestRoot "out_whatif"
            { & $script:ScriptPath -OutputDirectory $outputDir -VSCodeUserDataPath (Join-Path $script:TestRoot "User") -WhatIf } | Should -Not -Throw
            $outputDir | Should -Not -Exist
        }
    }
}
