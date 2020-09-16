Function Select-AHSubscription {
    <#
.SYNOPSIS
    Select a subscription in  GUI from the ones you have access to then Set-AZContext to it.
.DESCRIPTION
    Allows for selection of a subscription to Set-AZContext to without needing
    to know the exact spelling or ID.
.EXAMPLE
    Select-AHSubscription
.INPUTS
    String
.OUTPUTS
.NOTES
    Author:  Paul Harrison
.LINK
#>
    Test-AHEnvironment
    $sub = $Null
    While ($Null -eq $sub -or $sub -is [array]) {
        $sub = (Get-AzSubscription | Select-Object Name, Id, State | Out-GridView -PassThru -Title "Select the subscription to use")
    }
    try { Set-AzContext $($sub.id) }
    catch { throw }
}