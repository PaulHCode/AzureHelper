
Function New-AHPolicyExemption {
    <#
    .SYNOPSIS
        Provides a GUI to add policy exemptions for multiple resources of the same type across all subscriptions in the tenant you are currently in. 
        Be aware that it may take a few moments between prompts depending on the number of subscriptions, policy definitions, policy assignments, and resources in your environment.
    .DESCRIPTION
        If you have 300 storage accounts across 12 subscriptions that all need an exemption for the same reason, then this makes it easy.

        If you have a Management Group with a display name of 'Enterprise Policy' then this assumes that you're dealing with policies on that management group. If you don't have a management group with that name then it will prompt you which management group you want to work with.
        The command then finds which policies and policy sets are assigned at that management group, looks up the corrosponding policy definitions and prompts the user to select which ones the user wants an exclusion for.
        The command then checks which resources are in the environment and based on that list prompts the user to select which resource type the objects that need to be excluded are. This step just narrows down the choices for when the user needs to select which resources to exclude.
        The command then gets all resources of the designated type and allows the user to select which ones should be excluded.
        The command then prompts if the exemption should be a waiver or mitigated.
        The command then prompts for an expiration date for the exemption. It does not allow exemptions without expiration dates even though Azure does allow it.
        The command then prompts for a description for the exemption. This is the same exemption even if you selected 300 resources so phrase your description properly.
    .Example
            New-AHPolicyExemption
    .Notes
        Author: Paul Harrison
    #>
    [CmdletBinding()]
    param()

    Begin {
        If ('System.Management.Automation.ServerRemoteDebugger' -eq [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.Debugger.GetType().FullName) {
            throw 'This cmdlet can only be used on a local host and cannot be used from a remote session.'
            return
        }
        elseif ((Get-Item env:/).Name -contains 'AZURE_HTTP_USER_AGENT') {
            throw 'This cmdlet can only be used on a local host and cannot be used from Azure Cloud Shell.'
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
        $descriptionForm.Size = New-Object System.Drawing.Size(300, 200)
        $descriptionForm.StartPosition = 'CenterScreen'

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Location = New-Object System.Drawing.Point(75, 120)
        $okButton.Size = New-Object System.Drawing.Size(75, 23)
        $okButton.Text = 'OK'
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $descriptionForm.AcceptButton = $okButton
        $descriptionForm.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Location = New-Object System.Drawing.Point(150, 120)
        $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
        $cancelButton.Text = 'Cancel'
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $descriptionForm.CancelButton = $cancelButton
        $descriptionForm.Controls.Add($cancelButton)

        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(10, 20)
        $label.Size = New-Object System.Drawing.Size(280, 20)
        $label.Text = 'Please enter the description for the exemption:'
        $descriptionForm.Controls.Add($label)

        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Location = New-Object System.Drawing.Point(10, 40)
        $textBox.Size = New-Object System.Drawing.Size(260, 20)
        $descriptionForm.Controls.Add($textBox)

        $descriptionForm.Topmost = $true
        #EndRegion FancyDescriptionInput

    }
    Process {
        #Steps:
        ###    - Get management group of policies - maybe hard code
        $ManagementGroup = Get-AzManagementGroup | Where-Object { $_.DisplayName -eq 'Enterprise Policy' }
        If ($Null -eq $ManagementGroup) {
            $ManagementGroup = Get-AzManagementGroup | Out-GridView -PassThru -Title 'Select which Management Group has the policy applied to it'
        }
        ###    - Get Policy Initiative ID - only display policy defintions for policies that are already assigned
        $PolicySetDefinitionIds = [array]((Get-AzPolicyAssignment -Scope $ManagementGroup.Id -WarningAction SilentlyContinue).Properties.PolicyDefinitionId) #all policy definitions for assigned policies


        $PolicySets = [array]((Get-AzPolicyAssignment -Scope $ManagementGroup.Id -WarningAction SilentlyContinue)) #all policy definitions for assigned policies

        #some items are policy definitions, others are policy set definitions, get a readable version of each
        $PolicySetChoices = $PolicySets | Where-Object { $_.Properties.PolicyDefinitionId -like "*/policySetDefinitions/*" } | Select-Object @{N = 'DisplayName'; E = { $_.Properties.DisplayName } }, @{N = 'Description'; E = { $_.Properties.Description } }, Name, ResourceId, @{N = 'PolicyDefinitionId'; E = { $_.Properties.PolicyDefinitionId } }, * -EA 0
        $PolicySetChoices = ForEach ($item in $PolicySetChoices) {
            $item.Properties.PolicyDefinitionId | ForEach-Object { Get-AzPolicySetDefinition -Id $_ } | Select-Object @{n = 'DisplayName'; E = { $_.Properties.DisplayName } }, @{n = 'Description'; E = { $_.Properties.Description } }, ResourceId
        }

        $DefinitionChoices = $PolicySetChoices #+ $PolicyChoices
        $PolicySetToAddExemptionTo = $DefinitionChoices | Out-GridView -PassThru -Title 'Select which policy to add an exemption to'
        If (($PolicySetToAddExemptionTo.gettype()).BaseType.Name -eq 'Array') {
            throw 'One and only one policy set may be selected'
            return
        }
        $PolicyAssignment = (Get-AzPolicyAssignment -Scope $ManagementGroup.Id -PolicyDefinitionId $PolicySetToAddExemptionTo.ResourceId -WarningAction SilentlyContinue)
        ###    - Get Policy definition within the initiative
        If ($PolicySetToAddExemptionTo.ResourceId -like "*/policyDefinitions/*") {
            $PolicyDefinitionToExclude = $PolicySetToAddExemptionTo.ResourceId
            #$policyToAddExemptionTo = (Get-AzPolicyAssignment -Scope $ManagementGroup.Id -PolicyDefinitionId $PolicySetToAddExemptionTo.ResourceId)
        }
        Else {
            #it is a policy set so we need to know which policies within the set to exempt
            $definitionLookup = Get-AzPolicyDefinition | ForEach-Object { @{$_.PolicyDefinitionId = $_.Properties.DisplayName } } # we want pretty information so that humans can decide what to do
            $PolicyDefinitionToExclude = (Get-AzPolicySetDefinition -ResourceId $PolicySetToAddExemptionTo.ResourceId).Properties.PolicyDefinitions | Select-Object @{n = 'DefinitionDisplayName'; E = { $definitionLookup."$($_.PolicyDefinitionId)" } }, * -EA 0 | Out-GridView -PassThru -Title 'Select which policy/policies to add exemptions to within the initiative'
        }
        ###    - Get Resource(s) to exclude
        $SubscriptionsInThisTenant = Get-AzSubscription -TenantId (Get-AzContext).Tenant.id
        $AllResourceTypesScriptBlock = { (Get-AzResource | Group-Object ResourceType).Name }
        $allResourceTypes = Invoke-AzureCommand -ScriptBlock $AllResourceTypesScriptBlock -Subscription $SubscriptionsInThisTenant | Select-Object -Unique

        $resourceTypeToExclude = $allResourceTypes | Out-GridView -PassThru -Title 'Select which resource type to exclude'
        $resourcesToExcludeScriptBlock = { $resourceTypeToExclude | ForEach-Object { Get-AzResource -ResourceType $_ } }
        $resourcesToExcludeAll = Invoke-AzureCommand -ScriptBlock $resourcesToExcludeScriptBlock -Subscription $SubscriptionsInThisTenant

        $resourcesToExclude = $resourcesToExcludeAll | Out-GridView -PassThru -Title 'Select which specific resources to exclude'

        #get category
        $ExemptionCategory = @('Waiver', 'Mitigated') | Out-GridView -PassThru -Title 'Select the Exemption Category'

        #get expiration date
        $result = $dateForm.ShowDialog()
        If ($result -eq [Windows.Forms.DialogResult]::OK) {
            $ExpirationDate = $calendar.SelectionStart.ToString('yyyy-MM-dd')
        }
        Else {
            throw 'A date must be selected'
            return
        }
        If ($calendar.SelectionStart -gt [datetime]::now.AddDays(366)) {
            Write-Warning 'This exemption will be processed however expiration dates over 1 year in the future are discouraged.'
        }

        #get description
        $descriptionForm.Add_Shown({ $textBox.Select() })
        $result = $descriptionForm.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $description = $textBox.Text
        }
        Else {
            throw 'a description must be entered'
            return
        }

        ###    - Create splats

        $MySplats = ForEach ($definitionToExclude in $PolicyDefinitionToExclude) {
            ForEach ($resource in $resourcesToExclude) {
                $Policy = Get-AzPolicyDefinition -Id $definitionToExclude.PolicyDefinitionId
                $PolicyName = $Policy.Properties.DisplayName

                $DisplayName = "$($resource.Name) - $($PolicyAssignment.Properties.DisplayName) - $($Policy.Properties.DisplayName)"
                #$DisplayName = $DisplayName.Substring(0, 127).Trim()
                $DisplayName = $DisplayName.Substring(0, $(If ($DisplayName.Length -lt 128) { $DisplayName.Length }Else { 128 })).Trim()
                $ExemptionName = $DisplayName.Substring(0, $(If ($DisplayName.Length -lt 64) { $DisplayName.Length }Else { 64 })).Trim()

                @{
                    Name                        = $ExemptionName.replace('%', '').replace('&', '').replace('/', '').replace('?', '').replace('\', '').replace('<', '').replace('>', '').replace(':', '') #Azure doesn't like these characters
                    PolicyAssignment            = $PolicyAssignment
                    Scope                       = $resource.ResourceId
                    ExemptionCategory           = $ExemptionCategory
                    DisplayName                 = $DisplayName.replace('%', '').replace('&', '').replace('/', '').replace('?', '').replace('\', '').replace('<', '').replace('>', '').replace(':', '')
                    PolicyDefinitionReferenceId = $definitionToExclude.policyDefinitionReferenceId
                    ExpiresOn                   = $ExpirationDate
                    description                 = $description
                }
            }

        }

        ###    - Create exclusion

        ForEach ($splat in $MySplats) { New-AzPolicyExemption @splat }

    }
    end {}

}