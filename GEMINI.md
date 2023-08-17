# Gemini Engine Instructions for "My PowerShell Scripts" Repository

This document provides instructions for the Gemini AI to effectively assist with the development and maintenance of this repository.

## 1. Repository Overview

This repository provides a collection of PowerShell scripts for various applications and tasks, including OneNote, TheBrain, Windows, and Bluestacks. The scripts are intended to be useful for students and for general life-hacking.

## 2. Project Structure

- Scripts are organized into directories based on the application they target: `OneNote/`, `theBrain/`, `Windows/`, `Bluestacks/`.
- Each directory contains specific scripts and may have its own `README.md` file.
- The root directory contains general project files, including `CONTRIBUTING.md`, `LICENSE`, and PSScriptAnalyzer settings.
- System-specific files like `desktop.ini` should not be part of the repository. If found, they should be added to `.gitignore` and removed from the index.

## 3. Development Conventions and Standards

### 3.1. Language and Style

- All scripts are written in **PowerShell**.
- Adhere strictly to the existing coding style, including comment-based help, variable naming (`$PascalCase`), and error handling.
- All scripts that perform file I/O, web requests, or other operations that might fail **MUST** use `try...catch` blocks for error handling, and **MUST** include `$ErrorActionPreference = "Stop"` at the beginning of the script.
- New scripts **MUST** follow the structure of existing ones and include a complete header with metadata.

### 3.2. Script Header Template

All PowerShell scripts **MUST** include a comment-based help header with the following structure:

```powershell
<#
.SYNOPSIS
  A brief, one-line summary of what the script does.

.DESCRIPTION
  A more detailed description of the script's functionality.

.PARAMETER ParameterName
  A description of each parameter, if any.

.EXAMPLE
  PS C:\> .\ScriptName.ps1 -ParameterName "Value"
  An example of how to use the script.

.OUTPUTS
  A description of the objects that the script returns.

.NOTES
  Version:        1.0.0
  Author:         Your Name
  License:        GNU GPLv3 license
  Creation Date:  YYYY-MM-DD
  Last Modified:  YYYY-MM-DD
#>
```

### 3.3. Code Quality and Linting

- This project uses **PSScriptAnalyzer** for static analysis.
- The primary configuration is `PSScriptAnalyzerSettings.psd1` in the root directory. There are other specific configurations in subdirectories.
- **Before committing any changes to PowerShell scripts (`.ps1`), you MUST run PSScriptAnalyzer to ensure compatibility and adherence to project rules.**
- A build script, `Build.ps1`, will be created to automate the process of running PSScriptAnalyzer and Pester tests.

### 3.4. Testing

- This project uses **Pester** for unit and integration testing.
- All new scripts **MUST** be accompanied by Pester tests.
- Any modifications to existing scripts **MUST** include corresponding updates to the tests.
- All tests **MUST** pass before a commit is made.
- A `Build.ps1` script is provided to automate the process of running Pester tests and PSScriptAnalyzer.

### 3.5. Git Commit Conventions

This project follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. Each commit message should be prefixed with a type and an optional scope, followed by a description. An emoji is also used at the beginning of the subject line.

-   **Format**: `<emoji> <type>(<scope>): <description>`
-   **Example Types**:
    -   `feat`: A new feature (✨)
    -   `fix`: A bug fix (🐛)
    -   `docs`: Documentation only changes (📄)
    -   `build`: Changes that affect the build system or external dependencies (e.g., adding `.gitignore`)
-   When committing, review the existing `git log` to match the style.

## 4. Dependencies


- The scripts have a key dependency on the **`PSSQLite` PowerShell module**, which is used to query TheBrain's internal database.
- The `README.md` specifies version `1.1.0`. When assisting, verify its installation using `Get-Module -ListAvailable -Name PSSQLite`.
- The scripts also depend on TheBrain version 13 for Windows being installed, as they access its local application data.

## 5. Workflow for Modifications

1.  **Analyze Request:** Understand the user's goal in the context of TheBrain's functionality and the existing scripts.
2.  **Locate Relevant Scripts:** Use file search and read to identify the correct scripts to modify.
3.  **Implement Changes:** Apply changes following the established PowerShell conventions (see section 3).
4.  **Verify with Linter and Tests:** Run the `Build.ps1` script to execute `PSScriptAnalyzer` and Pester tests. Fix any reported issues.
5.  **Git Operations:**
    - Do not commit extraneous files (`desktop.ini`). Add them to `.gitignore`.
    - Follow existing commit message style if available.

## 6. Licensing

- The project is licensed under the **GNU General Public License v3.0 (GPLv3)**.
- Ensure any new contributions or modifications are compatible with this license.
- New script files should include a license header pointing to the main `LICENSE` file.
