


function Get-AHNonHubWindowsServers {
    <#
    .SYNOPSIS
        Gets a list of Windows servers not using Azure Hybrid Use Benefits.
    
    .DESCRIPTION
        Get-AHNonHubWindowsServers is a function that returns a list of Windows VMs that 
        are not using Azure Hybrid Use Benefits.  
    
    .PARAMETER AllSubscriptions
        Run this command against all subscriptions.
    
    .PARAMETER Subscription
        Specifies the subscription to run against. The default is the current subscription.
    
    .EXAMPLE
        Get-AHNonHubWindowsServers -AllSubscriptions
    
    .EXAMPLE
        Get-AHNonHubWindowsServers -AllSubscriptions | Export-Csv NonAHUBWindowsServers.csv -NoTypeInformation
    
    .INPUTS
        String
    
    .OUTPUTS
        Selected.Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineList
    
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
                $thisSub = (Get-AzContext).Subscription.Name
                Get-AzVm | 
                Where-Object {$_.StorageProfile.OsDisk.OsType -like "Windows" -and $Null -eq $_.LicenseType} |
                Select-Object @{N = "Subscription"; E = { $thisSub } }, ResourceGroupName,  Name, LicenseType, Id, VmId   
            }
        }
        process {
            if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
            else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
        }
    }