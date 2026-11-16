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
    # PowerShell wraps long error text at the console width, and boxes it with ' | ' markers: join the lines.
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -replace '(\r?\n\s*\|?\s*)+', ' ') }
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
    Assert-True ($run.ExitCode -ne 0 -and $run.Output -match 'never changed') "A different suffix must be refused (exit $($run.ExitCode)): $($run.Output)"
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    Assert-True ($settings.suffix -eq 'ab12cd') 'The suffix must not change.'
    $passed++

    $run = Invoke-Child -Variables @{ s = $settingsScript; b = $guidB } -Script "$stub`n& `$s -SharedSubscriptionId `$b"
    Assert-True ($run.ExitCode -ne 0 -and $run.Output -match 'different') 'A shared subscription equal to the workload subscription must be refused.'
    $passed++

    # MemberIndex accepts values > 20 (for example 25 and 300) and rejects 0.
    foreach ($largeIndex in 25, 300) {
        $run = Invoke-Child -Variables @{ s = $settingsScript; idx = $largeIndex } -Script "$stub`n& `$s -MemberIndex `$idx"
        Assert-True ($run.ExitCode -eq 0) "MemberIndex $largeIndex should be accepted: $($run.Output)"
        $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
        Assert-True ($settings.memberIndex -eq $largeIndex) "settings.json should store memberIndex $largeIndex."
        $passed++
    }

    $run = Invoke-Child -Variables @{ s = $settingsScript; a = $guidA; b = $guidB } -Script "$stub`n& `$s -TenantId `$a -SubscriptionId `$b -MemberIndex 0 -Location swedencentral"
    Assert-True ($run.ExitCode -ne 0) "MemberIndex 0 must be rejected: $($run.Output)"
    $passed++

    # -WriteLabCredentials writes .local/<subscriptionId>/datacenter.json without printing GUIDs or overwriting an existing file.
    $labKit = Join-Path $work 'kit-lab'
    New-Item -ItemType Directory -Path (Join-Path $labKit 'scripts') -Force | Out-Null
    Copy-Item (Join-Path $repoRoot 'scripts/Initialize-Settings.ps1') (Join-Path $labKit 'scripts')
    $labSettingsScript = Join-Path $labKit 'scripts/Initialize-Settings.ps1'
    $datacenterCredsPath = Join-Path $labKit ".local/$guidB/datacenter.json"

    $run = Invoke-Child -Variables @{ s = $labSettingsScript; a = $guidA; b = $guidB; c = $guidC } -Script "$stub`n& `$s -TenantId `$a -SubscriptionId `$b -SharedSubscriptionId `$c -MemberIndex 25 -Location swedencentral -Suffix ab12cd -WriteLabCredentials"
    Assert-True ($run.ExitCode -eq 0) "-WriteLabCredentials failed: $($run.Output)"
    Assert-True (Test-Path $datacenterCredsPath) 'datacenter.json should be created when -WriteLabCredentials is passed.'
    $creds = Get-Content $datacenterCredsPath -Raw | ConvertFrom-Json
    Assert-True ($creds.adminUsername -eq 'labadmin' -and $creds.adminPassword -eq 'FactoryLab-2026-Pw' -and $creds.sqlAppLogin -eq 'contosoapp' -and $creds.sqlAppPassword -eq 'FactoryLab-2026-Pw') 'datacenter.json should hold the documented lab credentials.'
    Assert-True ($run.Output -notmatch '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}') "-WriteLabCredentials console output must not contain any GUID: $($run.Output)"
    $passed++

    Set-Content -Path $datacenterCredsPath -Value '{"adminUsername":"labadmin","adminPassword":"CustomKeep-Pw1","sqlAppLogin":"contosoapp","sqlAppPassword":"CustomKeep-Pw1"}' -Encoding utf8NoBOM
    $run = Invoke-Child -Variables @{ s = $labSettingsScript } -Script "$stub`n& `$s -WriteLabCredentials"
    Assert-True ($run.ExitCode -eq 0) "Re-running -WriteLabCredentials failed: $($run.Output)"
    $credsAfter = Get-Content $datacenterCredsPath -Raw | ConvertFrom-Json
    Assert-True ($credsAfter.sqlAppPassword -eq 'CustomKeep-Pw1') 'Existing datacenter.json must not be overwritten.'
    $passed++

    # Get-PipelineEvidence -MemberIndex 35 filters server-side (?per_page=100&name=...) and downloads exact --name even past 30 artifacts.
    $evidenceKit = Join-Path $work 'kit-evidence'
    New-Item -ItemType Directory -Path (Join-Path $evidenceKit 'scripts') -Force | Out-Null
    Copy-Item (Join-Path $repoRoot 'scripts/Get-PipelineEvidence.ps1') (Join-Path $evidenceKit 'scripts')
    $evidenceScript = Join-Path $evidenceKit 'scripts/Get-PipelineEvidence.ps1'
    $ghLog = Join-Path $evidenceKit 'gh-calls.log'
    $ghEvidenceStub = @'
function global:gh {
    $global:LASTEXITCODE = 0
    $joined = $args -join ' '
    Add-Content -Path $logFile -Value $joined
    if ($args[0] -eq 'run' -and $args[1] -eq 'list') {
        return '[{"databaseId":777}]'
    }
    if ($args[0] -eq 'api' -and $joined -like '*runs/777/artifacts*') {
        # Unfiltered call returns only the first 30 artifacts (simulating GitHub default page size of 30).
        if ($args[1] -eq 'repos/contoso/factory-lead/actions/runs/777/artifacts?per_page=100&name=readiness-test-datacenter-member-35') {
            return 'readiness-test-datacenter-member-35'
        }
        return ((1..30 | ForEach-Object { "readiness-test-datacenter-member-$_" }) -join "`n")
    }
    if ($args[0] -eq 'run' -and $args[1] -eq 'download') {
        $dirIdx = [Array]::IndexOf($args, '--dir')
        $targetDir = $args[$dirIdx + 1]
        $nameIdx = [Array]::IndexOf($args, '--name')
        if ($nameIdx -lt 0) {
            $global:LASTEXITCODE = 1
            return 'Expected --name for targeted member download'
        }
        $artName = $args[$nameIdx + 1]
        $artFolder = Join-Path $targetDir $artName
        New-Item -ItemType Directory -Force -Path $artFolder | Out-Null
        Set-Content -Path (Join-Path $artFolder 'test-datacenter.txt') -Value "PASS evidence for $artName"
        return ''
    }
    $global:LASTEXITCODE = 1
    return "Unexpected gh call: $joined"
}
'@
    $run = Invoke-Child -Variables @{ e = $evidenceScript; logFile = $ghLog } -Script "$ghEvidenceStub`n& `$e -Repository 'contoso/factory-lead' -MemberIndex 35"
    Assert-True ($run.ExitCode -eq 0) "Get-PipelineEvidence -MemberIndex 35 failed: $($run.Output)"
    $savedEvidence = Get-Content (Join-Path $evidenceKit 'evidence/readiness/test-datacenter.txt') -Raw
    Assert-True ($savedEvidence -match 'readiness-test-datacenter-member-35') "Expected member 35 evidence, got: $savedEvidence"
    $loggedCalls = Get-Content $ghLog -Raw
    Assert-True ($loggedCalls -match '\?per_page=100&name=readiness-test-datacenter-member-35') "Expected server-side artifact name filter in gh api call: $loggedCalls"
    Assert-True ($loggedCalls -match 'run download 777 --repo contoso/factory-lead --name readiness-test-datacenter-member-35') "Expected exact --name download in gh run download: $loggedCalls"
    $passed++

    # With a signed-in az account, the script shows the subscription name and tenant before it writes.
    $azStub = @'
function global:az {
    $global:LASTEXITCODE = 0
    $command = $args -join ' '
    if ($command -like 'account show*') { return '{"id":"22222222-2222-2222-2222-222222222222","tenantId":"11111111-1111-1111-1111-111111111111","name":"Contoso Test Subscription"}' }
    $global:LASTEXITCODE = 1
}
'@
    $run = Invoke-Child -Variables @{ s = $settingsScript; a = $guidA; b = $guidB } -Script "$azStub`n& `$s -TenantId `$a -SubscriptionId `$b -MemberIndex 3 -Location swedencentral"
    Assert-True ($run.ExitCode -eq 0) "Settings with a signed-in account failed: $($run.Output)"
    Assert-True ($run.Output -match 'Subscription: Contoso Test Subscription' -and $run.Output -match 'Tenant:') 'The script should show the subscription name and tenant it saves.'
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

    # Deploy-Vending SNAT array handling: 0, 1 (singleton!), 516 (member 21 skips parent afwp-hub update), and 518 (member 256 appends 2 prefixes cleanly).
    $snatCases = @(
        @{ Name = 'zero-existing'; MemberIndex = 21; InitialCount = 0; ExpectPolicyDeploy = $true; ExpectedFinalCount = 2 }
        @{ Name = 'singleton-existing'; MemberIndex = 21; InitialCount = 1; ExpectPolicyDeploy = $true; ExpectedFinalCount = 3 }
        @{ Name = 'prepopulated-516-member21'; MemberIndex = 21; InitialCount = 516; ExpectPolicyDeploy = $false; ExpectedFinalCount = 0 }
        @{ Name = 'prepopulated-516-member256'; MemberIndex = 256; InitialCount = 516; ExpectPolicyDeploy = $true; ExpectedFinalCount = 518 }
    )
    foreach ($sc in $snatCases) {
        $snatCapture = Join-Path $work "snat-$($sc.Name).json"
        $snatLog = Join-Path $work "snat-$($sc.Name).log"
        Set-Content -Path $snatLog -Value '' -NoNewline
        $snatRunScript = @'
$hubSub = '22222222-2222-2222-2222-222222222222'
$initialRanges = if ([int]$initCount -eq 0) {
    @()
} elseif ([int]$initCount -eq 1) {
    @('10.10.0.0/16')
} else {
    @('10.10.0.0/16','10.128.0.0/10','10.100.0.0/16','172.16.0.0/12','192.168.0.0/16','100.64.0.0/10') +
    @(1..255 | ForEach-Object { "10.20.$_.0/26" }) +
    @(1..255 | ForEach-Object { "10.20.$_.128/25" })
}
$policyJson = @{ properties = @{ snat = @{ privateRanges = @($initialRanges) } } } | ConvertTo-Json -Depth 6 -Compress
function global:az {
    $global:LASTEXITCODE = 0
    $command = $args -join ' '
    Add-Content -Path $logFile -Value $command
    if ($command -like 'account show*') { return '{"tenantId":"tenant-1","user":{"type":"user"}}' }
    if ($command -like 'ad signed-in-user show*') { return '{"id":"user-1"}' }
    if ($command -like 'role assignment list*') { return '[{"roleDefinitionName":"Owner"}]' }
    if ($command -like 'network vnet show*vnet-hub*') { return "{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub`",`"location`":`"swedencentral`"}" }
    if ($command -like 'resource show*afw-hub*') { return "{`"properties`":{`"ipConfigurations`":[{`"properties`":{`"privateIPAddress`":`"10.100.0.4`"}}],`"firewallPolicy`":{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-hub/providers/Microsoft.Network/firewallPolicies/afwp-hub`"}}}" }
    if ($command -like 'resource show*afwp-hub*') { return $policyJson }
    if ($command -like 'resource show*log-management*') { return "{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-management/providers/Microsoft.OperationalInsights/workspaces/log-management`"}" }
    if ($command -like 'identity show*') { return '{"id":"identity-1"}' }
    if ($command -like 'group show*') { return "{`"id`":`"/subscriptions/$hubSub/resourceGroups/rg-hub`"}" }
    if ($command -like 'deployment group create*vending-afwp-snat-*') {
        $pIdx = [Array]::IndexOf($args, '--parameters')
        $pFile = $args[$pIdx + 1].TrimStart('@')
        Copy-Item -LiteralPath $pFile -Destination $capFile -Force
        return '{"properties":{"provisioningState":"Succeeded"}}'
    }
    if ($command -like 'deployment mg create*') { return '{"properties":{"provisioningState":"Succeeded"}}' }
    if ($command -like 'policy state trigger-scan*') { return '{}' }
    $global:LASTEXITCODE = 1
    return 'not found'
}
& $v -WorkloadSubscriptionId '11111111-1111-1111-1111-111111111111' -SharedSubscriptionId $hubSub -MemberIndex ([int]$mIdx) -BudgetEmail 'lead@example.test' -Confirm:$false *>&1
'@
        $run = Invoke-Child -Variables @{
            v         = $vendingScript
            initCount = [string]$sc.InitialCount
            mIdx      = [string]$sc.MemberIndex
            capFile   = $snatCapture
            logFile   = $snatLog
        } -Script $snatRunScript
        Assert-True ($run.ExitCode -eq 0) "SNAT case '$($sc.Name)' failed: $($run.Output)"
        $loggedCmds = @(Get-Content -Path $snatLog)
        $policyDeployIdx = [Array]::FindIndex($loggedCmds, [Predicate[string]]{ param($x) $x -like 'deployment group create*vending-afwp-snat-*' })
        $mgDeployIdx = [Array]::FindIndex($loggedCmds, [Predicate[string]]{ param($x) $x -like 'deployment mg create*' })
        Assert-True ($mgDeployIdx -ge 0) "SNAT case '$($sc.Name)' did not run deployment mg create."
        if ($sc.ExpectPolicyDeploy) {
            Assert-True ($policyDeployIdx -ge 0 -and $policyDeployIdx -lt $mgDeployIdx) "SNAT case '$($sc.Name)' must update afwp-hub BEFORE mg deployment."
            $capturedParams = (Get-Content -Raw -Path $snatCapture | ConvertFrom-Json).parameters.extraSnatPrefixes.value
            Assert-True (@($capturedParams).Count -eq $sc.ExpectedFinalCount) "SNAT case '$($sc.Name)' expected $($sc.ExpectedFinalCount) prefixes, got $(@($capturedParams).Count)."
            Assert-True (@($capturedParams | Where-Object { $_ -match '\s' -or ($_ -split '/').Count -ne 2 }).Count -eq 0) "SNAT case '$($sc.Name)' produced a corrupted/concatenated CIDR string!"
        }
        else {
            Assert-True ($policyDeployIdx -lt 0) "SNAT case '$($sc.Name)' must skip parent afwp-hub update when prefixes are already pre-populated!"
        }
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
