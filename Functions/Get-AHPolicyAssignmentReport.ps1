

(Get-AzPolicyAssignment | Select-Object -ExpandProperty Properties) | 
Select-Object DisplayName, Scope, <#NotScopes,#> Description, @{N = 'assignedBy'; E = { $_.Metadata.assignedBy } }, @{N = 'createdOn'; E = { $_.Metadata.createdOn } } | 
Export-Csv ./AssignedPolicyReport.csv


Function Get-AHPolicyAssignmentReport {
    [string]
    $ReportPath = ".\"

    (Get-AzPolicyAssignment | Select-Object -ExpandProperty Properties) | 
    Select-Object DisplayName, `
    @{N = 'Scope'; E = { If ($_.scope -like "/subscriptions/*") { (Get-AzSubscription -SubscriptionId ($_.scope.split('/')[-1])).Name }ElseIf ($_.scope -like "/providers/Microsoft.Management/managementGroups/*") { $_.scope.split('/')[-1] }Else { $_.scope } } }, `
        <#NotScopes,#> Description, @{N = 'assignedBy'; E = { $_.Metadata.assignedBy } }, @{N = 'createdOn'; E = { $_.Metadata.createdOn } } | Format-Table
    Export-Csv 
}




Function Get-AHPolicyAssignmentReport {
    param(
        [string]
        $ReportPath = ".\"
    )
    If (!(Test-Path $ReportPath)) {
        Throw("Invalid Path")
    }
    Else {
        $ReportPath = (Convert-Path $ReportPath) + '\' 
    }
    $ReportName = $ReportPath + "PolicyAssignmentReport.csv"

    #Get ones not in a sub first
    (Get-AzPolicyAssignment | Where{$Null -eq $_.SubscriptionId} | Select-Object -ExpandProperty Properties) | 
        Select-Object DisplayName, `
            @{N = 'Scope'; E = { If ($_.scope -like "/subscriptions/*") { (Get-AzSubscription -SubscriptionId ($_.scope.split('/')[-1])).Name }ElseIf ($_.scope -like "/providers/Microsoft.Management/managementGroups/*") { $_.scope.split('/')[-1] }Else { $_.scope } } }, `
            @{N = 'assignedBy'; E = { $_.Metadata.assignedBy } }, `
            @{N = 'createdOn'; E = { $_.Metadata.createdOn } }, `
            @{N= 'Effect';E={(Get-AzPolicyDefinition -Id ($_.PolicyDefinitionId)).Properties.PolicyRule.then.effect}}, `
            @{N = 'PolicyType'; E = { (Get-AzPolicyDefinition -id ($_.PolicyDefinitionId)).Properties.PolicyType } }, `
            EnforcementMode, `
            NotScopes, `
            Description | FT
        Export-Csv $ReportName -NoTypeInformation
}


(Get-AzPolicyDefinition).Properties.PolicyRule.then.effect | group