Function Remove-AHMyIPFromStorageAccount {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Id,
        [Parameter()]
        [string]
        $IPAddress
    )

    $Resource = Get-AzResource -Id $Id
    If (-not $?) {
        #The resource no longer exists
        return 
    }

    $SA = Get-AzStorageAccount -Name $Resource.Name -ResourceGroupName $Resource.ResourceGroupName
    If ($Null -ne $SA.NetworkRuleSet.IpRules.IPAddressOrRange -and $SA.NetworkRuleSet.IpRules.IPAddressOrRange.Contains($IPAddress)) {
        $NewIPRule = $SA.NetworkRuleSet.IpRules | Where-Object { $_.IPAddressOrRange -ne $IPAddress }
        $Null = Update-AzStorageAccountNetworkRuleSet -Name $sa.StorageAccountName -ResourceGroupName $SA.ResourceGroupName -IPRule $NewIPRule
    }
    Else {
        Write-Verbose "The IP $($Script:MyPublicIPAddress)/32 was already allowed on $($SA.StorageAccountName) in $($SA.ResourceGroupName)."
    } 
}
