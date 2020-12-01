Function Add-AHResourceToAddMyIPTo {
    <#
.SYNOPSIS
    Adds a resource to the list of resources to add or remove my IP to.
.DESCRIPTION
    Adds a resource to the list of resources to add or remove my IP to.
.PARAMETER ResourceId
    Define the resource to be added
.PARAMETER ResourceGroupName
    The name of a resource group.  All resources in the resource group will be added.
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
    param(
        [Parameter(ParameterSetName = "ResourceId", Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $ResourceID,

        [Parameter(ParameterSetName = "ResourceGroup", Mandatory = $true)]
        [switch]
        $ResourceGroupName,

        [parameter(ParameterSetName = "GUI", Mandatory = $true)]
        [switch]
        $GUI
    )
    begin {
        <#
        $AcceptableTypes = @(
            'Microsoft.KeyVault/vaults',
            'Microsoft.Compute/virtualMachines'
        )
 #>
        If ($Null -eq $Script:ResourceToAddMyIPTo) {
            $Script:ResourceToAddMyIPTo = @()
        }
    }

    process {
        If ($GUI) {
            Throw "The GUI has not yet been written."
        }
        ElseIf ($ResourceID) {
            $MyResource = Get-AzResource -ResourceId $ResourceID
            If (-not $?) {
                #The resource no longer exists
                return 
            }
            <#            If ($MyResource.Type -notin $AcceptableTypes) {
                Throw "Resources of type $($MyResource.Type) are currently not supported."
            }
            
            Else {#>
            $Script:ResourceToAddMyIPTo += [PSCustomObject]@{
                subscription = $MyResource.ResourceId.Split('/')[2] #this is faster than querying context, if this doesn't work at somepoint then replace with (Get-AzContext).Subscription.Id
                Type         = $MyResource.Type
                Id           = $MyResource.ResourceId
            }
            #}
        }
        ElseIf ($ResourceGroupName) {
            throw "use the -ResourceID switch for now, I haven't written the -ResourceGroupName one yet"
            try {
            
            }
            catch {
            
            }

        }
    }

}