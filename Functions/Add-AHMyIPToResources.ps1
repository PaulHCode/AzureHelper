Function Add-AHMyIPToResources {
    <#
.SYNOPSIS
    Adds your public IP address to the firewall rules.
.DESCRIPTION
    Adds your public IP as determined by Get-AHMyPublicIPAddress to the resources that you can check using Get-AHResourceToAddMyIPTo
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
    begin {
        $originalSub = (Get-AzContext).Subscription.Id
        $Script:MyPublicIPAddress = Get-AHMyPublicIPAddress
    }
    process {
        #this method minimizes the number of time to change AZ contexts
        ForEach ($GroupOfResources in (Get-AHResourceToAddMyIPTo | Group-Object -Property subscription)) {
            $Null = Set-AzContext -SubscriptionId $GroupOfResources.Name
            ForEach ($Resource in $GroupOfResources.Group) {
                Add-AHMyIPToResourcesHelper -Type $Resource.type -Id $Resource.Id
            }
        }
    }
    end {
        $Null = Set-AzContext -SubscriptionId $originalSub
    }
}

Function Add-AHMyIPToResourcesHelper {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Type,
        [Parameter()]
        [string]
        $Id
    )   

    switch ($Type) {
        'Microsoft.KeyVault/vaults' { Add-AHMyIPToKeyVault -Id $Id }
        'Microsoft.Storage/storageAccounts' { Add-AHMyIpToStorageAccount -Id $Id }
        'Microsoft.Sql/servers' { Add-AHMyIPToSQLServer -Id $Id }
        Default { Write-Warning "The type $Type is not supported. Resource ID $Id was not modified." }
    }

}

Function Add-AHMyIPToSQLServer {
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

    $SS = Get-AzSqlServerFirewallRule -ServerName $Resource.Name -ResourceGroupName $Resource.ResourceGroupName
    #Validate the IP doesn't already exist otherwise there will be duplicates.
    If ($SS | Where-Object { $_.StartIpAddress -eq $Script:MyPublicIPAddress -and $_.EndIpAddress -eq $Script:MyPublicIPAddress }) { 
        Write-Verbose "The IP $Script:MyPublicIPAddress was already allowed on SQL Server with resource ID $Id."
    }
    Else {
        $Null = New-AzSqlServerFirewallRule -ResourceGroupName $Resource.ResourceGroupName -ServerName $Resource.Name `
            -FirewallRuleName "ClientIPAddress_$(get-date -Format yyyy-MM-dd_hh-mm-ss)" `
            -StartIpAddress $Script:MyPublicIPAddress -EndIpAddress $Script:MyPublicIPAddress
    }
}

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

