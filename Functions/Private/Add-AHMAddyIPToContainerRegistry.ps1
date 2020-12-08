Function Add-AHMyIPToContainerRegistry {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Id
    )
    $CR = Get-AzResource -Id $Id
    If (-not $?) {
        #The resource no longer exists
        return 
    }

    #Validate the IP doesn't already exist otherwise there will be duplicates.
    If ($CR.Properties.NetworkRuleSet.IpRules.length -gt 0 -and $CR.Properties.NetworkRuleSet.IpRules.Value.Contains($Script:MyPublicIPAddress)) {
        Write-Verbose "The IP $Script:MyPublicIPAddress was already allowed on $($CR.ResourceName) in $($CR.ResourceGroupName)."
    }
    Else {
        # write-host "My IP: $($Script:MyPublicIPAddress) "
        $rules = @()
        ForEach ($rule in $CR.Properties.networkRuleSet.ipRules) {
            $rules += New-AzContainerRegistryNetworkRule -IPRule -IPAddressOrRange $rule.Value -Action $rule.Action
        }
        $rules += New-AzContainerRegistryNetworkRule -IPRule -IPAddressOrRange $Script:MyPublicIPAddress -Action 'Allow'
        $ruleSet = Set-AzContainerRegistryNetworkRuleSet  -NetworkRule $rules -DefaultAction $CR.Properties.NetworkRuleSet.DefaultAction
        Update-AzContainerRegistry -ResourceId $Id -NetworkRuleSet $ruleSet
    }
}
