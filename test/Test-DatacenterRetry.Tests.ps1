#Requires -Version 7.4

<#
.SYNOPSIS
Runs regression tests for the in-VM check retry in Test-Datacenter.ps1, never against Azure.
.DESCRIPTION
Loads only Add-Result and Invoke-VmCheck from the script and replaces the Azure CLI wrapper and the retry wait with stubs.
.EXAMPLE
./test/Test-DatacenterRetry.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/Test-Datacenter.ps1'
$passed = 0

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref] $null, [ref] $null)
foreach ($name in 'Add-Result', 'Invoke-VmCheck') {
    $function = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $true) | Select-Object -First 1
    Assert-True ($null -ne $function) "$name was not found in Test-Datacenter.ps1."
    . ([scriptblock]::Create($function.Extent.Text))
}

$script:resourceGroup = 'rg-datacenter'
$script:scriptsDir = $PSScriptRoot
$script:calls = 0
$script:failFirst = 0
$script:sleeps = 0
function Wait-BeforeRetry { $script:sleeps++ }
function Invoke-AzureCli {
    param([string[]] $Arguments)
    $script:calls++
    if ($script:calls -le $script:failFirst) { throw "Azure CLI 'vm run-command invoke' failed (exit 1)." }
    [pscustomobject]@{ value = @([pscustomobject]@{ message = "LABCHECK|PASS|in-VM check|ok" }) }
}

$resetRun = {
    param([int] $FailFirst)
    $script:results = [System.Collections.Generic.List[object]]::new()
    $script:calls = 0
    $script:failFirst = $FailFirst
    $script:sleeps = 0
}

& $resetRun 1
$null = Invoke-VmCheck -Name 'vm-dev01' -Script 'x.ps1' *>&1
Assert-True ($script:calls -eq 2) 'One failure should lead to one more attempt.'
Assert-True ($script:results.Count -eq 1 -and $script:results[0].Status -eq 'PASS') 'A retry that works should record the real result.'
Assert-True ($script:sleeps -eq 1) 'The retry should wait once.'
$passed++

& $resetRun 3
$null = Invoke-VmCheck -Name 'vm-dev01' -Script 'x.ps1' *>&1
Assert-True ($script:calls -eq 3) 'It should stop after three attempts.'
Assert-True ($script:results.Count -eq 1 -and $script:results[0].Status -eq 'FAIL') 'Three failures should record one FAIL.'
Assert-True ($script:results[0].Detail -match 'run-command invoke') 'The FAIL should keep the CLI error.'
$passed++

& $resetRun 3
$null = Invoke-VmCheck -Name 'vm-app01' -Script 'x.ps1' *>&1
Assert-True ($script:results[0].Detail -match 'Arc-enabled') 'The Arc hint should stay for vm-app01.'
$passed++

& $resetRun 0
$null = Invoke-VmCheck -Name 'vm-dev01' -Script 'x.ps1' *>&1
Assert-True ($script:calls -eq 1 -and $script:sleeps -eq 0) 'A first-try success should not retry or wait.'
$passed++

Write-Output "PASS: $passed Test-Datacenter retry checks (nothing was run against Azure)."
