#Requires -Version 7.4

<#
.SYNOPSIS
Tears down the B07 spike: the SQL MI and rg-spike-b07, then the datacenter (rg-datacenter) with its Arc resources.
.DESCRIPTION
Deletes, in this order, and waits for each:
1. The SQL MI in rg-spike-b07, then its virtual cluster, which releases snet-sqlmi. That can take an hour.
2. rg-spike-b07 (vnet-spike-mi, nsg-sqlmi, rt-sqlmi and anything else in it).
3. The Arc machine vm-app01 in rg-datacenter (its extensions and the Arc SQL Server resources go with it),
   then rg-datacenter.
Then it checks that both groups are gone and that no Arc machine or Arc SQL Server instance is left in
the subscription for vm-app01. B07 creates no role assignments. This deletes data and can't be undone.
.PARAMETER SubscriptionId
The workload subscription.
.EXAMPLE
./docs/spikes/B07-arc-mi-link/scripts/Remove-SpikeB07.ps1 -SubscriptionId '<workload-subscription-id>'
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$subscription = $SubscriptionId
$spikeGroup = 'rg-spike-b07'
$datacenterGroup = 'rg-datacenter'

function Invoke-AzureCli {
    param([string[]] $Arguments, [switch] $AllowFailure)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --subscription $subscription --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($AllowFailure) {
            return $null
        }
        throw "Azure CLI '$(($Arguments | Select-Object -First 3) -join ' ')' failed (exit $LASTEXITCODE): $(($output | Select-Object -Last 1))"
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Wait-Until {
    param([scriptblock] $Condition, [string] $What, [int] $Minutes)
    $deadline = (Get-Date).AddMinutes($Minutes)
    while (-not (& $Condition)) {
        if ((Get-Date) -gt $deadline) {
            throw "Timed out after $Minutes minutes waiting for $What."
        }
        Start-Sleep -Seconds 30
    }
    Write-Information "$((Get-Date).ToString('HH:mm:ss')) $What."
}

function Test-GroupExist {
    param([string] $Name)
    return (Invoke-AzureCli -Arguments @('group', 'exists', '-n', $Name)) -eq $true
}

if (-not $PSCmdlet.ShouldProcess("$spikeGroup and $datacenterGroup", 'Delete the B07 spike and the datacenter')) {
    return
}
$started = Get-Date
Write-Information "$($started.ToString('HH:mm:ss')) Teardown started."

if (Test-GroupExist -Name $spikeGroup) {
    foreach ($mi in @(Invoke-AzureCli -Arguments @('sql', 'mi', 'list', '-g', $spikeGroup))) {
        if ($mi) {
            Write-Information "Deleting the SQL MI $($mi.name)."
            $null = Invoke-AzureCli -Arguments @('sql', 'mi', 'delete', '-g', $spikeGroup, '-n', $mi.name, '--yes')
        }
    }
    Wait-Until -What 'the virtual cluster is gone and snet-sqlmi is free' -Minutes 120 -Condition {
        -not @(Invoke-AzureCli -Arguments @('sql', 'virtual-cluster', 'list', '-g', $spikeGroup))[0]
    }
    Write-Information "Deleting $spikeGroup."
    $null = Invoke-AzureCli -Arguments @('group', 'delete', '-n', $spikeGroup, '--yes')
}

if (Test-GroupExist -Name $datacenterGroup) {
    $arc = Invoke-AzureCli -Arguments @('resource', 'show', '-g', $datacenterGroup, '-n', 'vm-app01', '--resource-type', 'Microsoft.HybridCompute/machines') -AllowFailure
    if ($arc) {
        Write-Information 'Deleting the Arc machine vm-app01 (its extensions and Arc SQL Server resources go with it).'
        $null = Invoke-AzureCli -Arguments @('resource', 'delete', '--ids', $arc.id)
    }
    Write-Information "Deleting $datacenterGroup."
    $null = Invoke-AzureCli -Arguments @('group', 'delete', '-n', $datacenterGroup, '--yes')
}

$leftArc = @(Invoke-AzureCli -Arguments @('resource', 'list', '--resource-type', 'Microsoft.HybridCompute/machines', '--query', "[?name=='vm-app01'].id"))
$leftSql = @(Invoke-AzureCli -Arguments @('resource', 'list', '--resource-type', 'Microsoft.AzureArcData/sqlServerInstances', '--query', "[?starts_with(name, 'vm-app01')].id"))
$result = [ordered]@{
    "$spikeGroup exists" = Test-GroupExist -Name $spikeGroup
    "$datacenterGroup exists" = Test-GroupExist -Name $datacenterGroup
    'Arc machines named vm-app01' = @($leftArc | Where-Object { $_ }).Count
    'Arc SQL Server instances for vm-app01' = @($leftSql | Where-Object { $_ }).Count
}
$result.GetEnumerator() | ForEach-Object { Write-Information ("  {0}: {1}" -f $_.Key, $_.Value) }
Write-Information "$((Get-Date).ToString('HH:mm:ss')) Teardown finished after $([int] ((Get-Date) - $started).TotalMinutes) minutes."
if ($result.Values -contains $true -or ($result.Values | Where-Object { $_ -is [int] -and $_ -gt 0 })) {
    throw 'Something is left. See the list above.'
}
