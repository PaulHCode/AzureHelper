<#
    .Synopsis 
        Removes invalid characters from a file name.
    .DESCRIPTION
        Removes invalid characters from a file name.
    .EXAMPLE
        Remove-InvalidFileNameChars -Name '[MyFile]:*Name'
#>
Function Remove-InvalidFileNameChars {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )
    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $re = '[{0}]' -f [regex]::escape($invalidChars)
    return ($Name -replace $re)
}