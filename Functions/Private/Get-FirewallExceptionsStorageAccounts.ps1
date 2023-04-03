Function Get-AHVMBackupStatus {
    <#
.SYNOPSIS
    Gets the exceptions to firewall configurations for storage accounts  - helper to Get-FirewallExceptions
.DESCRIPTION
    Gets the exceptions to firewall configurations for storage accounts - helper to Get-FirewallExceptions
.PARAMETER AllSubscriptions
    Run this command against all subscriptions.
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.PARAMETER ResourceType
    asdf
.EXAMPLE
 
.INPUTS

.OUTPUTS

.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription,

        [Parameter(ValueFromPipeline = $true)]
        [ValidateSet('StorageAccounts')]
        $ResourceType
    )
    begin {

    }
    Process {


    }
    End {

        "This cmdlet doesn't do anything yet. I developed a different feature I wanted to commit on this branch so... here is this useless cmdlet"
    }

}
