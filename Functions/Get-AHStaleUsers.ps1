<#
    #Mainly copy/paste from original code found here:
        Original Author: Aaron Guilmette
        https://blogs.technet.microsoft.com/undocumentedfeatures/2018/06/22/how-to-find-staleish-azure-b2b-guest-accounts/
        https://gallery.technet.microsoft.com/Report-on-Azure-AD-Stale-8e64c1c5/edit?newSession=True
    
#>

Function Get-AHStaleUsers {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $InstallRequiredModules,
        [Parameter()]
        [int]
        $MaxInactiveTime,
        [Parameter()]
        [int]
        $StaleAgeInDays = 90   
    )

    # Requires Azure AD Preview Module
    If (!(Get-Module -ListAvailable "AzureADPreview" -ea SilentlyContinue)) {
        If ($InstallRequiredModules) {
            # Check if Elevated
            $wid = [system.security.principal.windowsidentity]::GetCurrent()
            $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
            $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
            if ($prp.IsInRole($adm)) {
                #			Write-Log -LogFile $Logfile -LogLevel SUCCESS -ConsoleOutput -Message "Elevated PowerShell session detected. Continuing."
            }
            else {
                #			Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "InstallRequiredModules must be run in an elevated PowerShell window. Please launch an elevated session and try again."
                #			$ErrorCount++
                Throw { "InstallRequiredModules must be run in an elevated PowerShell window." }
                #            Break
            }
		
            Install-Module AzureADPreview -Force
		
            Try {
                Import-Module AzureADPreview -Force
            }
            Catch {
                throw { "Unable to import module. Please verify that the module is installed and try again." }
                #			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to import module. Please verify that the module is installed and try again." -ConsoleOutput
                #			Write-Log -LogFile $Logfile -LogLevel WARN -Message "Continuing using defaults for Azure AD Policy settings ('90 days token refresh')."
            }
        }
        Else {
            throw { "Unable to detect module and InstallRequiredModules switch not supplied. Please verify that the module has installed and try again." }
            #		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to detect module and InstallRequiredModules switch not supplied. Please verify that the module has installed and try again." -ConsoleOutput
            #		Write-Log -LogFile $Logfile -LogLevel WARN -Message "Continuing using defaults for Azure AD Policy settings ('90 days token refresh')."
        }
    }
    Else {
        Import-Module AzureADPreview -Force	
    }

    # VerifyMaxInactiveTime
    #If ($MaxInactiveTime -lt 1) { throw { "MaxInactiveTime must be greater than 0." } }

    # Check for existing Azure AD Connection
    Try {
        $TestAzureAD = Get-AzureADTenantDetail
    }
    Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
        Write-Verbose "You're not connected.";
        Connect-AzureAD -credential $cred
    }

    #Should switch to MaxAgeMultiFactor since we're doing MFA
    If (!($MaxInactiveTime)) {
        $AzureADPolicy = Get-AzureADPolicy | Where-Object { $_.Type -eq "TokenLifetimePolicy" }
        If ($AzureADPolicy) {
            $PolicyData = $AzureADPolicy.Definition | ConvertFrom-Json
            # Retrieve value for MaxInactiveTime
            [int]$MaxInactiveTime = $PolicyData.TokenLifetimePolicy.MaxInactiveTime.Split(":")[0].Split(".")[0]
		
            # Test MaxInactiveTime; if not exist, set to AAD default of 90 days, 
            # per https://docs.microsoft.com/en-us/azure/active-directory/active-directory-configurable-token-lifetimes

        }
        If (!$MaxInactiveTime) {
            $MaxInactiveTime = "180" #changed to 180 instead of 90 since we do MFA on everyone
        }
    }

    #    Write-Host "MaxInactiveTime = $MaxInactiveTime"

    $Today = (Get-Date)
    $users = Get-AzureADUser -All $true
    [int]$StaleAge = $MaxInactiveTime + $StaleAgeInDays

    $StaleUsers = $users | ForEach-Object {
        $TimeStamp = $_.RefreshTokensValidFromDateTime
        #	$TimeStampString = $TimeStamp.ToString()
        [int]$LogonAge = [math]::Round(($Today - $TimeStamp).TotalDays)
        [int]$StaleAge = $MaxInactiveTime + $StaleAgeInDays
        $User = $($_.UserPrincipalName)
        If ($LogonAge -ge $StaleAge) {
            [pscustomobject]@{
                User                         = $($User)
                DisplayName                  = $($_.DisplayName)
                IsEnabled                    = $_.AccountEnabled
                ObjectID                     = $_.ObjectID
                IsStale                      = "True"
                LastLogon                    = $TimeStamp
                DaysSinceLastLogon           = $LogonAge
                UserIsStaleAfterThisManyDays = $StaleAge
            }
        }
    }

    $StaleUsers
}