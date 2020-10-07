Function Resize-AHVM {
    <#
.SYNOPSIS
    Resizes a VM.
.DESCRIPTION
    Resizes a VM to $NewVMSize
.PARAMETER SubscriptionId
    If the VM is not in the current subscription specify the subsctiptionId of the subscription it is in here
.PARAMETER VMName
    The name of the VM to resize
.PARAMETER ResourceGroup
    The resource group the VM is in
.PARAMETER NewVMSize
    The size the VM should be resized to
.PARAMETER AutoStart
    Turns the VM on after the resize
.PARAMETER Force
    Deallocates the VM to resize it if it is currently not deallocated
.EXAMPLE
    Remove-AHPolicyToReport -PolicyDefinitionID '/providers/Microsoft.Authorization/policyDefinitions/0015ea4d-51ff-4ce3-8d8c-f3f8f0179a56'
.INPUTS
    String
.OUTPUTS
.NOTES
    Author:  Paul Harrison
.LINK

#>

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

    If ($NewVMSize -eq $VM.HardwareProfile.VmSize) {
        Write-Verbose "$($VM.Name) is already a $NewVMSize - no changes made"
        return
    }

    Write-Verbose "Verifying the VM is deallocated"
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

    Write-Verbose "Verifying $NewVMSize is allowed in $($VM.Location)"
    If ((Get-AzVMSize -Location $($VM.Location)).Name -notcontains $NewVMSize) {
        Throw "Invalid VM Size for $($VM.Location)"  
    }

    $VM.HardwareProfile.VmSize = $NewVMSize

    Update-AzVM -VM $VM -ResourceGroupName $VM.ResourceGroupName
    If ($AutoStart) { Start-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name }
    
    If ($SubscriptionId) { Set-AzContext $oldSub }
}
