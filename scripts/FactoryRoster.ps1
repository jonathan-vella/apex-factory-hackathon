#Requires -Version 7.4

<#
.SYNOPSIS
Shared roster normalization and verification for platform setup and vending. Dot-source this file.
.EXAMPLE
. (Join-Path $PSScriptRoot 'FactoryRoster.ps1')
#>

function Import-FactoryRoster {
    param([Parameter(Mandatory)][string] $Path)
    $raw = Get-Content -Raw -LiteralPath $Path
    $rows = if ($Path -match '\.csv$') { @($raw | ConvertFrom-Csv) } else { @($raw | ConvertFrom-Json) }
    foreach ($row in $rows) {
        $pick = {
            param($Names)
            foreach ($name in $Names) {
                $property = $row.PSObject.Properties[$name]
                if ($property -and "$($property.Value)".Trim()) { return "$($property.Value)".Trim() }
            }
            return ''
        }
        [pscustomobject]@{
            index = [int] (& $pick @('index', 'Member index'))
            subscriptionId = (& $pick @('subscriptionId', 'Workload subscription ID'))
            memberPrincipalId = (& $pick @('memberPrincipalId', 'Entra object ID'))
            budgetEmail = (& $pick @('budgetEmail', 'Budget email'))
        }
    }
}

function ConvertTo-FactoryRosterJson {
    param([Parameter(Mandatory)][object[]] $Members)
    ConvertTo-Json -Compress -InputObject @($Members | ForEach-Object {
        [ordered]@{
            index = [int] $_.index
            subscriptionId = [string] $_.subscriptionId
            memberPrincipalId = [string] $_.memberPrincipalId
            budgetEmail = [string] $_.budgetEmail
        }
    })
}

function Get-FactoryRosterDigest {
    param([object[]] $Members)
    if (-not $Members.Count) { throw 'Roster verification requires at least one member. Run Sync-FactoryReaderGroup.ps1.' }
    $seen = [Collections.Generic.HashSet[int]]::new()
    $entries = foreach ($member in $Members | Sort-Object { [int] $_.index }) {
        $index = 0
        $oid = [guid]::Empty
        if (-not [int]::TryParse([string] $member.index, [ref] $index) -or $index -lt 1 -or -not $seen.Add($index)) {
            throw 'The roster contains a missing, invalid, or repeated member index.'
        }
        if (-not [guid]::TryParseExact([string] $member.memberPrincipalId, 'D', [ref] $oid) -or $oid -eq [guid]::Empty) {
            throw "Member $index has no valid Entra object ID. Correct the full roster before syncing or vending."
        }
        "${index}:$oid"
    }
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($entries -join "`n")))
}

function Get-FactoryVerifiedGroupIndex {
    param([object[]] $Members, [string] $TenantId, [string] $GroupId, [string] $MgPrefix, [string] $VerificationJson)
    $digest = Get-FactoryRosterDigest -Members $Members
    $verification = if ($VerificationJson) {
        try { ConvertFrom-Json -InputObject $VerificationJson -ErrorAction Stop }
        catch { throw 'The reader-group roster verification is invalid. Run Sync-FactoryReaderGroup.ps1.' }
    }
    if (-not $TenantId -or -not $GroupId -or $verification.version -ne 1 -or
        $verification.tenantId -ne $TenantId -or $verification.groupId -ne $GroupId -or
        $verification.mgPrefix -ne $MgPrefix -or $verification.digest -ne $digest) {
        throw 'Reader-group verification is missing or stale. Run Sync-FactoryReaderGroup.ps1 for the full roster before vending.'
    }
    if ($null -ne $verification.groupIndexes) { $verification.groupIndexes }
}
