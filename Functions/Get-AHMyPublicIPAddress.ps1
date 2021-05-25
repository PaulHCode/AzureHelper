Function Get-AHMyPublicIPAddress {    
    $response = Invoke-RestMethod -Uri "http://ifconfig.me/ip"
    
    # casting response to IPAddress class and get the result as a Bool
    if ( $response -as [IPAddress] -as [Bool] ) {
        return $response
    }else {
        throw 'Error getting your public IP address'
    }
}
