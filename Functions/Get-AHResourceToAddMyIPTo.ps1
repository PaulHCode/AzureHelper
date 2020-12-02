Function Get-AHResourceToAddMyIPTo {
    <#
.SYNOPSIS
    List the resources to add or remove my IP to.
.DESCRIPTION
    Lists the resources to add or remove my IP to.  The list is then used by other cmdlets found in the RELATED LINKS section of the help.
.EXAMPLE
    Get-AHResourceToAddMyIPTo
.INPUTS
.OUTPUTS
    System.Management.Automation.PSCustomObject
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
    $Script:ResourceToAddMyIPTo
}