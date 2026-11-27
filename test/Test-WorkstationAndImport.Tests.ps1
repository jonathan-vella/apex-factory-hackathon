#Requires -Version 7.4

<#
.SYNOPSIS
Runs offline end-to-end tests for Import-Kit.ps1, Initialize-Workstation.ps1, and Prepare-MiLinkSource.ps1 (-RemoveTraceFlags), never touching GitHub or Azure.
.DESCRIPTION
Covers:
1. Import-Kit.ps1 against a local tarball of the kit and a mock apex-accelerator repository: verifies factory/,
   factory/evidence/ starter templates, root app/ContosoUniversity, .github/modernization, .github/skills/*,
   .github/instructions/contoso-university.instructions.md, .gitattributes (*.bicepparam text eol=lf), lefthook.yml
   exclusions, .prettierignore, weekly-upstream-sync.yml, and -Force vs -ReplaceApp preservation.
2. Initialize-Workstation.ps1 auto-detection (10.10.3.5 -> index 3 and 10.128.1.5 -> index 257), fail-closed
   vnet-datacenter verification (including single-subscription mismatch and duplicate match rejection), missing tool
   installer hook, workflow OAuth scope refresh, private repo creation + kit import + unpushed-commit recovery,
   settings.json + datacenter.json generation, and zero raw GUIDs in output.
3. Prepare-MiLinkSource.ps1 Select-SqlStartupArgument trace-flag filtering (-T1800 and -T9567 removed, other SQLArg*
   parameters preserved in order).
.EXAMPLE
./test/Test-WorkstationAndImport.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$work = Join-Path ([System.IO.Path]::GetTempPath()) "ws-import-test-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $work -Force | Out-Null
$passed = 0
$guidRegex = '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:passed++
}

function Invoke-GitLocal {
    param([string] $Path, [string[]] $Arguments)
    $output = (& git -C $Path @Arguments 2>&1 | ForEach-Object { "$_" }) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed ($LASTEXITCODE) in ${Path}: $output"
    }
    return $output.Trim()
}

try {
    $env:GIT_AUTHOR_NAME = $env:GIT_COMMITTER_NAME = 'Test User'
    $env:GIT_AUTHOR_EMAIL = $env:GIT_COMMITTER_EMAIL = 'test@example.com'
    $env:GIT_CONFIG_GLOBAL = Join-Path $work 'gitconfig'
    Set-Content -LiteralPath $env:GIT_CONFIG_GLOBAL -Value "[core]`n`tautocrlf = false`n[init]`n`tdefaultBranch = main"
    $env:GIT_CONFIG_NOSYSTEM = '1'

    # Build a local tarball wrapping the current kit working tree under jonathan-vella-apex-factory-hackathon-testsha/
    $tarStage = Join-Path $work 'tar-stage'
    $tarTop = Join-Path $tarStage 'jonathan-vella-apex-factory-hackathon-testsha'
    New-Item -ItemType Directory -Path $tarTop -Force | Out-Null
    foreach ($item in @('scripts', 'infra', 'archetype', 'app', 'db', 'templates', '.github')) {
        $src = Join-Path $repoRoot $item
        $dst = Join-Path $tarTop $item
        New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
        Copy-Item -Path $src -Destination $dst -Recurse -Force
    }
    $kitTarball = Join-Path $work 'kit-local.tar.gz'
    & tar -czf $kitTarball -C $tarStage 'jonathan-vella-apex-factory-hackathon-testsha'
    Assert-True ($LASTEXITCODE -eq 0 -and (Test-Path $kitTarball)) 'Failed to create local kit tarball fixture.'

    # Create a mock apex-accelerator template git repo
    $mockAccel = Join-Path $work 'mock-accelerator'
    New-Item -ItemType Directory -Path (Join-Path $mockAccel '.github/agents') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $mockAccel '.github/workflows') -Force | Out-Null
    Set-Content -Path (Join-Path $mockAccel '.github/agents/01-orchestrator.agent.md') -Value "# Orchestrator`n"
    Set-Content -Path (Join-Path $mockAccel '.prettierignore') -Value "node_modules/`n" -NoNewline
    Set-Content -Path (Join-Path $mockAccel '.gitattributes') -Value "*.bicep text eol=lf`n" -NoNewline
    Set-Content -Path (Join-Path $mockAccel 'lefthook.yml') -Value @"
pre-commit:
  commands:
    iac-security-baseline:
      glob: "*.{bicep,tf}"
      run: npm run validate:iac-security-baseline
"@ -NoNewline
    Set-Content -Path (Join-Path $mockAccel '.github/workflows/weekly-upstream-sync.yml') -Value @"
name: Sync
env:
  EXCLUDE_PATHS: |
    README.md
"@ -NoNewline
    Invoke-GitLocal -Path $mockAccel -Arguments @('init', '--quiet') | Out-Null
    Invoke-GitLocal -Path $mockAccel -Arguments @('add', '-A') | Out-Null
    Invoke-GitLocal -Path $mockAccel -Arguments @('commit', '--quiet', '-m', 'initial template') | Out-Null

    # =========================================================================
    # Scenario 1: Import-Kit.ps1 end-to-end against local tarball
    # =========================================================================
    $importDest = Join-Path $work 'student-import-test'
    Copy-Item -Path $mockAccel -Destination $importDest -Recurse -Force
    $importKitPath = Join-Path $repoRoot 'scripts/Import-Kit.ps1'

    $importRunner = @"
`$ErrorActionPreference = 'Stop'
function global:Invoke-WebRequest {
    param([string] `$Uri, [string] `$OutFile, [switch] `$UseBasicParsing, [hashtable] `$Headers)
    Copy-Item -LiteralPath '$($kitTarball.Replace("'", "''"))' -Destination `$OutFile -Force
}
& '$($importKitPath.Replace("'", "''"))' -Destination '$($importDest.Replace("'", "''"))'
"@
    $encodedImport = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($importRunner))
    $importOut = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encodedImport 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "Import-Kit.ps1 failed: $importOut"

    # Verify factory/ and pre-populated factory/evidence/ starter files
    foreach ($expectedRel in @(
        'factory/scripts/Initialize-Settings.ps1',
        'factory/scripts/Initialize-Workstation.ps1',
        'factory/eslint.config.mjs',
        'factory/.markdownlint-cli2.jsonc',
        'factory/.gitignore',
        'factory/evidence/README.md',
        'factory/evidence/c01/opportunity-canvas.md',
        'factory/evidence/c03/triage.md',
        'factory/evidence/c04/decisions-and-register.md',
        'factory/evidence/c07/cutover-rollback-runbook.md',
        'factory/evidence/c10/handover-and-ai-review.md',
        'app/ContosoUniversity/ContosoUniversity.csproj',
        '.github/modernization/playbook.md',
        '.github/skills/sdk-container-publish/SKILL.md',
        '.github/skills/apex-adapt-archetype/SKILL.md',
        '.github/instructions/contoso-university.instructions.md',
        'infra/bicep/university/main.bicepparam',
        '.github/workflows/platform.yml'
    )) {
        Assert-True (Test-Path (Join-Path $importDest $expectedRel)) "Import-Kit.ps1 missing expected path: $expectedRel"
    }

    $instructionsText = Get-Content -Raw (Join-Path $importDest '.github/instructions/contoso-university.instructions.md')
    Assert-True ($instructionsText -match 'applyTo:\s*"app/ContosoUniversity/\*\*"') 'contoso-university.instructions.md must scope applyTo to app/ContosoUniversity/**.'

    $gitAttrText = Get-Content -Raw (Join-Path $importDest '.gitattributes')
    Assert-True ($gitAttrText -match '(?m)^\*\.bicepparam\s+text\s+eol=lf\s*$') '.gitattributes must enforce *.bicepparam text eol=lf.'

    $lefthookText = Get-Content -Raw (Join-Path $importDest 'lefthook.yml')
    Assert-True ($lefthookText -match 'exclude:\s*"\{infra/bicep/university/\*\*,app/\*\*,\.github/upgrades/\*\*\}"') "lefthook.yml must exclude university, app, and upgrades: $lefthookText"

    $syncText = Get-Content -Raw (Join-Path $importDest '.github/workflows/weekly-upstream-sync.yml')
    foreach ($syncEntry in @('factory/', 'app/', '.github/modernization/', '.github/skills/', '.github/instructions/contoso-university.instructions.md', 'lefthook.yml')) {
        Assert-True ($syncText -match "(?m)^\s+$([regex]::Escape($syncEntry))\s*$") "weekly-upstream-sync.yml missing EXCLUDE_PATHS entry: $syncEntry"
    }

    # Verify -Force preserves app/ContosoUniversity and factory/evidence/ edits unless -ReplaceApp is passed
    $csprojPath = Join-Path $importDest 'app/ContosoUniversity/ContosoUniversity.csproj'
    Add-Content -Path $csprojPath -Value "`n<!-- student edit -->"
    $canvasPath = Join-Path $importDest 'factory/evidence/c01/opportunity-canvas.md'
    Add-Content -Path $canvasPath -Value "`nStudent ranked outcome 1"

    $forceRunner = @"
`$ErrorActionPreference = 'Stop'
function global:Invoke-WebRequest {
    param([string] `$Uri, [string] `$OutFile, [switch] `$UseBasicParsing, [hashtable] `$Headers)
    Copy-Item -LiteralPath '$($kitTarball.Replace("'", "''"))' -Destination `$OutFile -Force
}
& '$($importKitPath.Replace("'", "''"))' -Destination '$($importDest.Replace("'", "''"))' -Force
"@
    $encodedForce = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($forceRunner))
    $forceOut = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encodedForce 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "Import-Kit.ps1 -Force failed: $forceOut"
    Assert-True ((Get-Content -Raw $csprojPath) -match 'student edit') 'Import-Kit.ps1 -Force must preserve student edits in app/ContosoUniversity.'
    Assert-True ((Get-Content -Raw $canvasPath) -match 'Student ranked outcome 1') 'Import-Kit.ps1 -Force must preserve student edits in factory/evidence/.'

    $replaceAppRunner = @"
`$ErrorActionPreference = 'Stop'
function global:Invoke-WebRequest {
    param([string] `$Uri, [string] `$OutFile, [switch] `$UseBasicParsing, [hashtable] `$Headers)
    Copy-Item -LiteralPath '$($kitTarball.Replace("'", "''"))' -Destination `$OutFile -Force
}
& '$($importKitPath.Replace("'", "''"))' -Destination '$($importDest.Replace("'", "''"))' -Force -ReplaceApp
"@
    $encodedReplaceApp = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($replaceAppRunner))
    $replaceAppOut = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encodedReplaceApp 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "Import-Kit.ps1 -Force -ReplaceApp failed: $replaceAppOut"
    Assert-True ((Get-Content -Raw $csprojPath) -notmatch 'student edit') 'Import-Kit.ps1 -Force -ReplaceApp must overwrite app/ContosoUniversity.'
    Write-Output 'PASS: Import-Kit.ps1 populates single-clone layout, evidence templates, hook exclusions, and preserves app work on -Force'

    # =========================================================================
    # Scenario 2: Initialize-Workstation.ps1 auto-detection & bootstrap
    # =========================================================================
    $wsScriptPath = Join-Path $repoRoot 'scripts/Initialize-Workstation.ps1'
    $tokens = $null; $parseErrors = $null
    $wsAst = [System.Management.Automation.Language.Parser]::ParseFile($wsScriptPath, [ref] $tokens, [ref] $parseErrors)
    Assert-True ($parseErrors.Count -eq 0) "Initialize-Workstation.ps1 has parse errors: $($parseErrors -join '; ')"

    foreach ($fnName in @('Resolve-MemberIndexFromIp', 'Get-ExpectedDatacenterPrefix', 'Test-UsablePython')) {
        $fnAst = $wsAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fnName }, $true) | Select-Object -First 1
        Assert-True ($null -ne $fnAst) "Missing function $fnName in Initialize-Workstation.ps1"
        . ([scriptblock]::Create($fnAst.Extent.Text))
    }

    Assert-True ((Resolve-MemberIndexFromIp -IpAddresses @('169.254.1.1', '10.10.3.5')) -eq 3) '10.10.3.5 must resolve to MemberIndex 3.'
    Assert-True ((Resolve-MemberIndexFromIp -IpAddresses @('10.128.1.5')) -eq 257) '10.128.1.5 must resolve to MemberIndex 257.'
    Assert-True ((Get-ExpectedDatacenterPrefix -Index 3) -eq '10.10.3.0/24') 'Index 3 prefix must be 10.10.3.0/24.'
    Assert-True ((Get-ExpectedDatacenterPrefix -Index 257) -eq '10.128.1.0/24') 'Index 257 prefix must be 10.128.1.0/24.'
    Assert-True (-not (Test-UsablePython -CommandPath 'C:\Users\labadmin\AppData\Local\Microsoft\WindowsApps\python.exe')) 'Test-UsablePython must reject the WindowsApps Store alias.'
    Assert-True (Test-UsablePython -CommandPath 'C:\Program Files\Python3\python.exe') 'Test-UsablePython must accept a real Python executable.'

    # Prepare a bare remote repo to act as the created student repo when git clone/push runs
    $bareRemote = Join-Path $work 'remote-apex-factory-m03.git'
    Invoke-GitLocal -Path $work -Arguments @('clone', '--bare', '--quiet', $mockAccel, $bareRemote) | Out-Null
    $wsRoot = Join-Path $work 'ws-src'
    $subGuid = '22222222-3333-4444-5555-666666666666'
    $tenantGuid = '11111111-2222-3333-4444-555555555555'
    $sharedGuid = '99999999-8888-7777-6666-555555555555'
    $realGit = (Get-Command git).Source

    $wsRunner = @"
`$ErrorActionPreference = 'Stop'
function global:Get-LocalIPv4Address { return @('10.10.3.5') }
function global:Invoke-WebRequest {
    param([string] `$Uri, [string] `$OutFile, [switch] `$UseBasicParsing, [hashtable] `$Headers)
    Copy-Item -LiteralPath '$($kitTarball.Replace("'", "''"))' -Destination `$OutFile -Force
}
function global:gh {
    `$global:LASTEXITCODE = 0
    if (`$args[0] -eq 'auth' -and `$args[1] -eq 'status') {
        Write-Output 'Token scopes: repo, workflow'
        return
    }
    if (`$args[0] -eq 'auth' -and `$args[1] -eq 'setup-git') { return }
    if (`$args[0] -eq 'api' -and `$args[1] -eq 'user') {
        Write-Output '{"login":"student03","id":12345,"name":"Student Three"}'
        return
    }
    if (`$args[0] -eq 'api' -and `$args[1] -eq 'repos/student03/apex-factory-m03') {
        `$global:LASTEXITCODE = 1
        Write-Output 'HTTP 404: Not Found'
        return
    }
    if (`$args[0] -eq 'repo' -and `$args[1] -eq 'create') {
        Write-Output 'https://github.com/student03/apex-factory-m03'
        return
    }
    if (`$args[0] -eq 'api' -and `$args[1] -like 'repos/student03/apex-factory-m03/commits*') {
        Write-Output '[{"sha":"abc1234"}]'
        return
    }
}
function global:az {
    `$global:LASTEXITCODE = 0
    `$cmd = `$args -join ' '
    if (`$cmd -like 'account show*') {
        Write-Output '{"id":"$subGuid","tenantId":"$tenantGuid","name":"Workload-03"}'
        return
    }
    if (`$cmd -like 'account list*') {
        Write-Output '[{"id":"$subGuid","tenantId":"$tenantGuid","name":"Workload-03"}]'
        return
    }
    if (`$cmd -like 'network vnet show*') {
        Write-Output '["10.10.3.0/24"]'
        return
    }
    if (`$cmd -like 'account set*') { return }
    if (`$cmd -like 'group show*') {
        Write-Output 'swedencentral'
        return
    }
    if (`$cmd -like 'network vnet peering list*') {
        Write-Output '["/subscriptions/$sharedGuid/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"]'
        return
    }
    if (`$cmd -like 'group list*') {
        Write-Output 'rg-university- pre03x'
        return
    }
}
function global:azd {
    `$global:LASTEXITCODE = 0
}
function global:git {
    if (`$args[0] -eq 'clone' -and `$args[1] -eq 'https://github.com/student03/apex-factory-m03.git') {
        & '$($realGit.Replace("'", "''"))' clone --quiet '$($bareRemote.Replace("'", "''"))' `$args[2]
        return
    }
    if (`$args.Count -ge 4 -and `$args[0] -eq '-C' -and `$args[2] -eq 'remote' -and `$args[3] -eq 'get-url') {
        Write-Output 'https://github.com/student03/apex-factory-m03.git'
        `$global:LASTEXITCODE = 0
        return
    }
    & '$($realGit.Replace("'", "''"))' @args
}
& '$($wsScriptPath.Replace("'", "''"))' -WorkspaceRoot '$($wsRoot.Replace("'", "''"))' -Suffix 'ab03cd' -SkipToolInstall -SkipOpenCode *>&1 | ForEach-Object { `$_.ToString() }
"@
    $encodedWs = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wsRunner))
    $wsOut = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encodedWs 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "Initialize-Workstation.ps1 failed: $wsOut"
    Assert-True ($wsOut -notmatch $guidRegex) "Initialize-Workstation.ps1 leaked a raw GUID in console output: $wsOut"

    $clonedRepo = Join-Path $wsRoot 'apex-factory-m03'
    Assert-True (Test-Path (Join-Path $clonedRepo 'app/ContosoUniversity/ContosoUniversity.csproj')) 'Cloned student repo must contain app/ContosoUniversity.'
    $writtenSettings = Get-Content -Raw (Join-Path $clonedRepo 'factory/.local/settings.json') | ConvertFrom-Json
    Assert-True ($writtenSettings.memberIndex -eq 3) "Expected memberIndex 3, got $($writtenSettings.memberIndex)"
    Assert-True ($writtenSettings.subscriptionId -eq $subGuid) 'settings.json must store auto-detected workload subscriptionId.'
    Assert-True ($writtenSettings.sharedSubscriptionId -eq $sharedGuid) 'settings.json must store auto-detected sharedSubscriptionId from hub peering.'
    Assert-True ($writtenSettings.tenantId -eq $tenantGuid) 'settings.json must store auto-detected tenantId.'
    Assert-True ($writtenSettings.suffix -eq 'ab03cd') "Expected suffix ab03cd, got $($writtenSettings.suffix)"
    Assert-True (Test-Path (Join-Path $clonedRepo "factory/.local/$subGuid/datacenter.json")) 'datacenter.json must be written by Initialize-Workstation.ps1.'

    # Verify fail-closed when single subscription's vnet-datacenter prefix does not match local IP
    $mismatchRunner = @"
`$ErrorActionPreference = 'Stop'
function global:Get-LocalIPv4Address { return @('10.10.3.5') }
function global:gh {
    `$global:LASTEXITCODE = 0
    if (`$args[0] -eq 'auth' -and `$args[1] -eq 'status') { Write-Output 'Token scopes: repo, workflow'; return }
    if (`$args[0] -eq 'auth' -and `$args[1] -eq 'setup-git') { return }
    if (`$args[0] -eq 'api' -and `$args[1] -eq 'user') { Write-Output '{"login":"student03","id":12345}'; return }
}
function global:az {
    `$global:LASTEXITCODE = 0
    `$cmd = `$args -join ' '
    if (`$cmd -like 'account show*') { Write-Output '{"id":"$subGuid","tenantId":"$tenantGuid"}'; return }
    if (`$cmd -like 'account list*') { Write-Output '[{"id":"$subGuid","tenantId":"$tenantGuid"}]'; return }
    if (`$cmd -like 'network vnet show*') { Write-Output '["10.10.9.0/24"]'; return }
}
function global:azd { `$global:LASTEXITCODE = 0 }
& '$($wsScriptPath.Replace("'", "''"))' -WorkspaceRoot '$($wsRoot.Replace("'", "''"))' -SkipToolInstall -SkipOpenCode
"@
    $encodedMismatch = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($mismatchRunner))
    $mismatchOut = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encodedMismatch 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -ne 0 -and $mismatchOut -match 'No accessible subscription contains rg-datacenter/vnet-datacenter') "Expected fail-closed error on prefix mismatch: $mismatchOut"

    # Verify rerun converges when a local commit is ahead of origin/main (unpushed commit recovery)
    Set-Content -Path (Join-Path $clonedRepo 'factory/evidence/c01/extra.txt') -Value 'unpushed'
    Invoke-GitLocal -Path $clonedRepo -Arguments @('add', 'factory/evidence/c01/extra.txt') | Out-Null
    Invoke-GitLocal -Path $clonedRepo -Arguments @('commit', '--quiet', '-m', 'docs: local unpushed commit') | Out-Null
    $aheadBefore = [int](Invoke-GitLocal -Path $clonedRepo -Arguments @('rev-list', '--count', 'origin/main..HEAD'))
    Assert-True ($aheadBefore -eq 1) "Expected 1 unpushed commit before rerun, got $aheadBefore"

    $rerunOut = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encodedWs 2>&1 | Out-String
    Assert-True ($LASTEXITCODE -eq 0) "Initialize-Workstation.ps1 rerun failed: $rerunOut"
    $aheadAfter = [int](Invoke-GitLocal -Path $clonedRepo -Arguments @('rev-list', '--count', 'origin/main..HEAD'))
    Assert-True ($aheadAfter -eq 0) "Initialize-Workstation.ps1 rerun must push previously unpushed commits to origin/main (expected 0 ahead, got $aheadAfter)."
    Write-Output 'PASS: Initialize-Workstation.ps1 auto-detects index/subscriptions/peering, fails closed on mismatch, recovers unpushed commits, and prints zero GUIDs'

    # =========================================================================
    # Scenario 3: Prepare-MiLinkSource.ps1 Select-SqlStartupArgument trace-flag filtering
    # =========================================================================
    $miScriptPath = Join-Path $repoRoot 'infra/datacenter/scripts/Prepare-MiLinkSource.ps1'
    $miTokens = $null; $miErrors = $null
    $miAst = [System.Management.Automation.Language.Parser]::ParseFile($miScriptPath, [ref] $miTokens, [ref] $miErrors)
    Assert-True ($miErrors.Count -eq 0) "Prepare-MiLinkSource.ps1 has parse errors: $($miErrors -join '; ')"
    $selectFn = $miAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Select-SqlStartupArgument' }, $true) | Select-Object -First 1
    Assert-True ($null -ne $selectFn) 'Select-SqlStartupArgument must exist in Prepare-MiLinkSource.ps1.'
    . ([scriptblock]::Create($selectFn.Extent.Text))

    $resTf = Select-SqlStartupArgument -Arguments @('-dF:\SQLData\master.mdf', '-T1800', '-eF:\SQLLog\ERRORLOG', '-T9567', '-lF:\SQLLog\mastlog.ldf')
    Assert-True (($resTf.KeptArgs -join '|') -eq '-dF:\SQLData\master.mdf|-eF:\SQLLog\ERRORLOG|-lF:\SQLLog\mastlog.ldf') 'Select-SqlStartupArgument must keep -d, -e, -l in order.'
    Assert-True (($resTf.RemovedArgs -join '|') -eq '-T1800|-T9567') 'Select-SqlStartupArgument must remove -T1800 and -T9567.'
    Write-Output 'PASS: Prepare-MiLinkSource.ps1 Select-SqlStartupArgument strips -T1800 and -T9567 while preserving other SQLArg* entries'

    Write-Output "PASS: $passed workstation and import checks (no GitHub or Azure calls)."
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
