<#
.SYNOPSIS
    Removes the IP address of the current machine from the network ACLs of a Key Vault.
.DESCRIPTION
    Removes the IP address of the current machine from the network ACLs of a Key Vault.
.EXAMPLE
    Remove-AHMyIPFromKeyVault -Id '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroup/providers/Microsoft.KeyVault/vaults/MyKeyVault' -IPAddress
#>
Function Remove-AHMyIPFromKeyVault {
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
    
    $KV = Get-AzKeyVault -VaultName $Resource.Name -ResourceGroupName $Resource.ResourceGroupName
    If ($Null -ne $KV.NetworkAcls.IpAddressRanges -and $KV.NetworkAcls.IpAddressRanges.Contains("$($IPAddress)/32")) {
        $NewRange = $KV.NetworkAcls.IpAddressRanges -ne "$($IPAddress)/32"
        Update-AzKeyVaultNetworkRuleSet -VaultName $KV.VaultName -ResourceGroupName $KV.ResourceGroupName -IpAddressRange $NewRange
    }
    Else {
        Write-Verbose "The IP $($IPAddress)/32 was already missing from $($KV.VaultName) in $($KV.ResourceGroupName)."
    }
}