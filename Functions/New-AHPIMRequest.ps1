<#
$myEnvironment = get-azcontext
$graphUri = $myEnvironment.environment.ExtendedProperties.MicrosoftGraphUrl
if($Null -eq $graphUri) {throw 'You must connect-azaccount first.'}

// Function to get the groups the user has PIM permission into
function getGroupsICanPIMInto() {
    $myEnvironment = get-azcontext
    $graphUri = $myEnvironment.environment.ExtendedProperties.MicrosoftGraphUrl
    if($Null -eq $graphUri) {throw 'You must connect-azaccount first.'}
    $token = (get-azaccesstoken -resourceurl $GraphResourceUrl).token
    $groupsICanPIMTo = Invoke-DCMsGraphQuery -AccessToken $token -GraphMethod 'POST' -GraphUri "$graphUri/v1.0/me/getMemberGroups" -GraphBody '{"securityEnabledOnly": true}'
    $groupsICanPIMTo
}




    $myEnvironment = get-azcontext
    $GraphResourceUrl = $myEnvironment.environment.ExtendedProperties.MicrosoftGraphUrl
    if($Null -eq $graphUri) {throw 'You must connect-azaccount first.'}
    $token = (get-azaccesstoken -resourceurl $GraphResourceUrl).token
    $groupsICanPIMTo = Invoke-DCMsGraphQuery -AccessToken $token -GraphMethod 'POST' -GraphUri "$GraphResourceUrl/v1.0/me/getMemberGroups" -GraphBody '{"securityEnabledOnly": true}'

#>