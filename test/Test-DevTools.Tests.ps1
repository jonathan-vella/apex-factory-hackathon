#Requires -Version 7.4

<#
.SYNOPSIS
Tests infra/datacenter/scripts/Install-DevTools.ps1 without Azure or network calls: syntax, Windows PowerShell 5.1 compatibility and GitHub release asset patterns.
.DESCRIPTION
Install-DevTools.ps1 runs on vm-dev01 as SYSTEM under Windows PowerShell 5.1. This test parses its AST, verifies Windows
PowerShell 5.1 compatibility, and checks its GitHub release asset patterns against representative release asset lists
(including PowerShell 7.7+, which ships zip and msixbundle assets without an MSI).
.EXAMPLE
./test/Test-DevTools.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$scriptPath = Join-Path $repoRoot 'infra/datacenter/scripts/Install-DevTools.ps1'
$passed = 0

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
    $script:passed++
}

$tokens = $null; $parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref] $tokens, [ref] $parseErrors)
Assert-True ($parseErrors.Count -eq 0) "Install-DevTools.ps1 has parse errors: $($parseErrors -join '; ')"

# Install-DevTools.ps1 runs before PowerShell 7 is installed, so Windows PowerShell 5.1 must parse it cleanly.
$windowsPowerShell = Get-Command powershell.exe -ErrorAction SilentlyContinue
if ($IsWindows -and $windowsPowerShell) {
    $command = '$e = $null; $t = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($args[0], [ref]$t, [ref]$e); if ($e.Count) { $e | ForEach-Object { $_.Message }; exit 1 }'
    $output = & $windowsPowerShell.Source -NoProfile -NonInteractive -Command "& { $command } '$scriptPath'" 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "Windows PowerShell 5.1 can't parse Install-DevTools.ps1: $output"
}

$sevenOnly = $ast.FindAll({
        param($n)
        $n -is [System.Management.Automation.Language.TernaryExpressionAst] -or
        $n -is [System.Management.Automation.Language.PipelineChainAst] -or
        ($n -is [System.Management.Automation.Language.ForEachStatementAst] -and $n.Parallel)
    }, $true)
Assert-True ($sevenOnly.Count -eq 0) 'Install-DevTools.ps1 uses syntax that Windows PowerShell 5.1 does not have.'
$sevenTokens = @($tokens | Where-Object { $_.Kind -in 'QuestionQuestion', 'QuestionQuestionEquals', 'QuestionDot', 'QuestionLBracket' })
Assert-True ($sevenTokens.Count -eq 0) 'Install-DevTools.ps1 uses ?? or ?. operators, which Windows PowerShell 5.1 does not have.'

$calls = @{}
$commandAsts = $ast.FindAll({
        param($n)
        $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Get-GitHubAssetUrl'
    }, $true)
foreach ($cmd in $commandAsts) {
    $elements = $cmd.CommandElements
    $repo = $null; $pattern = $null
    for ($i = 1; $i -lt $elements.Count - 1; $i++) {
        if ($elements[$i].Extent.Text -eq '-Repository') { $repo = $elements[$i + 1].Value }
        if ($elements[$i].Extent.Text -eq '-Pattern') { $pattern = $elements[$i + 1].Value }
    }
    if ($repo) { $calls[$repo] = $pattern }
}

Assert-True ($calls.Count -eq 3) "Expected 3 Get-GitHubAssetUrl calls, found $($calls.Count)."

# PowerShell 7.7+ ships zip and msixbundle assets without any MSI installer.
$ps77Assets = @(
    'hashes.sha256',
    'PowerShell-7.7.0-win-arm64.zip',
    'PowerShell-7.7.0-win-fxdependent.zip',
    'PowerShell-7.7.0-win-fxdependentWinDesktop.zip',
    'PowerShell-7.7.0-win-x64.zip',
    'PowerShell-7.7.0-win-x86.zip',
    'PowerShell-7.7.0.msixbundle'
)
$psPattern = $calls['PowerShell/PowerShell']
Assert-True (-not [string]::IsNullOrWhiteSpace($psPattern)) 'Missing Get-GitHubAssetUrl call for PowerShell/PowerShell.'
$psMatched = @($ps77Assets | Where-Object { $_ -match $psPattern })
Assert-True ($psMatched.Count -eq 1 -and $psMatched[0] -eq 'PowerShell-7.7.0-win-x64.zip') "PowerShell pattern '$psPattern' did not uniquely match PowerShell-7.7.0-win-x64.zip in a 7.7 release."

$gitAssets = @('Git-2.56.1-64-bit.exe', 'Git-2.56.1-arm64.exe', 'PortableGit-2.56.1-64-bit.7z.exe')
$gitMatched = @($gitAssets | Where-Object { $_ -match $calls['git-for-windows/git'] })
Assert-True ($gitMatched.Count -eq 1 -and $gitMatched[0] -eq 'Git-2.56.1-64-bit.exe') 'Git pattern did not uniquely match Git-2.56.1-64-bit.exe.'

$ghAssets = @('gh_2.104.0_checksums.txt', 'gh_2.104.0_windows_amd64.msi', 'gh_2.104.0_windows_arm64.msi', 'gh_2.104.0_windows_amd64.zip')
$ghMatched = @($ghAssets | Where-Object { $_ -match $calls['cli/cli'] })
Assert-True ($ghMatched.Count -eq 1 -and $ghMatched[0] -eq 'gh_2.104.0_windows_amd64.msi') 'GitHub CLI pattern did not uniquely match gh_2.104.0_windows_amd64.msi.'

$text = Get-Content -Raw $scriptPath
Assert-True ($text -match 'Add-MachinePath -Directory \$pwshDir') 'Install-DevTools.ps1 must add $pwshDir to the machine PATH.'
Assert-True ($text -match 'Add-MachinePath -Directory \$nodeDir') 'Install-DevTools.ps1 must add $nodeDir to the machine PATH.'
Assert-True ($text -match 'Add-MachinePath -Directory \$azdDir') 'Install-DevTools.ps1 must add $azdDir to the machine PATH.'
Assert-True ($text -match 'nodejs\.org/dist/index\.json') 'Install-DevTools.ps1 must resolve Node.js 24 LTS from nodejs.org.'
Assert-True ($text -match 'aka\.ms/azd-windows-amd64\.msi') 'Install-DevTools.ps1 must install Azure Developer CLI (azd).'
Assert-True ($text -match 'ExtractToDirectory') 'Install-DevTools.ps1 must extract the PowerShell zip archive.'
Assert-True ($text -match 'PowerShell 7 \(x64\)\.lnk') 'Install-DevTools.ps1 must create the PowerShell 7 Start Menu shortcut.'

$testDevVmPath = Join-Path $repoRoot 'infra/datacenter/scripts/Test-DevVm.ps1'
$testDevVmText = Get-Content -Raw $testDevVmPath
Assert-True ($testDevVmText -match "Test-Tool -Name 'node'") 'Test-DevVm.ps1 must check that node is installed.'
Assert-True ($testDevVmText -match "Test-Tool -Name 'azd'") 'Test-DevVm.ps1 must check that azd is installed.'

Write-Output "PASS: $passed Install-DevTools checks (no Azure or network calls)."
exit 0
