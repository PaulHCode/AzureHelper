


$MyScriptBlock = {
    $sub = (Get-AzContext).Name.split('(')[0]
    Get-AzVirtualNetwork | Select-Object -Property Name -ExpandProperty Addressspace | Select-Object Name, AddressPrefixes, @{N = 'Subscription'; E = { $sub } }
}


Invoke-AzureCommand -AllSubscriptions -ScriptBlock $MyScriptBlock

