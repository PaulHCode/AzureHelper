
Function Test-AHHubSpoke {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $HubvNetNames,
        [Parameter()]
        [switch]
        $AllSubscriptions
    )

    $peerings = Get-AHVnetPeerings -AllSubscriptions:$AllSubscriptions
    ForEach ($peering in $peerings) {

        $Authorized = $Null
        $ErrorReason = $Null
        $PeeringType = $Null

        If ($peering.vnetname -in $HubvNetNames) {
            #vnet is a hub
            If ($peering.RemoteVirtualNetworkName -in $HubvNetNames) {
                #remote vnet is a hub
                $PeeringType = 'Hub-Hub'
                If ($peering.AllowForwardedTraffic) {
                    $Authorized = $true
                }
                else {
                    $Authorized = $false
                    $ErrorReason = "In a multi-hub environment this blocks traffic from a spoke reaching a different hub than the one it is paired with."
                }
            }
            Else {
                #remote vnet is a spoke
                $PeeringType = 'Hub-Spoke'
                $Authorized = $true
                If ($peering.AllowForwardedTraffic) {
                    $ErrorReason = "This works, but consider setting AllowForwardedTraffic to $false since it isn't needed here."     
                }           
            }
        }
        Else {
            #vnet is a spoke
            If ($peering.RemoteVirtualNetworkName -in $HubvNetNames) {
                #remote vnet is a hub
                $PeeringType = 'Spoke-Hub'
                If ($peering.AllowForwardedTraffic) {
                    $Authorized = $true
                }
                Else {
                    $Authorized = $false
                    $ErrorReason = "This blocks traffic from a different spoke from getting to this spoke. "
                }
            }
            Else {
                #remote vnet is a spoke
                $PeeringType = 'Spoke-Spoke'
                $Authorized = $False
                $ErrorReason = "No Spoke-to-Spoke peers since it bypasses the hub. "
            }
        }
        If (-not $Peering.allowVirtualNetworkAccess) {
            $Authorized = $false
            $ErrorReason += "If the pairing exists it should stay enabled, not be switched off with AllowVirtualNetworkAccess."
        }
        [PSCustomObject]@{
            vnetName                  = $peering.vnetName
            RemoteVirtualNetworkName  = $peering.RemoteVirtualNetworkName
            allowForwardedTraffic     = $peering.allowForwardedTraffic
            allowVirtualNetworkAccess = $peering.allowVirtualNetworkAccess
            PeeringName               = $peering.PeeringName
            Authorized                = $Authorized
            PeeringType               = $PeeringType
            ErrorReason               = $ErrorReason
            ResourceGroupName         = $peering.resourceGroupName
            SubscriptionId            = $peering.SubscriptionId
        }
    }

}