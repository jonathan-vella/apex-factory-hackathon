#Requires -Version 7.4

<#
.SYNOPSIS
Tests the platform guard: it must fail closed on a wrong subscription or prefix. Never calls Azure.
.EXAMPLE
./test/Assert-PipelineGuard.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$guard = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Assert-PipelineGuard.ps1'
$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$shared = '11111111-1111-1111-1111-111111111111'
$workload = '22222222-2222-2222-2222-222222222222'
$live = '33333333-3333-3333-3333-333333333333'
$other = '44444444-4444-4444-4444-444444444444'

$cases = @(
    @{ Name = 'allowed subscriptions and prefix pass'; Expect = 0; Arguments = @('-SubscriptionId', "$shared,$workload", '-AllowedSubscriptionId', "$shared,$workload", '-MgPrefix', 'mg-factory-ci', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'ID case does not matter'; Expect = 0; Arguments = @('-SubscriptionId', $shared.ToUpperInvariant(), '-AllowedSubscriptionId', $shared, '-MgPrefix', 'mg-a', '-AllowedMgPrefix', 'mg-a') }
    @{ Name = 'a subscription that is not on the allowlist is refused'; Expect = 1; Arguments = @('-SubscriptionId', $other, '-AllowedSubscriptionId', "$shared,$workload", '-MgPrefix', 'mg-factory-ci', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'a denied subscription is refused'; Expect = 1; Arguments = @('-SubscriptionId', $live, '-AllowedSubscriptionId', $shared, '-DeniedSubscriptionId', $live, '-MgPrefix', 'mg-factory-ci', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'a denied subscription is refused even if it is also allowed'; Expect = 1; Arguments = @('-SubscriptionId', $live, '-AllowedSubscriptionId', "$shared,$live", '-DeniedSubscriptionId', $live, '-MgPrefix', 'mg-factory-ci', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'a wrong prefix is refused'; Expect = 1; Arguments = @('-SubscriptionId', $shared, '-AllowedSubscriptionId', $shared, '-MgPrefix', 'mg-factory', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'a denied prefix is refused'; Expect = 1; Arguments = @('-SubscriptionId', $shared, '-AllowedSubscriptionId', $shared, '-MgPrefix', 'mg-factory', '-AllowedMgPrefix', 'mg-factory', '-DeniedMgPrefix', 'mg-factory') }
    @{ Name = 'a prefix that only starts like the allowed one is refused'; Expect = 1; Arguments = @('-SubscriptionId', $shared, '-AllowedSubscriptionId', $shared, '-MgPrefix', 'mg-factory-ci-evil', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'an empty allowlist fails closed'; Expect = 1; Arguments = @('-SubscriptionId', $shared, '-MgPrefix', 'mg-factory-ci', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'an unset allowed prefix fails closed'; Expect = 1; Arguments = @('-SubscriptionId', $shared, '-AllowedSubscriptionId', $shared, '-MgPrefix', 'mg-factory-ci') }
    @{ Name = 'no subscription to check fails closed'; Expect = 1; Arguments = @('-AllowedSubscriptionId', $shared, '-MgPrefix', 'mg-factory-ci', '-AllowedMgPrefix', 'mg-factory-ci') }
    @{ Name = 'a malformed subscription ID is refused'; Expect = 1; Arguments = @('-SubscriptionId', 'not-a-guid', '-AllowedSubscriptionId', 'not-a-guid', '-MgPrefix', 'mg-factory-ci', '-AllowedMgPrefix', 'mg-factory-ci') }
)

$failed = 0
foreach ($case in $cases) {
    $output = & $pwsh -NoProfile -File $guard @($case.Arguments) 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne $case.Expect) {
        Write-Host "FAIL: $($case.Name) (expected exit $($case.Expect), got $exitCode)`n$output"
        $failed++
        continue
    }
    if ($exitCode -eq 1 -and $output -match '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') {
        Write-Host "FAIL: $($case.Name) printed a subscription ID`n$output"
        $failed++
        continue
    }
    Write-Host "PASS: $($case.Name)"
}
if ($failed -gt 0) { throw "$failed guard test(s) failed." }
Write-Host "PASS: $($cases.Count) guard scenarios (no Azure calls)."
