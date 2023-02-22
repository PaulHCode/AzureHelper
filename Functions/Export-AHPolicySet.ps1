<#
.Synopsis
   Exports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions
.DESCRIPTION
   Exports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions
.EXAMPLE
   Export-PolicySet -PolicySetDefinitionId '/providers/Microsoft.Management/managementGroups/TestManagementGroup0/providers/Microsoft.Authorization/policySetDefinitions/General Policies V2' -Force
.EXAMPLE
   Another example of how to use this cmdlet I'll put in later
.NOTES
   You can use the following one-liner to help you find the policy set definition ID you want
   Get-AzPolicySetDefinition | select @{N='Initiative';E={$_.Properties.DisplayName}}, resourceId | ogv -PassThru
.PARAMETER PolicySetDefinitionId
   The PolicySet definition Id to export
.PARAMETER OutputDir
   The directory to write the policy set to - by default it writes to the current working directory
.PARAMETER Force
   Forces the overwriting of an existing policy set even if the folder already exists
#>
function Export-AHPolicySet {
    [CmdletBinding()]
    param (
        [string]
        [ValidateScript({
                $result = Get-AzPolicySetDefinition -id $_
                If ($result.GetType().Name -eq 'PsPolicySetDefinition' -or $result.GetType().BaseType.Name -eq 'Object') { $true }Else { $false }
            })]
        $PolicySetDefinitionId,
        [string]
        [ValidateScript({
                test-path $_
            })]
        $OutputDir = '.', #set to . by default and validate it is valid
        [switch]
        $Force #include to overwrite directory
        
    )
    
    begin {
        $numchars = 30 #number of characters to use of the display name before truncating - we don't want 300 character file names
        #define helper function
        function Copy-Property {
            [CmdletBinding()]
            param([Parameter(ValueFromPipeline = $true)]$InputObject,
                $SourceObject,
                [string[]]$Property,
                [switch]$Passthru,
                [switch]$ForceLowercaseKeys)
               
            $passthruHash = @{Passthru = $passthru.IsPresent }
            
            $propHash = @{}
            $property | Foreach-Object {
                If ($ForceLowercaseKeys) {
                    $propHash += @{$_.ToLower() = $SourceObject.$_ }
                }
                Else {
                    $propHash += @{$_ = $SourceObject.$_ }
                }
            }
            $inputObject | Add-Member -NotePropertyMembers $propHash @passthruHash
        }
    }
    process {
        $policySets = Get-AzPolicySetDefinition -Id $PolicySetDefinitionId
        ForEach ($policySet in $policySets) {
            #Region Create folder for the initiative
            $folderName = If ($policySet.Properties.DisplayName.Length -le $numchars) { $policySet.Properties.DisplayName }else { $policySet.Properties.DisplayName.Substring(0, $numchars - 1) }
            $folderName += $policySet.Name
            $folderPath = Join-Path $OutputDir $folderName
            If (Test-Path $folderPath) {
                If ($Force) {
                    remove-item $folderPath -Force -Confirm:$false -Recurse
                }
                Else {
                    throw 'folder already exists'
                    return 1
                }
            }
            new-item -Path $folderPath -ItemType Directory | Out-Null
            #EndRegion

            #Region Export policy set definition
            $policySet.Properties.PolicyDefinitions | convertTo-Json -Depth 99 | out-file "$folderPath\$folderName-Policy.json" #export policy
            #EndRegion
            #Region Export Policy set parameters
            $policySet.Properties.Parameters | ConvertTo-Json -Depth 99 | out-file "$folderPath\$folderName-Parameters.json" # export parameters
            #EndRegion

            #Region Export each policy definition
            #I need to know exactly how to format each policy export first this will likely call another function that exports each policy definition
            #EndRegion
        }
    }
    
    end {
        
    }
}
