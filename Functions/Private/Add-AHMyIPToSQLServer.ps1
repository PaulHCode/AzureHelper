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