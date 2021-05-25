Function Get-AHMyPublicIPAddress {    
    # capturing the response
    $response = Invoke-RestMethod -Uri "http://ifconfig.me/ip"
    
    # casting response to IPAddress class and get the result as a Bool
    if ( $response -as [IPAddress] -as [Bool] ) {
        return $response
    }
}
