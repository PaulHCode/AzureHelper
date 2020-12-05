

<#
 - switch for file?
 - switch for folder?

 - verify existance of azcopy 
    - if it doesn't exist in the working directory or environmental paths then it prompts the user for the proper location
 - select file or folder to upload
 - pick subscription to upload to
 - select storage account
 - select container on the storage account
 - create a shared access signature for the storage account
 - perform the copy
 - validate the copy
 - remove the shared access signature
#>
<#

$AzCopyLocation = "C:\GitHub"
$AzCopyLocation += "\azcopy.exe"


#could get fancy and use GUI when available
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.ShowDialog() | Out-Null

$FileChooser = New-Object -TypeName System.Windows.forms.savefiledialog
$FileChooser.showdialog()





# Select where to put stuff
$TargetStorageAccount = $Null
$TargetStorageAccounts = Get-AzStorageAccount
If ($Null -eq $TargetStorageAccounts) {
    throw "No target storage accounts available.  Create a storage account or change to a subscription with a storage account."
}
While ($Null -eq $TargetStorageAccount -or $TargetStorageAccount -is [array]) {
    $TargetStorageAccount = $TargetStorageAccounts | Out-GridView -PassThru -Title "Select the target storage account"
}

$TargetStorageContainer = $Null
$TargetStorageContainers = Get-AzStorageAccount -Name $TargetStorageAccount.StorageAccountName -ResourceGroupName $TargetStorageAccount.ResourceGroupName
If ($Null -eq $TargetStorageContainers) {
    throw "No target storage containers available.  Create a storage container or select a storage account with a container."
}
While ($Null -eq $TargetStorageContainer -or $TargetStorageContainer -is [array]) {
    $TargetStorageContainer = $TargetStorageContainers | Out-GridView -PassThru -Title "Select the target storage container"
}

#>