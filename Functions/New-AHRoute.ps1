Function New-AHRoute {
    <#
.SYNOPSIS
    Creates a new UDR to allow traffic to an Azure Service

.DESCRIPTION
    New-Route provides a GUI and automation to add all the routes needed
    for a UDR for access to a particular service endpoint.  

.PARAMETER MaxRoutesPerRouteTable
    The current limitation for routes per route table is 400.  If that limit 
    is changed then override that limit by using this parameter.

.EXAMPLE
     New-AHRoute

.EXAMPLE
     New-AHRoute -MaxRoutePerRouteTable 500

.INPUTS
    Int32

.OUTPUTS
    Microsoft.Azure.Commands.Network.Models.PSRoute

.NOTES
    Author:  Paul Harrison
#>
    param(
        $MaxRoutesPerRouteTable = 400
    )
    Test-AHEnvironment
    $location = (Get-AzLocation | Out-GridView -PassThru -Title "Select the location").location
    $serviceTagRaw = (Get-AzNetworkServiceTag -Location $location).Values | Out-GridView -PassThru -Title "Select the Network Service Tag"
    $RouteTable = Get-AzRouteTable | Out-GridView -PassThru -Title "Select the Route Table to modify"
    If ((Get-AzRouteTable -ResourceGroupName $($RouteTable.ResourceGroupName) -Name $($RouteTable.Name)).routes.count + $($serviceTagRaw.properties.addressprefixes).count -gt $MaxRoutesPerRouteTable ) {
        Write-Error "This action would add more than $MaxRoutesPerRouteTable to the table.  No routes have been added."
    }
    Else {
        ForEach ($AddressPrefix in $($serviceTagRaw.properties.addressprefixes)) {
            $RouteName = $($serviceTagRaw.name) + $($AddressPrefix.split('/')[0])
            (Get-AzRouteTable -ResourceGroupName $($RouteTable.ResourceGroupName) -Name $($RouteTable.Name) | Add-AzRouteConfig -Name $RouteName -AddressPrefix $AddressPrefix -NextHopType Internet | Set-AzRouteTable).Routes | Where-Object { $_.Name -eq $RouteName } 
        }
    }
}
