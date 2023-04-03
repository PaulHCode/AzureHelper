<#
.SYNOPSIS
    Helper function for Remove-AHMyIPFromResources
.DESCRIPTION
    Helper function for Remove-AHMyIPFromResources
.EXAMPLE
    Remove-AHMyIPFromResourcesHelper -Type 'Microsoft.KeyVault/vaults' -Id '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroup/providers/Microsoft.KeyVault/vaults/MyKeyVault' -IPAddress <IP Address>
#>
Function Remove-AHMyIPFromResourcesHelper {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Type,
        [Parameter()]
        [string]
        $Id,
        [Parameter()]
        [string]
        $IPAddress
    )   

    switch ($Type) {
        'Microsoft.KeyVault/vaults' { Remove-AHMyIPFromKeyVault -Id $Id -IPAddress $IPAddress }
        'Microsoft.Storage/storageAccounts' { Remove-AHMyIPFromStorageAccount -Id $Id -IPAddress $IPAddress }
        'Microsoft.Sql/servers' { Remove-AHMyIPFromSQLServer -Id $Id -IPAddress $IPAddress }
        'Microsoft.ContainerRegistry/registries' { Remove-AHMyIPFromContainerRegistry -Id $Id -IPAddress $IPAddress }
        Default { Write-Warning "The type $Type is not supported. Resource ID $Id was not modified." }
    }

}
