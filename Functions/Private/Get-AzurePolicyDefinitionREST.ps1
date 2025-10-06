function Get-AzurePolicyDefinitionREST {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PolicyDefinitionId
    )
    $managementUri = (Get-AzEnvironment -Name (Get-AzContext).Environment.Name).ResourceManagerUrl.trim('/')
    $token = [runtime.interopservices.marshal]::PtrToStringAuto([runtime.interopservices.marshal]::SecureStringToBSTR((Get-AzAccessToken -AsSecureString -ResourceUrl $managementUri).token)) #;$token | scb
    $uri = "$($managementUri)$($PolicyDefinitionId)?api-version=2023-04-01"
    $header = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $($token)"
    }
    $result = Invoke-RestMethod -Method GET -Uri $uri -Headers $header
    $result
}