Function ConvertTo-FlatNormalizedObject {
    <#
        .SYNOPSIS 
        Flattends a nested object into a single level object then normalizes the output so that all objects have the same properties.
        .DESCRIPTION
        Flattends a nested object into a single level object then normalizes the output so that all objects have the same properties.
        .PARAMETER Objects
        The object (or objects) to be flatten.
        .PARAMETER Separator
        The separator used between the recursive property names
        .PARAMETER Base
        The first index name of an embedded array:
        - 1, arrays will be 1 based: <Parent>.1, <Parent>.2, <Parent>.3, …
        - 0, arrays will be 0 based: <Parent>.0, <Parent>.1, <Parent>.2, …
        - "", the first item in an array will be unnamed and than followed with 1: <Parent>, <Parent>.1, <Parent>.2, …
        .PARAMETER Depth
        The maximal depth of flattening a recursive property. Any negative value will result in an unlimited depth and could cause a infinitive loop.
        .EXAMPLE
           $Object2 = [PSCustomObject] @{
        "Name"    = "John Smith"
        "Age"     = "99"
        "Address" = @{
            "Street"  = "Main"
            "City"    = "New York"
            "Country" = [ordered] @{
                "Name" = "Fish"
            }
            "PaulTest" = 'Test'
        }
        ListTest  = @(
            [PSCustomObject] @{
                "Name" = "ASDF"
                "Age"  = "33"
            }
        )
    }
        $Object3 = [PSCustomObject] @{
        "Name"    = "Przemyslaw Klys"
        "Age"     = "30"
        "Address" = @{
            "Street"  = "Kwiatowa"
            "City"    = "Warszawa"
            "Country" = [ordered] @{
                "Name" = "Poland"
            }
            List      = @(
                [PSCustomObject] @{
                    "Name" = "Adam Klys"
                    "Age"  = "32"
                }
                [PSCustomObject] @{
                    "Name" = "Justyna Klys"
                    "Age"  = "33"
                }
                [PSCustomObject] @{
                    "Name" = "Justyna Klys"
                    "Age"  = 30
                }
                [PSCustomObject] @{
                    "Name" = "Justyna Klys"
                    "Age"  = $null
                }
            )
        }
        ListTest  = @(
            [PSCustomObject] @{
                "Name" = "Sława Klys"
                "Age"  = "33"
            }
        )
    }
    $AllObjects = @($Object2,$Object3)
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeLine)][Object[]]$Objects,
        [String]$Separator = ".",
        [ValidateSet("", 0, 1)]$Base = 1,
        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -ge 0 })]
        [int]$Depth = 5,
        [Parameter(DontShow)][String[]]$Path,
        [Parameter(DontShow)][System.Collections.IDictionary] $OutputObject
    )
    Begin {
        $AllProperties = @()
        $AllFlattened = @()
    }
    Process {
        $Flattened = ConvertTo-FlatObject -Objects $Objects -Separator $Separator -Base $Base -Depth $Depth -Path $Path
        $Flattened | ForEach-Object { $_ | Get-Member -MemberType Properties | ForEach-Object { if ($_.Name -notin $AllProperties) { $AllProperties += $_.Name } } } #get all properties for all objects
        $AllFlattened += $Flattened
    }
    End {
        $selectSplat = @{Property = $AllProperties | Where-Object { $_[0] -notin @('@', '$') } } #PS doesn't like properties that start with @ or $, if I find others later then I'll also ignore those or find a way to fix it
        $NormalizedFlattened = $AllFlattened | ForEach-Object { $_ | Select-Object @selectSplat } #"normalize" all values in the array by making it so that all of them have all properties that any other object has. The value will be $Null if it wasn't defined previously. This makes it so that export-csv works. There will be too many properties, but we can select the ones we want.
        $NormalizedFlattened
    }
}