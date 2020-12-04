Function Export-AHResourcesToAddMyIPTo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        [Parameter()]
        [Switch]
        $Force
    )

    If (Test-Path(Split-Path $Path -Parent)) {
        #Parent exists
        If (Test-Path $Path) {
            #Child exists
            If (-not $Force) {
                throw "The file already exists, use -Force to overwrite."
            }
        }
    }
    Else {
        Throw "Invalid Path. The path to $Path does not exist."
    }

    If ($Null -eq $Script:ResourceToAddMyIPTo) {
        throw "There are no items in the list to export.  Add items using Add-AHResourceToAddMyIPTo first."
    }
    Else {
        $Script:ResourceToAddMyIPTo | Export-Csv $Path
    }

}