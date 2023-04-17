<#
.Synopsis
   Exports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions
.DESCRIPTION
   Exports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions
.EXAMPLE
   Export-AHPolicySetDefinition -PolicySetDefinitionId '/providers/Microsoft.Management/managementGroups/TestManagementGroup0/providers/Microsoft.Authorization/policySetDefinitions/General Policies V2' -Force
.EXAMPLE
   
   I'm lazy, so if I want to export a ton of policy sets but I don't want to type out a bunch of stuff I use this
.NOTES
   You can use the following one-liner to help you find the policy set definition ID you want
   $MyPolicySets = Get-AzPolicySetDefinition | select @{N='DisplayName';E={$_.Properties.DisplayName}}, @{N='Description';E={$_.Properties.Description}}, resourceId | ogv -PassThru
   ($MyPolicySets).ResourceId | %{Export-AHPolicySetDefinition -PolicySetDefinitionId $_ -OutputDir 'C:\myPolicies'}
.PARAMETER PolicySetDefinitionId
   The PolicySet definition Id to export
.PARAMETER OutputDir
   The directory to write the policy set to - by default it writes to the current working directory
.PARAMETER Force
   Forces the overwriting of an existing policy set even if the folder already exists
#>
function Export-AHPolicySetDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
                $result = Get-AzPolicySetDefinition -id $_
                If ($result.GetType().Name -eq 'PsPolicySetDefinition' -or $result.GetType().BaseType.Name -eq 'Object') { $true }Else { $false }
            })]
        $PolicySetDefinitionId,
        [Parameter(Mandatory = $false)]
        [string]
        [ValidateScript({
                test-path $_
            })]
        $OutputDir = '.', #set to . by default and validate it is valid
        [Parameter(Mandatory = $false)]
        [int]
        [ValidateRange(10, 100)]
        $NumChars = 40,
        [switch]
        $Force #include to overwrite directory
        
    )
    
    begin {
        If ($PSVersionTable.PSVersion.Major -lt 7) {
            throw 'This cmdlet requires PowerShell 7 or greater'
        }
        $numchars = 40 #number of characters to use of the display name before truncating - we don't want 300 character file names
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
            If ([string]::IsNullOrEmpty($policySet.Properties.DisplayName)) {
                $folderName = $policySet.Name
            }
            Else {
                $folderName = If ($policySet.Properties.DisplayName.Length -le $numchars) { $policySet.Properties.DisplayName }else { $policySet.Properties.DisplayName.Substring(0, $numchars - 1) }
            }
            #$folderName += $policySet.Name
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
            $nonce = 0 #introduce a nonce in case the first $numChars of a policy description are identical
            ForEach ($item in $policySet.Properties.PolicyDefinitions) {
                
                #$fileName = If ($item.policyDefinitionReferenceId.Length -le $numchars) { $item.policyDefinitionReferenceId }else { $item.policyDefinitionReferenceId.Substring(0, $numchars - 1) }
                #$policy = Get-AzPolicyDefinition -id $item.policyDefinitionId
                #$proposedName = $policy.Properties.DisplayName# + $nonce
                #$fileName = If ($proposedName.Length + $($nonce.tostring().length) -le $numchars) { $proposedName + $nonce.tostring() }else { $proposedName.Substring(0, $numchars - 1 - $($nonce.ToString().Length)) + $nonce.ToString() }
                $fileName = If ($item.policyDefinitionReferenceId.Length -le $numchars) { $item.policyDefinitionReferenceId }else { $item.policyDefinitionReferenceId.Substring(0, $numchars - 1) }
                $filename = Remove-InvalidFileNameChars $filename
                $fileName += $item.policyDefinitionId.split('/')[-1] # just in case the first $numChars of the policyDefinitionReferenceId are the same on a bunch of policies in a policy set
                Export-AHPolicyDefinition -PolicyDefinitionId $item.policyDefinitionId | Out-File "$folderPath\$filename.json"
                $nonce += 1
            }
            #EndRegion
        }
    }
    
    end {
        
    }
}
