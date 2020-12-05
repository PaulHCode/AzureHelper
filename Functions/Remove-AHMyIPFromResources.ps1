Function Remove-AHMyIPFromResources {
    <#
.SYNOPSIS
    Removes your public IP address from the firewall rules.
.DESCRIPTION
    Removes your public IP as determined by Get-AHMyPublicIPAddress from the resources that you can check using Get-AHResourceToAddMyIPTo
.EXAMPLE

.EXAMPLE
.EXAMPLE
.INPUTS
    String
.OUTPUTS
.NOTES
    Author:  Paul Harrison
.LINK
    Get-AHResourceToAddMyIPTo
    Remove-AHResourceToAddMyIPTo
    Export-AHMyResourcesToAddMyIPTo
    Import-AHMyResourcesToAddMyIPTo
    Add-AHMyIPToResources
    Remove-AHMyIPFromResources
    Get-AHMyPublicIP
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $IPAddress
    )
    begin {
        $originalSub = (Get-AzContext).Subscription.Id
        $Script:MyPublicIPAddress = Get-AHMyPublicIPAddress
    }
    process {
        #this method minimizes the number of time to change AZ contexts
        ForEach ($GroupOfResources in (Get-AHResourceToAddMyIPTo | Group-Object -Property subscription)) {
            $Null = Set-AzContext -SubscriptionId $GroupOfResources.Name
            ForEach ($Resource in $GroupOfResources.Group) {
                Remove-AHMyIPFromResourcesHelper -Type $Resource.type -Id $Resource.Id -IPAddress $IPAddress
            }
        }
    }
    end {
        $Null = Set-AzContext -SubscriptionId $originalSub
    }
}

