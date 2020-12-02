Function Export-AHResourcesToAddMyIPTo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    If (Test-Path(Split-Path $Path -Parent)) {
        #Parent exists
        If (Test-Path $Path) {
            #Child exists
            While ($private:answer -ne 'y' -and $private:answer -ne 'n') {
                $private:answer = (Read-Host -Prompt "The file $Path already exists. Overwrite? (y/n)").ToLower()
            }
            If ('n' -eq $private:answer) {
                throw "Declined to overwrite, aborting."
            }
        }
    }
    Else {
        Throw "The path to $Path does not exist."
    }

    If ($Null -eq $Script:ResourceToAddMyIPTo) {
        throw "There are no items in the list to export.  Add items using Add-AHResourceToAddMyIPTo first."
    }
    Else {
        $Script:ResourceToAddMyIPTo | Export-Csv $Path
    }

}