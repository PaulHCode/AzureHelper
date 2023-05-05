<#
.SYNOPSIS 
    This function starts a compliance scan for a subscription or all subscriptions. This function requires PowerShell 7 or greater.
.DESCRIPTION 
    This function starts a compliance scan for a subscription or all subscriptions.
    It checks every resource group in the subscription in parallel.
.EXAMPLE 
    Start-AHComplianceScan
    Starts a compliance scan for the current subscription
.EXAMPLE
    Start-AHComplianceScan -AllSubscriptions
    Starts a compliance scan for all subscriptions
#>
Function Start-AHComplianceScan {
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
        [Parameter(ValueFromPipeline = $true)]
        $Subscription
    )
    begin {
        If ($PSVersionTable.PSVersion.Major -lt 7) {
            throw 'This cmdlet requires PowerShell 7 or greater'
        }

        $MyScriptBlock = {
            $subscriptionName = (Get-AzContext).subscription.Name
            $RGs = (Get-AzResourceGroup).ResourceGroupName
            $RGs | ForEach-Object -Parallel {
                $RG = $_
                $result = Invoke-AzResourceAction -ResourceGroupName $RG -ResourceType 'Microsoft.PolicyInsights/policyStates' -ResourceName 'default' -Action 'triggerEvaluation' -Force
                [pscustomobject]@{
                    SubscriptionName = $subscriptionName
                    ResourceGroup    = $RG
                    Result           = $result
                }
            }
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions }
    }
    end {}
}