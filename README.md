# AzureHelper
> Useful cmdlets I have written to make my work easier

## Helper Functions
> These functions are ones that I use just to make my daily work easier
- Invoke-AzureCommand - Runs a script block against every subscription
- Select-AHSubscription - GUI to find which subscriptions I have access to then Set-AzContext to it.
- New-AHRoute - Add UDR for access to Azure Endpoints 

## Azure Policy Compliance Reporting
- Get-AHSecurityReport - Gets a report of non-compliant resources for each policy selected
> These functions select policies to determine what Get-AHSecurityReport reports on
- Add-AHPolicyToReport
- Remove-AHPolicyToReport
- Get-AHPolicyToReport

## Azure Cost Savings Reporting
- Get-AHCostSavingsReport - Reports potential cost savings including unused resources

> Let me know if you have ideas for additional featues or resources to monitor
