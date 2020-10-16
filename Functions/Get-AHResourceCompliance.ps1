Function Get-AHResourceCompliance {
    <#
.SYNOPSIS
    Prompts the user to select an Azure Policy then returns a list of resources 
    that are not comnpliant with the policy.
.DESCRIPTION
    Get-AHResourceCompliance is a function that returns a list of resources that 
    are not compliaint with the policy that the user selects.  
.PARAMETER AllSubscriptions
    Run this command against all subscriptions.
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.PARAMETER PolicyDefinitionId
    Specifies the PolicyDefinitionId of the policy to check for compliance against.
.EXAMPLE
    Get-AHResourceCompliance -AllSubscriptions
.EXAMPLE
    Get-AHResourceCompliance -AllSubscriptions | Export-Csv NonCompliantResources-Policy1.csv -NoTypeInformation
.EXAMPLE
    Get-AHResourceCompliance -AllSubscriptions -PolicyDefinitionID '/providers/Microsoft.Authorization/policyDefinitions/34c877ad-507e-4c82-993e-3452a6e0ad3c' | Export-Csv .\StorageAccountsShouldRestrictNetworkAccess2.csv -NoTypeInformation
.INPUTS
    String
.OUTPUTS
    Selected.Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource
.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
    
        [Parameter]
        $Subscription,

        [parameter(ValueFromPipeline = $true)]
        $PolicyDefinitionID,

        [string]    
        [ValidateSet('NonCompliant', 'Compliant')]
        $Compliance = 'NonCompliant'
    )
    begin {
        Test-AHEnvironment

        If ($Null -eq $PolicyDefinitionID) {
            $PolicyDefinitionID = (Get-AzPolicyDefinition | Select-Object * -ExpandProperty Properties | Out-GridView -PassThru -Title "Select the Policy to check for compliance.").ResourceId
        }
        ElseIf ((Get-AzPolicyDefinition -Id $PolicyDefinitionID) -is [array]) {
            #If a PolicyDefinitionID is passed at the CLI and is malformed then this will return an array and re-prompt the user for a correct value
            $PolicyDefinitionID = @()
        }
        While ($PolicyDefinitionID -is [array]) {
            Write-Warning "Only one Policy may be selected at a time."
            #$PolicyDefinitionID = (Get-AzPolicyDefinition | Select-Object * -ExpandProperty Properties | Out-GridView -PassThru  -Title "Select the Policy to check for compliance.").ResourceId
        }
        $MyScriptBlock = {
            Get-AzPolicyState -Filter "PolicyDefinitionId eq '$PolicyDefinitionID' AND ComplianceState eq '$Compliance'" |  Get-AzResource | Select-Object @{N = "Subscription"; E = { (Get-AzContext).Subscription.Name } }, ResourceGroupName, ResourceName, ResourceId
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}