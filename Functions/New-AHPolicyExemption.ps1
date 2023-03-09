

Function New-AHPolicyExemption{
    [CmdletBinding()]
    param()

    Begin{
        If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
            throw "This cmdlet can only be used on a local host and cannot be used from a remote session."
            return
        }
        elseif ((get-item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
            throw "This cmdlet can only be used on a local host and cannot be used from Azure Cloud Shell."
            return
        }
#Region FancyDatePicker
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$dateForm = New-Object Windows.Forms.Form -Property @{
    StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
    Size          = New-Object Drawing.Size 243, 230
    Text          = 'Select a Date'
    Topmost       = $true
}

$calendar = New-Object Windows.Forms.MonthCalendar -Property @{
    ShowTodayCircle   = $false
    MaxSelectionCount = 1
}
$dateForm.Controls.Add($calendar)

$okButton = New-Object Windows.Forms.Button -Property @{
    Location     = New-Object Drawing.Point 38, 165
    Size         = New-Object Drawing.Size 75, 23
    Text         = 'OK'
    DialogResult = [Windows.Forms.DialogResult]::OK
}
$dateForm.AcceptButton = $okButton
$dateForm.Controls.Add($okButton)

$cancelButton = New-Object Windows.Forms.Button -Property @{
    Location     = New-Object Drawing.Point 113, 165
    Size         = New-Object Drawing.Size 75, 23
    Text         = 'Cancel'
    DialogResult = [Windows.Forms.DialogResult]::Cancel
}
$dateForm.CancelButton = $cancelButton
$dateForm.Controls.Add($cancelButton)
#EndRegion FancyDatePicker
#Region FancyDescriptionInput
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$descriptionForm = New-Object System.Windows.Forms.Form
$descriptionForm.Text = 'Data Entry Form'
$descriptionForm.Size = New-Object System.Drawing.Size(300,200)
$descriptionForm.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$descriptionForm.AcceptButton = $okButton
$descriptionForm.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$descriptionForm.CancelButton = $cancelButton
$descriptionForm.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please enter the information in the space below:'
$descriptionForm.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$descriptionForm.Controls.Add($textBox)

$descriptionForm.Topmost = $true
#EndRegion FancyDescriptionInput

    }
    Process {
#Steps:
###    - Get management group of policies - maybe hard code
    $ManagementGroup = Get-AzManagementGroup | Where{$_.DisplayName -eq 'Enterprise Policy'}
    If($Null -eq $ManagementGroup){
        $ManagementGroup = Get-AzManagementGroup | ogv -PassThru -Title 'Select which Management Group has the policy applied to it'
    }
###    - Get Policy Initiative ID - only display policy defintions for policies that are already assigned
    
    $PolicySetDefinitionIds = (Get-AzPolicyAssignment -Scope $ManagementGroup.Id -WarningAction SilentlyContinue).Properties.PolicyDefinitionId #all policy definitions for assigned policies
    #some items are policy definitions, others are policy set definitions, get a readable version of each
    #$PolicyChoices = $PolicySetDefinitionIds | Where{$_ -like "*/policyDefinitions/*"}
    $PolicySetChoices = $PolicySetDefinitionIds | Where{$_ -like "*/policySetDefinitions/*"}
    #$PolicyChoices = $PolicyChoices | %{Get-AzPolicyDefinition -Id $_ | select @{n='DisplayName';E={$_.Properties.DisplayName}}, @{n='Description';E={$_.Properties.Description}},ResourceId}
    $PolicySetChoices = $PolicySetChoices | %{Get-AzPolicySetDefinition -Id $_ | select @{n='DisplayName';E={$_.Properties.DisplayName}}, @{n='Description';E={$_.Properties.Description}},ResourceId}
    $DefinitionChoices = $PolicySetChoices #+ $PolicyChoices
    $PolicySetToAddExemptionTo = $DefinitionChoices | ogv -passthru -Title 'Select which policy to add an exemption to'
    If(($PolicySetToAddExemptionTo.gettype()).BaseType.Name -eq 'Array'){
        throw "One and only one policy set may be selected"
        return
    }
    $PolicyAssignment = (Get-AzPolicyAssignment -Scope $ManagementGroup.Id -PolicyDefinitionId $PolicySetToAddExemptionTo.ResourceId -WarningAction SilentlyContinue)
###    - Get Policy definition within the initiative
    If($PolicySetToAddExemptionTo.ResourceId -like "*/policyDefinitions/*"){
        $PolicyDefinitionToExclude = $PolicySetToAddExemptionTo.ResourceId
        #$policyToAddExemptionTo = (Get-AzPolicyAssignment -Scope $ManagementGroup.Id -PolicyDefinitionId $PolicySetToAddExemptionTo.ResourceId)
    }Else{ #it is a policy set so we need to know which policies within the set to exempt
        #$policyToAddExemptionTo = (get-azpolicysetass)
        $PolicyDefinitionToExclude = (Get-AzPolicySetDefinition -ResourceId $PolicySetToAddExemptionTo.ResourceId).Properties.PolicyDefinitions | ogv -passthru -Title 'Select which policy/policies to add exemptions to within the initiative'
    }
###    - Get Resource(s) to exclude
    $SubscriptionsInThisTenant = Get-AzSubscription -TenantId (get-azcontext).Tenant.id
    $AllResourceTypesScriptBlock = {(Get-AzResource | group ResourceType).Name}
    $allResourceTypes = Invoke-AzureCommand -ScriptBlock $AllResourceTypesScriptBlock -Subscription $SubscriptionsInThisTenant | select -Unique
    #$resourceTypeToExclude = (Get-AzResource | group ResourceType).Name | ogv -passthru -Title 'Select which resource type to exclude'
    $resourceTypeToExclude = $allResourceTypes | ogv -passthru -Title 'Select which resource type to exclude'
    $resourcesToExcludeScriptBlock = {$resourceTypeToExclude | %{get-azresource -ResourceType $_}}
    $resourcesToExcludeAll = Invoke-AzureCommand -ScriptBlock $resourcesToExcludeScriptBlock -Subscription $SubscriptionsInThisTenant
    #$resourcesToExclude = $resourceTypeToExclude | %{get-azresource -ResourceType $_} | ogv -passthru -Title 'Select which specific resources to exclude'
    $resourcesToExclude = $resourcesToExcludeAll | ogv -passthru -Title 'Select which specific resources to exclude'
    #$resourcesToExclude = Get-AzResource -ResourceType $resourceTypeToExclude
###    - Define naming
#    $DisplayName = "$($ResourceName) - $($PolicyAssignment.Properties.DisplayName) - $($nistControlId) - $($PolicyName)"
#    $ExemptionName = $DisplayName.Substring(0,64)

#get category
$ExemptionCategory = @('Waiver','Mitigated') | ogv -passthru -Title 'Select the Exemption Category'

#get expiration date
$result = $dateForm.ShowDialog()
If($result -eq [Windows.Forms.DialogResult]::OK){
    $ExpirationDate = $calendar.SelectionStart.ToString('yyyy-MM-dd')
}Else{
    throw 'A date must be selected'
    return
}
If($calendar.SelectionStart -gt [datetime]::now.AddDays(366)){
    write-warning "This exemption will be processed however expiration dates over 1 year in the future are discouraged."
}

#get description
$descriptionForm.Add_Shown({$textBox.Select()})
$result = $descriptionForm.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $description = $textBox.Text
}Else{
    throw "a description must be entered"
    return
}

###    - Create splats

    $MySplats = ForEach($definitionToExclude in $PolicyDefinitionToExclude){
        ForEach($resource in $resourcesToExclude){
            $Policy = Get-AzPolicyDefinition -Id $definitionToExclude.PolicyDefinitionId
            $PolicyName =  $Policy.Properties.DisplayName

            $DisplayName = "$($resource.Name) - $($PolicyAssignment.Properties.DisplayName) - $($Policy.Properties.DisplayName)"
            $ExemptionName = $DisplayName.Substring(0,64)

            @{
                Name = $ExemptionName
                PolicyAssignment = $PolicyAssignment
                Scope = $resource.ResourceId
                ExemptionCategory = $ExemptionCategory
                DisplayName = $DisplayName
                PolicyDefinitionReferenceId = $definitionToExclude.policyDefinitionReferenceId
                ExpiresOn = $ExpirationDate
                description = $description
            }
        }

    }

###    - Create exclusion

ForEach($splat in $MySplats){New-AzPolicyExemption @splat}

    }
    end{}

}