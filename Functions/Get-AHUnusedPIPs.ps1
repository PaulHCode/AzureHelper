function Get-AHUnusedPIPs {
    <#
.SYNOPSIS
    Gets a list of unused Public IPs in the environment.

.DESCRIPTION
    Get-AHUnusedPIPs is a function that returns a list of Public IPs that do not have a
    IPConfiguration.ID defined in the environment.  

.PARAMETER AllSubscriptions
    Run this command against all subscriptions.

.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.

.EXAMPLE
    Get-AHUnusedPIPs -AllSubscriptions

.EXAMPLE
    Get-AHUnusedPIPs -AllSubscriptions | Export-Csv UnusedPIPs.csv -NoTypeInformation

.INPUTS
    String

.OUTPUTS
    Selected.Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress

.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription<#,

        [switch]
        $IncludeCost#>
    )
    begin {
        Test-AHEnvironment

        <#If ($IncludeCost) {
            $SelectSplat += @{N = 'Last30DayCost'; E = { Get-AHResourceCost -ResourceId $_.Id -ToThePenny } }
        }#>

        $MyScriptBlock = {
            $CurrentSubscription = (Get-AzContext).Subscription.Name
            $SelectSplat = @{ N = "Subscription"; E = { $CurrentSubscription }}, 'ResourceGroupName', 'Location', 'Name', 'Id', 'PublicIpAllocationMethod', 'PublicIpAddressVersion', 'IpAddress'
            Get-AzPublicIpAddress | Where-Object {
                $null -eq $_.IpConfiguration.Id
            } | Select-Object -property $SelectSplat
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}
