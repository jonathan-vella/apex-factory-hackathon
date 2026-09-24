#Requires -Version 7.4

<#
.SYNOPSIS
Runs preflight regression tests with an in-process fake Azure CLI, never Azure.
.EXAMPLE
./test/Test-Preflight.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$preflight = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Test-Preflight.ps1'
$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$runner = @'
$ErrorActionPreference = 'Stop'
$global:providerReads = 0
function global:az {
    $global:LASTEXITCODE = 0
    $command = $args -join ' '
    Add-Content -LiteralPath $calls -Value $command
    if ($scenario -eq 'cli-error' -and $args[0] -eq 'version') {
        $global:LASTEXITCODE = 1
        return 'Sensitive CLI error must not appear in output'
    }
    if ($scenario -eq 'invalid-json' -and $args[0] -eq 'version') { return 'not JSON' }
    if ($args[0] -eq 'version') {
        $v = if ($scenario -eq 'old-cli') { '2.69.0' } else { '2.90.0' }
        return (@{'azure-cli'=$v} | ConvertTo-Json)
    }
    if ($command -like 'bicep version*') {
        if ($scenario -eq 'old-bicep') { return 'Bicep CLI version 0.29.0' }
        return 'Bicep CLI version 0.47.16'
    }
    if ($command -like 'account get-access-token*') { return '{"accessToken":"fake"}' }
    if ($command -like 'account show*') {
        if ($scenario -eq 'missing-subscription' -and $args -contains '--subscription') {
            $global:LASTEXITCODE = 1
            return 'Subscription 11111111-1111-1111-1111-111111111111 does not exist'
        }
        $tenant = if ($scenario -eq 'wrong-tenant' -and $args -contains '--subscription') { 'other' } else { 'tenant' }
        return (@{tenantId=$tenant; state='Enabled'} | ConvertTo-Json)
    }
    if ($command -like 'ad signed-in-user show*') { return '{"id":"fake-user"}' }
    if ($command -like 'role assignment list*') {
        if ($args -notcontains '--include-inherited' -or $args -notcontains '--include-groups') {
            throw 'Role check omitted inherited or group assignments.'
        }
        if ($scenario -eq 'no-owner') { return '[]' }
        if ($scenario -eq 'mg-unknown' -and $command -like '*managementGroups*') {
            $global:LASTEXITCODE = 1
            return 'Management groups could not be queried'
        }
        return '[{"roleDefinitionName":"Owner"}]'
    }
    if ($command -like 'vm list-skus*') {
        if ($args -notcontains '--all') { throw 'Restricted SKUs must be included.' }
        $r = switch ($scenario) {
            'zone-only' { @(@{type='Zone'}) }
            'location' { @(@{type='Location'}) }
            default { @() }
        }
        if ($scenario -eq 'missing-sku') { return '[]' }
        return (ConvertTo-Json -Depth 5 -InputObject @(@{name='Standard_D8as_v6'; resourceType='virtualMachines'; restrictions=@($r)}))
    }
    if ($command -like 'rest --method get --url /subscriptions/*/locations?*') {
        if ($scenario -eq 'missing-region') { return '{"value":[]}' }
        return '{"value":[{"name":"swedencentral","displayName":"Sweden Central"}]}'
    }
    if ($command -like 'provider show*') {
        if ($scenario -eq 'no-mi') { return '{"resourceTypes":[]}' }
        return '{"resourceTypes":[{"resourceType":"managedInstances","locations":["Sweden Central"]}]}'
    }
    if ($command -like 'provider register*') {
        if ($scenario -eq 'registration-error') {
            $global:LASTEXITCODE = 1
            return 'Registration denied'
        }
        return
    }
    if ($command -like 'provider list*') {
        $global:providerReads++
        $names = 'Compute','Network','Storage','Sql','Web','ContainerRegistry','ServiceBus','KeyVault',
            'ManagedIdentity','Insights','OperationalInsights','OperationsManagement','HybridCompute',
            'GuestConfiguration','AzureArcData','PolicyInsights','Security','Management'
        $data = foreach ($name in $names) {
            $state = 'Registered'
            if ($name -eq 'Compute' -and $scenario -in @('missing-provider','registration-error','fix','no-owner')) {
                if ($scenario -ne 'fix' -or $global:providerReads -le 2) { $state = 'Registering' }
            }
            @{namespace="Microsoft.$name"; registrationState=$state}
        }
        return (ConvertTo-Json -InputObject @($data))
    }
    throw "Unexpected Azure CLI command: $command"
}
function global:Start-Sleep { param([int] $Seconds) }
$parameters = @{ WorkloadSubscriptionId='11111111-1111-1111-1111-111111111111'; OutFile=$report }
if ($scenario -ne 'member') { $parameters.SharedSubscriptionId='22222222-2222-2222-2222-222222222222' }
if ($scenario -in @('fix','registration-error','no-owner')) { $parameters.Fix=$true }
if ($scenario -eq 'duplicate') { $parameters.SharedSubscriptionId=$parameters.WorkloadSubscriptionId }
if ($scenario -eq 'invalid-id') { $parameters.WorkloadSubscriptionId='not-a-guid' }
if ($scenario -eq 'output-error') { $parameters.OutFile=Join-Path $report 'missing/report.json' }
& $preflight @parameters
exit $LASTEXITCODE
'@

$scenarios = @(
    'healthy', 'member', 'zone-only', 'location', 'missing-sku', 'mg-unknown',
    'missing-subscription', 'invalid-id', 'wrong-tenant', 'no-owner', 'duplicate',
    'missing-region', 'no-mi', 'missing-provider', 'fix', 'registration-error',
    'old-cli', 'old-bicep', 'cli-error', 'invalid-json', 'output-error'
)
$passing = @('healthy', 'member', 'zone-only', 'location', 'missing-sku', 'mg-unknown', 'fix')
foreach ($scenario in $scenarios) {
    $report = [System.IO.Path]::GetTempFileName()
    $calls = [System.IO.Path]::GetTempFileName()
    try {
        $prefix = "`$scenario='$scenario'; `$report='$($report.Replace("'", "''"))'; `$calls='$($calls.Replace("'", "''"))'; `$preflight='$($preflight.Replace("'", "''"))';`n"
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($prefix + $runner))
        $output = (& $pwsh -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1 | Out-String)
        $exitCode = $LASTEXITCODE
        $expected = if ($scenario -in $passing) { 0 } else { 1 }
        if ($exitCode -ne $expected) { throw "$scenario expected exit $expected, got $exitCode`n$output" }
        if ($output -match '11111111-|22222222-|Sensitive CLI error') { throw "$scenario leaked raw CLI details." }
        if ($scenario -eq 'output-error') {
            if ($output -notmatch 'JSON output' -or $output -notmatch 'NO-GO: 1 failure') { throw 'JSON write failure was not reported.' }
            Write-Output "PASS: $scenario"
            continue
        }
        $data = Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
        $failures = @($data.Checks | Where-Object Status -EQ 'FAIL')
        if ($data.FailureCount -ne $failures.Count) { throw "$scenario JSON failure count mismatch." }
        if (($data.Verdict -eq 'GO') -ne ($expected -eq 0)) { throw "$scenario JSON verdict mismatch." }
        if (@($data.Checks | Where-Object Status -EQ 'MANUAL').Count -ne 5) { throw "$scenario manual checks missing." }
        if ($failures | Where-Object { -not $_.Fix }) { throw "$scenario FAIL is missing a remedy." }
        $commands = Get-Content -LiteralPath $calls
        if ($commands -match 'quota|account set|deployment| create ') { throw "$scenario attempted an out-of-scope command." }
        if ($scenario -notin @('fix','registration-error') -and ($commands -match '^provider register')) {
            throw "$scenario registered providers without eligible -Fix."
        }
        if ($scenario -eq 'fix' -and @($commands -match '^provider list').Count -lt 3) { throw 'Registration was not polled.' }
        $vm = $data.Checks | Where-Object Check -EQ 'VM size'
        if ($scenario -eq 'zone-only' -and ($vm.Status -ne 'PASS' -or $vm.Reason -notmatch 'non-zonally')) { throw 'Zone-only restriction should pass non-zonally.' }
        if ($scenario -eq 'location' -and $vm.Status -ne 'WARN') { throw 'Location restriction should warn.' }
        if ($scenario -eq 'mg-unknown' -and ($data.Checks | Where-Object Check -EQ 'Management groups').Status -ne 'WARN') { throw 'Indeterminate management rights should warn.' }
        if ($scenario -eq 'member' -and ($data.Checks.Check -contains 'Management groups' -or $commands -match 'managementGroups')) { throw 'Member must skip management groups.' }
        Write-Output "PASS: $scenario"
    }
    finally {
        Remove-Item -LiteralPath $report, $calls -Force
    }
}
Write-Output "PASS: $($scenarios.Count) preflight scenarios (no Azure calls)."
exit 0
