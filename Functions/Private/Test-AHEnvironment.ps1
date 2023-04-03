Function Test-AHEnvironment {
    <#
.SYNOPSIS
    Validates the environment is ready for use.
.DESCRIPTION
    Validates that the environment is ready for use like being connected to an azure subscription.
.EXAMPLE
    Test-AHEnvironment
.INPUTS
.OUTPUTS
.NOTES
    Author:  Paul Harrison
.LINK
#>
    If ($Null -eq (Get-AzContext)) {
        throw { 'Not connected to Azure - Run Connect-AzAccount before running using this module' }
    }
}