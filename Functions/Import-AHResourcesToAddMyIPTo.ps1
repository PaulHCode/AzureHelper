Function Import-AHResourcesToAddMyIPTo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    If (0 -ne $Script:ResourceToAddMyIPTo.count) {
        While ($private:answer -ne 'y' -and $private:answer -ne 'n') {
            $private:answer = (Read-Host -Prompt "There are already items stored in the list. Overwrite? (y/n)").ToLower()
        }
        If ('n' -eq $private:answer) {
            throw "Declined to overwrite, aborting."
        }
    }

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