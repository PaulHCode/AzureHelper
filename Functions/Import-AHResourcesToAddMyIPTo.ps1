Function Import-AHResourcesToAddMyIPTo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    If (!(Test-Path $Path)) {
        Throw "Invalid path"
    }
    Else {
        $Script:ResourceToAddMyIPTo = Import-Csv $Path
        IF (-not $?) {
            $Script:ResourceToAddMyIPTo = $()
            throw "Something went wrong, the list is now blank."
        }
    }

}

