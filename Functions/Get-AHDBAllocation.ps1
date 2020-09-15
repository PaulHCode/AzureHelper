
function Get-AHDBAllocation {
    <#
.SYNOPSIS
    Gets every Azure DB and returns key information to help make choices about
    reducing the cost of your SQL DBs.

.DESCRIPTION
    Get-AHDBAllocation is a function that returns a list of Azure SQL DBs and
    the maximum cpu_percent over the past 14 days,how the licenses are being 
    paid for, and how many CPUs are allocated.  

.PARAMETER AllSubscriptions
    Run this command against all subscriptions.

.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.

.EXAMPLE
    Get-AHDBAllocation -AllSubscriptions

.EXAMPLE
    Get-AHDBAllocation -AllSubscriptions | Export-Csv DBAllocation.csv -NoTypeInformation

.INPUTS
    String

.OUTPUTS
    Selected.Microsoft.Azure.Commands.Sql.Database.Model.AzureSqlDatabaseModel

.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription,

        [switch]
        $IncludeCost
    )
    begin {
        $CurrentSubscription = (Get-AzContext).Subscription.Name
        $SelectSplat = @{N = 'Subscription'; E = { $CurrentSubscription } }, 'ResourceGroupName', 'ServerName', 'DatabaseName', 'DatabaseId', 'CurrentServiceObjectiveName', 'Capacity', 'Family', 'SkuName', 'LicenseType', 'Location', 'ZoneRedundant', @{N = "MaxCPU"; E = { ((Get-AzMetric -WarningAction 0 -ResourceId $_.ResourceId -MetricName cpu_percent -TimeGrain 01:00:00 -StartTime ((Get-Date).AddDays(-14)) -EndTime (Get-Date) -AggregationType Maximum | Select-Object -ExpandProperty Data).maximum | Measure-Object -Maximum).Maximum } }
        If($IncludeCost){
            $SelectSplat += @{N='Last30DayCost';E={Get-AHResourceCost -ResourceId $_.ResourceId -ToThePenny}}
        }

        $MyScriptBlock = {
            Get-AzSqlServer | Get-AzSqlDatabase | Select-Object -Property $SelectSplat  
<#                Select-Object @{N = "Subscription"; E = { (Get-AzContext).Subscription.Name } }, ResourceGroupName, ServerName, DatabaseName, DatabaseId, CurrentServiceObjectiveName, Capacity, `
                Family, SkuName, LicenseType, Location, ZoneRedundant, `
            @{N = "MaxCPU"; E = { ((Get-AzMetric -WarningAction 0 -ResourceId $_.ResourceId -MetricName cpu_percent -TimeGrain 01:00:00 -StartTime ((Get-Date).AddDays(-14)) -EndTime (Get-Date) -AggregationType Maximum | Select-Object -ExpandProperty Data).maximum | Measure-Object -Maximum).Maximum } }
            #>
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}