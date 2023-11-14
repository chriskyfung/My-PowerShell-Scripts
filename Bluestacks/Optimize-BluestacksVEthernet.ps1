<#
.SYNOPSIS
  Optimize Virtual Ethernet Adapter Performance for BlueStacks with Hyper-V Enabled

.DESCRIPTION
  This script will perform the following operations:
  1. Disable Large Send Offload (LSO), Receive side scaling (RSS) and eceive segment coalescing (RSC) for all Virtual Ethernet Adapters.
  2. Disable TCP/IPv6, File and Printer Sharing for Microsoft Networks, Link-Layer Topology Discovery Mapper I/O Driver and Link-Layer Topology Discovery Responder for the network adapter named "vEthernet (BluestacksNxt)".
  3. Set the Receive Side Scaling (RSS) parameters for the network adapter named "vEthernet (BluestacksNxt)", -NumberOfReceiveQueues 1 -Profile "NUMAStatic" -MaxProcessors 4

.OUTPUTS
  None

.NOTES
  Version:        1.1.4
  Author:         chriskyfung
  Original from:  https://gist.github.com/chriskyfung/073e0fbfeeb7b5c1e7d13dc94d638bb9
#>

#Requires -Version 3.0
#Requires -PSEdition Desktop
#Requires -RunAsAdministrator

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

  Write-Host "An error occurred:"
  Write-Host $_

}
