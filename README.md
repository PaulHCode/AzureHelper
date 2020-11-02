# Overview

This module is comprised of useful cmdlets I have written to make my work easier. If you have ideas for additional features please let me know.

## Helper Functions

> These functions are ones that I use just to make my daily work easier

- Invoke-AzureCommand - Runs a script block against every subscription using -AllSubscriptions
- Select-AHSubscription -Find which subscriptions I have access to then Set-AzContext to it
- New-AHRoute - Add UDR for access to Azure Endpoints - GUI only using Out-GridView passthrough
- Get-AHBackedUpVMs - Gets all backed up VMs and their backup status
- Get-AHVMBackupStatus - Gets all VMs and their backup status
- Remove-AHVM - removes a VM and associcated resources like NIC, disks, etc.
- Resize-AHVM - resizes a VM
- Get-UnusedDisks - Gets all unused disks
- Get-UnusedNICs - Gets all unused Network cards
- Get-UnusedPIPs - Gets all unused Public IPs

## Azure Policy Compliance Reporting

- Get-AHSecurityReport - Gets a report of non-compliant resources for each policy selected
  > These functions select policies to determine what Get-AHSecurityReport reports on
- Add-AHPolicyToReport
- Remove-AHPolicyToReport
- Get-AHPolicyToReport

## Azure Cost Savings Reporting

- Get-AHCostSavingsReport - Reports potential cost savings including unused resources
