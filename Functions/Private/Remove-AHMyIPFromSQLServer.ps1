<#
.SYNOPSIS
    Removes the IP address from the SQL Server firewall rules
.DESCRIPTION
    Removes the IP address from the SQL Server firewall rules
.EXAMPLE
    Remove-AHMyIPFromSQLServer -Id '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroup/providers/Microsoft.Sql/servers/MySqlServer' -IPAddress <IP Address>
#>
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

