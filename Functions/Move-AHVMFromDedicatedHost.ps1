
Function Move-AHVMFromDedicatedHost {
    <#
    .SYNOPSIS
        Moves a VM from a dedicated host
    .PARAMETER VMName
        The name of the VM to move
    .PARAMETER VMResourceGroup
        The name of the Resource Group the VM is in
    .PARAMETER DeallocateIfNeeded
        If specified and the VM is not in a deallocated state then the VM is deallocated to move.  If the VM is not in a deallocated state and this parameter is not specified then the move fails.
    .PARAMETER StartVMAfterMove
        If specified and the move is successful then the VM is started.  The VM is started with -NoWait to return faster but does not guarantee the VM is finished booting. 
    .Example
            Move-AHVMFromDedicatedHost -HostName MyHost -HostResourceGroup HostRG -HostGroup MyHostG1 -VMName DHVM1 -VMResourceGroup VMRG -StartVMAfterMove
    .Notes
        Author: Paul Harrison
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $VMName,
        [Parameter(Mandatory = $true)]
        [string]
        $VMResourceGroup,
        [Parameter()]
        [switch]
        $DeallocateIfNeeded,
        [Parameter()]
        [switch]
        $StartVMAfterMove
    )

    try {
        $VM = Get-AzVM -ResourceGroupName $VMResourceGroup -Name $VMName
    }
    catch {
        throw "error finding VM"
    }    
    If (!$VM) {
        throw "VM not found"
    }
    If ('VM deallocated' -ne (Get-AzVM -ResourceGroupName $VMResourceGroup -Name $VMName -Status).statuses[1].DisplayStatus) {
        If ($DeallocateIfNeeded) {
            Stop-AzVM -ResourceGroupName $VMResourceGroup -Name $VMName -Force
        }
        Else {
            throw "$VMName in Resource Group $VMResourceGroup is not deallocated.  Deallocate or specify the DeallocateIfNeeded switch."
        }
    }

    $VM.Host = New-Object Microsoft.Azure.Management.Compute.Models.SubResource
    $vm.Host.Id = $Null
    $Null = Update-AzVM -ResourceGroupName $VMResourceGroup -VM $VM 

    If ($StartVMAfterMove) {
        $Null = Start-AzVM -ResourceGroupName $VMResourceGroup -Name $VMName -NoWait
    }
}
