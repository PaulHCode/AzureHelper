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
    .EXAMPLE
        $Exemptions = Get-AHAllPolicyExemptions
        $Exemptions.Properties | select displayName, description | export-csv -Path C:\temp\Exemptions.csv -NoTypeInformation
        Gets the displayName and Description for all policy exemptions then exports them to a CSV file. I used this to audit the policy exemptions to make sure all entries were reasonable.
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
        $exemptions = @()
    }
    Process {
        $managementGroups = Get-AzManagementGroup #| ForEach-Object { Get-AzManagementGroup -Expand -Recurse -GroupName $_.Name } 
        #Get management group exemptions
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
