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
