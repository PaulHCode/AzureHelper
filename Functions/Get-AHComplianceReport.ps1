Function Get-AHComplianceReport {
    <#
.SYNOPSIS
    Returns a list of resources and compliance status with the policies selected.
.DESCRIPTION
    Get-AHComplianceReport returns a list of resources and compliance status with
    the policies selected.  Check the LINK section for cmdlets to change which policies
    to report on.  
.PARAMETER AllSubscriptions
    Run this command against all subscriptions.
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.PARAMETER PolicyDefinitionId
    Specifies the PolicyDefinitionId of the policy to check for compliance against.
.EXAMPLE
    Get-AHComplianceReport -AllSubscriptions
.EXAMPLE
    Get-AHComplianceReport -AllSubscriptions | Export-Csv NonCompliantResources-Policy1.csv -NoTypeInformation
.EXAMPLE
    Get-AHComplianceReport -AllSubscriptions -PolicyDefinitionID '/providers/Microsoft.Authorization/policyDefinitions/34c877ad-507e-4c82-993e-3452a6e0ad3c' | Export-Csv .\StorageAccountsShouldRestrictNetworkAccess2.csv -NoTypeInformation
.INPUTS
    String
.OUTPUTS
    Selected.Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource
.NOTES
    Author:  Paul Harrison
.LINK
    Get-AHSecurityReport
    Add-AHPolicyToReport
    Get-AHPolicyToReport
    Remove-AHPolicyToReport
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,

        [Parameter(ValueFromPipeline = $true)]
        $Subscription,

        [string]
        $ReportPath = ".\"
    )
    begin {
        Test-AHEnvironment
        #Validate there are PolicyIDs defined to run against
        If ($Null -eq $Script:PolicyDefinitionIDs) {
            throw { "No PolicyDefinitionIDs defined.  Use Add-AHPolicyToReport to add additional policies." }
        }
        #validate ReportPath here
        If (!(Test-Path $ReportPath)) {
            Throw("Invalid Path")
        }
        Else {
            $ReportPath = (Convert-Path $ReportPath) + '\' 
        }

        $MyScriptBlock = {
            ForEach ($PolicyId in $Script:PolicyDefinitionIDs) {
                $PolicyName = (Get-AzPolicyDefinition -Id $PolicyId).Properties.Displayname.replace(' ', '')
                If ($PolicyName.length -gt 35) {
                    $PolicyName = $PolicyName.substring(0, 35)
                }
                $ReportName = $ReportPath + (Get-AzContext).name.split('(')[0].replace(' ', '') + '-Security-' + $PolicyName + '.csv'
                Get-AHResourceCompliance -PolicyDefinitionID $PolicyId -Compliance NonCompliant | Export-Csv $ReportName -NoTypeInformation
            }
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}