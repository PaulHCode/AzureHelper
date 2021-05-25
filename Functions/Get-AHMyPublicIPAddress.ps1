Function Get-AHMyPublicIPAddress {
    <#
.SYNOPSIS
    Gets the public IP that Azure would see from whatever computer you run this on.

.DESCRIPTION
    Gets the public IP that Azure would see from whatever computer you run this on.  

.EXAMPLE
    Get-AHMyPublicIPAddress

.OUTPUTS
    String

.NOTES
    Author:  Paul Harrison
#>

    $MyIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
    If ($MyIP -as [IPAddress] -as [Bool]) {
        $MyIP
    }
    else {
        throw 'Error getting your public IP address.'
    }
}