#Get all policies and group them by resources impacted

#$MyReport = @()
function Get-AHPolicyByResource {
    <#
    .SYNOPSIS
        Gets all resources that Azure Policies are applied to 
    
    .DESCRIPTION
        Gets all resources Azure Policies are applied to
    
    .EXAMPLE
        $myreport = Get-AHPolicyByResource
        $myreport | group -Property type | select name,count
        $myreport | where{$_.type -eq 'Microsoft.Compute/virtualMachines'} |ft Type, policyDisplayName, PolicySetDisplayName
        
        Get a list of all Azure Policies by resource then look at which resources are impacted.
        Check which policies and policy sets are impacting virtual machines.
    .EXAMPLE
    
    .INPUTS
        String
    
    .OUTPUTS
    
    .NOTES
        Author:  Paul Harrison
    #>
    $Assignments = Get-AzPolicyAssignment
    $MyReport = ForEach ($Assignment in $Assignments) {
        If ($Assignment.Properties.PolicyDefinitionId.split('/') -contains 'policySetDefinitions') {
            #policy set
            ForEach ($policy in (Get-AzPolicySetDefinition -id $Assignment.Properties.PolicyDefinitionId).Properties.PolicyDefinitions.PolicyDefinitionId) {
                $item = Get-PolicyInfoHelper -PolicyDefinitionId $Policy
                $item.PolicySetId = $Assignment.Properties.PolicyDefinitionId
                $item.PolicySetDisplayName = $Assignment.Properties.DisplayName
                #$MyReport += $item
                $item
            }
        }
        Else {
            #Policy, not policy set
            #$MyReport += Get-PolicyInfoHelper -PolicyDefinitionId $Assignment.Properties.PolicyDefinitionId
            Get-PolicyInfoHelper -PolicyDefinitionId $Assignment.Properties.PolicyDefinitionId
        }
    }
    $MyReport
}

function Get-PolicyInfoHelper {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $PolicyDefinitionId
    )

    $Definition = Get-AzPolicyDefinition -Id $PolicyDefinitionId
    $PolicyDefinitionJSON = az policy definition show -n (($PolicyDefinitionId -split ('/'))[-1]) 
    $PolicyInfo = [PSCustomObject]@{
        type                 = Find-EqualsInFile -file $PolicyDefinitionJSON
        PolicyDisplayName    = $Definition.Properties.DisplayName
        PolicySetDisplayName = $Null
        PolicyDefinitionId   = $Definition.PolicyDefinitionId
        PolicySetId          = $Null
    }
    $PolicyInfo
}




Function Find-EqualsInFile {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]
        $file
    )   
    ForEach ($Line in $file) {
        #Get-Content $filename) {
        If ($Null -eq $previousLine) {
            $previousLine = $Line
        }
        Else {
            If ($Line.Contains('"field":') -and $Line.Contains('"type"') -and $previousLine.Contains('"equals":')) {
                $previousLine.split(":")[1].trim(',').trim().trim('"')
            }
            ElseIf ($previousLine.Contains('"field":') -and $previousLine.Contains('"type"') -and $Line.Contains('"equals":')) {
                $Line.split(":")[1].trim(',').trim().trim('"')
            }
        
            $previousLine = $Line
        }
    }

}

