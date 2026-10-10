#Requires -Version 7.4

<#
.SYNOPSIS
Runs regression tests for Initialize-Settings, Deploy-Vending's output masking and the perf kit's SQL password lookup, never against Azure.
.EXAMPLE
./test/Test-Helpers.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$work = Join-Path $PSScriptRoot ".work-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $work | Out-Null
$passed = 0

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-Child {
    # Runs a script block in a fresh pwsh with the given variables, without prompts, and returns exit code and output.
    param([string] $Script, [hashtable] $Variables = @{})
    $prefix = ($Variables.GetEnumerator() | ForEach-Object { "`$$($_.Key) = '$($_.Value.ToString().Replace("'", "''"))'" }) -join "`n"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("$prefix`n$Script"))
    $output = (& $pwsh -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1 | Out-String)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

try {
    # Initialize-Settings: runs from a copy so that .local lands in the work folder.
    $kit = Join-Path $work 'kit'
    New-Item -ItemType Directory -Path (Join-Path $kit 'scripts') -Force | Out-Null
    Copy-Item (Join-Path $repoRoot 'scripts/Initialize-Settings.ps1') (Join-Path $kit 'scripts')
    $settingsScript = Join-Path $kit 'scripts/Initialize-Settings.ps1'
    $settingsFile = Join-Path $kit '.local/settings.json'
    $guidA = '11111111-1111-1111-1111-111111111111'
    $guidB = '22222222-2222-2222-2222-222222222222'
    $guidC = '33333333-3333-3333-3333-333333333333'
    $stub = 'function global:az { $global:LASTEXITCODE = 1 }'

    $run = Invoke-Child -Variables @{ s = $settingsScript; a = $guidA; b = $guidB } -Script "$stub`n& `$s -TenantId `$a -SubscriptionId `$b -MemberIndex 3 -Location swedencentral -SharedSubscriptionId 44444444-4444-4444-4444-444444444444 -Suffix ab12cd"
    Assert-True ($run.ExitCode -eq 0) "Fresh settings failed: $($run.Output)"
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    Assert-True ($settings.suffix -eq 'ab12cd' -and $settings.memberIndex -eq 3) 'Fresh settings should keep the restored suffix.'
    $passed++

    $run = Invoke-Child -Variables @{ s = $settingsScript; c = $guidC } -Script "$stub`n& `$s -SharedSubscriptionId `$c"
    Assert-True ($run.ExitCode -eq 0) "Adding the shared subscription prompted or failed: $($run.Output)"
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    Assert-True ($settings.sharedSubscriptionId -eq $guidC -and $settings.subscriptionId -eq $guidB -and $settings.suffix -eq 'ab12cd') 'Only the shared subscription should change.'
    $passed++

    $run = Invoke-Child -Variables @{ s = $settingsScript } -Script "$stub`n& `$s -Suffix zzzzzz"
    Assert-True ($run.ExitCode -ne 0 -and $run.Output -match 'never changed') 'A different suffix must be refused.'
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    Assert-True ($settings.suffix -eq 'ab12cd') 'The suffix must not change.'
    $passed++

    $run = Invoke-Child -Variables @{ s = $settingsScript; b = $guidB } -Script "$stub`n& `$s -SharedSubscriptionId `$b"
    Assert-True ($run.ExitCode -ne 0 -and $run.Output -match 'different') 'A shared subscription equal to the workload subscription must be refused.'
    $passed++

    # Deploy-Vending: the summary masks subscription IDs unless -ShowIds.
    $vendingScript = Join-Path $repoRoot 'scripts/Deploy-Vending.ps1'
    $vendingStub = @'
$hubSub = '22222222-2222-2222-2222-222222222222'
function global:az {
    $global:LASTEXITCODE = 0
    $command = $args -join ' '
    if ($command -like 'account show*') { return '{"tenantId":"tenant-1"}' }
    if ($command -like 'ad signed-in-user show*') { return '{"id":"user-1"}' }
    if ($command -like 'role assignment list*') { return '[{"roleDefinitionName":"Owner"}]' }
    if ($command -like 'network vnet show*vnet-hub*') { return "{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub`"}" }
    if ($command -like 'resource show*afw-hub*') { return "{`"properties`":{`"ipConfigurations`":[{`"properties`":{`"privateIPAddress`":`"10.0.0.4`"}}],`"firewallPolicy`":{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-hub/providers/Microsoft.Network/firewallPolicies/afwp-hub`"}}}" }
    if ($command -like 'resource show*log-management*') { return "{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-management`"}" }
    if ($command -like 'identity show*') { return '{"id":"identity-1"}' }
    if ($command -like 'group show*') { return "{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-hub`"}" }
    if ($command -like 'deployment mg what-if*') { return }
    $global:LASTEXITCODE = 1
    return 'not found'
}
'@
    foreach ($showIds in $false, $true) {
        $extra = if ($showIds) { ' -ShowIds' } else { '' }
        $run = Invoke-Child -Variables @{ v = $vendingScript } -Script "$vendingStub`n& `$v -WorkloadSubscriptionId '11111111-1111-1111-1111-111111111111' -SharedSubscriptionId `$hubSub -MemberIndex 1 -BudgetEmail 'lead@example.test' -WhatIf$extra *>&1"
        Assert-True ($run.ExitCode -eq 0) "Vending what-if failed (ShowIds=$showIds): $($run.Output)"
        Assert-True ($run.Output -match 'Hub VNet') "Vending summary missing (ShowIds=$showIds): $($run.Output)"
        if ($showIds) {
            Assert-True ($run.Output -match '22222222-2222-2222-2222-222222222222') 'ShowIds should print the full resource IDs.'
        }
        else {
            Assert-True ($run.Output -notmatch '22222222-2222-2222-2222-222222222222' -and $run.Output -match '/subscriptions/<subscription-id>/resourceGroups/rg-hub') 'The default summary should mask the subscription ID.'
        }
        $passed++
    }

    # The member's Reader grant on the hub shows in the summary only when a principal is passed.
    foreach ($principal in '', '33333333-3333-3333-3333-333333333333') {
        $extra = if ($principal) { " -MemberPrincipalId '$principal'" } else { '' }
        $run = Invoke-Child -Variables @{ v = $vendingScript } -Script "$vendingStub`n& `$v -WorkloadSubscriptionId '11111111-1111-1111-1111-111111111111' -SharedSubscriptionId `$hubSub -MemberIndex 1 -BudgetEmail 'lead@example.test' -WhatIf$extra *>&1"
        Assert-True ($run.ExitCode -eq 0) "Vending what-if failed (principal='$principal'): $($run.Output)"
        $expected = if ($principal) { 'Hub Reader\s+the member' } else { 'Hub Reader\s+skipped' }
        Assert-True ($run.Output -match $expected) "The vending summary should show the hub Reader grant as '$expected' (principal='$principal'): $($run.Output)"
        $passed++
    }

    # PerfKit: the SQL password comes from -SqlPassword, then the kit's .local, then the lab password.
    if (Get-Module -ListAvailable -Name SqlServer) {
        $perfKit = Join-Path $work 'perf'
        New-Item -ItemType Directory -Path (Join-Path $perfKit 'db/perf-kit') -Force | Out-Null
        Copy-Item (Join-Path $repoRoot 'db/perf-kit/PerfKit.psm1') (Join-Path $perfKit 'db/perf-kit')
        $module = Join-Path $perfKit 'db/perf-kit/PerfKit.psm1'
        $perfScript = @'
Import-Module SqlServer -DisableNameChecking
Import-Module $module -Force
$secure = if ($pw) { ConvertTo-SecureString $pw -AsPlainText -Force }
$text = Get-PerfKitConnectionString -Server 10.10.1.4 -Authentication SqlPassword -SqlPassword $secure
Write-Output $text
'@
        $run = Invoke-Child -Variables @{ module = $module; pw = '' } -Script $perfScript
        Assert-True ($run.ExitCode -eq 0 -and $run.Output -match 'FactoryLab-2026-Pw') "The lab password fallback failed: $($run.Output)"
        $passed++

        $secretsDir = Join-Path $perfKit '.local/44444444-4444-4444-4444-444444444444'
        New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null
        Set-Content -Path (Join-Path $secretsDir 'datacenter.json') -Value '{"sqlAppLogin":"contosoapp","sqlAppPassword":"FromLocal-Pw1"}'
        $run = Invoke-Child -Variables @{ module = $module; pw = '' } -Script $perfScript
        Assert-True ($run.ExitCode -eq 0 -and $run.Output -match 'FromLocal-Pw1') "The .local lookup failed: $($run.Output)"
        $passed++

        $run = Invoke-Child -Variables @{ module = $module; pw = 'Explicit-Pw1' } -Script $perfScript
        Assert-True ($run.ExitCode -eq 0 -and $run.Output -match 'Explicit-Pw1' -and $run.Output -notmatch 'FromLocal-Pw1') "-SqlPassword should win: $($run.Output)"
        $passed++
    }
    else {
        Write-Output 'SKIP: the SqlServer module is not installed; the perf kit password tests did not run.'
    }

    Write-Output "PASS: $passed helper scenarios (no Azure calls)."
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
