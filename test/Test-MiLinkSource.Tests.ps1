#Requires -Version 7.4

<#
.SYNOPSIS
Tests infra/datacenter/scripts/Prepare-MiLinkSource.ps1 without running it: syntax, Windows PowerShell 5.1 compatibility, the subnet check and the help. Never touches Azure or a SQL Server.
.DESCRIPTION
The script changes a SQL Server and Windows Firewall, so it only runs on vm-app01, in a Bastion session. These checks cover what can be tested anywhere:
it parses in PowerShell 7 and (on Windows) in Windows PowerShell 5.1, it uses no PowerShell 7-only syntax, it asks for an elevated session,
it accepts only 10.20.<n>.128/26 with n from 1 to 20, it has comment-based help, and it logs to C:\LabTools\logs. It also checks that the datacenter's
run-command registrations don't mention it and that the C7 page downloads it from the right path.
.EXAMPLE
./test/Test-MiLinkSource.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$scriptPath = Join-Path $repoRoot 'infra/datacenter/scripts/Prepare-MiLinkSource.ps1'
$passed = 0

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
    $script:passed++
}

$tokens = $null; $parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref] $tokens, [ref] $parseErrors)
Assert-True ($parseErrors.Count -eq 0) "Prepare-MiLinkSource.ps1 has parse errors: $($parseErrors -join '; ')"

# vm-app01 has Windows PowerShell 5.1 only for this script, so it must parse there too.
$windowsPowerShell = Get-Command powershell.exe -ErrorAction SilentlyContinue
if ($IsWindows -and $windowsPowerShell) {
    $command = '$e = $null; $t = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($args[0], [ref]$t, [ref]$e); if ($e.Count) { $e | ForEach-Object { $_.Message }; exit 1 }'
    $output = & $windowsPowerShell.Source -NoProfile -NonInteractive -Command "& { $command } '$scriptPath'" 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "Windows PowerShell 5.1 can't parse the script: $output"
}

$sevenOnly = $ast.FindAll({
        param($n)
        $n -is [System.Management.Automation.Language.TernaryExpressionAst] -or
        $n -is [System.Management.Automation.Language.PipelineChainAst] -or
        $n -is [System.Management.Automation.Language.ForEachStatementAst] -and $n.Parallel
    }, $true)
Assert-True ($sevenOnly.Count -eq 0) 'The script uses syntax that Windows PowerShell 5.1 does not have.'
$sevenTokens = @($tokens | Where-Object { $_.Kind -in 'QuestionQuestion', 'QuestionQuestionEquals', 'QuestionDot', 'QuestionLBracket' })
Assert-True ($sevenTokens.Count -eq 0) 'The script uses ?? or ?. operators, which Windows PowerShell 5.1 does not have.'

Assert-True ($ast.ScriptRequirements.IsElevationRequired) 'The script must require an elevated session (#Requires -RunAsAdministrator).'
Assert-True ($ast.ScriptRequirements.RequiredPSVersion -eq [version] '5.1') 'The script must require Windows PowerShell 5.1.'

$parameter = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'MiSubnetPrefix' }
Assert-True ($null -ne $parameter) 'The script has no MiSubnetPrefix parameter.'
$mandatory = $parameter.Attributes | Where-Object { $_.TypeName.Name -eq 'Parameter' } | ForEach-Object { $_.NamedArguments } | Where-Object { $_.ArgumentName -eq 'Mandatory' }
Assert-True ($null -ne $mandatory) 'MiSubnetPrefix must be mandatory.'
$validate = $parameter.Attributes | Where-Object { $_.TypeName.Name -eq 'ValidateScript' }
Assert-True ($null -ne $validate) 'MiSubnetPrefix must validate its value.'
$validator = $validate.PositionalArguments[0].ScriptBlock.GetScriptBlock()

foreach ($good in '10.20.1.128/26', '10.20.3.128/26', '10.20.9.128/26', '10.20.10.128/26', '10.20.19.128/26', '10.20.20.128/26') {
    $result = $validator.InvokeWithContext($null, @(New-Object psvariable '_', $good))
    Assert-True ($true -eq $result[0]) "$good should be accepted."
}
foreach ($bad in '10.20.0.128/26', '10.20.21.128/26', '10.20.3.0/24', '10.20.3.128/25', '10.10.3.128/26', '10.20.3.128', '10.20.03.128/26', '10.20.3.128/26 ', '', 'any') {
    $rejected = $false
    try { $null = $bad | ForEach-Object $validator } catch { $rejected = $true }
    Assert-True $rejected "'$bad' should be rejected."
}

$help = $ast.GetHelpContent()
Assert-True (-not [string]::IsNullOrWhiteSpace($help.Synopsis)) 'The script has no .SYNOPSIS.'
Assert-True (-not [string]::IsNullOrWhiteSpace($help.Description)) 'The script has no .DESCRIPTION.'
Assert-True ($help.Parameters.ContainsKey('MISUBNETPREFIX')) 'The help has no .PARAMETER MiSubnetPrefix.'
Assert-True ($help.Examples.Count -ge 1) 'The help has no .EXAMPLE.'

$text = Get-Content -Raw $scriptPath
Assert-True ($text.Contains("'C:\LabTools\logs'")) 'The script must log to C:\LabTools\logs.'
Assert-True ($text -match 'Get-NetFirewallRule -DisplayName' -and $text -match 'sys\.symmetric_keys' -and $text -match 'sys\.certificates') 'The script must check before it creates the rule, the master key and the certificates, so a second run changes nothing.'
Assert-True ($text -notmatch 'Invoke-AzRestMethod|Connect-AzAccount|\baz\s+(login|account|resource)') 'The script must not call Azure.'

# The datacenter's run-command registrations must not pick this script up: it runs by hand, in a Bastion session.
$registrations = Get-ChildItem (Join-Path $repoRoot 'infra/datacenter') -Recurse -Include '*.bicep', '*.bicepparam' | Select-String -SimpleMatch 'Prepare-MiLinkSource'
Assert-True ($null -eq $registrations) 'The datacenter run-command registrations must not mention Prepare-MiLinkSource.ps1.'

$page = Get-Content -Raw (Join-Path $repoRoot 'site/src/content/docs/challenges/c07-migrate-and-go-live.md')
Assert-True ($page.Contains('raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/infra/datacenter/scripts/Prepare-MiLinkSource.ps1')) 'C7 must download the script from its raw URL on main.'
Assert-True ($page -match '-MiSubnetPrefix 10\.20\.') 'C7 must show the -MiSubnetPrefix command.'

Write-Output "PASS: $passed MI link source script checks (nothing was run against Azure or SQL Server)."
exit 0
