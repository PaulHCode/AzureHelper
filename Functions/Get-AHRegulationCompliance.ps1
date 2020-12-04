

Function Get-AHRegulationCompliance {
    <#
.SYNOPSIS
    Gets regulatory compliance of the regulation specified and generates a report showing compliance with each control in the regulation.
.DESCRIPTION
.PARAMETER AllSubscriptions
    Run this command against all subscriptions.
.PARAMETER Subscription
    Specifies the subscription to run against. The default is the current subscription.
.PARAMETER Regulation
    Specifies the regulation out of the Regulations.json file to check for compliance with.  The file is extensible and easily modified to customize and add additional regulations.
.PARAMETER RegulationFile
    The file that has the regulations stored in it.
.PARAMETER Summary
    Summarize the results
.PARAMETER Parallel
    Enables parallel execution so that all regulations are checked simultaneously.  This must not be used at the same time as AllSubscriptions.
.EXAMPLE
    $results = Get-AHRegulationCompliance -Regulation "DoD 800-53R4" -Parallel

    #This finds regulatory compliance with DoD 800-53R4 for the current subscription.
.EXAMPLE
    $results = Get-AHRegulationCompliance -Regulation "DoD 800-53R4" -AllSubscriptions

    #This gets regulatory compliance with DoD 800-53R4 across all subscriptions.  
.EXAMPLE
    $results = Get-AHRegulationCompliance -Regulation "DoD 800-53R4" -AllSubscriptions -Summary

    #This gets regulatory compliance with DoD 800-53R4 across all subscriptions then summarizes it by control.  This report makes it easy to find how many resources are not compliant with each control in an entire tenant.
.INPUTS
    String
.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Switch]
        $AllSubscriptions,

        [Parameter(ValueFromPipeline = $true)]
        $Subscription,

        [string]
        $Regulation,

        [string]
        $RegulationFile = 'C:\GitHub\AzureHelper\Regulations.json',

        [switch]
        $Summary,

        [validatescript( { $_ -and (($PSVersionTable.psversion.major -gt 7 -and $PSVersionTable.psversion.minor -gt 0) -or ($PSVersionTable.psversion.major -eq 7 -and $PSVersionTable.psversion.minor -eq 0 -and $PSVersionTable.psversion.Patch -ge 3)) })]
        [switch]
        $Parallel
    )
    #    begin {
    If (!(Test-Path $RegulationFile)) { throw 'Invalid Regulation File' }

    $Regulations = Get-Content $RegulationFile | ConvertFrom-Json
    $RegToCheck = $Regulations | Where-Object { $_.Name -eq $Regulation }
    If ($Null -eq $RegToCheck) { throw "$Regulation not found in $RegulationFile" }
    $Total = @()

    $Sub = (Get-AzContext).Subscription.Name

    $controlCount = 0
    $policyCount = 0
    $PolicyDefinitions = Get-AzPolicyDefinition
    
    #single threaded version    
    If (!$Parallel) {
        ForEach ($Control in $RegToCheck.Control) {
            Write-Progress -Activity "Checking for $($RegToCheck.Name) compliance" -Status "Checking $($Control.Name)" -PercentComplete (100 * $controlCount / $($RegToCheck.Control.count))
            $policyCount = 0
            $subTotal = ForEach ($Policy in $Control.Policy) {
                Write-Progress -Activity "Checking: $($Policy.Name)" -PercentComplete (100 * $policyCount / $($Control.Policy.count)) -Id 1
                $policyCount++
                $PolicyDefinitionId = ($PolicyDefinitions | Where-Object { $_.Properties.DisplayName -eq $Policy.Name }).PolicyDefinitionId
                $PolicyState = Get-AzPolicyState -Filter "PolicyDefinitionId eq '$PolicyDefinitionID'"
                $item = New-Object PSCustomObject -Property @{
                    Subscription      = $Sub
                    Regulation        = $Regulation
                    Control           = $Control.Name
                    Policy            = $Policy.Name
                    PolicyExists      = ($Null -ne $PolicyDefinitionId)
                    NonCompliantCount = ($PolicyState | Where-Object { $_.ComplianceState -eq 'NonCompliant' }).count
                    TotalObjectCount  = ($PolicyState).count
                }

                $item
            }
            $Total += $subTotal


            $controlCount++
        }
    }
    Else {
        #yay multithreading
        $RegToCheck.Control | ForEach-Object -ThrottleLimit 64 -Parallel {
            $Control = $_
            $policyCount = 0
            ForEach ($Policy in $Control.Policy) {
                $policyCount++
                $PolicyDefinitionId = ($using:PolicyDefinitions | Where-Object { $_.Properties.DisplayName -eq $Policy.Name }).PolicyDefinitionId
                $PolicyState = Get-AzPolicyState -Filter "PolicyDefinitionId eq '$PolicyDefinitionID'"


                $item = New-Object PSCustomObject -Property @{
                    Subscription      = $using:Sub
                    Regulation        = $using:Regulation
                    Control           = $Control.Name
                    Policy            = $Policy.Name
                    PolicyExists      = ($Null -ne $PolicyDefinitionId)
                    NonCompliantCount = ($PolicyState | Where-Object { $_.ComplianceState -eq 'NonCompliant' }).count
                    TotalObjectCount  = ($PolicyState).count
                }
                $item
            }

            $Total += $subTotal

            $controlCount++
        }
    }


    If (!$Summary) {
        $Total
    }
    Else {    
        $Total | Group-Object -Property Control | Select-Object @{N = 'Subscription'; E = { $Sub } }, @{N = 'Regulation'; E = { $Regulation } }, @{N = 'Control'; E = { $_.Name } }, @{N = 'isCompliant'; E = { $_.count -eq 0 } }
    }
}