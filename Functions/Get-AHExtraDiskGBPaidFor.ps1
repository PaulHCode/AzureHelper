function Get-AHExtraDiskGBPaidFor {
    <#
.SYNOPSIS
    Gets every disk and returns how much space is paid for but not allocated.

.DESCRIPTION
    Get-AHExtraDiskGBPaidFor is a function that returns a list of Azure Disks and
    the size in GB that is being paid for but is not currently allocated.  

.PARAMETER AllSubscriptions
    Run this command against all subscriptions.

.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.

.EXAMPLE
     Get-AHExtraDiskGBPaidFor -AllSubscriptions

.EXAMPLE
     Get-AHExtraDiskGBPaidFor -AllSubscriptions | Export-Csv ExtraDiskGBPaidFor.csv -NoTypeInformation

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
        $Subscription
    )

    begin {
        Test-AHEnvironment
        Function Get-ExtraGBPaidForHelper {
            param(
                $disk
            )
            # I should get these programatically but I don't use this function much or care to fix this
            $PList = @(4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32767) #premium ssd
            $EList = @(4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32767) #standard ssd
            $SList = @(32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32767) #standard hdd
        
            If ($($disk.sku.Name) -like "*UltraSSD*") {
                0
            }
            ElseIf ($($disk.sku.Name) -like "*Premium*") {
                $allowedDiskSizes = $PList
            }
            Elseif ($($disk.sku.Name) -like "*StandardSSD*") {
                $allowedDiskSizes = $EList
            }
            Elseif ($($disk.sku.Name) -like "*Standard*") {
                $allowedDiskSizes = $SList
            }
        
            If ($allowedDiskSizes -contains $($disk.diskSizeGB)) {
                0
            }
            Elseif ($($disk.diskSizeGB) -gt $($allowedDiskSizes[$allowedDiskSizes.Count - 1])) {
                Write-Error "Disk size too big"
            }
            Else {
                If (($($disk.diskSizeGB) -lt $allowedDiskSizes[0])) {
                    $allowedDiskSizes[0] - $($disk.diskSizeGB)
                }
                Else {
                    For ($i = 0; $i -lt $($allowedDiskSizes.Count - 1); $i++) {
                        If (($($disk.diskSizeGB) -gt $allowedDiskSizes[$i]) -and ($($disk.diskSizeGB) -lt $allowedDiskSizes[($i + 1)])) {
                            $allowedDiskSizes[$i + 1] - $($disk.diskSizeGB)
                        }
                    }
                }
            }
        }
        $MyScriptBlock = {
            Get-AzDisk | Select-Object @{ N = "Subscription"; E = { (Get-AzContext).Subscription.Name } }, ResourceGroupName, Name, Id, OsType, DiskSizeGB, @{N = "ExtraGBPaidFor"; E = { Get-ExtraGBPaidForHelper -disk $_ } }
        }        
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
}