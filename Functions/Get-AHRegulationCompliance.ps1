

Function Get-AHRegulationCompliance {
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,

        [Parameter(ValueFromPipeline = $true)]
        $Subscription,

        [string]
        $Regulation,

        [string]
        $RegulationFile = 'C:\GitHub\AzureHelper\Regulations.json',

        [switch]
        $Summary
    )
    begin {
        If (!(Test-Path $RegulationFile)) { throw 'Invalid Regulation File' }

        $Regulations = Get-Content $RegulationFile | ConvertFrom-Json
        $RegToCheck = $Regulations | Where-Object { $_.Name -eq $Regulation }
        If ($Null -eq $RegToCheck) { throw "$Regulation not found in $RegulationFile" }
        $Total = @()

        #        $MyScriptBlock = {
        $Sub = (Get-AzContext).Subscription.Name

        $controlCount = 0
        $policyCount = 0
        $PolicyDefinitions = Get-AzPolicyDefinition
        ForEach ($Control in $RegToCheck.Control) {
            Write-Progress -Activity "Checking for $($RegToCheck.Name) compliance" -Status "Checking $($Control.Name)" -PercentComplete (100 * $controlCount / $($RegToCheck.Control.count))
            $policyCount = 0
            ForEach ($Policy in $Control.Policy) {
                Write-Progress -Activity "Checking: $($Policy.Name)" -PercentComplete (100 * $policyCount / $($Control.Policy.count)) -Id 1
                $policyCount++
                $PolicyDefinitionId = ($PolicyDefinitions | Where-Object { $_.Properties.DisplayName -eq $Policy.Name }).PolicyDefinitionId
                $PolicyState = Get-AzPolicyState -Filter "PolicyDefinitionId eq '$PolicyDefinitionID'"
                $item = "" | Select-Object Subscription, Regulation, Control, Policy, PolicyExists, NonCompliantCount, TotalObjectCount
                $item.Subscription = $Sub
                $item.Regulation = $Regulation
                $item.Control = $Control.Name
                $item.Policy = $Policy.Name
                $item.PolicyExists = ($Null -ne $PolicyDefinitionId)
                $item.NonCompliantCount = ($PolicyState | Where-Object { $_.ComplianceState -eq 'NonCompliant' }).count
                $item.TotalObjectCount = ($PolicyState).count
                $Total += $item
            }
            $controlCount++
        }
        If (!$Summary) {
            $Total
        }
        Else {    
            $Total | Group-Object -Property Control | Select-Object @{N = 'Subscription'; E = { $Sub } }, @{N = 'Regulation'; E = { $Regulation } }, @{N = 'Control'; E = { $_.Name } }, @{N = 'isCompliant'; E = { $_.count -eq 0 } }
        }
    }
}
#process {
#    if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock <#-ArgumentList $ArgumentList#> }
#    else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions <#-ArgumentList $ArgumentList#> }
#}
#}







<#
$policyState | Where{$_.ComplianceState -eq 'NonCompliant'}).count

2
PS C:\GitHub\AzureHelper> $policyState = Get-AzPolicyState -Filter "PolicyDefinitionId eq '/providers/Microsoft.Authorization/policyDefinitions/6b1cbf55-e8b6-442f-ba4c-7246b6381474'"

PS C:\GitHub\AzureHelper> 



#>