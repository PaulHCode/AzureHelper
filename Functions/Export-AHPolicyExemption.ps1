<# 
.Synopsis
   Exports Azure Policy Exemptions
.DESCRIPTION
   Exports Azure Policy Exemptions
.EXAMPLE
   Export-AHPolicyExemption -outputDir C:\MyExemptions\
.PARAMETER outputDir
   The directory to write policy exemptions to
.PARAMETER IncludeEmpty 
   Write empty files if there are no exemptions for the policy
#>
function Export-AHPolicyExemption {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        $outputDir,
        [switch]
        $IncludeEmpty
    )

    Begin {
        If ($PSVersionTable.PSVersion.Major -lt 7) {
            throw 'This cmdlet requires PowerShell 7 or greater'
        }
    
        If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
            throw 'This cmdlet can only be used on a local host and cannot be used from a remote session.'
            return
        }
        elseif ((get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
            throw 'This cmdlet can only be used on a local host and cannot be used from Azure Cloud Shell.'
            return
        }

        Function Remove-InvalidFileNameChars {
            param(
                [Parameter(Mandatory = $true,
                    Position = 0,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
                [string]$Name
            )
            $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
            $re = '[{0}]' -f [regex]::escape($invalidChars)
            return ($Name -replace $re)
        }
       
    }
    Process {
        $ManagementGroups = Get-AzManagementGroup
        $ManagementGroupLookup = $ManagementGroups | ForEach-Object { @{$_.Id = $_.DisplayName } }
        $policy = Get-AzPolicyAssignment | Select-Object @{N = 'DisplayName'; e = { $_.Properties.DisplayName } }, `
        @{N = 'ManagementGroup'; E = { $ManagementGroupLookup."$($_.Properties.Scope)" } }, `
            * -WarningAction SilentlyContinue | Out-GridView -passthru -Title 'Select policies to export exemptions for'

        #now that I know what to export, export it
        ForEach ($PolicyToExport in $policy) {
            $exemptions = get-azpolicyExemption -PolicyAssignmentIdFilter $PolicyToExport.ResourceId
            If (($Null -eq $exemptions -and $IncludeEmpty) -or ($Null -ne $exemptions)) {
                $filename = Remove-InvalidFileNameChars $PolicyToExport.Properties.DisplayName
                If ($filename.Length -gt 59) { $filename = $filename.substring(0, 59) }
                $filename += '.json'
                $outFile = join-path $outputDir $filename
                $exemptions | ConvertTo-Json -Depth 99 | out-file -LiteralPath $outFile
            }
        }
    }
    End {
    }
}
