# Windows PowerShell Scripts

This folder contains PowerShell scripts for Windows system administration and maintenance tasks.

## Requirements

- Windows 10 or 11
- PowerShell 5.1 or higher
- Administrator privileges (required by all scripts in this folder)

## Scripts

### Optimize-DockerDesktopVHD.ps1

Optimizes the Docker Desktop virtual hard disk (VHDX) to reclaim unused space.

This script shrinks the Docker Desktop VHDX file by compacting it to remove unused blocks. Before running, it will:
1. Check if Docker Desktop is running
2. Prompt for confirmation to stop Docker Desktop
3. Use `Optimize-VHD` cmdlet to compact the VHDX file

**Usage:**

```powershell
# Use default VHDX path
.\Optimize-DockerDesktopVHD.ps1

# Specify custom VHDX path
.\Optimize-DockerDesktopVHD.ps1 -VhdPath "D:\Docker\docker_data.vhdx"

# Preview without executing
.\Optimize-DockerDesktopVHD.ps1 -WhatIf

# Verbose output
.\Optimize-DockerDesktopVHD.ps1 -Verbose
```

**Parameters:**

| Parameter  | Type   | Default | Description                                      |
| ---------- | ------ | ------- | ------------------------------------------------ |
| `-VhdPath` | String | Auto    | Path to the Docker VHDX file                     |
| `-Mode`    | String | Full    | Optimization mode: `Full`, `Retain`, or `None`   |
| `-WhatIf`  | Switch | -       | Shows what would happen without executing        |
| `-Verbose` | Switch | -       | Displays detailed operation messages             |

**Default VHDX Location:**

```
%LocalAppData%\Docker\wsl\disk\docker_data.vhdx
```

**Example Output:**

```
Initial VHDX file size: 10240 MB
Docker Desktop is currently running. It must be stopped before optimizing the VHDX file.

Process: Docker Desktop
PID: 12345

Do you want to continue?
[Y] Yes  [N] No  [?] Help

Docker Desktop has been stopped.
Optimizing VHDX file in Full mode...
Final VHDX file size:   5120 MB
Space reclaimed:        5120 MB (50.00%)
Docker Desktop VHDX optimization completed successfully.
```

---

## Running the Scripts

1. Open PowerShell as Administrator
2. Navigate to this folder:

   ```powershell
   cd "...\My PowerShell Scripts\Windows"
   ```
3. Run the desired script:

   ```powershell
   .\ScriptName.ps1
   ```

> **Note:** If you encounter an execution policy error, you may need to allow script execution:
>
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## License

All scripts in this folder are licensed under the [GNU GPLv3 License](../LICENSE).
