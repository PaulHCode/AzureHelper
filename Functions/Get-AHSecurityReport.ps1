
Function Get-AHSecurityReport {
    <#
.SYNOPSIS
    Retrieves a list of changes that can be made to a subscription to be more secure.

.DESCRIPTION
    Get-SavingsReport is a function that compiles a list of changes for each subscription
    to cut costs utilizing other functions in the AzureHelper module. The list of items
    that is checks is defined in $Script:PolicyDefinitionIDs and is accessed through 
    commands found in the Related section 

.PARAMETER AllSubscriptions
    Run this command against all subscriptions.

.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.

.PARAMETER ReportPath
    Specifies the path the report should be output to

.EXAMPLE
    Get-AHSecurityReport -AllSubscriptions

.INPUTS
    String

.OUTPUTS
    Selected.Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource

.NOTES
    Author:  Paul Harrison

.LINK
        Add-AHPolicyToReport
        Get-AHPolicyToReport
        Remove-AHPolicyToReport
        Get-AHComplianceReport
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

                Get-AHNonCompliantResources -PolicyDefinitionID $PolicyId | Export-Csv $ReportName -NoTypeInformation
            }
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }

}
