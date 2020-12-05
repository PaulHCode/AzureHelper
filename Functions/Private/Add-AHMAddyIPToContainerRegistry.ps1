Function Add-AHMyIPToContainerRegistry {
    #This function doesn't work yet, don't use it.
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
    If ($Null -ne $CR.Properties.NetworkRuleSet.IpRules -and $CR.Properties.NetworkRuleSet.IpRules.Value.Contains($Script:MyPublicIPAddress)) {
        Write-Verbose "The IP $Script:MyPublicIPAddress was already allowed on $($CR.ResourceName) in $($CR.ResourceGroupName)."
    }
    Else {
        write-host "My IP: $($Script:MyPublicIPAddress) "
        $rule = New-AzContainerRegistryNetworkRule -IPRule -IPAddressOrRange $Script:MyPublicIPAddress 
        Set-AzContainerRegistryNetworkRuleSet  -NetworkRule $rule -DefaultAction $Rule.NetworkRuleSet.DefaultAction
    }
}
