<#
    .SYNOPSIS
        Find-AHDuplicateSubnets - Find duplicate subnets in all VNets
    .DESCRIPTION
        Find-AHDuplicateSubnets - Find duplicate subnets in all VNets
    .EXAMPLE
        Find-AHDuplicateSubnets
    .PARAMETER AllSubscriptions
        Find duplicate subnets in all VNets in all subscriptions
#>
Function Find-AHDuplicateSubnets {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $AllSubscriptions
    )
    $SummarizeSubnetsUsedInAllVNets = {
        $subscriptionName = (Get-AzContext).subscription.Name
        $VNets = (Get-AzVirtualNetwork)
        $SubnetsUsedInAllVNets = @()
        foreach ($VNet in $VNets) {
            $SubnetsUsedInthisVNet = Get-AzVirtualNetwork -Name $VNet.Name | Get-AzVirtualNetworkSubnetConfig
            $SubnetsUsedInAllVNets += [pscustomobject]@{
                SubscriptionName  = $subscriptionName
                vNet              = $VNet.Name
                vNetAddressSpaces = $vnet.AddressSpace.AddressPrefixes -join (';')
                subnet            = $SubnetsUsedInthisVNet.AddressPrefix -join (';') #$subnet
            }
        }
        $SubnetsUsedInAllVNets
    }
    $Summary = Invoke-AzureCommand -ScriptBlock $SummarizeSubnetsUsedInAllVNets -AllSubscriptions:$AllSubscriptions
    $allSubnets = $summary.subnet | ForEach-Object { $_.split(';') }
    $AnalyzedSummary = $Summary | ForEach-Object {
        $subnetCheck = ForEach ($subnet in $_.subnet.split(';')) { If (($allSubnets | Where-Object { $_ -eq $subnet }).count -gt 1) { "$($_.SubscriptionName) - $($_.vNet) - $subnet" }else {} }
        [pscustomobject]@{
            SubscriptionName  = $_.SubscriptionName
            vNet              = $_.vNet
            vNetAddressSpaces = $_.vNetAddressSpaces
            subnet            = $_.subnet
            DuplicatedInVNet  = $subnetCheck -join (';') #If($subnetCheck.contains($true)){$true}else{$false}
        }
    }
    $AnalyzedSummary # | ft -autosize
}