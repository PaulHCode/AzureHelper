Function Request-AHJITVMAccess {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Id,
        #        [Parameter()]
        #        [int[]]
        #        $Ports,
        [Parameter()]
        [int]
        [ValidateScript( { $_ -le 24 })]
        $Hours = 4,
        [Parameter()]
        [validateScript( { [IPAddress] $_ })]
        [string]
        $SourceIP = $(Get-AHMyPublicIPAddress),
        [Parameter()]
        [ValidateSet("Linux", "Windows")]
        [string]
        $OS
    )

    $MyResource = Get-AzResource -ResourceId $Id
    If (!$?) {
        throw "Invalid ResourceId"
    }

    # Start Section: Put policy in place
    <#
    $JitPolicy = (@{
            id    = $Id; 
            ports = (@{
                    number                     = 22;
                    protocol                   = "*";
                    allowedSourceAddressPrefix = @($(Get-AHMyPublicIPAddress)); #@("*");
                    maxRequestAccessDuration   = "PT3H"
                },
                @{
                    number                     = 3389;
                    protocol                   = "*";
                    allowedSourceAddressPrefix = @($(Get-AHMyPublicIPAddress)); #@("*");
                    maxRequestAccessDuration   = "PT3H"
                })
        })
    $AssignmentVM = @($JitPolicy)
    Set-AzJitNetworkAccessPolicy -Kind "Basic" -Location $MyResource.Location -Name "default" -ResourceGroupName $MyResource.ResourceGroupName -VirtualMachine $AssignmentVM
    #>
    # End Section: Put policy in place

    #Start Section: Activate Policy
    $JitPolicyVm1 = (@{
            id    = $Id; 
            ports = (@{
                    number                     = If ('Windows' -eq $OS) { 3389 }elseif ('Linux' -eq $OS) { 22 }else { throw "invalid OS" };
                    endTimeUtc                 = get-date (Get-Date -AsUTC).AddHours($Hours) -Format O  #"12/09/2020 20:11:18";
                    allowedSourceAddressPrefix = @($(Get-AHMyPublicIPAddress)) #@("173.72.158.65")
                })
        })
    $ActivationVM = @($JitPolicyVm1)

    Start-AzJitNetworkAccessPolicy -ResourceGroupName $MyResource.ResourceGroupName -Location $MyResource.Location -Name "default" -VirtualMachine $ActivationVM
    #End Section: Activate Policy


}
<#
$testOut = Request-AHJITVMAccess `
    -Id /subscriptions/c85c1e96-a251-49cd-8b78-050291feeea1/resourceGroups/PolicyDemo/providers/Microsoft.Compute/virtualMachines/PolicyDemoVM1 `
    -Hours 1 `
    -OS Linux



$MyPublicIP = Get-AHMyPublicIPAddress
$MyResource = Get-AzResource -Id /subscriptions/c85c1e96-a251-49cd-8b78-050291feeea1/resourceGroups/PolicyDemo/providers/Microsoft.Compute/virtualMachines/PolicyDemoVM1
$JitPolicy = (@{
        id    = $MyResource.ResourceId; 
        ports = (@{
                number                     = 22
                endTimeUtc                 = Get-Date (Get-Date -AsUTC).AddHours(1) -Format O
                allowedSourceAddressPrefix = @($MyPublicIP) 
            })
    })
$ActivationVM = @($JitPolicy)
Start-AzJitNetworkAccessPolicy -ResourceGroupName $($MyResource.ResourceGroupName) -Location $MyResource.Location -Name "default" -VirtualMachine $ActivationVM







#>



<#
https://docs.microsoft.com/en-us/azure/security-center/security-center-just-in-time?tabs=jit-config-powershell%2Cjit-request-powershell#enable-jit-vm-access-
https://docs.microsoft.com/en-us/powershell/module/az.security/start-azjitnetworkaccesspolicy?view=azps-5.2.0
https://docs.microsoft.com/en-us/powershell/module/az.security/set-azjitnetworkaccesspolicy?view=azps-5.2.0
#>