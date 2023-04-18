
<#
.Synopsis
   Imports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions
.DESCRIPTION
   Imports an Azure Policy Initiative definition (also known as a policy set) and the associated policy definitions.
   This will overwrite the PolicySetDefinitionFile with the proper ManagementGroupName specified instead of whatever management group is currently there from the export.
   This command assumes any necessary definitions are located in the same directory as the PolicySetDefinitionFile
.EXAMPLE
   $ManagementGroupName = 'MyManagementGroup'
   $PolicySetDefinitionFile = '.\Initiatives\Custom General V2\Custom General V2-Policy.json'
   $PolicySetParameterFile = '.\Initiatives\Custom General V2\Custom General V2-Parameters.json'
   $PolicySetName = 'Custom General V2'
   Import-AHPolicySetDefinition -PolicySetDefinitionFile $PolicySetDefinitionFile -PolicySetParameterFile $PolicySetParameterFile -PolicySetName $PolicySetName -PolicySetDescription $PolicySetName -ManagementGroupName $ManagementGroupName -IncludeMissingPolicyDefinitions

   This example imports the policy set "Custom General V2". I stored many initiatives in subfolders of the 'initiatives' folder then looped through all of them
.NOTES
   
.PARAMETER PolicySetDefinitionFile
   The PolicySet definition file to import
.PARAMETER PolicySetParameterFile
   The PolicySet parameter file to import
.PARAMETER PolicySetName
   The name for the policy set
.PARAMETER PolicySetDescription
   The description for the policy set
.PARAMETER ManagementGroupName
   The name of the management group to create this policy set in
.PARAMETER PolicySetCategory
   This category will be assigned to the policy set definition
.PARAMETER IncludeMissingPolicyDefinitions
   Imports the policy definitions required for the policy set if they don't already exist in the new environment
.PARAMETER PurgeExistingPolicyDefinitions
   Purges existing policies in the management group that have the same name as one to be imported. Purge will fail if the policy definition is currently in use by  policy set but if you want to clean it out completely it will provide you with an error telling you which policy set it is a part of.
#>
function Import-AHPolicySetDefinition {
        [CmdletBinding()]
        param (
                [Parameter(Mandatory = $true)]
                [string]
                [ValidateScript({ Test-Path $_ })]
                $PolicySetDefinitionFile,
                [Parameter(Mandatory = $true)]
                [string]
                [ValidateScript({ Test-Path $_ })]
                $PolicySetParameterFile,
                [switch]
                $IncludeMissingPolicyDefinitions,
                [Parameter(Mandatory = $true)]
                [string]
                $PolicySetName,
                [Parameter(Mandatory = $true)]
                [string]
                $PolicySetDescription,
                [Parameter(Mandatory = $false)]
                [string]
                $PolicySetCategory,
                [Parameter(Mandatory = $false)]
                [string]
                [ValidateScript({
                                $temp = Get-AzManagementGroup $_ -ea 0 -wa 0
                                $temp.gettype().Name -eq 'PSManagementGroup' -or $temp.GetType().BaseType.Name -eq 'Object'
                        })]
                $ManagementGroupName,
                [Parameter(Mandatory = $false)]
                [switch]
                $PurgeExistingPolicyDefinitions
        )
        
        begin {
                If ($PSVersionTable.PSVersion.Major -lt 7) {
                        throw 'This cmdlet requires PowerShell 7 or greater'
                }

                $builtinPolicies = Get-AzPolicyDefinition -Builtin

                #this is a stupid function I plan to fix later so I'll add it to private functions later, but for testing it is fine here
                Function FindByValue {
                        #this function determines if there is a NoteProperty with value $value of any child at any dept of the $object. If there is it returns true, otherwise it returns false. It must be an exact match but is not case sensitive right now.
                        [CmdletBinding()]
                        param($object, $value, $totalResult = $false)
                        #write-verbose "object = $object"
                        #write-verbose "value = $value"
                        #write-verbose ''
                        $result = $false
                        If ($Null -ne $object) {
                                $keys = $object | Get-Member -MemberType NoteProperty
                                $keys | Where-Object { $Null -ne $_ } | ForEach-Object {
                                        If ($object.$($_.Name) -eq $value) {
                                                #$totalPath + '.' + $($_.Name)
                                                $result = $true
                                                $totalResult = $result -or $totalResult
                                        }
                                        Else {
                                                $result = FindByValue -object $($object.$($_.Name)) -value $value #-totalPath $($totalPath + '.' + $($_.Name)) #| out-null
                                                $totalResult = $result -or $totalResult
                                        }
                                }
                        } 
                        $totalResult
                }
                    
        }
        process {
                If ($PurgeExistingPolicyDefinitions) {
                        $PolicyPath = Split-Path -Path $PolicySetDefinitionFile -Parent
                        ForEach ($file in (Get-ChildItem $policyPath -Filter *.json | Where-Object { $_.Name -ne $(Split-Path $PolicySetDefinitionFile -Leaf) -and $_.Name -ne $(Split-Path $PolicySetParameterFile -Leaf) } )) {
                                $policy = Get-Content $file -Raw | ConvertFrom-Json -Depth 99
                                ####################################################################################################################################################
                                If ($Null -ne $policy.Name -and $Null -ne (Get-AzPolicyDefinition -Name $policy.Name -ManagementGroupName $ManagementGroupName -ErrorAction SilentlyContinue)) {
                                        #Check if there are any policy definitions in the same management group with the same name, if so, delete them
                                        #delete them
                                        Remove-AzPolicyDefinition -Name $policy.Name -ManagementGroupName $ManagementGroupName -Force | Out-Null
                                }

                        }
                }
                If ($IncludeMissingPolicyDefinitions) {
                        #this is a dumb way, I know, maybe I'll be smarter later
                        $PolicyPath = Split-Path -Path $PolicySetDefinitionFile -Parent
                        ForEach ($file in (Get-ChildItem $policyPath -Filter *.json | Where-Object { $_.Name -ne $(Split-Path $PolicySetDefinitionFile -Leaf) -and $_.Name -ne $(Split-Path $PolicySetParameterFile -Leaf) } )) {
                                $policy = Get-Content $file -Raw | ConvertFrom-Json -Depth 99
                                ####################################################################################################################################################
                                If ($builtinPolicies.Name -notcontains $($policy.Name)) {
                                        #Check to see if the policy is a builtin one that already exists in the environment if it doesn't exist as a builtin policy then import the policy to the to the management group
                                        $results = Get-AzPolicyDefinition -ManagementGroupName $ManagementGroupName | Where-Object { $_.Name -eq $policy.Name } 
                                        If ($results.count -eq 0) {
                                                #If the policy is not already in the environment then prepare the policy for importing
                                                
                                                ### If the policy definition file contains information about "location" data then automatically fix the location based on (get-azlocation).Location
                                                If (FindByValue -object $policy -value 'location') {
                                                        Write-Warning "The Policy $($policy.Name) contains location data. Please validate location data is correct for this environment."
                                                }
                                                ### import the policy
                                                $PolicyDefinitionSplat = @{}
                                                If (![string]::IsNullOrEmpty($policy.Properties.DisplayName)) { $PolicyDefinitionSplat.Add('DisplayName', $($policy.Properties.DisplayName)) }
                                                If (![string]::IsNullOrEmpty($policy.Properties.Description)) { $PolicyDefinitionSplat.Add('Description', $($policy.Properties.Description)) }
                                                #If (![string]::IsNullOrEmpty($policy.Name)) { $PolicyDefinitionSplat.Add('Name', $policy.Name) } #I didn't use this because the policy definition must always have a name defined
                                                $result = New-AzPolicyDefinition @PolicyDefinitionSplat -Name $policy.Name -Policy $file.FullName -ManagementGroupName $ManagementGroupName #-ErrorAction Break
                                                #$result = New-AzPolicyDefinition @PolicyDefinitionSplat -Policy $file #-ErrorAction Break
                                                Write-Verbose @"

Name: $($result.Name)
ResourceId: $($result.ResourceId)
"@

                                                ### After the policy is imported, modify the PolicySetDefinition JSON to point to the new custom PolicyDefinitionId
                                                #    The ".id" in the policy definition file will match the PolicyDefinitionId in the PolicySet definition. we want to replace it with the $newDefinitionOutput.PolicyDefinitionId
                                                $policySet = Get-Content $PolicySetDefinitionFile -Raw | ConvertFrom-Json -Depth 99
                                                For ($i = 0; $i -lt $policySet.count; $i++) {
                                                        If ($policySet[$i].policyDefinitionId -eq $policy.id) {
                                                                $policySet[$i].policyDefinitionId = $result.PolicyDefinitionId
                                                        }
                                                }
                                                $policySet | ConvertTo-Json -Depth 99 | Out-File $PolicySetDefinitionFile -Force

                                                
                                                #then update the Policy Defintion File
                                                $policyDefinition = Get-Content $file -Raw | ConvertFrom-Json -Depth 99
                                                $policyDefinition.id = $result.PolicyDefinitionId
                                                $policyDefinition | ConvertTo-Json -Depth 99 | Out-File -LiteralPath $file.FullName -Force

                                        }
                                }
                                #####################################################################################################################################################
                                

                        }
                }


                ### fix location data in the policy set parameters file - I'm not going to fix location data because it must be considered manually but I should alert
                ### fix location data in the policy set definition - I'm not going to fix location data because it must be considered manually but I should alert





                ##handle ManagementGroupName problems here - since the Policy Set's policyDefinitionId is overwritten anyway, this section is no longer needed if the policy didn't exist and needed to get imported

                $temp = Get-Content $PolicySetDefinitionFile -Raw | ConvertFrom-Json -Depth 99
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
                $PolicySetDefinitionSplat = @{
                        PolicyDefinition = $PolicySetDefinitionFile
                        Parameter        = $PolicySetParameterFile
                }
                Write-Verbose "`n`nPolicySetName = $PolicySetName"
                If (![string]::IsNullOrEmpty($PolicySetName)) { $PolicySetDefinitionSplat.Add('Name', $PolicySetName) }
                If (![string]::IsNullOrEmpty($PolicySetDescription)) { $PolicySetDefinitionSplat.Add('Description', $PolicySetDescription) }
                If (![string]::IsNullOrEmpty($ManagementGroupName)) { $PolicySetDefinitionSplat.Add('ManagementGroupName', $ManagementGroupName) }
                If (![string]::IsNullOrEmpty($PolicySetCategory)) { $PolicySetDefinitionSplat.Add('Metadata', "{`"category`":`"$PolicySetCategory`"}") }
                #                $result = New-AzPolicySetDefinition -PolicyDefinition $PolicySetDefinitionFile -Parameter $PolicySetParameterFile -Name $PolicySetName -Description $PolicySetDescription -ManagementGroupName $ManagementGroupName
                $result = New-AzPolicySetDefinition @PolicySetDefinitionSplat
                Write-Verbose @"

Name: $($result.Name)
ResourceId: $($result.ResourceId)
"@
        }

        end {

        }
}