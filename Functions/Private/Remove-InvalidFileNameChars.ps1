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
    $invalidChars += '{}' #I know these are allowed but I want to make my life easier
    $re = '[{0}]' -f [regex]::escape($invalidChars)
    $result = $Name -replace $re
    return ($result.replace('[', '').replace(']', ''))
}