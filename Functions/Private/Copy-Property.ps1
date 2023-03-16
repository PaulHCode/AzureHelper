#Copied from https://powershellstation.com/2016/01/14/copying-properties-to-another-object
function Copy-Property { 
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline = $true)]$InputObject,
        $SourceObject,
        [string[]]$Property,
        [switch]$Passthru,
        [switch]$ForceLowercaseKeys)
       
    $passthruHash = @{Passthru = $passthru.IsPresent }
    $propHash = @{}
    $property | Foreach-Object {
        If ($ForceLowercaseKeys) {
            $propHash += @{$_.ToLower() = $SourceObject.$_ }
        }
        Else {
            $propHash += @{$_ = $SourceObject.$_ }
        }
    }
    $inputObject | Add-Member -NotePropertyMembers $propHash @passthruHash
}
