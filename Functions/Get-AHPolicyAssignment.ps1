Function Get-AHPolicyAssignment {
    param(
        #        [string]
        #        $ReportPath = ".\",

        [Switch]
        $AllSubscriptions,
    
        [Parameter(ValueFromPipeline = $true)]
        $Subscription,

        [Switch]
        $ManagementGroupOnly
    )
    begin {
        <#
        If (!(Test-Path $ReportPath)) {
            Throw("Invalid Path")
        }
        Else {
            $ReportPath = (Convert-Path $ReportPath) + '\' 
        }
        $ReportName = $ReportPath + "PolicyAssignmentReport.csv"
    #>
        #Get ones not in a sub first
        #$Sub = $Null

        $ArgumentList = @()
        $ArgumentList += $ManagementGroupOnly

        $MyScriptBlock = {
            param($ManagementGroupOnly)
            $SelectSplat = 'DisplayName', `
            @{N = 'Scope'; E = { If ($_.scope -like "/subscriptions/*") { (Get-AzSubscription -SubscriptionId ($_.scope.split('/')[-1])).Name }ElseIf ($_.scope -like "/providers/Microsoft.Management/managementGroups/*") { $_.scope.split('/')[-1] }Else { $_.scope } } }, `
            @{N = 'assignedBy'; E = { $_.Metadata.assignedBy } }, `
            @{N = 'createdOn'; E = { $_.Metadata.createdOn } }, `
            @{N = 'Effect'; E = { (Get-AzPolicyDefinition -Id ($_.PolicyDefinitionId)).Properties.PolicyRule.then.effect } }, `
            @{N = 'PolicyType'; E = { (Get-AzPolicyDefinition -id ($_.PolicyDefinitionId)).Properties.PolicyType } }, `
                'EnforcementMode', `
                #                'NotScopes', `
                'Description'
            If ($ManagementGroupOnly) { $Subscription = $Null }Else { $Subscription = (Get-AzContext).Subscription.Id }
            (Get-AzPolicyAssignment | Where-Object { $Subscription -eq $_.SubscriptionId } | Select-Object -ExpandProperty Properties) | Select-Object $SelectSplat  #| Format-Table #            Export-Csv $ReportName -NoTypeInformation
        }
    }
    process {
        if ($Subscription) { $Subscription | Invoke-AzureCommand -ScriptBlock $MyScriptBlock -ArgumentList $ArgumentList }
        else { Invoke-AzureCommand -ScriptBlock $MyScriptBlock -AllSubscriptions:$AllSubscriptions -ArgumentList $ArgumentList }
    }
}


