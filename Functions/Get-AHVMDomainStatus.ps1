Function Get-AHVMDomainStatus {
    <#
.SYNOPSIS
    Queries every VM in an Azure subscription to which are joined to the same domain as the VM running this command.
.DESCRIPTION
    Queries every VM in an Azure subscription to which are joined to the same domain as the VM running this command.
.EXAMPLE
     Get-AHVMDomainStatus
.EXAMPLE
     Get-AHVMDomainStatus | Export-CSV VMDomainStatus.csv
.INPUTS
.OUTPUTS
    Selected.System.String
.NOTES
    Author:  Paul Harrison
#>
    param(
        [parameter(
            ParameterSetName = 'AllVMs'
        )]
        [switch]
        $AllVMs,

        [parameter(
            ParameterSetName = 'OneVM'
        )]
        [string]
        $VMName,

        [parameter(
            ParameterSetName = 'OneVM'
        )]
        [string]
        $VMResourceGroup
    )
    Begin {
        Test-AHEnvironment
        Try {
            $Null = get-command get-adcomputer -ErrorAction Stop
        }
        Catch {
            Throw 'To use Get-AHVMDomainStatus the command Get-ADComputer must be available from the ActiveDirectory module.'
        }
        If (!(Get-CimInstance -ClassName win32_computersystem).partofdomain) {
            Throw "Get-AHVMDomainStatus is being ran from a computer that is not domain joined."
        }

        $domain = ([adsi]'').distinguishedName -replace (",DC=", '.') -replace ("DC=", '') #(get-addomain).name
        $Subscription = (get-azcontext).subscription.name
        $VMCounter = 0
        write-verbose "Checking if each VM in $((get-azcontext).subscription.name) is domain joined to $domain"
    }
    process {    
        $output = @()
        If ($AllVMs) {
            $VMs = (get-azvm | Where-Object { $Null -ne $_.OSProfile.WindowsConfiguration })
        }
        ElseIf ($Null -ne $VMName -and $Null -ne $VMResourceGroup) {
            $VMs = (get-azvm -Name $VMName -ResourceGroupName $VMResourceGroup)
        }
        Else {
            Throw 'Use either the -AllVMs switch or specify both -VMName and -VMResourceGroup'
        }
        ForEach ($VM in $VMs) {
            write-progress -Activity "Checking if $Subsciption Azure VMs are joined to $domain" -status "Checking $($VM.Name)" -percentComplete (100 * $VMCounter / ($vms.count))
            $VMCounter++
            $VMout = "" | Select-Object Name, ResourceGroupName, HostName, DomainJoined
            $VMout.Name = $VM.Name
            $VMout.ResourceGroupName = $VM.ResourceGroupName
            $DetectedHostname = $Null
            
            foreach ($NIC in ($VM.NetworkProfile.NetworkInterfaces.id)) {
                foreach ($ipconfig in (Get-AzNetworkInterface -ResourceId $NIC).IpConfigurations) {
                    If ($DetectedHostname) {
                        try {
                            $DetectedHostname = ([system.net.dns]::GetHostByAddress(($ipconfig.privateIpAddress))).hostname
                        }
                        Catch {
                            #not detected on the current domain
                            #                $DetectedHostname = $Null
                        }
                    }
                }
            }
    
            $VMout.HostName = $DetectedHostname
            $VMout.DomainJoined = $false
            If ($DetectedHostname) {
                $VMout.DomainJoined = $true
                try {
                    Get-ADComputer -Identity $DetectedHostname
                }
                catch {
                    $VMout.DomainJoined = $false
                }
            }
            #        $VMout.DomainJoined = !($Null -eq $DetectedHostname)
            $output += $VMout
        }
        $output
    }
}
    