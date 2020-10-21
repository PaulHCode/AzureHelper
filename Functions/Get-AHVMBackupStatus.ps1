
Function Get-AHVMBackupStatus {
    <#
.SYNOPSIS
    Gets the all VMs in the subscription and their backup status
.DESCRIPTION
    Gets the all VMs in the subscription and their backup status
.PARAMETER AllSubscriptions
    Run this command against all subscriptions.
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.EXAMPLE
    Get-AHVMBackupStatus
.INPUTS
    String
.OUTPUTS
    Selected.System.String
.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription
    )
    begin {

        $MyScriptBlock = {
            $Sub = (Get-AzContext).Subscription.Name
            try { az account set --subscription ((Get-AzContext).Subscription.Id) }
            catch { throw }
            $BackedUpVMs = Get-AHBackedUpVMs #-AllSubscriptions:$AllSubscriptions -Subscription:$Subscription
            Get-AzVm | Where-Object { $_.id -notin $BackedUpVMs.Id } | ForEach-Object {
                $VM = "" | Select-Object 'Subscription', 'VMName', 'VMResourceGroupName', 'VaultName', 'VaultResourceGroupName', 'VMStillExists', 'LastBackupStatus', 'LastBackupTime', 'Id'
                $VM.Subscription = $Sub
                $VM.VMName = $_.Name
                $VM.VMResourceGroupName = $_.ResourceGroupName
                $VM.VMStillExists = $true
                $VM.VaultResourceGroupName = $Null
                $VM.VaultName = $Null
                $VM.LastBackupStatus = $Null
                $VM.LastBackupTime = $Null
                $VM.Id = $_.Id
                $BackedUpVMs += $VM
            }
            $BackedUpVMs
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}