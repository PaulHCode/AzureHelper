Function Get-AHAppliedPolicies {
    <#
.SYNOPSIS
    Gets the Azure Policies applied to $ResourceId that Deny or DeployIfNotExists
.DESCRIPTION
    Gets the Azure Policies applied to $ResourceId that Deny or DeployIfNotExists
.PARAMETER ResourceId
    Define the resource to be analyzed
.EXAMPLE
    Get-AHAppliedPolicies -ResourceId '/subscriptions/e533f641-62b6-47e6-95a8-b0a850169e3c/resourceGroups/policytest/providers/Microsoft.Compute/virtualMachines/TestWindowsVM'

    Lists all Azure Policies applied to the ResourceId
.EXAMPLE
    Get-AHAppliedPolicies -ResourceId '/subscriptions/e533f641-62b6-47e6-95a8-b0a850169e3c/resourceGroups/policytest/providers/Microsoft.Compute/virtualMachines/TestWindowsVM'| Where{$_.policydefinitionaction -in @('deny','deployifnotexists')}

    Lists all Azure Policies that Deny or DINE applied to the ResourceId
.INPUTS
    String
.OUTPUTS
    Selected.Microsoft.Azure.Commands.ResourceManager.Cmdlets.Implementation.Policy.PsPolicyAssignment
.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $ResourceId
    )
    #I make the terrible assumption that the ResourceId is valid... oh well
    $sub = ($ResourceId -split ('/'))[2] 
    If ((az account show | ConvertFrom-Json).id -ne $sub) {
        try { az account set $sub }
        catch { throw }
    }
    If ($((Get-AzContext).Subscription.Id -ne $sub)) {
        try { Set-AzContext -SubscriptionId $sub }
        catch { throw }
    }

    $Policies = az policy state list --resource $ResourceId | ConvertFrom-Json #| Where-Object { $_.PolicyDefinitionAction -in @('deny', 'deployifnotexists') }

    ForEach ($Policy in $Policies) {
        Get-AzPolicyAssignment -Id $($Policy.PolicyAssignmentId) | 
        Select-Object @{N = 'DisplayName'; E = { $_.Properties.DisplayName } }, `
        @{N = 'PolicyDefinitionAction'; E = { $Policy.PolicyDefinitionAction } }, `
        @{N = 'Parameters'; E = { $_.Properties.Parameters } }, `
        @{N = 'EnforcementMode'; E = { $_.Properties.EnforcementMode } }, `
            ResourceId, SubscriptionId, PolicyAssignmentId, `
        @{N = 'PolicyDefinitionId'; E = { $_.Properties.PolicyDefinitionId } } 
    } 

} 