Function Add-AHMyIPToKeyVault {
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

    $KV = Get-AzKeyVault -VaultName $Resource.Name -ResourceGroupName $Resource.ResourceGroupName
    If ('allow' -eq $KV.NetworkAcls.DefaultAction.ToString().ToLower()) {
        Write-Verbose "$($KV.VaultName) in $($KV.ResourceGroupName) has the DefaultAction set to Allow, adding IP anyway in case the DefaultAction is set to Deny later."
    }
    #Validate the IP doesn't already exist otherwise there will be duplicates.
    If ($Null -ne $KV.NetworkAcls.IpAddressRanges -and $KV.NetworkAcls.IpAddressRanges.Contains("$($Script:MyPublicIPAddress)/32")) {
        Write-Verbose "The IP $($Script:MyPublicIPAddress)/32 was already allowed on $($KV.VaultName) in $($KV.ResourceGroupName)."
    }
    Else {
        $NewRange = $KV.NetworkAcls.IpAddressRanges + "$($Script:MyPublicIPAddress)/32"
        Update-AzKeyVaultNetworkRuleSet -VaultName $KV.VaultName -ResourceGroupName $KV.ResourceGroupName -IpAddressRange $NewRange
    }
}

