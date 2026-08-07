# VS Code PowerShell Scripts

A collection of PowerShell utilities for managing VS Code configurations, profiles, and extensions.

## Export-VSCodeExtensionList.ps1

Exports all VS Code user profiles and their installed extensions to a timestamped text file in your **My Documents** folder.

### Prerequisites

- **Windows OS** (script uses Windows-specific environment variables)
- **PowerShell 5.0+** (Windows PowerShell 5.1 or PowerShell 7 / Core Edition)
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

**Specify a custom output directory:**

```powershell
.\Export-VSCodeExtensionList.ps1 -OutputDirectory "D:\Backups\VSCode"
```

**Run from another directory:**

```powershell
& "C:\Path\To\VSCode\Export-VSCodeExtensionList.ps1"
```

### Output

The script generates a text file named `vscode-profiles-export-YYYY-MM-DD.txt` in your **My Documents** folder by default. You can override this with the `-OutputDirectory` parameter.

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
4. Compiles results into a single output file in your default My Documents folder (or a custom directory specified via `-OutputDirectory`)

### Troubleshooting

| Issue                      | Solution                                                                                 |
|----------------------------|------------------------------------------------------------------------------------------|
| `'code' is not recognized` | Ensure the VS Code CLI is installed and PATH is refreshed                                |
| `storage.json not found`   | VS Code may not be installed, or profiles haven't been created yet                       |
| Empty extension list       | Verify extensions are installed in the profile; some extensions may be machine-specific  |
| `-OutputDirectory` empty   | The parameter is validated with `ValidateNotNullOrEmpty`; provide a valid directory path |

### Output File Contents

- **Header section:** Timestamp, machine name, separator
- **Per-profile sections:** Profile name followed by extension list and count
- **Footer section:** End-of-export marker

---

## Export-VSCodeProfiles.ps1

Performs a comprehensive backup of all VS Code profiles, including extensions, settings, keybindings, and snippets, to a structured folder in your **My Documents** directory.

### Prerequisites

- **Windows OS**
- **PowerShell 5.0+** (Desktop Edition)
- **VS Code CLI (`code`)** must be available in your system PATH (by default). You can specify a different command or path via the `-CodeCommand` parameter.

### Usage

**Basic execution:**

```powershell
.\Export-VSCodeProfiles.ps1
```

**Specify a custom VS Code CLI command:**

```powershell
.\Export-VSCodeProfiles.ps1 -CodeCommand "C:\Program Files\Microsoft VS Code\bin\code.cmd"
```

### Output

The script creates a folder named `vscode-export-YYYY-MM-DD` in your **My Documents** folder with the following structure:

```text
vscode-export-2026-06-01/
├── manifest.json          ← Full index of all profiles + extensions
├── storage.json           ← Profile metadata (names, IDs)
├── settings.json          ← Global editor settings
├── keybindings.json       ← Keyboard shortcuts
├── snippets/              ← Code snippets
└── extensions/
    ├── Default.txt        ← Extensions in the Default profile
    ├── Python.txt         ← Extensions in the Python profile
    └── Web_Dev.txt        ← Extensions in the Web Dev profile
```

### How It Works

1. **Profile metadata:** Copies `storage.json` from the VS Code user data directory
2. **Profile discovery:** Reads `storage.json` to find all configured profiles
3. **Extension export:** Uses `code --list-extensions --profile <name>` for each profile, saving to individual `.txt` files
4. **Settings export:** Copies `settings.json`, `keybindings.json`, and the `snippets/` folder
5. **Manifest generation:** Creates a JSON file containing all profile information in a machine-readable format

### Sample output

```plaintext
=== VS Code Profile Export ===
Output: C:\Users\chriskyfung\Documents\vscode-export-2026-07-21

[✓] Saved storage.json
[✓] Found profiles: Default, Python, Work

  Exporting: Default
    42 extensions found
  Exporting: Python
    15 extensions found
  Exporting: Work
    28 extensions found

Saving global settings...
  [✓] settings.json
  [✓] keybindings.json
  [✓] snippets/

[✓] Generated manifest.json

=== Summary ===
  Default: 42 extensions
  Python: 15 extensions
  Work: 28 extensions

Export complete: C:\Users\chriskyfung\Documents\vscode-export-2026-07-21
```

### Sample `manifest.json` Output

The generated manifest is human-readable and machine-parseable for reinstalls:

```json
{
  "profiles": [
    {
      "name": "Default",
      "extension_count": 12,
      "extensions": [
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "..."
      ]
    },
    {
      "name": "Python",
      "extension_count": 8,
      "extensions": [
        "ms-python.python",
        "ms-toolsai.jupyter",
        "..."
      ]
    }
  ]
}
```

This `manifest.json` can also drive your restore script directly — just parse `profiles[].name` and `profiles[].extensions` to reinstall everything in one pass.

### Troubleshooting

| Issue                                 | Solution                                                    |
|---------------------------------------|-------------------------------------------------------------|
| `'code' is not recognized`            | Ensure the VS Code CLI is installed and accessible via PATH |
| `Access denied` creating output files | Close VS Code or any applications using the settings files  |
| `snippets/` folder missing            | VS Code creates this folder only when snippets are saved    |

---

### License

The project is licensed under the GPLv3 License. See the [License](/LICENSE) file for details.
