#Author: Adam Bertram
#Link: https://github.com/adbertram/Random-PowerShell-Work/blob/master/Azure/Remove-AzrVirtualMachine.ps1
#Date: 10/16/2020

#Deletes the VM and the associated resources
#I like the code that was provided but I did some modifying to get it up to date and working as desired for my needs
function Remove-AHVM {
    <#
	.SYNOPSIS
		This function is used to remove any Azure VMs as well as any attached disks. By default, this function creates a job
		due to the time it takes to remove an Azure VM.
		
	.EXAMPLE
		PS> Get-AzVm -Name 'BAPP07GEN22' | Remove-AzrVirtualMachine
	
		This example removes the Azure VM BAPP07GEN22 as well as any disks attached to it.
		
	.PARAMETER VMName
		The name of an Azure VM. This has an alias of Name which can be used as pipeline input from the Get-AzureRmVM cmdlet.
	
	.PARAMETER ResourceGroupName
		The name of the resource group the Azure VM is a part of.
	
	.PARAMETER Wait
		If you would rather wait for the Azure VM to be removed before returning control to the console, use this switch parameter.
		If not, it will create a job and return a PSJob back.
	#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string]$VMName,
		
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,

        [Parameter()]
        [pscredential]$Credential,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [switch]$Wait
		
    )

    process {
        $scriptBlock = {
            param ($VMName,
                $ResourceGroupName)
            $commonParams = @{
                'Name'              = $VMName;
                'ResourceGroupName' = $ResourceGroupName
            }
            $vm = Get-AzVm @commonParams
            
            #region Remove the boot diagnostics disk
            if ($vm.DiagnosticsProfile.bootDiagnostics) {
                Write-Verbose -Message 'Removing boot diagnostics storage container...'
                $diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
                Get-AzStorageAccount -Name $diagSa -ResourceGroupName $vm.ResourceGroupName | Remove-AzStorageAccount -Force
            
            }
            #endregion


            Write-Verbose -Message 'Removing the Azure VM...'
            $null = $vm | Remove-AzVM -Force
            Write-Verbose -Message 'Removing the Azure network interface...'
            foreach ($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
                $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
                foreach ($ipConfig in $nic.IpConfigurations) {
                    if ($ipConfig.PublicIpAddress -ne $null) {
                        Write-Verbose -Message 'Removing the Public IP Address...'
                        Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
                    } 
                }
                $nsg = Get-AzNetworkSecurityGroup | Where-Object { $_.Id -eq $nic.NetworkSecurityGroup.Id }
                If ($nsg.NetworkInterfaces.Count -eq 0) {
                    Write-Verbose "No other VMs using $($nsg.name) - deleting $($nsg.name)"
                    $nsg | Remove-AzNetworkSecurityGroup -Force
                }
            } 

            			
            ## Remove the OS disk
            Write-Verbose -Message 'Removing OS disk...'
            if ('Uri' -in $vm.StorageProfile.OSDisk.Vhd) {
                ## Not managed
                $osDiskId = $vm.StorageProfile.OSDisk.Vhd.Uri
                $osDiskContainerName = $osDiskId.Split('/')[-2]

                ## TODO: Does not account for resouce group 
                $osDiskStorageAcct = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $osDiskId.Split('/')[2].Split('.')[0] }
                $osDiskStorageAcct | Remove-AzStorageBlob -Container $osDiskContainerName -Blob $osDiskId.Split('/')[-1]

                #region Remove the status blob
                Write-Verbose -Message 'Removing the OS disk status blob...'
                $osDiskStorageAcct | Get-AzStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzStorageBlob
                #endregion
            }
            else {
                ## managed
                #Get-AzDisk | Where-Object { $_.ManagedBy -eq $vm.Id } | Remove-AzDisk -Force
                Get-AzDisk | Where-Object { $_.id -eq $vm.StorageProfile.OsDisk.ManagedDisk.Id } | Remove-AzDisk -Force
            }
			
            ## Remove any other attached disks
            if ('DataDiskNames' -in $vm.PSObject.Properties.Name -and @($vm.DataDiskNames).Count -gt 0) {
                Write-Verbose -Message 'Removing data disks...'
                foreach ($uri in $vm.StorageProfile.DataDisks.Vhd.Uri) {
                    $dataDiskStorageAcct = Get-AzStorageAccount -Name $uri.Split('/')[2].Split('.')[0]
                    $dataDiskStorageAcct | Remove-AzStorageBlob -Container $uri.Split('/')[-2] -Blob $uri.Split('/')[-1]
                }
            }
            Else {
                foreach ($disk in $vm.StorageProfile.DataDisks) {
                    Remove-AzDisk -DiskName $Disk.name -ResourceGroupName $vm.ResourceGroupName -Force
                }
            }



        }
			
        if ($Wait.IsPresent) {
            & $scriptBlock -VMName $VMName -ResourceGroupName $ResourceGroupName
        }
        else {
            $initScript = {
                $null = Login-AzAccount -Credential $Credential
            }
            $jobParams = @{
                'ScriptBlock'          = $scriptBlock
                'InitializationScript' = $initScript
                'ArgumentList'         = @($VMName, $ResourceGroupName)
                'Name'                 = "Azure VM $VMName Removal"
            }
            Start-Job @jobParams 
        }
    }
}
