#Requires -Version 7.4

<#
.SYNOPSIS
Tests the phases of Invoke-PipelineVending.ps1 with stub scripts and a stub az, never Azure.
.DESCRIPTION
Builds a temporary folder with the script under test, stub versions of the scripts it calls and a fake az on PATH, then
checks that members are vended one after another, that every VM restarts only after the last member is vended and all
restarts overlap, that the exemptions and probes start only after the restarts finish, and that each failure stops
where it should and names the member.
.EXAMPLE
./test/Invoke-PipelineVending.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$script = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Invoke-PipelineVending.ps1'
$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$work = Join-Path ([System.IO.Path]::GetTempPath()) "vending-test-$([guid]::NewGuid())"
$bin = Join-Path $work 'bin'
New-Item -ItemType Directory -Path $bin -Force | Out-Null
Copy-Item $script (Join-Path $work 'Invoke-PipelineVending.ps1')

$stamp = '$([DateTime]::Now.ToString(''HH:mm:ss.fff''))'
Set-Content (Join-Path $work 'Assert-PipelineGuard.ps1') '[CmdletBinding()] param([Parameter(ValueFromRemainingArguments)] $Rest) exit 0'
Set-Content (Join-Path $work 'Deploy-Vending.ps1') @"
[CmdletBinding()] param([string] `$WorkloadSubscriptionId, [string] `$SharedSubscriptionId, [int] `$MemberIndex, [string] `$MgPrefix, [string] `$ParentManagementGroupId, [string] `$Location, [string] `$BudgetEmail, [string] `$MemberPrincipalId)
Set-Content (Join-Path `$env:TEST_LOG ([guid]::NewGuid())) "$stamp vend-start `$MemberIndex"
Start-Sleep -Milliseconds 700
if (`$env:TEST_FAIL -eq "vend-`$MemberIndex") { throw 'vending failed' }
Set-Content (Join-Path `$env:TEST_LOG ([guid]::NewGuid())) "$stamp vend-end `$MemberIndex"
"@
Set-Content (Join-Path $work 'New-DatacenterExemptions.ps1') @"
[CmdletBinding()] param([string] `$SubscriptionId, [string] `$Owner)
Set-Content (Join-Path `$env:TEST_LOG ([guid]::NewGuid())) "$stamp exempt `$SubscriptionId"
Write-Information 'nothing to exempt' -InformationAction Continue
cmd /c exit 1
"@
Set-Content (Join-Path $work 'Test-Connectivity.ps1') @"
[CmdletBinding()] param([string] `$SubscriptionId, [string] `$SharedSubscriptionId, [int] `$MemberIndex)
Set-Content (Join-Path `$env:TEST_LOG ([guid]::NewGuid())) "$stamp probe `$MemberIndex"
Write-Output "PASS-LINE member `$MemberIndex"
if (`$env:TEST_FAIL -eq "probe-`$MemberIndex") { exit 1 }
exit 0
"@
if ($IsWindows) {
    Set-Content (Join-Path $bin 'az.cmd') "@echo off`r`npwsh -NoProfile -File `"%~dp0az-stub.ps1`" %*`r`nexit /b %ERRORLEVEL%`r`n"
}
else {
    $az = Join-Path $bin 'az'
    Set-Content $az "#!/bin/sh`nexec pwsh -NoProfile -File `"`$(dirname `"`$0`")/az-stub.ps1`" `"`$@`"`n"
    chmod +x $az
}
# The fake az is a PowerShell script, so every call logs to its own uniquely named file.
Set-Content (Join-Path $bin 'az-stub.ps1') @'
$stamp = [DateTime]::Now.ToString('HH:mm:ss.fff')
Set-Content (Join-Path $env:TEST_LOG ([guid]::NewGuid())) "$stamp az $($args -join ' ')"
if ("$($args[0]) $($args[1])" -eq 'vm restart') {
    Start-Sleep -Seconds 2
    if (($args -join ' ') -match 'fail-vm') { exit 1 }
}
exit 0
'@

$guid = { param($n) "{0:x8}-0000-0000-0000-000000000000" -f $n }
$roster = (1..3 | ForEach-Object { @{ index = $_; subscriptionId = (& $guid $_); budgetEmail = 'a@b.c'; memberPrincipalId = (& $guid 99) } } | ConvertTo-Json -Compress)

function Invoke-Scenario {
    param([string] $Name, [hashtable] $Environment = @{}, [string[]] $Members = @('1', '2', '3'))
    $log = Join-Path $work "$Name.log"
    New-Item -ItemType Directory -Path $log -Force | Out-Null
    $oldPath = $env:PATH
    $env:PATH = "$bin$([System.IO.Path]::PathSeparator)$oldPath"
    $env:TEST_LOG = $log
    $env:TEST_FAIL = ''
    foreach ($key in $Environment.Keys) { Set-Item "env:$key" $Environment[$key] }
    try {
        $env:TEST_ROSTER = $roster
        $env:TEST_MEMBERS = $Members -join ','
        $env:TEST_SHARED = (& $guid 500)
        $command = "& '$(Join-Path $work 'Invoke-PipelineVending.ps1')' -RosterJson `$env:TEST_ROSTER -MemberIndex (`$env:TEST_MEMBERS -split ',') -SharedSubscriptionId `$env:TEST_SHARED -MgPrefix mg-test; exit `$LASTEXITCODE"
        $output = & $pwsh -NoProfile -NonInteractive -Command $command 2>&1 | Out-String
        [pscustomobject]@{ Exit = $LASTEXITCODE; Output = $output; Log = @(Get-ChildItem $log -File | ForEach-Object { (Get-Content $_.FullName -Raw).Trim() } | Sort-Object { Get-Time $_ }) }
    }
    finally { $env:PATH = $oldPath; $env:TEST_FAIL = '' }
}

function Get-Time { param($Line) [TimeSpan]::Parse(($Line.Trim() -split '\s+')[0].Replace(',', '.')) }
function Assert-True { param([bool] $Condition, [string] $Message) if (-not $Condition) { throw "FAIL: $Message" } }

try {
    $r = Invoke-Scenario -Name healthy
    Assert-True ($r.Exit -eq 0) "healthy run exited $($r.Exit): $($r.Output)"
    $vendLines = @($r.Log | Where-Object { $_ -match 'vend-(start|end)' })
    $expected = 'vend-start 1', 'vend-end 1', 'vend-start 2', 'vend-end 2', 'vend-start 3', 'vend-end 3'
    Assert-True (($vendLines | ForEach-Object { ($_ -split ' ', 2)[1] }) -join '|' -eq ($expected -join '|')) 'members are not vended one after another'
    $lastVendEnd = Get-Time ($r.Log | Where-Object { $_ -match 'vend-end 3' } | Select-Object -First 1)
    $restartStarts = @($r.Log | Where-Object { $_ -match 'vm restart' })
    Assert-True ($restartStarts.Count -eq 6) "expected 6 VM restarts, got $($restartStarts.Count)"
    Assert-True (-not ($restartStarts | Where-Object { (Get-Time $_) -lt $lastVendEnd })) 'a restart started before the last member was vended'
    $spread = ($restartStarts | ForEach-Object { (Get-Time $_).TotalSeconds } | Measure-Object -Maximum -Minimum)
    Assert-True (($spread.Maximum - $spread.Minimum) -lt 1.5) 'the restarts did not start together'
    $firstExempt = Get-Time ($r.Log | Where-Object { $_ -match ' exempt ' } | Select-Object -First 1)
    Assert-True ($firstExempt -gt (($restartStarts | ForEach-Object { Get-Time $_ } | Measure-Object -Maximum).Maximum)) 'the exemptions started before the restarts were done'
    Assert-True (@($r.Log | Where-Object { $_ -match ' probe ' }).Count -eq 3) 'not every member was probed'
    Assert-True ($r.Output -match 'Member 2: vended and connected') 'the summary is missing a member'
    Assert-True ($r.Output -match 'PASS-LINE member 3') 'the probe output was not shown'
    Write-Output 'PASS: serial vending, one parallel restart wave, then parallel probes'

    $r = Invoke-Scenario -Name vend-fails -Environment @{ TEST_FAIL = 'vend-2' }
    Assert-True ($r.Exit -ne 0) 'a vending failure did not fail the stage'
    Assert-True ($r.Output -match 'Vending stopped at member 2') 'the failing member is not named'
    Assert-True (-not ($r.Log | Where-Object { $_ -match 'vm restart| exempt | probe ' })) 'work continued after a vending failure'
    Write-Output 'PASS: a vending failure stops before any restart'

    $r = Invoke-Scenario -Name restart-fails -Environment @{ TEST_FAIL = '' } -Members @('1')
    Assert-True ($r.Exit -eq 0) 'single member run failed'
    Write-Output 'PASS: a single member runs the same phases'

    $oldRoster = $roster
    $roster = (1..3 | ForEach-Object { @{ index = $_; subscriptionId = $(if ($_ -eq 2) { 'fail-vm-0000-0000-0000-000000000000' } else { & $guid $_ }); budgetEmail = 'a@b.c' } } | ConvertTo-Json -Compress)
    $r = Invoke-Scenario -Name restart-fails2
    Assert-True ($r.Exit -ne 0) 'a restart failure did not fail the stage'
    Assert-True ($r.Output -match 'Restarting the VMs failed \(member 2') 'the member with the failed restart is not named'
    Assert-True (-not ($r.Log | Where-Object { $_ -match ' exempt | probe ' })) 'probes ran after a restart failure'
    $roster = $oldRoster
    Write-Output 'PASS: a restart failure names the member and skips the probes'

    $r = Invoke-Scenario -Name probe-fails -Environment @{ TEST_FAIL = 'probe-3' }
    Assert-True ($r.Exit -ne 0) 'a failed probe did not fail the stage'
    Assert-True ($r.Output -match 'failed for member\(s\) 3') 'the failing member is not named'
    Assert-True ($r.Output -match 'Member 1: vended and connected' -and $r.Output -match 'Member 2: vended and connected') 'the passing members are not reported'
    Write-Output 'PASS: a failed probe names its member and still reports the others'
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output 'PASS: 5 vending scenarios (no Azure calls).'
exit 0
