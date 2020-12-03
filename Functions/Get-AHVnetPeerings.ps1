
Function Get-AHVnetPeerings {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $AllSubscriptions
    )

    $MyScriptBlock = { Get-AzVirtualNetwork } 
    $vNets = Invoke-AzureCommand -ScriptBlock $myScriptBlock -AllSubscriptions:$AllSubscriptions
    $vNets = $vNets | Where-Object { $_.virtualNetworkPeerings } 
    $peerings = ForEach ($vnet in $vNets) {
        ForEach ($peering in $vnet.virtualNetworkPeerings) {
            [PSCustomObject]@{
                vnetName                  = $vnet.Name
                RemoteVirtualNetworkName  = $peering.RemoteVirtualNetwork.Id.split('/')[-1]
                allowForwardedTraffic     = $peering.allowForwardedTraffic
                allowVirtualNetworkAccess = $peering.AllowVirtualNetworkAccess
                PeeringName               = $peering.Name
                ResourceGroupName         = $vnet.ResourceGroupName
                SubscriptionId            = $vnet.Id.split('/')[2]
            }
        }
    }
    $results = ForEach ($peer in $peerings) {
        $peer | Select-Object vnetName, RemoteVirtualNetworkName, `
        @{N = 'HasReturnPeer'; E = { $peer.vnetName -in ($peerings | Where-Object { $_.vnetName -eq $peer.remotevirtualnetworkname } ).Remotevirtualnetworkname } }, `
            allowForwardedTraffic, allowVirtualNetworkAccess, PeeringName, ResourceGroupName, SubscriptionId
    }
    $results | Sort-Object vnetname
}