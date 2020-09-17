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
    If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
        throw "This cmdlet can only be used on a local host and cannot be used from a remote session."
    }
    elseif ((get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
        throw "This cmdlet can only be used on a local host and cannot be used from Azure Cloud Shell."
    }
    $sub = $Null
    While ($Null -eq $sub -or $sub -is [array]) {
        $sub = (Get-AzSubscription | Select-Object Name, Id, State | Out-GridView -PassThru -Title "Select the subscription to use")
    }
    try { Set-AzContext $($sub.id) }
    catch { throw }
}