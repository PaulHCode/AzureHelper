Function Remove-AHPolicyToReport {
        <#
.SYNOPSIS
    Removes a PolicyID from the list of a Azure policies to be analyzed.
.DESCRIPTION
    Remove-AHPolicyToReport removes an Azure Policy from the list of policies
    to be analyzed by other AzureHelper cmdlets.
.PARAMETER PolicyDefinitionID
    Define the policy to be removed by the PolicyDefinitionID
.PARAMETER All
    Remove all PolicyDefinitionIds
.EXAMPLE
    Remove-AHPolicyToReport -PolicyDefinitionID '/providers/Microsoft.Authorization/policyDefinitions/0015ea4d-51ff-4ce3-8d8c-f3f8f0179a56'
.INPUTS
    String
.OUTPUTS
.NOTES
    Author:  Paul Harrison
.LINK
    Get-AHSecurityReport
    Add-AHPolicyToReport
    Get-AHPolicyToReport
    Get-AHSecurityReport
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $PolicyDefinitionID,

        [switch]
        $All
    )
    If($All){
        $Script:PolicyDefinitionIDs = @()
    }
    ElseIf ($Null -eq $PolicyDefinitionID<# -or (Get-AzPolicyDefinition -Id $PolicyDefinitionID) -is [array]#>) { 
        #If a PolicyDefinitionID is passed at the CLI and is malformed then this will return an array and re-prompt the user for a correct value
        throw { "Invalid PolicyDefinitionID" }
    }
    Elseif ($Script:PolicyDefinitionIDs -notcontains $PolicyDefinitionID) {
        Throw { "The PolicyDefinitionID $PolicyDefinitionID is not in the list." }
    }
    Else {
        $Script:PolicyDefinitionIDs = $Script:PolicyDefinitionIDs -ne $PolicyDefinitionID
    }
}