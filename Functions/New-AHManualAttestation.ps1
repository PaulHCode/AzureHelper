function New-AHManualAttestation {
    <#
    .SYNOPSIS
    Creates a new manual attestation in Azure Policy
    .DESCRIPTION
    This function creates a new manual attestation in Azure Policy
    .EXAMPLE
    New-AHManualAttestation -SubscriptionId 'yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy' -FullPolicyAssignmentId '/subscriptions/yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy/providers/microsoft.authorization/policyassignments/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -PolicyDefinitionId '7d7a8356-5c34-9a95-3118-1424cfaf192a' -Comment 'This is my attestation' -ComplianceState 'Compliant' -Owner 'Frank' -ExpiresOn $([datetime]::UtcNow.AddYears(1)) -AssessmentDate $([datetime]::UtcNow)
    #>
    [CmdletBinding()]
    [Alias('New-AHAttestation')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,
        [Parameter(Mandatory = $true)]
        [string]$FullPolicyAssignmentId,
        [Parameter(Mandatory = $true)]
        [string]$PolicyDefinitionId,
        #[Parameter(Mandatory = $false)]
        #[string]$AttestationName = (New-Guid).guid,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Compliant', 'NonCompliant', 'Unknown')]
        [string]$ComplianceState,
        #[Parameter(Mandatory = $true)]
        #[string]$PolicyDefinitionReferenceId,
        [Parameter(Mandatory = $false)]
        [string]$Owner = '',
        [Parameter(Mandatory = $false)]
        [datetime]$AssessmentDate,
        [Parameter(Mandatory = $false)]
        [datetime]$ExpiresOn,
        [Parameter(Mandatory = $false)]
        [string]$Comment,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    begin {
        $AttestationHashJavascript = @'
var args = process.argv.slice(1);
function hashCode(str) {
    //console.log(str);
    var hash = 0;
    var char;
    for (var i = 0; i < str.length; i++) {
        char = str.charCodeAt(i);
        hash = (hash << 5) - hash + char;
        hash = hash & hash;
    }
    return hash;
}
var attestationId = hashCode(args[0]);
console.log(attestationId);
'@
    }
    process {
        $AttestationName = (node -e $AttestationHashJavascript $($subscriptionId + $FullPolicyAssignmentId + $PolicyDefinitionId))
        $PolicyDefinitionReferenceId = $PolicyDefinitionId

        $AttestationSplat = @{
            Scope                       = "/subscriptions/$subscriptionId"
            Name                        = $AttestationName
            ComplianceState             = $ComplianceState
            PolicyAssignmentId          = $FullPolicyAssignmentId
            PolicyDefinitionReferenceId = $PolicyDefinitionReferenceId
        }
        If ($ExpiresOn) { $AttestationSplat.Add('ExpiresOn', $ExpiresOn) }
        If ($Owner) { $AttestationSplat.Add('Owner', $Owner) }
        If ($AssessmentDate) { $AttestationSplat.Add('AssessmentDate', $AssessmentDate) }
        If ($Comment) { $AttestationSplat.Add('Comment', $Comment) }

        Write-Host "AttestationName = $AttestationName"
        Write-Host "PolicyDefinitionReferenceId = $PolicyDefinitionReferenceId"
        $attestationExists = Get-AzPolicyAttestation -Scope "/subscriptions/$subscriptionId" -Name $AttestationName -ErrorAction SilentlyContinue
        if ($attestationExists) {
            if ($Force) {
                Write-Verbose "Attestation $AttestationName already exists. Overwriting."
                Set-AzPolicyAttestation @AttestationSplat
            }
            else {
                throw "Attestation $AttestationName already exists. Use -Force to overwrite."
            }
        }
        Else {
            New-AzPolicyAttestation @AttestationSplat
        }
    }
}
