<#
    .DESCRIPTION
        This function gets all policy exemptions for all management groups, subscriptions, resource groups, and individual resources.
    .EXAMPLE
        Get-AHAllPolicyExemptions
        Gets all policy exemptions for all management groups, subscriptions, resource groups, and individual resources.
    .EXAMPLE
        $Exemptions = Get-AHAllPolicyExemptions
        Gets all policy exemptions
    .EXAMPLE
        $Exemptions = Get-AHAllPolicyExemptions | Where{$_.Properties.PolicyDefinitionReferenceIds.Count -eq 0}
        Gets all policy exemptions then returns the ones that are applied to all policies, not just a subset of the policies within the .
    .EXAMPLE
        $Exemptions = Get-AHAllPolicyExemptions | Where{$_.Properties.ExpiresOn -lt [datetime]::Now}
        Gets all policy exemptions then returns the ones that have expired.
    .EXAMPLE
        $Exemptions = Get-AHAllPolicyExemptions | Where{$_.Properties.ExpiresOn -gt ([datetime]::Now).AddDays(365) -or '' -eq $_.Properties.ExpiresOn}
        Gets all policy exemptions then returns the ones that will expire over 1 year from now or have no expiration date.
#>
function Get-AHAllPolicyExemptions {
    [CmdletBinding()]
    param ( 
        <# #Maybe I'll add in switches to make it easier later, until then there are examples
        [switch]
        $AppliedToAllPolicies,
        [switch]
        $ExcludeExpired,
        [switch]
        $IncludeExpired,
        [switch]
        $something
#>
    )
    Begin {

    }
    Process {

        $managementGroups = Get-AzManagementGroup #| Where{$_.DisplayName -eq 'Enterprise Policy'}
        #Get management group exemptions
        $exemptions = @()
        ForEach ($managementGroup in $managementGroups) {
            $exemptions += Get-AzPolicyExemption -Scope $managementGroup.Id
        }
        #Get subscription exemptions
        $exemptionScriptBlock = {
            Get-AzPolicyExemption -IncludeDescendent
        }
        $exemptions += Invoke-AzureCommand -ScriptBlock $exemptionScriptBlock -AllSubscriptions
    }
    End {
        $exemptions
    }
}







<#
$managementGroups = Get-AzManagementGroup #| Where{$_.DisplayName -eq 'Enterprise Policy'}
#Get management group exemptions
$exemptions = @()
ForEach ($managementGroup in $managementGroups) {
    $exemptions += Get-AzPolicyExemption -Scope $managementGroup.Id
}
#Get subscription exemptions
$exemptionScriptBlock = {
    Get-AzPolicyExemption -IncludeDescendent
}
$exemptions += Invoke-AzureCommand -ScriptBlock $exemptionScriptBlock -AllSubscriptions

$exemptions
#>










<#
$exemptionSummary = ForEach ($exemption in $exemptions) {
    If ($exemption.ResourceId -like "/subscriptions/*") {
        $exemptionScope = "SubOrLower"
    }
    ElseIf ($exemption.ResourceId -like "/providers/Microsoft.Management/managementGroups/*") {
        $exemptionScope = "ManagementGroup"
    }
    Else {
        $exemptionScope = "Unknown"
    }
    [pscustomobject]@{
        DisplayName          = $exemption.Properties.DisplayName
        PolicyExemptionCount = $exemption.Properties.PolicyDefinitionReferenceIds.Count
        Scope                = $exemptionScope
        ExpirationDate       = $exemption.Properties.ExpiresOn
        Description          = $exemption.Properties.Description
    }
}
#>

#$assignment = get-azpolicyassignment | Where{$_.properties.displayname -eq 'NIST SP 800-53 Rev. 4' -and $_.PolicyAssignmentId -like "*$($managementGroup.ResourceId)*"}
#$exemptions = get-azpolicyExemption -policyAssignmentIdFilter $assignment.ResourceId
