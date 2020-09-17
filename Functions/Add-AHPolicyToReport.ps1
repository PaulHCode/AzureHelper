Function Add-AHPolicyToReport {
    <#
.SYNOPSIS
    Adds a PolicyID to the list of a Azure policies to be analyzed.
.DESCRIPTION
    Add-AHPolicyToReport adds an Azure Policy to the list of policies
    to be analyzed by other AzureHelper cmdlets.
.PARAMETER PolicyDefinitionID
    Define the policy to be added by the PolicyDefinitionID
.PARAMETER GUI
    Select the PolicyDefinitionIds to add though the GUI
.PARAMETER AllCustom
    Add all custom PolicyDefinitionIds
.EXAMPLE
    Add-AHPolicyToReport -PolicyDefinitionID '/providers/Microsoft.Authorization/policyDefinitions/0015ea4d-51ff-4ce3-8d8c-f3f8f0179a56'
.EXAMPLE
    Add-AHPolicyToReport -AllCustom
.EXAMPLE
    Add-AHPolicyToReport -GUI
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
        [Parameter(ParameterSetName = "CLI", Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $PolicyDefinitionID,

        [Parameter(ParameterSetName = "GUI", Mandatory = $true)]
        [switch]
        $GUI,

        [parameter(ParameterSetName = "AllCustom", Mandatory = $true)]
        [switch]
        $AllCustom
    )
    If ($AllCustom) {
        (Get-AzPolicyDefinition -Custom).ResourceId | ForEach-Object { $Script:PolicyDefinitionIDs += $_ }
    }
    ElseIf ($GUI) {
        If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
            throw "The GUI switch can only be used on a local host and cannot be used from a remote session."
        }
        elseif ((get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
            throw "The GUI switch can only be used on a local host and cannot be used from Azure Cloud Shell."
        }
        ((Get-AzPolicyDefinition | Select-Object @{N = 'DisplayName'; E = { $_.Properties.DisplayName } }, @{N = 'PolicyType'; E = { $_.Properties.PolicyType } }, @{N = 'Description'; E = { $_.Properties.Description } }, @{N = 'ResourceId'; E = { $_.ResourceId } } | Out-GridView -PassThru -Title "Select the Policies to add to the report").ResourceId) | ForEach-Object { $Script:PolicyDefinitionIDs += $_ }
    }
    ElseIf ($Null -eq $PolicyDefinitionID -or (Get-AzPolicyDefinition -Id $PolicyDefinitionID) -is [array]) { 
        #If a PolicyDefinitionID is passed at the CLI and is malformed then this will return an array and re-prompt the user for a correct value
        throw { "Invalid PolicyDefinitionID" }
    }
    Elseif ($Script:PolicyDefinitionIDs -contains $PolicyDefinitionID) {
        Throw { "The PolicyDefinitionID $PolicyDefinitionID is already in the list." }
    }
    Else {
        $Script:PolicyDefinitionIDs += $PolicyDefinitionID
    }
}