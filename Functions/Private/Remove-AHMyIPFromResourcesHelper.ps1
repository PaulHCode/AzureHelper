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
        #        'Microsoft.ContainerRegistry/registries' { Remove-AHMyIPFromContainerRegistries -Id $Id -IPAddress $IPAddress } #I haven't written this function yet
        Default { Write-Warning "The type $Type is not supported. Resource ID $Id was not modified." }
    }

}
