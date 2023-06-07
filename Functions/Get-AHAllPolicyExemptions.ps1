<#
    .DESCRIPTION
        This function gets all policy exemptions for all management groups, subscriptions, resource groups, and individual resources.
    .EXAMPLE
        Get-AHAllPolicyExemptions
        Gets all policy exemptions for all management groups, subscriptions, resource groups, and individual resources.
#>
function Get-AHAllPolicyExemptions {
    [CmdletBinding()]
    param ( )
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
