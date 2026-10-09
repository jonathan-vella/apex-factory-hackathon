#Requires -Version 7.0
<#
.SYNOPSIS
    Writes agent-output/university/06-deployment-summary.md from the live deployment record and marks APEX Step 6 complete.

.DESCRIPTION
    Runs PowerShell 7 and the Azure CLI only. Reads the azd subscription-scope deployment record (name, location,
    timestamp, duration, provisioning state, output resource types/names, deployment outputs) and the post-deploy
    test results, and writes them to `agent-output/university/06-deployment-summary.md` so the artifact exists even
    though `azd` bypasses APEX Deploy (`07b`), which would normally write it. The H2 heading sequence matches APEX's
    `06-deployment-summary.md` template exactly (`tools/scripts/check-h2-order.mjs` enforces this as a required
    prefix), with content adapted for a live `azd provision` outcome instead of a pre-deploy dry run. No tenant ID,
    subscription ID, full ARM resource ID or identity client/object ID is written: output resources are reduced to
    resource type and name only, and any GUID-shaped deployment output value is redacted. After writing the file it
    tries to mark Step 6 complete with `apex-recall` (if present on PATH); if that command is not available it leaves
    the file in place and prints the command to run manually. Both the summary write and the `apex-recall` call are
    best-effort: a missing or failing `apex-recall` does not fail the caller (the azd postprovision hook).

.PARAMETER EnvName
    azd environment name, used to find the matching subscription-scope deployment. Defaults to AZURE_ENV_NAME.

.PARAMETER Outcome
    The PSCustomObject returned by postdeploy-tests.ps1 (ContainerImage, Results). Resource names and types come from
    the deployment record itself (az deployment sub show), not from this parameter.

.EXAMPLE
    $outcome = ./postdeploy-tests.ps1 ...
    ./write-deployment-summary.ps1 -Outcome $outcome

.OUTPUTS
    None. Writes agent-output/university/06-deployment-summary.md.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$EnvName = $env:AZURE_ENV_NAME,

    [Parameter(Mandatory)]
    [PSCustomObject]$Outcome
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-AzJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Arguments)
    $text = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "az $($Arguments -join ' ') failed: $text" }
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text | ConvertFrom-Json -Depth 32
}

function ConvertTo-RedactedResource {
    # Reduces a full ARM resource ID to "<Provider>/<type>/<name>" only - no subscription or tenant ID.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Id)
    $marker = '/providers/'
    $index = $Id.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -lt 0) { return ($Id -split '/')[-1] }
    return $Id.Substring($index + $marker.Length)
}

function ConvertTo-RedactedOutputValue {
    # Deployment outputs are resource names/FQDNs (safe) except for identity client/object IDs, which are GUIDs.
    # Redact any bare GUID value so no identity ID is ever written to the artifact.
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)][AllowNull()]$Value)
    process {
        if ($Value -is [string] -and $Value -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
            return '<redacted-guid>'
        }
        return $Value
    }
}

if ([string]::IsNullOrWhiteSpace($EnvName)) {
    throw 'EnvName is required (AZURE_ENV_NAME is not set). Run this from azd, or pass -EnvName explicitly.'
}

Write-Host "Finding the subscription-scope deployment for azd environment '$EnvName'..."
$deployment = Invoke-AzJson -Arguments @(
    'deployment', 'sub', 'list',
    '--query', "sort_by([?starts_with(name, '$EnvName')], &properties.timestamp)[-1]"
)
if (-not $deployment) {
    throw "No subscription-scope deployment found starting with '$EnvName'. Run azd provision first."
}

$outputResources = @($deployment.properties.outputResources | ForEach-Object { ConvertTo-RedactedResource -Id $_.id } | Sort-Object)
# ConvertFrom-Json deserializes .properties.timestamp as a [datetime]; string interpolation then renders it in the
# local culture/offset, not UTC. Format explicitly to avoid that (a real bug hit earlier in this effort).
$deploymentTimestamp = ([DateTime]$deployment.properties.timestamp).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$resourceGroupName = $deployment.properties.outputs.resourceGroupName.value

$testRows = foreach ($r in $Outcome.Results) {
    "| $($r.Name) | $($r.Status) | $($r.Detail) |"
}
$passed = @($Outcome.Results | Where-Object { $_.Status -eq 'Passed' }).Count
$pending = @($Outcome.Results | Where-Object { $_.Status -eq 'Pending' }).Count
$failed = @($Outcome.Results | Where-Object { $_.Status -eq 'Failed' }).Count

$generatedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$resourceRows = foreach ($r in $outputResources) { "- ``$r``" }

$redactedOutputs = [ordered]@{}
foreach ($prop in $deployment.properties.outputs.PSObject.Properties) {
    $value = $prop.Value.value
    if ($value -is [array]) {
        $redactedOutputs[$prop.Name] = @($value | ConvertTo-RedactedOutputValue)
    }
    else {
        $redactedOutputs[$prop.Name] = (ConvertTo-RedactedOutputValue -Value $value)
    }
}
$outputsJson = ($redactedOutputs | ConvertTo-Json -Depth 5)

$markdown = @"
# 🚀 Step 6: Deployment Summary - university

![Step](https://img.shields.io/badge/Step-6-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Complete-success?style=for-the-badge)
![Agent](https://img.shields.io/badge/Agent-azd%20(bypasses%2007b)-purple?style=for-the-badge)

<details open>
<summary><strong>📑 Deployment Summary</strong></summary>

- [✅ Preflight Validation](#-preflight-validation)
- [📋 Deployment Details](#-deployment-details)
- [🏗️ Deployed Resources](#️-deployed-resources)
- [📤 Outputs (Expected)](#-outputs-expected)
- [🚀 To Actually Deploy](#-to-actually-deploy)
- [📝 Post-Deployment Tasks](#-post-deployment-tasks)
- [References](#references)

</details>

> Generated by ``write-deployment-summary.ps1`` (postprovision hook) | $generatedAt
> Status: **Succeeded**

| ⬅️ Previous                                                        | 📑 Index            | Next ➡️                              |
| ------------------------------------------------------------------ | -------------------- | ------------------------------------- |
| [05-implementation-reference.md](05-implementation-reference.md)   | [README](README.md)  | 07-as-built.md (As-Built, agent 08)   |

## ✅ Preflight Validation

This deployment ran through the ``adapt-archetype`` prompt, not APEX Deploy (``07b``): ``preflight.ps1`` (read-only)
set the derived azd env values, then ``azd provision --preview`` previewed the change before the member ran
``azd provision``. See ``05-implementation-reference.md`` for that preview's output; it only lists resource types
azd has display names for (SQL MI, the UAMI, role assignments, diagnostic settings and the schedule do not appear
there even though they are deployed).

| Property             | Value                 | Status |
| --------------------- | --------------------- | ------ |
| Project Type          | azd-project            | ℹ️     |
| Deployment Scope      | Subscription            | ℹ️     |
| What-If Status        | Ran via ``azd provision --preview`` (adapt-archetype prompt) | ✅     |
| Provisioning Result   | $($deployment.properties.provisioningState) | ✅     |

## 📋 Deployment Details

| Field              | Value                                        |
| ------------------- | --------------------------------------------- |
| Deployment Name     | ``$($deployment.name)``                       |
| Resource Group      | ``$resourceGroupName``                        |
| Location            | $($deployment.location)                       |
| Timestamp           | $deploymentTimestamp                          |
| Duration            | $($deployment.properties.duration)            |
| Status              | $($deployment.properties.provisioningState)   |

No tenant ID, subscription ID or full ARM resource ID is recorded here (resource type/name only, same convention as
every other packaged artifact).

## 🏗️ Deployed Resources

$($resourceRows -join "`n")

## 📤 Outputs (Expected)

<details>
<summary><strong>Deployment Outputs JSON</strong></summary>

``````json
$outputsJson
``````

</details>

Identity client/object IDs (GUID-shaped values, for example ``uamiClientId``) are redacted above; resource names and
FQDNs are not sensitive and are kept.

## 🚀 To Actually Deploy

Already deployed via ``azd provision`` (owner decision, 2026-10-07: CoE consumers deploy with azd, not APEX Deploy).
To apply further template changes:

<details>
<summary><strong>🚀 azd</strong></summary>

``````bash
cd infra/bicep/university
azd env select $EnvName
azd provision --preview
azd provision
``````

</details>

APEX Deploy (``07b``) stays an optional advanced path; ``deploy.ps1`` stays the no-azd fallback.

## 📝 Post-Deployment Tasks

Container image persisted for later provisions: ``$($Outcome.ContainerImage)``

Summary: $passed passed, $pending pending, $failed failed.

| Task (Test) | Status | Detail |
| ------------ | ------ | ------ |
$($testRows -join "`n")

## 📝 Key Notes

| Note                                                                 | Impact                      | Reference                                          |
| --------------------------------------------------------------------| ---------------------------- | --------------------------------------------------- |
| This file is written by the ``azd postprovision`` hook, not APEX Deploy (``07b``) | Artifact parity for As-Built | ``azd`` is the primary deploy path (owner decision, 2026-10-07); ``07b`` stays optional |
| Diagnostics and telemetry rows may show ``Pending``                  | Expected, not a defect        | DeployIfNotExists settings and app telemetry are asynchronous or await the app image (B06/B10) |

## References

| Topic             | Link                                                                                   |
| ------------------ | --------------------------------------------------------------------------------------- |
| azd provision      | [azd provision](https://learn.microsoft.com/azure/developer/azure-developer-cli/reference#azd-provision) |
| What-If Operations | [Preview Changes](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if) |

---

_Deployment summary generated from the live ``az deployment sub show`` record and ``postdeploy-tests.ps1`` results._

---

<div align="center">

| ⬅️ [05-implementation-reference.md](05-implementation-reference.md) | 🏠 [Project Index](README.md) | ➡️ 07-as-built.md (As-Built, agent 08) |
| --------------------------------------------------------------------| ------------------------------ | ---------------------------------------- |

</div>
"@

$repoRoot = Join-Path $PSScriptRoot '..' '..' '..' '..'
$summaryDir = Join-Path $repoRoot 'agent-output' 'university'
if (-not (Test-Path $summaryDir)) { New-Item -ItemType Directory -Path $summaryDir -Force | Out-Null }
$summaryPath = Join-Path $summaryDir '06-deployment-summary.md'
Set-Content -Path $summaryPath -Value $markdown -Encoding utf8NoBOM
Write-Host "Wrote $summaryPath"

$recallCmd = Get-Command apex-recall -ErrorAction SilentlyContinue
if ($recallCmd) {
    & apex-recall transition 6 7 --artifact $summaryPath 2>&1 | ForEach-Object { Write-Host "apex-recall: $_" }
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Step 6 marked complete via apex-recall.'
    }
    else {
        Write-Warning "apex-recall transition 6 7 exited $LASTEXITCODE. Record Step 6 complete manually: apex-recall transition 6 7 --artifact $summaryPath (or your pinned APEX release's equivalent command)."
    }
}
else {
    Write-Warning "apex-recall was not found on PATH. $summaryPath is written; record Step 6 complete manually with your pinned APEX release's step-transition command before running As-Built (agent 08)."
}
