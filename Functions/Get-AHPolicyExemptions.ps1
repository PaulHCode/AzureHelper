<#
.SYNOPSIS
    Retrieves all policy exemptions for management groups and subscriptions in an Azure tenant.

.DESCRIPTION
    The Get-AHPolicyExemptions function retrieves all policy exemptions for management groups and subscriptions in an Azure tenant. The function first retrieves all management groups in the tenant and then retrieves all policy exemptions for each management group. Next, the function retrieves all subscriptions in the tenant and then retrieves all policy exemptions for each subscription. Finally, the function exports all policy exemptions to a JSON file.

.PARAMETER None
    This function does not accept any parameters.

.EXAMPLE
    PS C:\> Get-AHPolicyExemptions
    Retrieves all policy exemptions for management groups and subscriptions in an Azure tenant.

.EXAMPLE
    PS C:\> Get-AHPolicyExemptions | ConvertTo-JSON -Depth 99 | Out-File -FilePath 'C:\Temp\PolicyExemptions.json' -Encoding UTF8 -Force

.NOTES
    Author: Paul Harrison
    Date:   20231012
#>
function Get-AHPolicyExemptions {
    [CmdletBinding()]

    $policyExemptions = @()

    # Get all management groups in the tenant
    $managementGroups = Get-AzManagementGroup | ForEach-Object { Get-AzManagementGroup -Expand -Recurse -GroupName $_.Name }

    foreach ($managementGroup in $managementGroups) {
        Write-Verbose "Processing management group $($managementGroup.DisplayName)"

        # Get all policy exemptions for the management group
        $policyExemptions += Get-AzPolicyExemption -Scope $managementGroup.Id
    }

    # Get all subscriptions in the tenant
    $subscriptions = Get-AzSubscription | Where-Object { $_.state -eq 'Enabled' }

    foreach ($subscription in $subscriptions) {
        Set-AzContext -Subscription $subscription.Id -TenantId $subscription.TenantId | Out-Null
        Write-Verbose "Processing subscription $($subscription.Name)"
        # Get all policy exemptions for the subscription
        $policyExemptions += Get-AzPolicyExemption -IncludeDescendent
    }

    $policyExemptions 
}
