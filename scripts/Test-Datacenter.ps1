#Requires -Version 7.4

<#
.SYNOPSIS
Checks that the member's datacenter is ready: attendees run it at T-3.
.DESCRIPTION
Checks rg-datacenter in Azure (VM state, size, licence type, Trusted Launch, zones, IPs, disks, public
IPs), then runs read-only checks inside vm-app01 and vm-dev01 through az vm run-command invoke. Prints
PASS or FAIL per check, then an overall verdict. Exits 0 when every check passes, 1 otherwise.
Changes nothing.
.PARAMETER SubscriptionId
The member's workload subscription.
.PARAMETER MemberIndex
The member index n, 1-20.
.PARAMETER VmSize
The VM size the datacenter was deployed with, if not the default.
.PARAMETER NoHybridBenefit
Expect vm-app01 without Azure Hybrid Benefit (deployed with -NoHybridBenefit).
.EXAMPLE
./scripts/Test-Datacenter.ps1 -SubscriptionId '<workload-subscription-id>' -MemberIndex 1
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [ValidateRange(1, 20)]
    [int] $MemberIndex = 1,
    [string] $VmSize = 'Standard_D8as_v6',
    [switch] $NoHybridBenefit
)

$ErrorActionPreference = 'Stop'
$subscription = $SubscriptionId
$expectedSize = $VmSize
$resourceGroup = 'rg-datacenter'
$scriptsDir = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'infra', 'datacenter', 'scripts'
$appVmIp = "10.10.$MemberIndex.4"
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string] $Check, [bool] $Pass, [string] $Detail)
    $results.Add([pscustomobject]@{
        Check = $Check
        Status = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
}

function Invoke-AzureCli {
    param([string[]] $Arguments)
    # Capture native stderr rather than letting the CLI print subscription IDs.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --subscription $subscription --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE)."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Test-Vm {
    param([string] $Name, [string] $PrivateIp, [string] $LicenseType)
    try {
        $vm = Invoke-AzureCli -Arguments @('vm', 'show', '--show-details', '-g', $resourceGroup, '-n', $Name)
    }
    catch {
        Add-Result -Check "azure: $Name exists" -Pass $false -Detail $_.Exception.Message
        return $null
    }
    $security = $vm.securityProfile
    Add-Result -Check "azure: $Name running" -Pass ($vm.powerState -eq 'VM running') -Detail $vm.powerState
    Add-Result -Check "azure: $Name size" -Pass ($vm.hardwareProfile.vmSize -eq $expectedSize) -Detail $vm.hardwareProfile.vmSize
    Add-Result -Check "azure: $Name licenseType" -Pass ("$($vm.licenseType)" -eq $LicenseType) -Detail "$($vm.licenseType)"
    Add-Result -Check "azure: $Name Trusted Launch" `
        -Pass ($security.securityType -eq 'TrustedLaunch' -and $security.uefiSettings.secureBootEnabled -and $security.uefiSettings.vTpmEnabled) `
        -Detail "$($security.securityType), Secure Boot $($security.uefiSettings.secureBootEnabled), vTPM $($security.uefiSettings.vTpmEnabled)"
    Add-Result -Check "azure: $Name no zone" -Pass (@($vm.zones).Where({ $_ }).Count -eq 0) -Detail $(if ($vm.zones) { "zones: $($vm.zones -join ',')" } else { 'none' })
    Add-Result -Check "azure: $Name private IP" -Pass ($vm.privateIps -eq $PrivateIp) -Detail $vm.privateIps
    return $vm
}

function Invoke-VmCheck {
    param([string] $Name, [string] $Script, [string[]] $Parameters)
    try {
        $arguments = @('vm', 'run-command', 'invoke', '-g', $resourceGroup, '-n', $Name, '--command-id', 'RunPowerShellScript',
            '--scripts', "@$(Join-Path -Path $scriptsDir -ChildPath $Script)")
        if ($Parameters) {
            $arguments += @('--parameters') + $Parameters
        }
        $response = Invoke-AzureCli -Arguments $arguments
        $message = ($response.value | ForEach-Object { $_.message }) -join "`n"
        $lines = @($message -split "`r?`n" | Where-Object { $_ -like 'LABCHECK|*' })
        if ($lines.Count -eq 0) {
            Add-Result -Check "${Name}: in-VM checks" -Pass $false -Detail "no results: $($message.Trim() -replace '\s+', ' ')"
            return
        }
        foreach ($line in $lines) {
            $parts = $line -split '\|', 4
            Add-Result -Check $parts[2] -Pass ($parts[1] -eq 'PASS') -Detail $parts[3]
        }
    }
    catch {
        Add-Result -Check "${Name}: in-VM checks" -Pass $false -Detail $_.Exception.Message
    }
}

Write-Output "Checking the datacenter of member $MemberIndex. The in-VM checks take a few minutes."

try {
    $null = Invoke-AzureCli -Arguments @('group', 'show', '-n', $resourceGroup)
}
catch {
    Add-Result -Check "azure: $resourceGroup exists" -Pass $false -Detail 'not found. Deploy it with scripts/Deploy-Datacenter.ps1.'
}

if ($results.Count -eq 0) {
    $appLicense = if ($NoHybridBenefit) { 'None' } else { 'Windows_Server' }
    $appVm = Test-Vm -Name 'vm-app01' -PrivateIp $appVmIp -LicenseType $appLicense
    $devVm = Test-Vm -Name 'vm-dev01' -PrivateIp "10.10.$MemberIndex.5" -LicenseType 'Windows_Client'

    if ($appVm) {
        $dataDisks = @($appVm.storageProfile.dataDisks)
        $disk = $dataDisks | Select-Object -First 1
        $dataDiskOk = $dataDisks.Count -eq 1 -and $disk.lun -eq 0 -and $disk.name -eq 'disk-data-vm-app01' -and
            $disk.diskSizeGb -eq 1024 -and $disk.caching -eq 'ReadOnly' -and $disk.managedDisk.storageAccountType -eq 'Premium_LRS'
        Add-Result -Check 'azure: vm-app01 P30 data disk' -Pass $dataDiskOk `
            -Detail $(if ($disk) { "$($dataDisks.Count) disk(s): $($disk.name), LUN $($disk.lun), $($disk.diskSizeGb) GiB, $($disk.caching), $($disk.managedDisk.storageAccountType)" } else { 'none' })
        $osType = $appVm.storageProfile.osDisk.managedDisk.storageAccountType
        Add-Result -Check 'azure: vm-app01 OS disk Premium SSD' -Pass ($osType -eq 'Premium_LRS') -Detail $osType
    }
    if ($devVm) {
        $devDataDisks = @($devVm.storageProfile.dataDisks)
        Add-Result -Check 'azure: vm-dev01 no data disk' -Pass ($devDataDisks.Count -eq 0) -Detail "$($devDataDisks.Count) data disk(s)"
        $osDisk = Invoke-AzureCli -Arguments @('disk', 'show', '-g', $resourceGroup, '-n', 'osdisk-vm-dev01')
        Add-Result -Check 'azure: vm-dev01 OS disk at tier P30' -Pass ($osDisk.tier -eq 'P30' -and $osDisk.sku.name -eq 'Premium_LRS') `
            -Detail "$($osDisk.sku.name), $($osDisk.diskSizeGb) GiB, tier $($osDisk.tier)"
    }

    $publicIps = @(Invoke-AzureCli -Arguments @('network', 'public-ip', 'list', '-g', $resourceGroup) | ForEach-Object { $_.name })
    $unexpected = @($publicIps | Where-Object { $_ -ne 'pip-nat-datacenter' })
    Add-Result -Check 'azure: no public IPs except pip-nat-datacenter' -Pass ($unexpected.Count -eq 0) -Detail ($publicIps -join ', ')

    if ($appVm -and $appVm.powerState -eq 'VM running') {
        Invoke-VmCheck -Name 'vm-app01' -Script 'Test-AppVm.ps1' -Parameters @('MinStudents=8', 'TargetStudents=200000', 'TargetEnrollments=2000000')
    }
    if ($devVm -and $devVm.powerState -eq 'VM running') {
        Invoke-VmCheck -Name 'vm-dev01' -Script 'Test-DevVm.ps1' -Parameters @("AppVmIp=$appVmIp")
    }
}

$results | Format-Table Check, Status, Detail -Wrap | Out-String -Width 200 | Write-Output
$failures = @($results | Where-Object Status -EQ 'FAIL').Count
if ($failures -eq 0) {
    Write-Output "PASS: all $($results.Count) checks passed. The datacenter is ready."
    exit 0
}
Write-Output "FAIL: $failures of $($results.Count) checks failed."
exit 1
