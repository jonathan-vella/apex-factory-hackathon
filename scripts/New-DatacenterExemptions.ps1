#Requires -Version 7.4

<#
.SYNOPSIS
Records the datacenter's deliberate policy exceptions as exemptions, with owner and expiry.
.DESCRIPTION
The datacenter existed before the workload subscription moved under <MgPrefix>-corp, so it isn't
blocked by the landing zone's policies but can show as non-compliant. This script starts a compliance
scan of rg-datacenter, finds the kit's ALZ-lite assignments (display name "ALZ-lite: ...") that
rg-datacenter violates, plus any assignment named with -IncludeAssignment, and creates one exemption
per assignment, scoped to rg-datacenter only: category Waiver, the expiry date, and a
description with the owner, the reason (pre-existing on-premises simulation, migrating in C7) and the
target date. It never exempts the spoke or the workload resources. Then it prints a table to paste into
the deferred-work register. Other violated assignments (for example tenant policies) are listed but
never exempted unless named. A re-run updates the same exemptions. Use -WhatIf to list them only.
.PARAMETER SubscriptionId
The member's workload subscription.
.PARAMETER Owner
The name of the person who owns the deferred work.
.PARAMETER ExpiresOn
The exemptions' expiry and target date. Default: 14 days from today.
.PARAMETER IncludeAssignment
Names or display names of other assignments to exempt too, for example the Microsoft cloud security
benchmark that Defender for Cloud assigns ("Azure Security Baseline" or "ASC Default"). Only those the
datacenter violates are exempted.
.PARAMETER SkipScan
Use the current compliance results instead of starting a scan, which takes several minutes.
.EXAMPLE
./scripts/New-DatacenterExemptions.ps1 -SubscriptionId '<workload-subscription-id>' -Owner 'Alex Kim'
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/New-DatacenterExemptions.ps1 -SubscriptionId $s.subscriptionId -Owner 'Alex Kim' -ExpiresOn 2026-11-30 -WhatIf
.EXAMPLE
./scripts/New-DatacenterExemptions.ps1 -SubscriptionId '<workload-subscription-id>' -Owner 'Alex Kim' -IncludeAssignment 'Azure Security Baseline'
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Owner,
    [datetime] $ExpiresOn = (Get-Date).Date.AddDays(14),
    [string[]] $IncludeAssignment = @(),
    [switch] $SkipScan
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$subscription = $SubscriptionId
$resourceGroup = 'rg-datacenter'
$reason = 'pre-existing on-premises simulation, migrating in C7'
$targetDate = $ExpiresOn.ToString('yyyy-MM-dd')
$included = $IncludeAssignment

function Invoke-AzureCli {
    param([string[]] $Arguments)
    # Capture native stderr rather than letting the CLI print subscription IDs.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --subscription $subscription --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE)."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

if ($ExpiresOn -le (Get-Date)) {
    throw "ExpiresOn ($targetDate) must be in the future."
}
$null = Invoke-AzureCli -Arguments @('group', 'show', '-n', $resourceGroup)

if (-not $SkipScan) {
    Write-Information "Scanning $resourceGroup for policy compliance. This takes a few minutes."
    $null = Invoke-AzureCli -Arguments @('policy', 'state', 'trigger-scan', '--resource-group', $resourceGroup)
}

$states = @(Invoke-AzureCli -Arguments @('policy', 'state', 'list', '--resource-group', $resourceGroup,
        '--filter', "complianceState eq 'NonCompliant'"))
$violations = @($states | Group-Object -Property policyAssignmentId)
$skipped = [System.Collections.Generic.List[string]]::new()
$register = foreach ($violation in $violations) {
    $assignmentName = $violation.Group[0].policyAssignmentName
    $assignment = Invoke-AzureCli -Arguments @('rest', '--method', 'get', '--uri',
        "https://management.azure.com$($violation.Name)?api-version=2025-03-01")
    $displayName = if ($assignment.properties.displayName) { $assignment.properties.displayName } else { $assignmentName }
    # Only the kit's own assignments, unless the member names another one.
    if (-not ($displayName -like 'ALZ-lite:*' -or $included -contains $assignmentName -or $included -contains $displayName)) {
        $skipped.Add("$displayName ($assignmentName)")
        continue
    }
    $exemptionName = ("exempt-datacenter-$assignmentName" -replace '[^A-Za-z0-9-]', '-')
    $exemptionName = $exemptionName.Substring(0, [Math]::Min(64, $exemptionName.Length))
    $description = "Owner: $Owner. Reason: $reason. Target date: $targetDate."
    if ($PSCmdlet.ShouldProcess("$resourceGroup for '$displayName'", 'Create policy exemption')) {
        $null = Invoke-AzureCli -Arguments @('policy', 'exemption', 'create', '--name', $exemptionName,
            '--display-name', "Datacenter: $displayName", '--policy-assignment', $violation.Name,
            '--exemption-category', 'Waiver', '--expires-on', $ExpiresOn.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'),
            '--description', $description, '--resource-group', $resourceGroup)
    }
    [pscustomobject]@{
        Assignment = $displayName
        Resources = @($violation.Group.resourceId | Sort-Object -Unique).Count
        Exemption = $exemptionName
        Category = 'Waiver'
        Owner = $Owner
        Reason = $reason
        Target = $targetDate
    }
}

if ($skipped.Count) {
    Write-Information 'Violated but not exempted (not ALZ-lite; name them with -IncludeAssignment to exempt them):'
    $skipped | ForEach-Object { Write-Information "  $_" }
}
if (-not $register) {
    Write-Information "$resourceGroup violates no assignment to exempt: nothing to do."
    return
}

Write-Information "`nPaste this into your deferred-work register:`n"
Write-Output '| Policy assignment | Non-compliant resources | Exemption | Category | Owner | Reason | Target date |'
Write-Output '|---|---|---|---|---|---|---|'
foreach ($row in $register) {
    Write-Output "| $($row.Assignment) | $($row.Resources) | $($row.Exemption) | $($row.Category) | $($row.Owner) | $($row.Reason) | $($row.Target) |"
}
Write-Information "`nThe exemptions expire on $targetDate. Extend them with this script and a new -ExpiresOn, or migrate first."
