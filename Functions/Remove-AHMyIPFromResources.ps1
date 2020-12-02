Function Remove-AHMyIPFromResources {
    <#
.SYNOPSIS
    Removes your public IP address from the firewall rules.
.DESCRIPTION
    Removes your public IP as determined by Get-AHMyPublicIPAddress from the resources that you can check using Get-AHResourceToAddMyIPTo
.EXAMPLE
    
.EXAMPLE
.EXAMPLE
.INPUTS
    String
.OUTPUTS
.NOTES
    Author:  Paul Harrison
.LINK
    Get-AHResourceToAddMyIPTo
    Remove-AHResourceToAddMyIPTo
    Export-AHMyResourcesToAddMyIPTo
    Import-AHMyResourcesToAddMyIPTo
    Add-AHMyIPToResources
    Remove-AHMyIPFromResources
    Get-AHMyPublicIP
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $IPAddress
    )
    begin {
        $originalSub = (Get-AzContext).Subscription.Id
        $Script:MyPublicIPAddress = Get-AHMyPublicIPAddress
    }
    process {
        #this method minimizes the number of time to change AZ contexts
        ForEach ($GroupOfResources in (Get-AHResourceToAddMyIPTo | Group-Object -Property subscription)) {
            $Null = Set-AzContext -SubscriptionId $GroupOfResources.Name
            ForEach ($Resource in $GroupOfResources.Group) {
                Remove-AHMyIPFromResourcesHelper -Type $Resource.type -Id $Resource.Id -IPAddress $IPAddress
            }
        }
    }
    end {
        $Null = Set-AzContext -SubscriptionId $originalSub
    }
}

Function Remove-AHMyIPFromResourcesHelper {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Type,
        [Parameter()]
        [string]
        $Id,
        [Parameter()]
        [string]
        $IPAddress
    )   

    switch ($Type) {
        'Microsoft.KeyVault/vaults' { Remove-AHMyIPFromKeyVault -Id $Id -IPAddress $IPAddress }
        'Microsoft.Storage/storageAccounts' { Remove-AHMyIPFromStorageAccount -Id $Id -IPAddress $IPAddress }
        'Microsoft.Sql/servers' { Remove-AHMyIPFromSQLServer -Id $Id -IPAddress $IPAddress }
        Default { Write-Warning "The type $Type is not supported. Resource ID $Id was not modified." }
    }

}

Function Remove-AHMyIPFromSQLServer {
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

    $SS = Get-AzSqlServerFirewallRule -ServerName $Resource.Name -ResourceGroupName $Resource.ResourceGroupName
    $SS | Where-Object { $_.StartIpAddress -eq $IPAddress -and $_.EndIpAddress -eq $IPAddress } | Remove-AzSqlServerFirewallRule
}

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