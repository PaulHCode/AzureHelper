function Get-AHUnusedNICs {
    <#
.SYNOPSIS
    Gets a list of unused NICs in the environment.

.DESCRIPTION
    Get-AHUnusedNICs is a function that returns a list of NICs that are not attached
    in the environment.  This can occur when VMs are deleted but not the NICs attached
    to the VM.  

.PARAMETER AllSubscriptions
    Run this command against all subscriptions.

.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.

.PARAMETER IncludeCost
    Include cost data in the output - This makes the command take about 25x longer to run.

.EXAMPLE
    Get-AHUnusedNICs -AllSubscriptions

.EXAMPLE
    Get-AHUnusedNICs -AllSubscriptions | Export-Csv UnusedNICs.csv -NoTypeInformation

.INPUTS
    String

.OUTPUTS
    Selected.Microsoft.Azure.Commands.Compute.Automation.Models.PSDiskList

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
        Test-AHEnvironment
        $CurrentSubscription = (Get-AzContext).Subscription.Name
        $SelectSplat = @{N = "Subscription"; E = { $CurrentSubscription } }, 'ResourceGroupName', 'VirtualMachine', 'MacAddress', 'NetworkSecurityGroup', 'PrivateEndpoint', 'Location', 'Id', 'Name'
        If ($IncludeCost) {
            $SelectSplat += @{N = 'Last30DayCost'; E = { Get-AHResourceCost -ResourceId $_.Id -ToThePenny } }
        }

        $MyScriptBlock = {
            Get-AzNetworkInterface | Where-Object {
                $null -eq $_.ManagedBy
            } | Select-Object -Property $SelectSplat
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}