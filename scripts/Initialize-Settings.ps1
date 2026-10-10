#Requires -Version 7.4

<#
.SYNOPSIS
Creates or updates .local/settings.json, the file the other kit scripts read.
.DESCRIPTION
Prompts for the tenant ID, your workload subscription ID, your member index and the location, checks
each value, and writes factory/.local/settings.json (git-ignored). Run it from anywhere inside the
kit folder. If you're signed in with az login, the tenant and subscription default to the current
az account. Re-running keeps the existing values and never changes your suffix. When settings.json
already holds all four core values, passing any parameter, for example -SharedSubscriptionId, updates only
that value without prompting for the others. With no parameters, it prompts for each value and offers the
stored one as the default (press Enter to keep it). The shared services subscription ID can be added in C0,
if you are the platform lead, or when your platform lead shares it, in C2.
.PARAMETER TenantId
The Entra tenant ID.
.PARAMETER SubscriptionId
Your workload subscription ID.
.PARAMETER MemberIndex
Your member number, 1 to 20, assigned by your coach.
.PARAMETER Location
The Azure region. Defaults to swedencentral.
.PARAMETER SharedSubscriptionId
The team's shared services subscription ID. Optional until C2; the platform lead shares it with the team.
.PARAMETER Suffix
Restores your resource-name suffix (4 to 6 lowercase letters or digits) on a machine that has lost
.local/settings.json, for example a deleted Codespace. Use the suffix you were given the first time.
It is refused when settings.json already holds a different suffix: the suffix is never changed.
.EXAMPLE
./scripts/Initialize-Settings.ps1
.EXAMPLE
./scripts/Initialize-Settings.ps1 -SharedSubscriptionId '00000000-0000-0000-0000-000000000000'
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $SubscriptionId,
    [int] $MemberIndex,
    [string] $Location,
    [string] $SharedSubscriptionId,
    [ValidatePattern('^[a-z0-9]{4,6}$')]
    [string] $Suffix
)

$ErrorActionPreference = 'Stop'
$guidPattern = '^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$'
$settingsDir = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local'
$settingsPath = Join-Path $settingsDir 'settings.json'

$current = [ordered]@{}
if (Test-Path $settingsPath) {
    (Get-Content $settingsPath -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $current[$_.Name] = $_.Value }
}

# With every core value already stored, passing any parameter changes only that value and skips the prompts.
$storedCore = @('tenantId', 'subscriptionId', 'memberIndex', 'location')
if (@($storedCore | Where-Object { -not $current[$_] }).Count -eq 0 -and $PSBoundParameters.Count -gt 0) {
    if (-not $TenantId) { $TenantId = [string] $current['tenantId'] }
    if (-not $SubscriptionId) { $SubscriptionId = [string] $current['subscriptionId'] }
    if (-not $MemberIndex) { $MemberIndex = [int] $current['memberIndex'] }
    if (-not $Location) { $Location = [string] $current['location'] }
    if (-not $SharedSubscriptionId -and $current['sharedSubscriptionId']) { $SharedSubscriptionId = [string] $current['sharedSubscriptionId'] }
}

if ($Suffix -and $current['suffix'] -and $current['suffix'] -ne $Suffix) {
    throw "settings.json already holds the suffix '$($current['suffix'])'. The suffix is never changed; delete .local/settings.json only if you are starting over."
}

$account = $null
if (Get-Command az -ErrorAction SilentlyContinue) {
    $json = & az account show --output json 2>$null
    if ($LASTEXITCODE -eq 0 -and $json) { $account = $json | ConvertFrom-Json }
}

function Read-Setting {
    param(
        [string] $Name,
        [string] $Prompt,
        [string] $Value,
        [string] $Default,
        [scriptblock] $Validate,
        [string] $Hint,
        [switch] $Optional
    )
    while ($true) {
        if (-not $Value) {
            $suffix = if ($Default) { " [$Default]" } elseif ($Optional) { ' [press Enter to skip]' } else { '' }
            $Value = "$(Read-Host "$Prompt$suffix")".Trim()
            if (-not $Value) { $Value = $Default }
        }
        if (-not $Value -and $Optional) { return '' }
        if ($Value -and (& $Validate $Value)) { return $Value }
        Write-Warning "$Name is not valid. $Hint"
        $Value = ''
    }
}

$isGuid = { param($v) $v -match $guidPattern }

$TenantId = Read-Setting -Name 'tenantId' -Prompt 'Tenant ID' -Value $TenantId `
    -Default ($current['tenantId'] ?? $account.tenantId) -Validate $isGuid -Hint 'Expected a GUID like 00000000-0000-0000-0000-000000000000.'
$SubscriptionId = Read-Setting -Name 'subscriptionId' -Prompt 'Your workload subscription ID' -Value $SubscriptionId `
    -Default ($current['subscriptionId'] ?? $account.id) -Validate $isGuid -Hint 'Expected a GUID.'
$memberDefault = if ($current['memberIndex']) { [string]$current['memberIndex'] } else { '' }
$MemberIndex = [int](Read-Setting -Name 'memberIndex' -Prompt 'Your member index (1-20, from your coach)' -Value $(if ($MemberIndex) { [string]$MemberIndex }) `
    -Default $memberDefault -Validate { param($v) $v -match '^\d+$' -and [int]$v -ge 1 -and [int]$v -le 20 } -Hint 'Expected a whole number from 1 to 20.')
$Location = Read-Setting -Name 'location' -Prompt 'Location' -Value $Location `
    -Default ($current['location'] ?? 'swedencentral') -Validate { param($v) $v -match '^[a-z0-9]+$' } -Hint 'Expected a region name like swedencentral.'
$SharedSubscriptionId = Read-Setting -Name 'sharedSubscriptionId' -Prompt 'Shared services subscription ID (from your platform lead, needed in C2)' -Value $SharedSubscriptionId `
    -Default $current['sharedSubscriptionId'] -Validate $isGuid -Hint 'Expected a GUID.' -Optional

if ($SharedSubscriptionId -and $SharedSubscriptionId -eq $SubscriptionId) {
    throw 'The shared services subscription must be different from your workload subscription.'
}

# A stable 6-character suffix (letter first) for resource names; generated once, never changed.
$suffix = if ($Suffix) { $Suffix } else { $current['suffix'] }
if (-not $suffix) {
    $chars = [char[]]'abcdefghijklmnopqrstuvwxyz0123456789'
    $suffix = (Get-Random -InputObject ([char[]]'abcdefghijklmnopqrstuvwxyz')) + (-join (1..5 | ForEach-Object { Get-Random -InputObject $chars }))
}

$settings = [ordered]@{
    tenantId       = $TenantId
    subscriptionId = $SubscriptionId
    location       = $Location
    memberIndex    = $MemberIndex
    suffix         = $suffix
}
if ($SharedSubscriptionId) { $settings['sharedSubscriptionId'] = $SharedSubscriptionId }

New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
$settings | ConvertTo-Json | Set-Content -Path $settingsPath
Write-Host "Wrote $((Resolve-Path $settingsPath).Path)"
Write-Host "Your suffix is '$suffix'. It names your resources; don't change it."
