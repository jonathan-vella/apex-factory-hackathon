#Requires -Version 7.4

<#
.SYNOPSIS
Downloads the readiness evidence that your member pipeline kept, into factory/evidence/readiness/.
.DESCRIPTION
The member stage of platform.yml runs Test-Datacenter.ps1 before Arc onboarding and keeps its output as a run artifact
(readiness-test-datacenter-member-<index>). This script finds the latest successful platform run in your repo that has that
artifact, downloads it and saves it as evidence/readiness/test-datacenter.txt next to the kit's scripts
(factory/evidence/readiness/ in your repo). It also writes
.local/<subscription-id>/datacenter.json with the documented fixed lab credentials, unless that file exists, because the runner
deployed the datacenter and the later challenges read the passwords from that file. It prints nothing that identifies your
subscription. Commit the evidence file yourself to main with a conventional message, as Step 1 explains.
.PARAMETER Repository
owner/name of your repo. Defaults to the git remote.
.PARAMETER RunId
A specific run to take the evidence from. Defaults to the latest successful run that has it.
.PARAMETER MemberIndex
The member index (1 or greater) whose readiness-test-datacenter-member-<index> artifact to download. When 0 (default),
reads memberIndex from .local/settings.json if present, or falls back to readiness-test-datacenter-member-*.
.PARAMETER OutDirectory
Where to save it. Defaults to evidence/readiness next to the scripts folder.
.EXAMPLE
./scripts/Get-PipelineEvidence.ps1
.EXAMPLE
./scripts/Get-PipelineEvidence.ps1 -Repository 'contoso/factory-lead' -MemberIndex 25
#>

[CmdletBinding()]
param(
    [ValidatePattern('^$|^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $Repository = '',
    [long] $RunId = 0,
    [ValidateRange(0, [int]::MaxValue)]
    [int] $MemberIndex = 0,
    [string] $OutDirectory = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'evidence', 'readiness')
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$artifactPattern = 'readiness-test-datacenter-member-*'
$settingsFile = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', 'settings.json'
$settingsObj = if (Test-Path -Path $settingsFile) { Get-Content -Path $settingsFile -Raw | ConvertFrom-Json } else { $null }
if ($MemberIndex -eq 0 -and $null -ne $settingsObj -and $settingsObj.PSObject.Properties['memberIndex']) {
    $parsedIndex = 0
    if ([int]::TryParse("$($settingsObj.memberIndex)", [ref] $parsedIndex) -and $parsedIndex -ge 1) {
        $MemberIndex = $parsedIndex
    }
}

function Invoke-GitHubCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & gh @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "GitHub CLI '$($Arguments | Select-Object -First 2 | Join-String -Separator ' ')' failed. Run gh auth login, and check -Repository." }
    return ($output | ForEach-Object { $_.ToString() }) -join "`n"
}

if (-not $Repository) {
    $remote = (& git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/]([^/]+/[^/.]+?)(\.git)?$') { $Repository = $Matches[1] }
    if (-not $Repository) { throw 'Pass -Repository owner/name.' }
}

$runStatusFilter = if ($MemberIndex -gt 0) { 'completed' } else { 'success' }
$candidates = if ($RunId -gt 0) { @($RunId) } else {
    @((Invoke-GitHubCli @('run', 'list', '--repo', $Repository, '--workflow', 'platform.yml', '--status', $runStatusFilter, '--limit', '100', '--json', 'databaseId') | ConvertFrom-Json) | ForEach-Object { $_.databaseId })
}
$exactArtifact = if ($MemberIndex -gt 0) { "readiness-test-datacenter-member-$MemberIndex" } else { '' }
$found = $null
$savedFromLoop = $false
foreach ($candidate in $candidates) {
    if ($MemberIndex -gt 0) {
        $names = @((Invoke-GitHubCli @('api', "repos/$Repository/actions/runs/$candidate/artifacts?per_page=100&name=$exactArtifact", '--jq', '.artifacts[].name')) -split "`r?`n" | Where-Object { $_ -eq $exactArtifact })
    }
    else {
        $names = @((Invoke-GitHubCli @('api', '--paginate', "repos/$Repository/actions/runs/$candidate/artifacts?per_page=100", '--jq', '.artifacts[].name')) -split "`r?`n" | Where-Object { $_ -like $artifactPattern })
    }
    if ($names.Count -eq 0) { continue }

    $temp = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', ".tmp-evidence-$([guid]::NewGuid().ToString('N'))"
    try {
        if ($MemberIndex -gt 0) {
            $null = Invoke-GitHubCli @('run', 'download', "$candidate", '--repo', $Repository, '--name', $exactArtifact, '--dir', $temp)
        }
        else {
            $null = Invoke-GitHubCli @('run', 'download', "$candidate", '--repo', $Repository, '--pattern', $artifactPattern, '--dir', $temp)
        }
        $file = Get-ChildItem -Path $temp -Recurse -Filter 'test-datacenter.txt' | Select-Object -First 1
        if (-not $file) {
            if ($RunId -gt 0) { throw 'The artifact has no test-datacenter.txt.' }
            continue
        }
        $reportText = Get-Content -Path $file.FullName -Raw
        if ($RunId -eq 0 -and $reportText -match '(?m)^FAIL:\s+\d+\s+of\s+\d+\s+checks\s+failed\.') {
            continue
        }
        New-Item -ItemType Directory -Force -Path $OutDirectory | Out-Null
        $target = Join-Path $OutDirectory 'test-datacenter.txt'
        Copy-Item -Path $file.FullName -Destination $target -Force
        $found = $candidate
        $savedFromLoop = $true
        break
    }
    finally {
        Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
if (-not $found -or -not $savedFromLoop) { throw "No successful platform run in $Repository has the readiness evidence yet. Run: gh workflow run platform.yml --repo $Repository -f stage=member" }
Write-Information "Saved the Test-Datacenter output from run $found to $target."

# The runner deployed the datacenter, so the credentials file Deploy-Datacenter.ps1 writes never reached this folder. The
# Actions member stage always uses the documented fixed lab credentials (no overrides), so write the same file here: later
# challenges (the vm-dev01 setup, C7 to C9) read the passwords from it.
if ($null -ne $settingsObj) {
    $subscription = "$($settingsObj.subscriptionId)"
    if ($subscription -match '^[0-9a-fA-F-]{36}$') {
        $secretsDir = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', $subscription
        $secretsFile = Join-Path -Path $secretsDir -ChildPath 'datacenter.json'
        if (-not (Test-Path -Path $secretsFile)) {
            New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null
            $labPassword = 'FactoryLab-2026-Pw'
            [ordered]@{ adminUsername = 'labadmin'; adminPassword = $labPassword; sqlAppLogin = 'contosoapp'; sqlAppPassword = $labPassword } |
                ConvertTo-Json | Set-Content -Path $secretsFile -Encoding utf8NoBOM
            Write-Information 'Saved the documented lab credentials in .local/<subscription-id>/datacenter.json, as the later challenges expect.'
        }
    }
}
Write-Information 'Commit it with a conventional message, for example: docs: Add the readiness datacenter test evidence'
