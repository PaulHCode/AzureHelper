# Overview

This module is comprised of useful cmdlets I have written to make my work easier. If you have ideas for additional features please let me know.

## Helper Functions

> These functions are ones that I use just to make my daily work easier

- Invoke-AzureCommand - Runs a script block against every subscription using -AllSubscriptions
- Select-AHSubscription -GUI to show which subscriptions I have access to then Set-AzContext to it
- Move-AHVMFromDedicatedHost - Moves a VM from a dedicated host
- Move-AHVMToDedicatedHost - Moves a VM to the specified dedicated host
- New-AHRoute - Add UDR for access to Azure Endpoints - GUI only using Out-GridView passthrough
- Remove-AHVM - This function is used to remove any Azure VMs as well as any attached disks. By default, this function creates a job due to the time it takes to remove an Azure VM.
- Resize-AHVM - resizes a VM
- Get-AHResourceCost - Gets the cost of a resource over the specified number of previous days
- Get-AHSavingsReport - Retrieves a list of changes that can be made to a subscription to cut costs
- Get-AHStaleUsers - Gets a list of stale AAD users (mostly copied from Aaron Guilmette with a few tweaks)

## Inventory Functions

- Get-AHAppliedPolicies - Gets the Azure Policies applied to \$ResourceId that Deny or DeployIfNotExists
- Get-AHBackedUpVMs - Gets all backed up VMs and their backup status
- Get-AHCostSavingsReport - Reports potential cost savings including unused resources
- Get-AHVMBackupStatus - Gets all VMs and their backup status
- Get-AHDBAllocation - Gets every Azure DB and returns key information to help make choices about reducing the cost of your SQL DBs.
- Get-AHExtraDiskGBPaidFor - Gets every disk and returns how much space is paid for but not allocated.
- Get-AHNonHubWindowsServers - Gets a list of Windows servers not using Azure Hybrid Use Benefits.
- Get-AHUnusedDisks - Gets all unused disks
- Get-AHUnusedNICs - Gets all unused Network cards
- Get-AHUnusedPIPs - Gets all unused Public IPs
- Get-AHVMDomainStatus - Queries every VM in an Azure subscription to which are joined to the same domain as the VM running this command.
- Remove-AHVM - removes a VM and associcated resources like NIC, disks, etc.

## Azure Policy and Regulatory Compliance Reporting

- Get-AHSecurityReport - Gets a report of non-compliant resources for each policy selected
- Get-AHComplianceReport - Returns a list of resources and compliance status with the policies selected.
- Get-AHNonCompliantResources - Prompts the user to select an Azure Policy then returns a list of resources that are not comnpliant with the policy.
- Get-AHPolicyAssignment - Gets a list of all Azure Policy assignments
- Get-AHPolicyByResource - Gets all resources that Azure Policies are applied to
- Get-AHRegulationCompliance - Gets regulatory compliance of the regulation specified and generates a report showing compliance with each control in the regulation.
- Get-AHResourceCompliance - Prompts the user to select an Azure Policy then returns a list of resources that are not comnpliant with the policy.
  > These functions select policies to determine what Get-AHSecurityReport reports on
- Add-AHPolicyToReport - Adds a PolicyID to the list of a Azure policies to be analyzed.
- Remove-AHPolicyToReport - Removes a PolicyID from the list of a Azure policies to be analyzed.
- Get-AHPolicyToReport - List the Azure policies to be analyzed.
