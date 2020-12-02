Function Add-AHResourceToAddMyIPTo {
    <#
.SYNOPSIS
    Adds a resource to the list of resources to add or remove my IP to.
.DESCRIPTION
    Adds a resource to the list of resources to add or remove my IP to.  The list is then used by other cmdlets found in the LINK section of the help.
.PARAMETER ResourceId
    Define the resource to be added
.PARAMETER ResourceGroupName
    The name of a resource group.  All resources in the resource group will be added.
.EXAMPLE
    Add-AHResourceToAddMyIPTo -ResourceId /subscriptions/xxxxxxxx-a123-asdf-1234-123456abcdef/resourceGroups/Test1RG/providers/Microsoft.Storage/storageAccounts/sa2
    Add-AHResourceToAddMyIPTo -ResourceId /subscriptions/xxxxxxxx-a123-asdf-1234-123456abcdef/resourceGroups/Test1RG/providers/Microsoft.KeyVault/vaults/KV5
    Add-AHResourceToAddMyIPTo -ResourceId /subscriptions/xxxxxxxx-a123-asdf-1234-123456abcdef/resourceGroups/Test1RG/providers/Microsoft.Sql/servers/ss1

    Adds a storage account, key vault, and sql server to the list
.EXAMPLE
    Add-AHResourceToAddMyIPTo -GUI

    Use the GUI to select the resources to add to the list.
.EXAMPLE
    Add-AHResourceToAddMyIPTo -ResourceGroupName Test1RG
    Add-AHMyIPToResources
    #do my work here
    Remove-AHMyIPFromResources
    (Get-AHResourceToAddMyIPTo).Id | Remove-AHResourceToAddMyIPTo
    Add-AHResourceToAddMyIPTo -ResourceGroupName Test2RG

    Adds all resources in the Test1RG resource group to the list, then adds my public IP to the firewall rules on those resource, then removes access to resources, then clears the list to start work in another resource group
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
        [string]
        $ResourceGroupName,

        [parameter(ParameterSetName = "GUI", Mandatory = $true)]
        [switch]
        $GUI
    )
    begin {
        If ($Null -eq $Script:ResourceToAddMyIPTo) {
            $Script:ResourceToAddMyIPTo = @()
        }
    }

    process {
        If ($GUI) {
            If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
                throw "The GUI switch can only be used on a local host and cannot be used from a remote session."
            }
            elseif ((get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
                throw "The GUI switch can only be used on a local host and cannot be used from Azure Cloud Shell."
            }           

            $Resources = Get-AzResource | Out-GridView -PassThru -Title 'Select the resources to add your IP to' 
            If (-not $?) {
                Throw "Something went wrong"
            }
            Else {
                ForEach ($Resource in $Resources) {
                    Add-AHResourceToAddMyIPTo -ResourceID $Resource.ResourceId
                }
            }
        }
        ElseIf ($ResourceID) {
            $MyResource = Get-AzResource -ResourceId $ResourceID
            If (-not $?) {
                #The resource no longer exists
                return 
            }
            Else {
                $Script:ResourceToAddMyIPTo += [PSCustomObject]@{
                    subscription = $MyResource.ResourceId.Split('/')[2] #this is faster than querying context, if this doesn't work at somepoint then replace with (Get-AzContext).Subscription.Id
                    Type         = $MyResource.Type
                    Id           = $MyResource.ResourceId
                }
            }
        }
        ElseIf ($ResourceGroupName) {
            $Resources = Get-AzResource -ResourceGroupName $ResourceGroupName
            If (-not $?) {
                Throw "The resource group $ResourceGroupName does not exist."
            }
            Else {
                ForEach ($Resource in $Resources) {
                    Add-AHResourceToAddMyIPTo -ResourceID $Resource.ResourceId
                }
            }


        }
    }

}