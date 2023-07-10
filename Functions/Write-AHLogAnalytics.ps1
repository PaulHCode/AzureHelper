Function Write-AHLogAnalytics {
    <#
.SYNOPSIS
    This function sends data to Log Analytics using the Data Collector REST API
.DESCRIPTION
    This function sends data to Log Analytics using the Data Collector REST API
.PARAMETER WorkspaceId
    Specifies the WorkspaceId of the Log Analytics workspace to send the data to.
.PARAMETER SharedKey
    Specifies the SharedKey of the Log Analytics workspace to send the data to.
.PARAMETER LogType
    Specifies the LogType data to send to Log Analytics.
.PARAMETER TimeStampInput
    Specifies the optional TimeStampInput.
.PARAMETER json
    Specifies the json data to send to Log Analytics. The JSON should have 50 or fewer fields.
.PARAMETER odsEndpoint
    Specifies the optional custom odsEndpointURI for other environments I'm not aware of. If not specified, the default is used based on the Azure Environments.
    For example, if you are using Azure Commercial and wanted to specify your odsEndpointUri, you would specify: 'ods.opinsights.azure.com', do not include the https://, or a trailing slash.
.EXAMPLE
    $json = @"
    [{  "StringValue": "MyString1",
        "NumberValue": 42,
        "BooleanValue": true,
        "DateValue": "2019-09-12T20:00:00.625Z",
        "GUIDValue": "9909ED01-A74C-4874-8ABF-D2678E3AE23D"
    },
    {   "StringValue": "MyString2",
        "NumberValue": 43,
        "BooleanValue": false,
        "DateValue": "2019-09-12T20:00:00.625Z",
        "GUIDValue": "8809ED01-A74C-4874-8ABF-D2678E3AE23D"
    }]
"@
    Write-AHLogAnalytics -WorkspaceId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -SharedKey 'MySharedKeyGoesHere' -LogType 'MyLogType' -json $json
.EXAMPLE
    Write-AHLogAnalytics -WorkspaceId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -SharedKey 'MySharedKeyGoesHere' -LogType 'MyLogType' -json $json -TimeStampField $MyDateTimeObject
.NOTES
    Author: #Credit to https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api?tabs=powershell
    I took what they had, validated it, and included it here with minor changes to make it even easier
#>
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceId,
        [Parameter(Mandatory = $true)]
        [string]$SharedKey,
        [Parameter(Mandatory = $true)]
        [string]$LogType,
        [Parameter(Mandatory = $false)]
        [datetime]$TimeStampInput = [datetime]::UtcNow,
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            ((($_ | ConvertFrom-Json -Depth 99) | Get-Member -MemberType NoteProperty).count -le 50) -and `
                ([system.text.asciiEncoding]::Unicode.GetByteCount($_) -lt 32MB) -and `
                ([system.text.asciiEncoding]::Unicode.GetByteCount((($_ | ConvertFrom-Json -Depth 99) | Get-Member -MemberType NoteProperty).Name) -lt 32KB)
            })]
        [string]$json,
        [Parameter(Mandatory = $false)]
        [string]$odsEndpoint
    )

    begin {
        If ([string]::IsNullOrEmpty($odsEndpoint)) {
            switch ((Get-AzContext).Environment.Name) {
                'AzureCloud' {
                    $odsEndpoint = 'ods.opinsights.azure.com'
                    break
                }
                'AzureChinaCloud' {
                    $odsEndpoint = 'ods.opinsights.azure.cn'
                    break
                }
                'AzureUSGovernment' {
                    $odsEndpoint = 'ods.opinsights.azure.us'
                    break
                }
                'AzureGermanCloud' {
                    $odsEndpoint = 'ods.opinsights.azure.de'
                    break
                }
                default {
                    throw 'Unknown Azure Environment'
                }
            }
        }
        #$odsEndpoint
            
        # Create the function to create and post the request
        Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType, $TimeStampField) {
            $method = "POST"
            $contentType = "application/json"
            $resource = "/api/logs"
            $rfc1123date = [DateTime]::UtcNow.ToString("r")
            $contentLength = $body.Length
            $signature = Build-Signature `
                -customerId $customerId `
                -sharedKey $sharedKey `
                -date $rfc1123date `
                -contentLength $contentLength `
                -method $method `
                -contentType $contentType `
                -resource $resource
            $uri = "https://" + $customerId + '.' + $odsEndpoint + $resource + "?api-version=2016-04-01"

            $headers = @{
                "Authorization"        = $signature;
                "Log-Type"             = $logType;
                "x-ms-date"            = $rfc1123date;
                "time-generated-field" = $TimeStampField;
            }
            $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
            #$response | fl * -Force
            return $response.StatusCode

        }
        
        # Create the function to create the authorization signature
        Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
            $xHeaders = "x-ms-date:" + $date
            $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

            $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
            $keyBytes = [Convert]::FromBase64String($sharedKey)

            $sha256 = New-Object System.Security.Cryptography.HMACSHA256
            $sha256.Key = $keyBytes
            $calculatedHash = $sha256.ComputeHash($bytesToHash)
            $encodedHash = [Convert]::ToBase64String($calculatedHash)
            $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
            return $authorization
        }
    }

    Process {
        $TimeStampField = Get-Date $($TimeStampInput.ToUniversalTime()) -Format "o"
        $CustomerId = $WorkspaceId

        # Submit the data to the API endpoint
        $result = Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType -TimeStampField $TimeStampField
        If ($result -ne 200) {
            Write-Error "Error writing to log analytics: $result"
        }
    }
    End {

    }
}