Function Add-AHMyIPToResourcesHelper {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Type,
        [Parameter()]
        [string]
        $Id
    )   

    switch ($Type) {
        'Microsoft.KeyVault/vaults' { Add-AHMyIPToKeyVault -Id $Id }
        'Microsoft.Storage/storageAccounts' { Add-AHMyIpToStorageAccount -Id $Id }
        'Microsoft.Sql/servers' { Add-AHMyIPToSQLServer -Id $Id }
        'Microsoft.ContainerRegistry/registries' { Add-AHMyIPToContainerRegistry -Id $Id } #I haven't written stuff for registries yet
        Default { Write-Warning "The type $Type is not supported. Resource ID $Id was not modified." }
    }

}


