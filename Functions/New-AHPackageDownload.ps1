<#
    .SYNOPSIS
        Create a new package from the evidence package definition file.
    .DESCRIPTION
        Create a new package from the download package definition file by copying relevant files from the storage accounts to a local folder.
    .PARAMETER EvidencePackageDefinitionFile
        The path to the package definition file
    .EXAMPLE
        New-AHPackageDownload -DownloadPackageDefinitionFile .\DownloadPackageDefinitionFile.json
    .NOTES
        An example DownloadPackageDefinitionFile:

[
    {
        "SubscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "EvidenceLocations": [
            {
                "SAName": "xxpolicyreportingsa",
                "SAGroup": "MonitoringServices-rg",
                "Container": "xxpolicyexports",
                "FileFilters": [
                    "*"
                ],
                "ExcludeFilter": [],
                "DestinationPath": ".\\XX\\Identity\\"
            },
            {
                "SAName": "xxpolicyreportingsa",
                "SAGroup": "MonitoringServices-usva-rg",
                "Container": "xxallresourcessummary",
                "FileFilters": [
                    "*"
                ],
                "ExcludeFilter": [
                    "Test-*"
                ],
                "DestinationPath": ".\\XX\\Azure Resource List\\"
            }
        ]
    },
    {
        "SubscriptionId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
        "EvidenceLocations": [
            {
                "SAName": "yypolicyreportingsa",
                "SAGroup": "MonitoringServices-rg",
                "Container": "yypolicyexports",
                "FileFilters": [
                    "*"
                ],
                "ExcludeFilter": [],
                "DestinationPath": ".\\YY\\Identity\\"
            },
            {
                "SAName": "yypolicyreportingsa",
                "SAGroup": "MonitoringServices-usva-rg",
                "Container": "yyallresourcessummary",
                "FileFilters": [
                    "*"
                ],
                "ExcludeFilter": [
                    "Test-*"
                ],
                "DestinationPath": ".\\YY\\Azure Resource List\\"
            }
        ]
    }
]
#>
Function New-AHPackageDownload {
    [CmdletBinding()]
    [Alias('New-AHEvidencePackage')]
    param(
        [Alias('EvidencePackageDefinitionFile')]
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
                Test-Path $_ -PathType Leaf
            })]
        $DownloadPackageDefinitionFile
    )
    begin {
        $tempLocation = Join-Path $env:TEMP EvidencePackage
        if (!(Test-Path $tempLocation -PathType Container)) { mkdir $tempLocation | Out-Null }
    }
    process {
        $definition = Get-Content $EvidencePackageDefinitionFile | ConvertFrom-Json
        $filesExported = @()
        ForEach ($package in $definition) {
            Set-AzContext -SubscriptionId $package.SubscriptionId | Out-Null
            $targets = $package.EvidenceLocations
            ForEach ($target in $targets) {
                $targetContext = New-AzStorageContext -StorageAccountName $target.SAName -UseConnectedAccount
                $blobs = Get-AzStorageBlob -Container $target.Container -Blob * -Context $targetContext 
                If ($blobs) {
                    $tempPath = ($blobs | Sort-Object LastModified -Descending )[0].name.split('/')
                    $tempPath = $tempPath[0..$($tempPath.count - 2)] -join ('/')
                    $recentBlobs = $blobs | Where-Object { $_.Name -like "$tempPath*" }
                
                    foreach ($filter in $target.FileFilters) {
                        $passesFilter = $recentBlobs | Where-Object { $_.name.split('/')[-1] -like $filter }
                        forEach ($exclusion in $target.ExcludeFilter) {
                            $passesFilter = $passesFilter | Where-Object { $_.Name.split('/')[-1] -notlike $exclusion }
                        }
                        ForEach ($toExport in $passesFilter) {
                            If (!(Test-Path $target.DestinationPath -PathType Container)) { mkdir $($target.DestinationPath) | Out-Null }
                            Get-AzStorageBlobContent -Container $target.Container -Blob $toExport.Name -Destination $tempLocation -Context $targetContext -Force | Out-Null
                            Move-Item -Path $(Join-Path $tempLocation $toExport.Name) -Destination $target.DestinationPath -Force | Out-Null
                        }
                        $filesExported += $passesFilter
                    }
                }
            }
        }
    }
    end {
        Remove-Item $tempLocation -Recurse -Force
        $filesExported | Select-Object * -ExpandProperty LastModified | Group-Object Date | Select-Object count, @{N = 'Date Collected'; E = { Get-Date $_.Name -Format MM/dd/yyyy } }
    }
}