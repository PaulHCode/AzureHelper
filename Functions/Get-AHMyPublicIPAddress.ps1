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

    $response = Invoke-RestMethod -Uri "http://ifconfig.me/ip"
        
    # casting response to IPAddress class and get the result as a Bool
    if ( $response -as [IPAddress] -as [Bool] ) {
        return $response
    }
    else {
        throw 'Error getting your public IP address'
    }
}