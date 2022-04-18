Function Move-AHVMToSubnet {
    <#
    .SYNOPSIS
        Moves a VM to the specified VNET
    .PARAMETER VNetName
        The name of the VNet to move the VM to
    .PARAMETER VNetResourceGroup
        The name of the ResourceGroup the VNet is in
    .PARAMETER VMName
        The name of the VM to move
    .PARAMETER VMResourceGroup
        The name of the Resource Group the VM is in
    .PARAMETER DeallocateIfNeeded
        If specified and the VM is not in a deallocated state then the VM is deallocated to move.  If the VM is not in a deallocated state and this parameter is not specified then the move fails.
    .PARAMETER StartVMAfterMove
        If specified and the move is successful then the VM is started.  The VM is started with -NoWait to return faster but does not guarantee the VM is finished booting. 
    .Example
            Move-AHVMToSubnet -vNetName NewVNet -VNetResourceGroup NewVnetRG -VMName MyVM -VMResourceGroup VMRG -DeallocateIfNeeded -StartVMAfterMove
    .Notes
        Author: Paul Harrison
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $SubnetName,
        [Parameter(Mandatory = $true)]
        [string]
        $VNetName,
        [Parameter(Mandatory = $true)]
        [string]
        $VNetResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $VMName,
        [Parameter(Mandatory = $true)]
        [string]
        $VMResourceGroupName,
        [Parameter()]
        [switch]
        $DeallocateIfNeeded,
        [Parameter()]
        [switch]
        $StartVMAfterMove
    )
    Throw "This function isn't written yet but I committed to master. Oh well. Just don't use it yet."

    #Check for target vNet existence
    $vNet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $VNetResourceGroupName 
    IF (!$?) {
        throw 'Error finding target vNet'            
    }
    If (!$vNet) {
        throw 'Target vNet not found'
    }

    #Check for target subnet existence
    $vNet = Get-AzVirtualNetwork -Name $VNetName | Get-AzVirtualNetworkSubnetConfig -Name $SubnetName
    IF (!$?) {
        throw 'Error finding target subnet'            
    }
    If (!$vNet) {
        throw 'Target subnet not found'
    }

    #Check for VM existence
    try {
        $VM = Get-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName
    }
    catch {
        throw 'error finding VM'
    }    
    If (!$VM) {
        throw 'VM not found'
    }
    
    #If there are multiple NICs then state that and fail
    If ($VM.NetworkProfile.NetworkInterfaces.Count -gt 1) {
        throw 'The VM has multiple NICs. VMs with multiple NICs are not currently supported by this function. If you really want that feature then drop me a line at github.com/paulhcode'
    }

    #Get the NIC
    try {
        $NIC = Get-AzNetworkInterface -ResourceId $VM.NetworkProfile.NetworkInterfaces[0].Id
    }
    catch {
        throw 'NIC not found'
    }

    #If the subnet is in the same vnet then
    #   1 
    $NIC = Get-AzNetworkInterface -ResourceGroupName 
    #   2
    #   3
    #Else if in the same region but a different vNet
    #   1
    #   2
    #   3
    #Else if in a different region
    #   1
    #   2
    #   3

    #https://www.azureblue.io/how-to-move-an-azure-vm-to-another-vnet/

    
    If ($StartVMAfterMove) {
        $Null = Start-AzVM -ResourceGroupName $VMResourceGroup -Name $VMName -NoWait
    }
}

