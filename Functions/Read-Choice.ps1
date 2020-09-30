#Found at https://www.zerrouki.com/powershell-menus-host-ui-promptforchoice-defined-or-dynamic/
function Read-Choice {     
    Param(
        [System.String]$Message, 
         
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]$Choices, 
         
        [System.Int32]$DefaultChoice = 0, 
         
        [System.String]$Title = [string]::Empty 
    )        
    [System.Management.Automation.Host.ChoiceDescription[]]$Poss = $Choices | ForEach-Object {            
        New-Object System.Management.Automation.Host.ChoiceDescription "&$($_)", "Sets $_ as an answer."      
    }       
    $Host.UI.PromptForChoice( $Title, $Message, $Poss, $DefaultChoice )     
}