#Requires -Version 7.4

<#
.SYNOPSIS
Downloads the C0 evidence that your member pipeline kept, into factory/evidence/c00/.
.DESCRIPTION
The member stage of platform.yml runs Test-Datacenter.ps1 before Arc onboarding and keeps its output as a run artifact.
This script finds the latest successful platform run in your repo that has that artifact, downloads it and saves it as
evidence/c00/test-datacenter.txt next to the kit's scripts (factory/evidence/c00/ in your repo). It also writes
.local/<subscription-id>/datacenter.json with the documented fixed lab credentials, unless that file exists, because the runner
deployed the datacenter and the later challenges read the passwords from that file. It prints nothing that identifies your
subscription. Commit the evidence file yourself, with a conventional message, as C1 explains.
.PARAMETER Repository
owner/name of your repo. Defaults to the git remote.
.PARAMETER RunId
A specific run to take the evidence from. Defaults to the latest successful run that has it.
.PARAMETER OutDirectory
Where to save it. Defaults to evidence/c00 next to the scripts folder.
.EXAMPLE
./scripts/Get-PipelineEvidence.ps1
#>

[CmdletBinding()]
param(
    [ValidatePattern('^$|^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $Repository = '',
    [long] $RunId = 0,
    [string] $OutDirectory = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'evidence', 'c00')
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$artifactPattern = 'c00-test-datacenter-member-*'

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

$candidates = if ($RunId -gt 0) { @($RunId) } else {
    @((Invoke-GitHubCli @('run', 'list', '--repo', $Repository, '--workflow', 'platform.yml', '--status', 'success', '--limit', '20', '--json', 'databaseId') | ConvertFrom-Json) | ForEach-Object { $_.databaseId })
}
$found = $null
foreach ($candidate in $candidates) {
    $names = @((Invoke-GitHubCli @('api', "repos/$Repository/actions/runs/$candidate/artifacts", '--jq', '.artifacts[].name')) -split "`n" | Where-Object { $_ -like $artifactPattern })
    if ($names.Count -gt 0) { $found = $candidate; break }
}
if (-not $found) { throw "No successful platform run in $Repository has the C0 evidence yet. Run: gh workflow run platform.yml --repo $Repository -f stage=member" }

$temp = Join-Path ([System.IO.Path]::GetTempPath()) "c00-evidence-$([guid]::NewGuid())"
try {
    $null = Invoke-GitHubCli @('run', 'download', "$found", '--repo', $Repository, '--pattern', $artifactPattern, '--dir', $temp)
    $file = Get-ChildItem -Path $temp -Recurse -Filter 'test-datacenter.txt' | Select-Object -First 1
    if (-not $file) { throw 'The artifact has no test-datacenter.txt.' }
    New-Item -ItemType Directory -Force -Path $OutDirectory | Out-Null
    $target = Join-Path $OutDirectory 'test-datacenter.txt'
    Copy-Item -Path $file.FullName -Destination $target -Force
}
finally {
    Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Information "Saved the Test-Datacenter output from run $found to $target."

# The runner deployed the datacenter, so the credentials file Deploy-Datacenter.ps1 writes never reached this folder. The
# Actions member stage always uses the documented fixed lab credentials (no overrides), so write the same file here: later
# challenges (C0 task 7, C7 to C9) read the passwords from it.
$settingsFile = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', 'settings.json'
if (Test-Path -Path $settingsFile) {
    $subscription = (Get-Content -Path $settingsFile -Raw | ConvertFrom-Json).subscriptionId
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
Write-Information 'Commit it with a conventional message, for example: docs: Add the C0 datacenter test evidence'
