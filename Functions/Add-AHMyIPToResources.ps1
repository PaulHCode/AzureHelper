Function Add-AHMyIPToResources {
    <#
.SYNOPSIS
    Adds your public IP address to the firewall rules.
.DESCRIPTION
    Adds your public IP as determined by Get-AHMyPublicIPAddress to the resources that you can check using Get-AHResourceToAddMyIPTo
.EXAMPLE
    Add-AHMyIPToResources
.EXAMPLE
  #Add the RG that has the resources I want to access to the list
  Add-AHResourceToAddMyIPTo -ResourceGroupName MyResourceGroup1
  Add-AHResourceToAddMyIPTo -ResourceId /subscriptions/xxxxxxxx-a123-asdf-1234-123456abcdef/resourceGroups/Test1RG/providers/Microsoft.KeyVault/vaults/KV5
  #Give myself access to those resources
  Add-AHMyIPToResources
  #Check which resources I have in my list
  Get-AHResourceToAddMyIPTo | Format-List
  #Export them for use later
  Export-AHResourcesToAddMyIPTo -Path 'C:\folder\ResourceINeedAccessTo.csv'
  #Remove access to resources I don't need to access anymore
  Remove-AHMyIPFromResources -IPAddress (Get-AHMyPublicIPAddress)
  #Clear the list in use
  (Get-AHResourceToAddMyIPTo).Id | Remove-AHResourceToAddMyIPTo
  #Add another list for other resources you work with
  Import-AHResourcesToAddMyIPTo  -Path 'C:\folder\TheOtherResourcesINeedAccessTo.csv'
  #Verify that they are the right ones
  Get-AHResourceToAddMyIPTo
  #Give myself access to those resources
  Add-AHMyIPToResources
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
    begin {
        $originalSub = (Get-AzContext).Subscription.Id
        $Script:MyPublicIPAddress = Get-AHMyPublicIPAddress
    }
    process {
        #this method minimizes the number of time to change AZ contexts
        ForEach ($GroupOfResources in (Get-AHResourceToAddMyIPTo | Group-Object -Property subscription)) {
            $Null = Set-AzContext -SubscriptionId $GroupOfResources.Name
            ForEach ($Resource in $GroupOfResources.Group) {
                Add-AHMyIPToResourcesHelper -Type $Resource.type -Id $Resource.Id
            }
        }
    }
    end {
        $Null = Set-AzContext -SubscriptionId $originalSub
    }
}

