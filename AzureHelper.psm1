foreach ($file in(Get-ChildItem "$PSScriptRoot\Functions" -Filter *.ps1 -Recurse)) {
    . $file.FullName
}
$Script:PolicyDefinitionIDs = @()
$Script:ResourceToAddMyIPTo = @()
#$Script:MyPublicIPAddress = Get-AHMyPublicIPAddress #this is broken, fix it later