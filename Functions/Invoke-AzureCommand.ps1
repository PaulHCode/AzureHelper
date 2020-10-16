function Invoke-AzureCommand {
    <#
.SYNOPSIS
    Runs a script block against every subscription or a different subscription than
    the current context.
.DESCRIPTION
    Invoke-AzureCommand runs a script block against a different context or every 
    subscription.  
.PARAMETER ScriptBlock
    The script block to run
.PARAMETER ArgumentList
    Specifies an array of arguments to pass to the ScriptBlock 
.PARAMETER AllSubscriptions
    Run this command against all subscriptions except disabled subscriptions.
.PARAMETER IncludeDisabledSubscriptions
    Include disabled subscriptions when selecting -AllSubscriptions
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.EXAMPLE
     Invoke-AllSubs -ScriptBlock ([scriptblock]::Create('write-host "hello world from $((get-azcontext).name)"'))
.EXAMPLE
     $DiskScriptBlock = {Get-AzDisk | Where{$_.DiskSizeGB -gt 512}}
    Invoke-AzureCommand -AllSubscriptions -ScriptBlock $DiskScriptBlock | FT ResourceGroupName, Name, DiskSizeGB
    This example finds every disk larger than 512 GB in every subscription
.INPUTS
    ScriptBlock
.OUTPUTS
    [array]
.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [ScriptBlock]
        $ScriptBlock,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription,
    
        [switch]
        $AllSubscriptions,

        [switch]
        $IncludeDisabledSubscriptions,

        [array]
        $ArgumentList
    )

    process {
        Test-AHEnvironment
        if (-not $AllSubscriptions -and -not $Subscription) {
            return $ScriptBlock.Invoke($ArgumentList)
        }
    
        $currentSub = Get-AzContext
    
        if ($Subscription) { $subs = $Subscription }
        else { $subs = Get-AzSubscription }
        If (!($IncludeDisabledSubscriptions)) {
            $subs = $subs | Where-Object { 'Enabled' -eq $_.State }
        }
    
        $subCount = 0
        foreach ($sub in $subs) {
            $Null = Set-AzContext $sub
            Write-Progress -Activity "Checking each subscription" -Status (Get-AzContext).Subscription.Name -PercentComplete (100 * $subCount / $($subs.count))
            $ScriptBlock.Invoke($ArgumentList)
            $subCount++
        }
        $null = Set-AzContext $currentSub
    }
}