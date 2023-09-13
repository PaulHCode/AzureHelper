Function Test-AHFunctionApp {
    <#
        .SYNOPSIS 
            This function runs all the functions in a function app.
        .DESCRIPTION
            This function runs all the functions in a function app.  This is useful for testing
            functions that are not HTTP triggered.
        .PARAMETER SubscriptionId
            The subscription ID of the function app
        .PARAMETER TenantId
            The tenant ID of the function app
        .PARAMETER ResourceGroupName
            The resource group name of the function app
        .PARAMETER FunctionAppName
            The name of the function app
        .PARAMETER waitPeriod
            The number of seconds to wait between running each function.  The default is 30 seconds.
        .EXAMPLE
            Test-AHFunctionApp -SubscriptionId '00000000-0000-0000-0000-000000000000' -ResourceGroupName 'functions-test' -FunctionAppName 'aztosoTest'
            Runs all the functions in the function app 'aztosoTest' in the resource group 'functions-test' in the subscription '00000000-0000-0000-0000-000000000000'
        .INPUTS
            String
        .OUTPUTS
            None
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId = (Get-AzContext).Subscription.Id,
        [Parameter(Mandatory = $false)]
        [string]$TenantId = (Get-AzContext).Tenant.Id,
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]$FunctionAppName,
        [Parameter(Mandatory = $false)]
        [int]$waitPeriod = 30
    )
    begin {
        Set-AzContext -SubscriptionId $SubscriptionId -TenantId $TenantId | Out-Null
        $environment = (Get-AzContext).Environment.Name
        $resourceManagerUrl = (Get-AzEnvironment -Name $(Get-AzContext).environment.name).ResourceManagerUrl
        $ADAuthorityURI = (Get-AzEnvironment -Name $(Get-AzContext).environment.name).ActiveDirectoryAuthority
    }
    process {
        #This is in the process block in case different functions are passed to this function in through the pipeline
        Switch ($environment) {
            'AzureUsGovernment' {
                $functionAppUrl = "https://$FunctionAppName.azurewebsites.us/"
            }
            'AzureCloud' {
                $functionAppUrl = "https://$FunctionAppName.azurewebsites.net/"
            }
            'AzureChinaCloud' {
                $functionAppUrl = "https://$FunctionAppName.azurewebsites.chinacloudapi.cn/"
            }
            'AzureGermanCloud' {
                $functionAppUrl = "https://$FunctionAppName.azurewebsites.cloudapi.de/"
            }
        }

        $resourceManagerToken = (Get-AzAccessToken -ResourceUrl $resourceManagerUrl).Token
        # get the master host key
        # - https://learn.microsoft.com/en-us/rest/api/appservice/web-apps/list-host-keys
        # - https://aztoso.com/functions/keys/#:~:text=To%20get%20the%20host%2C%20master%2C%20and%20system%20key%2C,following%20command%3A%20az%20functionapp%20keys%20list%20-grg-functions-test%20-naztosotest
        $uri = $resourceManagerUrl + "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/host/default/listkeys?api-version=2018-11-01"
        $header = @{Authorization = "Bearer $resourceManagerToken" }
        $result = Invoke-RestMethod -Method Post -Uri $uri -Headers $header
        $MasterKey = $result.masterKey

        $FunctionApp = Get-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName

        #Find all the functions in the function app
        # - https://learn.microsoft.com/en-us/rest/api/appservice/web-apps/list-functions
        $uri = $resourceManagerUrl + "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$FunctionAppName/functions?api-version=2018-11-01"
        $functions = Invoke-RestMethod -Method Get -Uri $uri -Headers $header

        # Run the functions
        # - https://learn.microsoft.com/en-us/azure/azure-functions/functions-manually-run-non-http
        ForEach ($function in $functions.value) {
            $uri = $functionAppUrl + "admin/functions/$($function.properties.Name)"
            $header = @{
                'x-functions-key' = $MasterKey
                'Content-Type'    = 'application/json'
            }
            $body = @{
                input = 'test'
            }
            $result = Invoke-RestMethod -Method Post -Uri $uri -Headers $header -Body ($body | ConvertTo-Json)
            Start-Sleep -Seconds $waitPeriod
        }

    }
    end {

    }
}