#Requires -Version 7.4

<#
.SYNOPSIS
Fails closed unless a pipeline job only touches the subscriptions and management-group prefix it is allowed to.
.DESCRIPTION
The first step of every platform workflow job. It compares what the job is about to use with the allowlist
the environment holds, and exits 1 on the first problem, so nothing deploys:
- the allowlist must not be empty, and must not overlap the deny list;
- every requested subscription must be on the allowlist and not on the deny list;
- the requested management-group prefix must equal the allowed one and not be a denied one.
The deny list is for subscriptions and prefixes the pipeline must never touch, such as a live lab in the
same tenant. IDs are never printed: a failure says which rule broke, not the value.
.PARAMETER SubscriptionId
The subscriptions this job will use.
.PARAMETER AllowedSubscriptionId
The allowlist, from the environment variable ALLOWED_SUBSCRIPTIONS (comma separated).
.PARAMETER DeniedSubscriptionId
The deny list, from DENIED_SUBSCRIPTIONS (comma separated). May be empty.
.PARAMETER MgPrefix
The management-group prefix this job will use.
.PARAMETER AllowedMgPrefix
The only prefix allowed, from MG_PREFIX.
.PARAMETER DeniedMgPrefix
Prefixes that are never allowed, from DENIED_MG_PREFIXES (comma separated). May be empty.
.EXAMPLE
./scripts/Assert-PipelineGuard.ps1 -SubscriptionId $shared, $workload -AllowedSubscriptionId $env:ALLOWED_SUBSCRIPTIONS -MgPrefix $env:MG_PREFIX -AllowedMgPrefix $env:MG_PREFIX
#>

[CmdletBinding()]
param(
    [string[]] $SubscriptionId = @(),
    [string[]] $AllowedSubscriptionId = @(),
    [string[]] $DeniedSubscriptionId = @(),
    [string] $MgPrefix = '',
    [string] $AllowedMgPrefix = '',
    [string[]] $DeniedMgPrefix = @()
)

$ErrorActionPreference = 'Stop'

function ConvertTo-List {
    param([string[]] $Value)
    return @($Value | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })
}

$requested = ConvertTo-List $SubscriptionId
$allowed = ConvertTo-List $AllowedSubscriptionId
$denied = ConvertTo-List $DeniedSubscriptionId
$deniedPrefixes = ConvertTo-List $DeniedMgPrefix
$problems = [System.Collections.Generic.List[string]]::new()

if ($allowed.Count -eq 0) { $problems.Add('The subscription allowlist is empty.') }
if (@($allowed | Where-Object { $_ -in $denied }).Count -gt 0) { $problems.Add('A subscription is on both the allowlist and the deny list.') }
if ($requested.Count -eq 0) { $problems.Add('No subscription was given to check.') }
foreach ($id in $requested) {
    if ($id -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') { $problems.Add('A requested subscription is not a valid ID.'); continue }
    if ($id -in $denied) { $problems.Add('A requested subscription is on the deny list.') }
    elseif ($id -notin $allowed) { $problems.Add('A requested subscription is not on the allowlist.') }
}
if (-not $AllowedMgPrefix) { $problems.Add('The allowed management-group prefix is not set.') }
if ($MgPrefix.ToLowerInvariant() -in $deniedPrefixes) { $problems.Add('The management-group prefix is on the deny list.') }
elseif ($AllowedMgPrefix -and $MgPrefix -cne $AllowedMgPrefix) { $problems.Add('The management-group prefix is not the allowed one.') }

if ($problems.Count -gt 0) {
    $problems | Sort-Object -Unique | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    Write-Error 'The guard refused this job. Nothing was deployed.' -ErrorAction Continue
    exit 1
}
Write-Information "Guard passed: $($requested.Count) subscription(s) on the allowlist, prefix '$MgPrefix' allowed." -InformationAction Continue
exit 0
