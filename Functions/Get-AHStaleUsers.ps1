<#
    #Mainly copy/paste from original code found here:
        Original Author: Aaron Guilmette
        https://blogs.technet.microsoft.com/undocumentedfeatures/2018/06/22/how-to-find-staleish-azure-b2b-guest-accounts/
        https://gallery.technet.microsoft.com/Report-on-Azure-AD-Stale-8e64c1c5/edit?newSession=True
    
        #I tweaked it for my purposes
#>

Function Get-AHStaleUsers {
    <#
.SYNOPSIS
    Gets a list of stale AAD users.

.DESCRIPTION
    Gets a list of AAD users older than ($MaAgeMultiFactor + $StaleAgeInDays) days old.
    This command may not work properly in PS Core.  I recommend running it on 5.1 Desktop.

.PARAMETER InstallRequiredModules
    Installs the required modules if necessary.

.PARAMETER MaxAgeMultiFactor
    The MaxAgeMultiFactor for the environment.  Defaults to 180.

.PARAMETER StaleAgeInDays
    The minimum age of the accounts.  Defaults to 90.

.EXAMPLE
    $staleUsers = Get-AHStaleUsers -InstallRequiredModules

.EXAMPLE
    $staleUsers = Get-AHStaleUsers -InstallRequiredModules -StaleAgeInDays 90 -MaxAgeMultiFactor 90

.EXAMPLE
    $staleUsers = Get-AHStaleUsers -InstallRequiredModules -StaleAgeInDays 90 -MaxAgeMultiFactor 90
    $staleUsers | Where{$_.IsEnabled} | sort -Property LastLogon | Format-Table

.INPUTS
    int

.OUTPUTS
    System.Management.Automation.PSCustomObject

.REMARKS
    This is a test

.NOTES
    Author:  Paul Harrison
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $InstallRequiredModules,
        [Parameter()]
        [int]
        $MaxAgeMultiFactor,
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
            }
            else {
                Throw { "InstallRequiredModules must be run in an elevated PowerShell window." }
            }
		
            Install-Module AzureADPreview -Force
		
            Try {
                Import-Module AzureADPreview -Force
            }
            Catch {
                throw { "Unable to import module. Please verify that the module is installed and try again." }
            }
        }
        Else {
            throw { "Unable to detect module and InstallRequiredModules switch not supplied. Please verify that the module has installed and try again." }
        }
    }
    Else {
        Import-Module AzureADPreview -Force	
    }


    # Check for existing Azure AD Connection
    Try {
        $TestAzureAD = Get-AzureADTenantDetail
    }
    Catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
        Write-Verbose "You're not connected.";
        Connect-AzureAD -credential $cred
    }

    If (!($MaxAgeMultiFactor)) {
        <#        $AzureADPolicy = Get-AzureADPolicy | Where-Object { $_.Type -eq "TokenLifetimePolicy" }
        If ($AzureADPolicy) {
            $PolicyData = $AzureADPolicy.Definition | ConvertFrom-Json
            # Retrieve value for MaxAgeMultiFactor
            [int]$MaxAgeMultiFactor = $PolicyData.TokenLifetimePolicy.MaxAgeMultiFactor.Split(":")[0].Split(".")[0]
		
            # Test MaxAgeMultiFactor; if not exist, set to AAD default of 90 days, 
            # per https://docs.microsoft.com/en-us/azure/active-directory/active-directory-configurable-token-lifetimes

        }
        #>
        If (!$MaxAgeMultiFactor) {
            $MaxAgeMultiFactor = "180" #180 is the default as per the article above
        }
    }

    #Write-Host "MaxAgeMultiFactor = $MaxAgeMultiFactor"
    # VerifyMaxAgeMultiFactor
    If ($MaxAgeMultiFactor -lt 1) { throw { "MaxAgeMultiFactor must be greater than 0." } }



    $Today = (Get-Date)
    $users = Get-AzureADUser -All $true
    [int]$StaleAge = $MaxAgeMultiFactor + $StaleAgeInDays

    $StaleUsers = $users | ForEach-Object {
        $TimeStamp = $_.RefreshTokensValidFromDateTime
        [int]$LogonAge = [math]::Round(($Today - $TimeStamp).TotalDays)
        [int]$StaleAge = $MaxAgeMultiFactor + $StaleAgeInDays
        $User = $($_.UserPrincipalName)
        If ($LogonAge -ge $StaleAge) {
            [pscustomobject]@{
                User                         = $($User)
                DisplayName                  = $($_.DisplayName)
                IsEnabled                    = $_.AccountEnabled
                ObjectID                     = $_.ObjectID
                IsStale                      = $true
                LastLogon                    = $TimeStamp
                DaysSinceLastLogon           = $LogonAge
                UserIsStaleAfterThisManyDays = $StaleAge
            }
        }
    }

    $StaleUsers
}