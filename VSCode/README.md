# VS Code PowerShell Scripts

A collection of PowerShell utilities for managing VS Code configurations, profiles, and extensions.

## Export-VSCodeExtensionList.ps1

Exports all VS Code user profiles and their installed extensions to a timestamped text file in your **My Documents** folder.

### Prerequisites

- **Windows OS** (script uses Windows-specific environment variables)
- **PowerShell 5.0+** (Desktop Edition)
- **VS Code CLI (`code`)** must be available in your system PATH
  - Install via VS Code: `Shell Command: Install 'code' command in PATH` from the Command Palette

### Usage

**Basic execution:**

```powershell
.\Export-VSCodeExtensionList.ps1
```

**WhatIf mode (preview without exporting):**

```powershell
.\Export-VSCodeExtensionList.ps1 -WhatIf
```

**Run from another directory:**

```powershell
& "C:\Path\To\VSCode\Export-VSCodeExtensionList.ps1"
```

### Output

The script generates a text file named `vscode-profiles-export-YYYY-MM-DD.txt` in your **My Documents** folder:

```plaintext
VS Code Profile & Extension Export
Generated: 2026-06-01
Machine:   my-machine
==================================================

--------------------------------------------------
Profile: Default
--------------------------------------------------
dbaeumer.vscode-eslint
esbenp.prettier-vscode
pkief.material-icon-theme

Total: 3 extension(s)

--------------------------------------------------
Profile: Python
--------------------------------------------------
ms-python.python
ms-toolsai.jupyter

Total: 2 extension(s)

==================================================
End of export
```

### How It Works

1. Reads `storage.json` from the VS Code user data directory
2. Discovers all configured profiles (including `Default`)
3. Uses `code --list-extensions --profile <name>` for each profile
4. Compiles results into a single output file in your My Documents folder

### Troubleshooting

| Issue                      | Solution                                                                                |
|----------------------------|-----------------------------------------------------------------------------------------|
| `'code' is not recognized` | Ensure the VS Code CLI is installed and PATH is refreshed                               |
| `storage.json not found`   | VS Code may not be installed, or profiles haven't been created yet                      |
| Empty extension list       | Verify extensions are installed in the profile; some extensions may be machine-specific |

### Output File Contents

- **Header section:** Timestamp, machine name, separator
- **Per-profile sections:** Profile name followed by extension list and count
- **Footer section:** End-of-export marker

### License

The project is licensed under the GPLv3 License. See the [License](/LICENSE) file for details.
