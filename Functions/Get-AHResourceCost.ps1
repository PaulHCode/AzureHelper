Function Get-AHResourceCost {
    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceId,

        [int]
        $Days = 30,

        [switch]
        $ToThePenny
    )
    Test-AHEnvironment
    $MyDate = Get-Date
    $Cost = ((Get-AzConsumptionUsageDetail -InstanceId $ResourceId -StartDate ($MyDate.AddDays(-30)) -EndDate $MyDate | Measure-Object -Property pretaxcost -sum).sum)   

    If($ToThePenny){
        "{0:n2}" -f $Cost
    }Else{
        $Cost
    }
}