
Function Copy-AHPolicyExemptions {
    <#
.SYNOPSIS
    Copies policy exemptions from one policy assignment to another.

.DESCRIPTION
    The Copy-AHPolicyExemptions function copies policy exemptions from one policy assignment to another. 
    The function checks if the exemptionFile contains data about subscriptions that the user currently has access to. If it contains subscriptions that the user does not have access to, the function throws an error unless the -Force switch is used.
    The function then iterates through each policy assignment pair in the assignmentMappingFile and copies the policy exemptions from the source policy assignment to the destination policy assignment.

.PARAMETER assignmentMappingFile
    The path to the JSON file that contains the mapping of source and destination policy assignments.

.PARAMETER exemptionFile
    The path to the JSON file that contains the policy exemptions to be copied.

.PARAMETER Force
    If specified, the function will not throw an error if the exemptionFile contains subscriptions that the user does not have access to.

.EXAMPLE 
    Copy policy exemptions from one policy assignment to another.
    PS C:\> Copy-AHPolicyExemptions -assignmentMappingFile '.\AssignmentMapping.json' -exemptionFile '.\PolicyExemptions.json'

    This example copies policy exemptions from the policy assignments specified in the AssignmentMapping.json file to the policy assignments specified in the PolicyExemptions.json file.

.EXAMPLE 
    Copy policy exemptions from one policy assignment to another, ignoring subscriptions that the user does not have access to.
    PS C:\> Copy-AHPolicyExemptions -assignmentMappingFile '.\AssignmentMapping.json' -exemptionFile '.\PolicyExemptions.json' -Force

    This example copies policy exemptions from the policy assignments specified in the AssignmentMapping.json file to the policy assignments specified in the PolicyExemptions.json file, ignoring any subscriptions in the PolicyExemptions.json file that the user does not have access to.

.NOTES
    This function requires the Az PowerShell module to be installed.

    The function assumes that the user is logged in to the correct Azure account and has the necessary permissions to access the policy assignments and exemptions.

    The function does not modify the source policy assignments or exemptions.

    The function does not support copying policy exemptions between different Azure environments (e.g. from a development environment to a production environment).

    The function does not support copying policy exemptions between different Azure tenants.

    The function does not support copying policy exemptions for policies that are not assigned to a scope (e.g. management groups).

    The function does not support copying policy exemptions for policies that are assigned to a scope that the user does not have access to.

.LINK
    https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azpolicyexemption
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $assignmentMappingFile,
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $exemptionFile,
        [switch]
        $Force,
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path $(Split-Path $_) -PathType Container })]
        [string]
        $LogPath
    )

    #    $assignmentMappingFile = '.\AssignmentMapping.json'
    #    $exemptionFile = '.\PolicyExemptions.json'

    $AssignmentMap = Get-Content $assignmentMappingFile | ConvertFrom-Json
    $inputExemptions = Get-Content $exemptionFile | ConvertFrom-Json

    #check to see if the exemptionFile contains data about subscriptions that we currently have access to
    $allSubs = $((Get-AzSubscription).id)
    If ((($exemptions.SubscriptionId | Group-Object).name | ForEach-Object { $_ -in $allSubs }).contains($false)) {
        If (!$Force) {
            throw 'The exemption file contains subscriptions that you do not have access to. Please verify the right file was selected and you are logged into the right account.'
        }
        Else {
            Write-Warning 'The exemption file contains subscriptions that you do not have access to. Please verify the right file was selected and you are logged into the right account.'
            Write-Warning 'This could also happen if you are using an account that does not have access to all the subscriptions in the exemption file.'
        }
    }



    ForEach ($assignmentPair in $AssignmentMap) {
        "`n`nstarting on assignmentPair: $assignmentPair" | ForEach-Object { If ($LogPath) { $_ | Out-File -FilePath $LogPath -Append }; $_ | Write-Verbose }
        $sourceExemptions = $inputExemptions | Where-Object { $_.Properties.PolicyAssignmentId -eq $assignmentPair.Source }
        ForEach ($exemption in $sourceExemptions) {
            $sourceAssignment = Get-AzPolicyAssignment -Id $assignmentPair.Source
            "sourceAssignment = $($sourceAssignment.PolicyAssignmentId)" | ForEach-Object { If ($LogPath) { $_ | Out-File -FilePath $LogPath -Append }; $_ | Write-Verbose }
            If (!$sourceAssignment) {
                #make sure the source assignment exists in this environment - we don't want accidental copying of exemptions between environments
                #Write-Warning "No assignment found for $($assignmentPair.Source)" | If($LogPath){Out-File -FilePath $LogPath -Append}
                "No assignment found for $($assignmentPair.Source)" | ForEach-Object { If ($LogPath) { $_ | Out-File -FilePath $LogPath -Append }; $_ | Write-Warning }
            }
            Else {
                $targetAssignment = Get-AzPolicyAssignment -Id $assignmentPair.Destination
                "targetAssignment = $($targetAssignment.PolicyAssignmentId)" | ForEach-Object { If ($LogPath) { $_ | Out-File -FilePath $LogPath -Append }; $_ | Write-Verbose }
                If ($targetAssignment) {
                    $newExemptionSplat = @{
                        Name              = $exemption.Name + '-migrated'
                        ExemptionCategory = $exemption.Properties.ExemptionCategory
                        PolicyAssignment  = $targetAssignment #$assignmentPair.Destination
                    }
                    if ($exemption.Properties.DisplayName) { $newExemptionSplat.Add('DisplayName', $exemption.Properties.DisplayName) }
                    If ($exemption.Properties.Description) { $newExemptionSplat.Add('Description', $exemption.Properties.Description) }
                    If ($exemption.Properties.PolicyDefinitionReferenceIds) { $newExemptionSplat.Add('PolicyDefinitionReferenceId', $exemption.Properties.PolicyDefinitionReferenceIds) }
                    If ($exemption.Properties.ExpiresOn) { $newExemptionSplat.Add('ExpiresOn', $exemption.Properties.ExpiresOn) }
                    If ($exemption.Properties.Metadata.ToString()) { $newExemptionSplat.Add('Metadata', $exemption.Properties.Metadata) }
                    $newExemptionSplat.Add('Scope', $exemption.ResourceId.split('/providers/Microsoft.Authorization/policyExemption')[0])
                    "attempted New-AzPolicyExemption splat: $([pscustomobject]$newExemptionSplat)" | ForEach-Object { If ($LogPath) { $_ | Out-File -FilePath $LogPath -Append }; $_ | Write-Verbose }
                    $result = New-AzPolicyExemption @newExemptionSplat
                    "Created (or attempted to create existing policy) policy exemption: $($result.ResourceId)" | ForEach-Object { If ($LogPath) { $_ | Out-File -FilePath $LogPath -Append }; $_ | Write-Verbose }
                }
                Else {
                    "No assignment found for $($assignmentPair.Destination)" | ForEach-Object { If ($LogPath) { $_ | Out-File -FilePath $LogPath -Append }; $_ | Write-Warning }
                }
            }
        }
    }

}