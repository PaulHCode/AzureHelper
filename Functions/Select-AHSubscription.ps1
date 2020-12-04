Function Select-AHSubscription {
    <#
.SYNOPSIS
    Select a subscription from the ones you have access to then Set-AZContext to it.
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
    If (!((Get-AzSubscription) -is [array])) { write-warning "The only subscription is currently selected."; return }
    If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
        #throw "This cmdlet can only be used on a local host and cannot be used from a remote session."
        $choice = Read-Choice -Message "Select the subscription to use" -Choices $(Get-AzSubscription).Name
        $sub = (Get-AzSubscription)[$choice]
    }
    elseif ((get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
        #throw "This cmdlet can only be used on a local host and cannot be used from Azure Cloud Shell."
        $choice = Read-Choice -Message "Select the subscription to use" -Choices $(Get-AzSubscription).Name
        $sub = (Get-AzSubscription)[$choice]
    }
    Else {
        $sub = $Null
        While ($Null -eq $sub -or $sub -is [array]) {
            $sub = (Get-AzSubscription | Select-Object Name, Id, State | Out-GridView -PassThru -Title "Select the subscription to use")
        }
    }
    Set-AzContext $($sub.id) 
    
}