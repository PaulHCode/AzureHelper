Function Resize-AHVM {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript( { ((Get-AzSubscription).Id) -contains $_ })]
        [string]
        $SubscriptionId,
        [Parameter()]
        [string]
        $VMName,
        [Parameter()]
        [string]
        $ResourceGroup,
        [Parameter()]
        [string]
        $NewVMSize,
        [Parameter()]
        [switch]
        $Force,
        [Parameter()]
        [switch]
        $AutoStart
    )

    $oldSub = ((Get-AzContext).Subscription.Id)

    If ($SubscriptionId -and ($SubscriptionId -ne ((Get-AzContext).Subscription.Id))) {
        try { Set-AzContext $SubscriptionId }
        catch { throw }
    }

    try { 
        $VMStatus = Get-AzVM -ResourceGroupName $ResourceGroup -VMName $VMName -Status
        $VM = Get-AzVM -ResourceGroupName $ResourceGroup -VMName $VMName
    }
    catch { throw }

    If (!(($VMStatus.Statuses.code -like "*PowerState/*" -like "*deallocated"))) {
        If ($Force) {
            Stop-AzVM -ResourceGroupName  $VM.ResourceGroupName -Name $VM.Name -Force -NoWait
            While (!(((get-azvm -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Status).Statuses.code) -like "*PowerState/*" -like "*deallocated" )) {
                Write-Verbose "Waiting for $($VM.Name) to deallocate..."
                Start-Sleep -Seconds 5
            }
        }
        Else {
            Throw "The VM $($VM.Name) is currently not dealloated.  Unable to resize."
        }    
    }
    #    Write-Host "VM ="
    #    $VM | Format-List *
    #    Write-Host "Location = $($VM.Location)"
    #    write-host "VM Size = $($VM.HardwareProfile.VmSize)"
    If ((Get-AzVMSize -Location $($VM.Location)).Name -notcontains $NewVMSize) {
        Throw "Invalid VM Size for $($VM.Location)"  
    }

    #    If()

    $VM.HardwareProfile.VmSize = $NewVMSize

    Update-AzVM -VM $VM -ResourceGroupName $VM.ResourceGroupName
    If ($AutoStart) { Start-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name }
    
    If ($SubscriptionId) { Set-AzContext $oldSub }
}
