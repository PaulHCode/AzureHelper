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

