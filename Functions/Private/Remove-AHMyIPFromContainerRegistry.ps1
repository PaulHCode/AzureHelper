Function Remove-AHMyIPFromContainerRegistry {
    #This function doesn't work yet, don't use it.
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Id,
        [Parameter()]
        [string]
        $IPAddress
    )
    $CR = Get-AzResource -Id $Id
    If (-not $?) {
        #The resource no longer exists
        return 
    }


    If ($CR.Properties.NetworkRuleSet.IpRules.length -gt 0 -and $CR.Properties.NetworkRuleSet.IpRules.Value.Contains($IPAddress)) {
        $rules = @()
        ForEach ($rule in $CR.Properties.networkRuleSet.ipRules | Where-Object { $_.value -ne $IPAddress }) {
            $rules += New-AzContainerRegistryNetworkRule -IPRule -IPAddressOrRange $rule.Value -Action $rule.Action
        }
        $ruleSet = Set-AzContainerRegistryNetworkRuleSet  -NetworkRule $rules -DefaultAction $CR.Properties.NetworkRuleSet.DefaultAction
        $Null = Update-AzContainerRegistry -ResourceId $Id -NetworkRuleSet $ruleSet
    }
    Else {
        <#
        #write-host "My IP: $($Script:MyPublicIPAddress) "
        $rules = @()
        ForEach ($rule in $CR.Properties.networkRuleSet.ipRules) {
            $rules += New-AzContainerRegistryNetworkRule -IPRule -IPAddressOrRange $rule.Value -Action $rule.Action
        }
        $rules += New-AzContainerRegistryNetworkRule -IPRule -IPAddressOrRange $Script:MyPublicIPAddress -Action 'Allow'
        $ruleSet = Set-AzContainerRegistryNetworkRuleSet  -NetworkRule $rules -DefaultAction $CR.Properties.NetworkRuleSet.DefaultAction
        Update-AzContainerRegistry -ResourceId $Id -NetworkRuleSet $ruleSet
#>
        Write-Verbose "The IP $IPAddress was already missing from $($CR.ResourceName) in resource group $($CR.ResourceGroupName)"
    }
}
