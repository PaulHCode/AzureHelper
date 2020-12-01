Function Get-AHMyPublicIPAddress {
    (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
    #I really should do data validation to make sure that an IP is returned, or at least make sure something was returned.
}