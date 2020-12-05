Function Add-AHMyIPToStorageAccount {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Id
    )

    $Resource = Get-AzResource -Id $Id
    If (-not $?) {
        #The resource no longer exists
        return 
    }

    $SA = Get-AzStorageAccount -Name $Resource.Name -ResourceGroupName $Resource.ResourceGroupName
    If ('allow' -eq $SA.NetworkRuleSet.DefaultAction.ToString().ToLower()) {
        Write-Verbose "$($SA.StorageAccountName) in $($SA.ResourceGroupName) has the DefaultAction set to Allow, adding IP anyway in case the DefaultAction is set to Deny later."
    }
    #Validate the IP doesn't already exist otherwise there will be duplicates.
    If ($Null -ne $SA.NetworkRuleSet.IpRules.IPAddressOrRange -and $SA.NetworkRuleSet.IpRules.IPAddressOrRange.Contains($Script:MyPublicIPAddress)) {
        Write-Verbose "The IP $($Script:MyPublicIPAddress)/32 was already allowed on $($SA.StorageAccountName) in $($SA.ResourceGroupName)."
    }
    Else {
        $NewIP = [PSCustomObject]@{
            Action           = 'Allow'
            IPAddressOrRange = $Script:MyPublicIPAddress
        }
        $NewIPRule = $SA.NetworkRuleSet.IpRules + $NewIP
        Update-AzStorageAccountNetworkRuleSet -Name $sa.StorageAccountName -ResourceGroupName $SA.ResourceGroupName -IPRule $NewIPRule
    }
}