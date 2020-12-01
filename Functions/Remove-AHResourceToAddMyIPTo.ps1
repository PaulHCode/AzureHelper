Function Remove-AHResourceToAddMyIPTo {
    <#
    .Parameter Id
        A resource ID or array of resource IDs to remove.
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $ResourceId
    )
    process {
        $Script:ResourceToAddMyIPTo = $Script:ResourceToAddMyIPTo | Where-Object { $_.Id -notin $ResourceId }
    }
}