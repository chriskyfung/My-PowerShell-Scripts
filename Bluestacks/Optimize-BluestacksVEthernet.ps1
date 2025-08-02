<#
.SYNOPSIS
  Optimizes the "vEthernet (BluestacksNxt)" adapter for BlueStacks performance.

.DESCRIPTION
  This script optimizes the virtual Ethernet adapter used by BlueStacks when Hyper-V is enabled.
  It performs the following actions:
  - Disables other vEthernet adapters.
  - Disables LSO, RSS, and RSC on all vEthernet adapters.
  - Disables IPv6 and other unnecessary bindings on the BlueStacks adapter.
  - Configures RSS settings for the BlueStacks adapter.
  - Displays the final configuration of the adapter.

.EXAMPLE
  PS C:\> .\Optimize-BluestacksVEthernet.ps1
  Runs the optimization script. This script requires administrator privileges.

.OUTPUTS
  String. The script outputs the final configuration of the network adapters to the console.

.NOTES
  Version:        1.2.0
  Author:         chriskyfung, Gemini
  License:        GNU GPLv3 license
  Creation Date:  2023-06-24
  Last Modified:  2025-08-01
  Original from:  https://gist.github.com/chriskyfung/073e0fbfeeb7b5c1e7d13dc94d638bb9
#>

#Requires -Version 3.0
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Try {

  # Disable all Virtual Ethernet Adapters except the Virtual Ethernet Adapter for BlueStacks
  Get-NetAdapter -Name "vEthernet *" | Where-Object Name -inotmatch "BluestacksNxt" | Disable-NetAdapter -Confirm:$false
  # Ensure the Virtual Ethernet Adapter for BlueStacks is active
  Enable-NetAdapter -Name "vEthernet (BluestacksNxt)"

  # Disable Large Send Offload (LSO) for all Virtual Ethernet Adapters. Learn more: https://learn.microsoft.com/en-us/windows-hardware/drivers/network/performance-in-network-adapters#supporting-large-send-offload-lso
  Disable-NetAdapterLso -Name "vEthernet (*)"
  # Disable Receive side scaling (RSS) for all Virtual Ethernet Adapters. Learn more: https://learn.microsoft.com/en-us/windows-hardware/drivers/network/introduction-to-receive-side-scaling?source=recommendations
  Disable-NetAdapterRss -Name "vEthernet (*)"
  # Disable Receive segment coalescing (RSC) for all Virtual Ethernet Adapters. Learn more: https://learn.microsoft.com/en-us/windows-hardware/drivers/network/overview-of-receive-segment-coalescing
  Disable-NetAdapterRsc -Name "vEthernet (*)"

  # Disable specific adapter bindings on vEthernet (BluestacksNxt). Learn more: https://learn.microsoft.com/en-us/powershell/module/netadapter/disable-netadapterbinding
  Disable-NetAdapterBinding -Name "vEthernet (BluestacksNxt)" -ComponentID @("ms_tcpip6", "ms_server", "ms_lltdio", "ms_rspndr")
  # Set Sets the RSS properties on vEthernet (BluestacksNxt). Learn more: https://learn.microsoft.com/en-us/powershell/module/netadapter/set-netadapterrss
  Set-NetAdapterRss -Name "vEthernet (BluestacksNxt)" -NumberOfReceiveQueues 1 -Profile "NUMAStatic" -MaxProcessorNumber 3 -MaxProcessors 4

  # List all acitve network adapters
  (Get-NetAdapter | Where-Object status -eq "up" | Format-List -Property Name, InterfaceDescription, Status | Out-String).TrimEnd()

  Write-Host "`nvEthernet (BluestacksNxt) - Large Send Offload (LSO):`n"
  (Get-NetAdapterLso -Name "vEthernet (BluestacksNxt)" | Format-List -Property "*Enabled" | Out-String).Trim()

  Write-Host "`nvEthernet (BluestacksNxt) - Receive Side Scaling (RSS):`n"
  (Get-NetAdapterRss -Name "vEthernet (BluestacksNxt)" | Format-List -Property "Enabled" | Out-String).Trim()

  Write-Host "`nvEthernet (BluestacksNxt) - Receive Segment Coalescing (RSC):`n"
  (Get-NetAdapterRsc -Name "vEthernet (BluestacksNxt)" | Format-List -Property "*Enabled" | Out-String).Trim()

  Write-Host "`n"

} Catch {
    Write-Error "An error occurred during network adapter optimization: $($_.Exception.Message)"
    # Exit with a non-zero status code to indicate failure
    exit 1
}
