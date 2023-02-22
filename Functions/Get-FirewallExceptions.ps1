
Function Get-AHVMBackupStatus {
    <#
.SYNOPSIS
    Gets the exceptions to firewall configurations
.DESCRIPTION
    Gets the exceptions to firewall configurations
.PARAMETER AllSubscriptions
    Run this command against all subscriptions.
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.PARAMETER ResourceType
    asdf
.EXAMPLE
 
.INPUTS

.OUTPUTS

.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription,

        [Parameter(ValueFromPipeline = $true)]
        [ValidateSet('StorageAccounts')]
        $ResourceType
    )
    begin {

    }
    Process {
        #        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        #        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
    End {

        "This cmdlet doesn't do anything yet. I developed a different feature I wanted to commit on this branch so... here is this useless cmdlet"
    }

}




<#
$sa = Get-AzStorageAccount -ResourceGroupName trash -Name testpaul
$sa.NetworkRuleSet.DefaultAction
$sa.NetworkRuleSet.IpRules
#>

<#
$result = Get-AzStorageAccount | ForEach-Object {
    [pscustomobject] @{
        Name                     = $_.StorageAccountName
        ResourceGroupName        = $_.ResourceGroupName
        NetworkRuleBypass        = $_.NetworkRuleSet.Bypass
        NetworkRuleDefaultAction = $_.NetworkRuleSet.DefaultAction
        NetworkRuleIPRules       = $_.NetworkRuleSet.IpRules.IPAddressOrRange
        NetworkRulevnetRules     = $_.NetworkRuleSet.VirtualNetworkRules.VirtualNetworkResourceId
    }
}
$result | Format-Table #whatever you want. I''ll make it prettier and include a bit more info then have it export to a more useful format like csv or json or something 

#storage accounts organized by default allow/deny
$result | Group-Object NetworkRuleDefaultAction | Select-Object count, name
$result | Select-Object name -ExpandProperty NetworkRuleIPRules

Get-AzStorageAccount | Select-Object name, ResourceGroupName -ExpandProperty NetworkRuleSet | Select-Object Name, ResourceGroup -ExpandProperty IpRules

$MyScriptBlock = @{Get-AzStorageAccount | Select StorageAccountName, ResourceGroupName -ExpandProperty NetworkRuleSet | select StorageAccountName, ResourceGroupName -ExpandProperty IpRules }


Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName -ExpandProperty NetworkRuleSet, VirtualNetworkRules | Select-Object StorageAccountName, ResourceGroupName -ExpandProperty IpRules

$result = Get-AzStorageAccount
Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName -ExpandProperty NetworkRuleSet | Select-Object StorageAccountName, ResourceGroupName -ExpandProperty IpRules


$MyScriptBlock = {
    Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName -ExpandProperty NetworkRuleSet, VirtualNetworkRules | Select-Object StorageAccountName, ResourceGroupName -ExpandProperty IpRules
}
#>