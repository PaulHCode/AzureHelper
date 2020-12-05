

<#
    If either of the following are true then get GUI input using a CLI compatible way  
       ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) 
        (get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT')    
    Else
        Get input using a graphical way like ogv

#>

<#

Function Get-AHGUIInput {
    [CmdletBinding()]
    param (
        [Parameter()]
        [array]
        $InputArray
    )


    If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
        #Remote sessions
        $item = Read-Choice -Message "Select the subscription to use" -Choices $InputArray
        $choice = $InputArray[$item]
        #$sub = (Get-AzSubscription)[$choice]
    }
    ElseIf ((get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
        #Azure Cloud Shell
    }
    Else {
        #"normal"
        
    }
    $choice
}

#>