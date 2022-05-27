Function Move-AHVMToAvailabilitySet {
    <#
    .SYNOPSIS
        Moves a VM to the specified availability set
    .PARAMETER ResourceGroup
        The name of the resource group
    .PARAMETER VMName
        The name of the VM to move
    .PARAMETER NewAvailabilitySet
        The name of the new availability set
    .PARAMETER File
        The path and file name to write backup data to in case data was configured incorrectly
    .Example
            Move-AHVMToAvailabilitySet -ResourceGroup MyRG -VMName VM2 -NewAvailabilitySet AS2 -File .\test.xml
    .Notes
        Author: Paul Harrison
        This function is largely copied from: https://docs.microsoft.com/en-us/azure/virtual-machines/windows/change-availability-set#change-the-availability-set
        If there is enough demand I may make the function more generalized like allow moving between availability sets that are in different resource groups, regions, etc, but this is just a quick POC to show that it works.

        This is a work in progress. I don't know if I'll expand the file backup part in case something goes wrong or get rid of it later because this should just work. I don't have code in here to support restoring from the backed up file in case anything breaks either... whatever

    #>


    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroup,
        [Parameter(Mandatory = $true)]
        [string]
        $VMName,
        [Parameter(Mandatory = $true)]
        [Alias('NewAvailabilitySetName')]
        [string]
        $NewAvailSetName,
        [Parameter(Mandatory = $false)] #not mandatory, but recommended
        [string] #I should add in file path validation, oh well
        $File
    )

    Begin {
        
    }
    process {
        #get my VM to mess with
        $originalVM = Get-AzVM -ResourceGroup $ResourceGroup -Name $VMName

        # Create new availability set if it does not exist
        $availSet = Get-AzAvailabilitySet -ResourceGroupName $resourceGroup -Name $newAvailSetName -ErrorAction Ignore
        if (-Not $availSet) {
            $availSet = New-AzAvailabilitySet -Location $originalVM.Location -Name $newAvailSetName -ResourceGroupName $resourceGroup -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 -Sku Aligned
        }


        #document the info I need about it
        $originalVMBackup = [PSCustomObject]@{
            Location        = $originalVM.Location
            Name            = $originalVM.Name
            HardwareProfile = $originalVM.HardwareProfile
            StorageProfile  = $originalVM.StorageProfile
            ManagedDiskId   = $originalVM.StorageProfile.OsDisk.ManagedDisk.Id
            NetworkProfile  = $originalVM.NetworkProfile
            availSetId      = $availSet.Id
            OSType          = $originalVM.StorageProfile.OsDisk.OsType
            #I should copy the old AS platformfaultdomaincount, platformupdatedomaincount, sku, etc tot the new one if it isn't defined already
        }

        If ($file) {
            $originalVMBackup | Export-Clixml $File -Force
        }
        $originalVM = $originalVMBackup

    
        # Remove the original VM
        Remove-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Confirm:$false -Force
    
        $newVM = New-AzVMConfig -VMName $originalVM.Name -VMSize $originalVM.HardwareProfile.VmSize -AvailabilitySetId $originalVM.availSetId

        #        $mySplat = @{
        #            VM            = $newVM
        #            ManagedDiskId = $originalVM.ManagedDiskId
        #            Name          = $originalVM.StorageProfile.OsDisk.Name 
        #        }
        If ($originalVM.OSType -eq 'Windows') {
            Set-AzVMOSDisk -VM $newVM -CreateOption Attach -ManagedDiskId $originalVM.ManagedDiskId -Name $originalVM.StorageProfile.OsDisk.Name -Windows
        }
        Elseif ($originalVM.OSType -eq 'Linux') {
            Set-AzVMOSDisk -VM $newVM -CreateOption Attach -ManagedDiskId $originalVM.ManagedDiskId -Name $originalVM.StorageProfile.OsDisk.Name Linux
        }
        Else {
            throw "Unexpected OSType $($originalVM.OSType)"
        }
        
    
        # Add Data Disks
        foreach ($disk in $originalVM.StorageProfile.DataDisks) { 
            Add-AzVMDataDisk -VM $newVM -Name $disk.Name -ManagedDiskId $disk.ManagedDisk.Id -Caching $disk.Caching -Lun $disk.Lun -DiskSizeInGB $disk.DiskSizeGB -CreateOption Attach
        }
        
        # Add NIC(s) and keep the same NIC as primary; keep the Private IP too, if it exists.
        foreach ($nic in $originalVM.NetworkProfile.NetworkInterfaces) {	
            if ($nic.Primary -eq 'True') {
                Add-AzVMNetworkInterface -VM $newVM -Id $nic.Id -Primary
            }
            else {
                Add-AzVMNetworkInterface -VM $newVM -Id $nic.Id 
            }
        }
        
        # Recreate the VM
        New-AzVM -ResourceGroupName $resourceGroup -Location $originalVM.Location -VM $newVM -DisableBginfoExtension
    
    
    
    }
}