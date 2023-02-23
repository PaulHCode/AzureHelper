<#
I'm not sure if this is worth writing yet since it is pretty easy to use:

New-AzPolicySetDefinition -PolicyDefinition <PolicySetDefinition JSON> -Parameter <PolicySetParameters JSON> -Name <Name> -Description <Description>

The only reasons I'm considering writing this is because: 
- the export's policyDefinitionIds are going to reference the source locations instead of the destination locations so I could help the user through this
- I could automatically import all necessary policy definitions for the policy set

Parameters
        - PolicySetDefinition JSON
        - PolicySetParameters JSON
        - Name
        - Description
        - Where to import the policy definition to (management group name or subscription name)


#>



<#
$NewManagementGroup = 'TestManagementGroup0'
$temp = Get-Content '.\General Policies V2\General Policies V2-Policy.json' -Raw | convertfrom-json
$NewPolicy = ForEach ($i in $temp) {
    If ($i.PolicyDefinitionId -like '*/managementGroups/*') {
        #get managementGroup Name then replace it
        $arr = $i.PolicyDefinitionId.split('/')
        $managementGroupIndex = $arr.IndexOf('managementGroups') + 1
        $arr[$managementGroupIndex] = $NewManagementGroup
        $NewPolicyDefinitionId = $arr -join ('/')
        $i.PolicyDefinitionId = $NewPolicyDefinitionId
        $i
    }
    Else {
        $i
    }
}
$NewPolicy | ConvertTo-Json -Depth 99 | Out-File '.\General Policies V2\test.json'
#New-AzPolicySetDefinition -PolicyDefinition '.\General Policies V2\General Policies V2-Policy.json' -Parameter '.\General Policies V2\General Policies V2-Parameters.json' -Name 'Frank' -Description 'Frank' -ManagementGroupName 'TestManagementGroup0'
New-AzPolicySetDefinition -PolicyDefinition '.\General Policies V2\test.json' -Parameter '.\General Policies V2\General Policies V2-Parameters.json' -Name 'Frank' -Description 'Frank' -ManagementGroupName 'TestManagementGroup0'

#>









<#
.Synopsis
   Imports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions
.DESCRIPTION
   Imports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions.
   This will overwrite the PolicySetDefinitionFile with the proper ManagementGroupName specified instead of whatever management group is currently there from the export.
   This command assumes any necessary definitions are located in the same directory as the PolicySetDefinitionFile
.EXAMPLE
   Import-AHPolicySetDefinition -PolicySetDefinitionId '/providers/Microsoft.Management/managementGroups/TestManagementGroup0/providers/Microsoft.Authorization/policySetDefinitions/General Policies V2' -Force
.EXAMPLE
   Another example of how to use this cmdlet I'll put in later
.NOTES
   
.PARAMETER PolicySetDefinitionFile
   The PolicySet definition file to import
.PARAMETER PolicySetParameterFile
   The PolicySet parameter file to import
.PARAMETER IncludeMissingPolicyDefinitions
   Imports the policy definitions required for the policy set if they don't already exist in the new environment
#>
function Import-AHPolicySetDefinition {
        [CmdletBinding()]
        param (
                [Parameter(Mandatory = $true)]
                [string]
                [ValidateScript({ test-path $_ })]
                $PolicySetDefinitionFile,
                [Parameter(Mandatory = $true)]
                [string]
                [ValidateScript({ test-path $_ })]
                $PolicySetParameterFile,
                [switch]
                $IncludeMissingPolicyDefinitions,
                [Parameter(Mandatory = $true)]
                [string]
                $PolicySetName,
                [Parameter(Mandatory = $true)]
                [string]
                $PolicySetDescription,
                [Parameter(Mandatory = $true)]
                [string]
                [ValidateScript({
                                $temp = Get-AzManagementGroup $_ -ea 0 -wa 0
                                $temp.gettype().Name -eq 'PSManagementGroup' -or $temp.GetType().BaseType.Name -eq 'Object'
                        })]
                $ManagementGroupName
        )
        
        begin {

        }
        process {
                If ($IncludeMissingPolicyDefinitions) {
                        #this is a dumb way, I know, maybe I'll be smarter later
                        $PolicyPath = Split-Path -Path $PolicySetDefinitionFile -Parent
                        ForEach ($file in (Get-ChildItem $policyPath -filter *.json | Where-Object { $_.Name -ne $(split-path $PolicySetDefinitionFile -Leaf) -and $_.Name -ne $(split-path $PolicySetParameterFile -Leaf) } )) {
                                $policy = Get-Content $file -Raw | convertfrom-json -Depth 99
                                $PolicyDefinitionSplat = @{}
                                If (![string]::IsNullOrEmpty($policy.Properties.DisplayName)) { $PolicyDefinitionSplat.Add('DisplayName', $($policy.Properties.DisplayName)) }
                                If (![string]::IsNullOrEmpty($policy.Properties.Description)) { $PolicyDefinitionSplat.Add('Description', $($policy.Properties.Description)) }
                                New-AzPolicyDefinition @PolicyDefinitionSplat -Name $policy.Name -Policy $file
                        }
                }

                <#
handle ManagementGroupName problems here
#>
                $temp = Get-Content $PolicySetDefinitionFile -Raw | convertfrom-json -Depth 99
                $NewPolicy = ForEach ($i in $temp) {
                        If ($i.PolicyDefinitionId -like '*/managementGroups/*') {
                                #get managementGroup Name then replace it
                                $arr = $i.PolicyDefinitionId.split('/')
                                $managementGroupIndex = $arr.IndexOf('managementGroups') + 1
                                $arr[$managementGroupIndex] = $ManagementGroupName
                                $NewPolicyDefinitionId = $arr -join ('/')
                                $i.PolicyDefinitionId = $NewPolicyDefinitionId
                                $i
                        }
                        Else {
                                $i
                        }
                }
                $NewPolicy | ConvertTo-Json -Depth 99 | Out-File $PolicySetDefinitionFile -Force




                #autofill policySetDescription depending on metadata? maybe not, maybe force the user to do it since it is a new environemnt... we'll see
                New-AzPolicySetDefinition -PolicyDefinition $PolicySetDefinitionFile -Parameter $PolicySetParameterFile -Name $PolicySetName -Description $PolicySetDescription -ManagementGroupName $ManagementGroupName
        }
        end {

        }
}