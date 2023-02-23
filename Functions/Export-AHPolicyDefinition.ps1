<#
.Synopsis
   Exports an Azure Policy  definition
.DESCRIPTION
   Exports an Azure Policy  definition
.EXAMPLE
   Export-AHPolicyDefinition -PolicyDefinitionId '/subscriptions/abcdefgh-asdf-1234-95a8-b0a850169e3c/providers/Microsoft.Authorization/policyDefinitions/george' | out-file .\MyPolicyNamedGeorge.json

   This example outputs george to a file 
.EXAMPLE
    Export-AHPolicyDefinition -PolicyDefinitionId '/subscriptions/abcdefgh-asdf-1234-95a8-b0a850169e3c/providers/Microsoft.Authorization/policyDefinitions/george'

    This example just shows me what george would look like on the screen
.NOTES
   I did not write Import-AHPolicyDefinition because you can just use the cmdlet New-AzPolicyDefinition that Microsoft wrote. The whole point of writing this export is so that the output is compatible with that cmdlet.

   I can then later import george into another tenant but maybe I want my policy to be named as frank there so I use the following
   New-AzPolicyDefinition -Name frank -DisplayName frank -Description frank -Policy .\MyPolicyNamedGeorge
.PARAMETER PolicyDefinitionId
   The Policy definition Id to export
#>
function Export-AHPolicyDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
                $result = Get-AzPolicyDefinition -id $_
                If ($result.GetType().Name -eq 'PsPolicyDefinition' -or $result.GetType().BaseType.Name -eq 'Object') { $true }Else { $false }
            })]
        $PolicyDefinitionId
    )
    begin {
        #$numchars = 30 #number of characters to use of the display name before truncating - we don't want 300 character file names
    }
    process {
        $original = Get-AzPolicyDefinition -id $PolicyDefinitionId

        $fixed = [pscustomobject]@{}
        $exclusions = @('ResourceId', 'ResourceName', 'ResourceType', 'SubscriptionId', 'Properties', 'PolicyDefinitionId')
        $properties = ($original | Get-Member -MemberType Properties).Name | Where-Object { $_ -notin $exclusions }
        Copy-Property -SourceObject $original -InputObject $fixed -Property $properties -ForceLowercaseKeys

        #add in type
        $fixed | Add-Member -NotePropertyName 'type' -NotePropertyValue 'Microsoft.Authorization/policyDefinitions'

        #still need to change PolicyRule to policyRule
        #copy all elements of _.Properties except PolicyRule
        $tempProperties = [pscustomobject]@{}
        $properties = ($original.Properties | Get-Member -MemberType Properties).Name | Where-Object { $_ -ne 'PolicyRule' }
        Copy-Property -SourceObject $($original.Properties) -InputObject $tempProperties -Property $properties -ForceLowercaseKeys #-Verbose
        #add back in policyRule with the corrected capitalization
        $tempProperties | Add-Member -NotePropertyName 'policyRule' -NotePropertyValue $original.Properties.PolicyRule
        #add Properties back onto the main object
        $fixed | Add-Member -NotePropertyName 'properties' -NotePropertyValue $tempProperties
        #add back in id instead of PolicyDefinitionId
        $fixed | Add-Member -NotePropertyName 'id' -NotePropertyValue $original.PolicyDefinitionId

        $fixed | ConvertTo-Json -Depth 99
    }
    end {
        
    }

}


