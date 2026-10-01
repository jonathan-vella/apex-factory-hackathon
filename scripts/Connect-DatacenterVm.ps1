#Requires -Version 7.4

<#
.SYNOPSIS
Opens a Remote Desktop session to a datacenter VM from your local Windows computer, through Bastion.
.DESCRIPTION
Connects your local Remote Desktop client (mstsc) to vm-dev01 or vm-app01 in rg-datacenter through
bas-datacenter (Bastion Standard with native client support), using az network bastion rdp. Sign in
as labadmin with the lab password. The command returns when you close the session.

It needs a Windows computer with the Azure CLI, the Azure CLI bastion extension
(az extension add --name bastion) and az login to the member's tenant. Your account needs Reader on
the VM, its NIC and bas-datacenter. It doesn't work in Azure Cloud Shell, macOS or Linux: there, use
the portal instead (rg-datacenter > the VM > Connect > Bastion).
.PARAMETER SubscriptionId
The member's workload subscription.
.PARAMETER VmName
The VM to connect to: vm-dev01 (default) or vm-app01.
.EXAMPLE
./scripts/Connect-DatacenterVm.ps1 -SubscriptionId '<workload-subscription-id>'
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Connect-DatacenterVm.ps1 -SubscriptionId $s.subscriptionId -VmName vm-app01
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [ValidateSet('vm-dev01', 'vm-app01')]
    [string] $VmName = 'vm-dev01'
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$resourceGroup = 'rg-datacenter'
$bastionName = 'bas-datacenter'
$portalFallback = "Connect in the Azure portal instead: $resourceGroup > $VmName > Connect > Bastion."

function Invoke-AzureCli {
    param([string[]] $Arguments)
    # Capture native stderr rather than letting the CLI print subscription IDs.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --subscription $SubscriptionId --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE). Run az login, check that your account has Reader on $resourceGroup, and try again."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

if (-not $IsWindows) {
    throw "The local Remote Desktop client needs Windows, and native client connections don't work in Cloud Shell. $portalFallback"
}
if (-not (Get-Command -Name az -ErrorAction SilentlyContinue)) {
    throw "The Azure CLI isn't installed. Install it from https://aka.ms/installazurecliwindows. $portalFallback"
}
$PSNativeCommandUseErrorActionPreference = $false
$null = & az extension show --name bastion --only-show-errors --output none 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "The Azure CLI bastion extension isn't installed. Run: az extension add --name bastion"
}

$vm = Invoke-AzureCli -Arguments @('vm', 'show', '--show-details', '-g', $resourceGroup, '-n', $VmName)
if ($vm.powerState -ne 'VM running') {
    throw "$VmName is '$($vm.powerState)'. Start it with: az vm start --subscription <subscription-id> -g $resourceGroup -n $VmName"
}
$bastion = Invoke-AzureCli -Arguments @('network', 'bastion', 'show', '-g', $resourceGroup, '-n', $bastionName)
if (-not $bastion.enableTunneling) {
    throw "$bastionName doesn't have native client support on. Re-run scripts/Deploy-Datacenter.ps1. $portalFallback"
}

Write-Information "Opening Remote Desktop to $VmName ($($vm.privateIps)) through $bastionName. Sign in as labadmin with the lab password."
Write-Information 'Keep this window open: closing it ends the tunnel.'
& az network bastion rdp --subscription $SubscriptionId -g $resourceGroup -n $bastionName --target-resource-id $vm.id --only-show-errors
if ($LASTEXITCODE -ne 0) {
    throw "az network bastion rdp failed (exit $LASTEXITCODE). $portalFallback"
}
