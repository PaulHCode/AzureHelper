Function Add-AHPolicyToReport {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "CLI",Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $PolicyDefinitionID,

        [Parameter(ParameterSetName = "GUI",Mandatory = $true)]
        [switch]
        $GUI
    )
    If ($GUI) {
        ((Get-AzPolicyDefinition | Select @{N='DisplayName';E={$_.Properties.DisplayName}}, @{N='PolicyType';E={$_.Properties.PolicyType}}, @{N='Description';E={$_.Properties.Description}}, @{N='ResourceId';E={$_.ResourceId}} | Out-GridView -PassThru -Title "Select the Policies to add to the report").ResourceId) | ForEach-Object { $Script:PolicyDefinitionIDs += $_ }
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