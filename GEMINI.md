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
- Adhere strictly to the existing coding style, including comment-based help (`<# .SYNOPSIS ... #>`), variable naming (`$PascalCase`), and error handling (`$ErrorActionPreference = "Stop"`).
- New scripts should follow the structure of existing ones, including the header with metadata (Version, Author, License).

### 3.2. Code Quality and Linting

- This project uses **PSScriptAnalyzer** for static analysis.
- The primary configuration is `PSScriptAnalyzerSettings.psd1` in the root directory. There are other specific configurations in subdirectories.
- **Before committing any changes to PowerShell scripts (`.ps1`), you MUST run PSScriptAnalyzer to ensure compatibility and adherence to project rules.** The command to run the analyzer on a specific file would be: `Invoke-ScriptAnalyzer -Path .\path\to\script.ps1 -Settings .\path\to\PSScriptAnalyzerSettings.psd1`

### 3.3. Git Commit Conventions

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
4.  **Verify with Linter:** Run `Invoke-ScriptAnalyzer` against any modified `.ps1` files using the relevant settings file (e.g., `theBrain/PSScriptAnalyzerSettings.psd1`). Fix any reported issues.
5.  **Testing:** As there are no automated tests, verification relies on careful code review and manual testing by the user. Explain the changes made and how the user can test them.
6.  **Git Operations:**
    - Do not commit extraneous files (`desktop.ini`). Add them to `.gitignore`.
    - Follow existing commit message style if available.

## 6. Licensing

- The project is licensed under the **GNU General Public License v3.0 (GPLv3)**.
- Ensure any new contributions or modifications are compatible with this license.
- New script files should include a license header pointing to the main `LICENSE` file.