Function Remove-AHResourceToAddMyIPTo {
    <#
.SYNOPSIS
    Remove one or more items from the list the resources to add or remove my IP to.
.DESCRIPTION
    Remove one or more items from the list the resources to add or remove my IP to.
.Parameter Id
    A resource ID or array of resource IDs to remove.
.EXAMPLE
    Remove-AHResourceToAddMyIPTo -ResourceId /subscriptions/xxxxxxxx-a123-asdf-1234-123456abcdef/resourceGroups/Test1RG/providers/Microsoft.Storage/storageAccounts/sa2
.EXAMPLE
    (Get-AHResourceToAddMyIPTo).Id | Remove-AHResourceToAddMyIPTo

    Removes all resources from the list
.INPUTS
    System.String
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
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $ResourceId
    )
    process {
        $Script:ResourceToAddMyIPTo = $Script:ResourceToAddMyIPTo | Where-Object { $_.Id -notin $ResourceId }
    }
}