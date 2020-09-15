
Function Get-AHPolicyToReport {
        <#
.SYNOPSIS
    List the Azure policies to be analyzed.
.DESCRIPTION
    Get-AHPolicyToReport list the Azure Policies to be analyzed by other AzureHelper cmdlets.
.EXAMPLE
    Get-AHPolicyToReport 
.INPUTS
.OUTPUTS
    [string[]]]
.NOTES
    Author:  Paul Harrison
.LINK
    Get-AHSecurityReport
    Add-AHPolicyToReport
    Get-AHPolicyToReport
    Remove-AHPolicyToReport
    Get-AHComplianceReport
#>
        $Script:PolicyDefinitionIDs
}