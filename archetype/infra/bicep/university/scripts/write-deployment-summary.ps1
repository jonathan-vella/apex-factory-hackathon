#Requires -Version 7.0
<#
.SYNOPSIS
    Writes agent-output/university/06-deployment-summary.md from the observed deployment record and the post-deployment test results.

.DESCRIPTION
    Runs PowerShell 7 and the Azure CLI only, and only reads from Azure. Every status in the summary comes from an
    observation: the provisioning state, location, timestamp, duration, output resources and outputs come from the
    azd subscription-scope deployment record in ARM; test statuses come from Outcome.Results. Anything this script
    cannot observe (Bicep build and lint results, a what-if preview, a missing record) is written as "unverified",
    never as a success. Provisioning state, readiness (Passed, Pending, Failed) and application telemetry (pending
    the app image, B06/B10) are reported separately.

    The deployment record is selected by the azd environment name (deployment name prefix or the azd-env-name tag).
    The summary only claims the record as its own when the record's resourceGroupName output equals the azd
    environment's resourceGroupName and that resource group exists. No record, several equally recent records, or an
    unconfirmed resource group are reported as unverified and never as success.

    Resource IDs are reduced to type/name. Tenant, subscription and identity IDs (any GUID), full ARM IDs, bearer tokens
    and secret-looking values are redacted recursively from outputs and test details, and table cells are escaped so
    evidence cannot change the document structure.

    Writing the summary is evidence only. It never means the deployment succeeded and never grants permission to
    advance any workflow step. After writing, and only when apex-recall already shows an authorized Step 6 in
    progress, the script records the artifact with `apex-recall checkpoint`. A missing or failing apex-recall leaves
    the summary in place with a warning. The script does not start, force, transition or otherwise edit workflow state.

.PARAMETER EnvName
    azd environment name, used to find the deployment record. Defaults to AZURE_ENV_NAME.

.PARAMETER Outcome
    The object returned by postdeploy-tests.ps1: ContainerImage and Results (Name, Status, Detail).

.EXAMPLE
    $outcome = ./postdeploy-tests.ps1 -ResourceGroupName $rg ...
    ./write-deployment-summary.ps1 -Outcome $outcome

.OUTPUTS
    None. Writes agent-output/university/06-deployment-summary.md.
#>
[CmdletBinding()]
param(
    [string]$EnvName = $env:AZURE_ENV_NAME,

    [Parameter(Mandatory)]
    [PSCustomObject]$Outcome
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$ProjectName = 'university'
$SummaryRelativePath = "agent-output/$ProjectName/06-deployment-summary.md"
$TelemetryTestName = 'Application telemetry'

function Get-OptionalValue {
    # Strict-mode-safe lookup of a dotted property path; returns $null when any segment is missing.
    param($InputObject, [Parameter(Mandatory)][string]$Path)
    $current = $InputObject
    foreach ($segment in $Path.Split('.')) {
        if ($null -eq $current) { return $null }
        $property = $current.PSObject.Properties[$segment]
        if ($null -eq $property) { return $null }
        $current = $property.Value
    }
    return $current
}

function Invoke-AzJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Arguments, [switch]$AllowFailure)
    $all = & az @Arguments --only-show-errors --output json 2>&1
    $exitCode = $LASTEXITCODE
    $errors = @($all | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() })
    $text = (@($all | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) -join "`n").Trim()
    if ($exitCode -ne 0) {
        if ($AllowFailure) { return $null }
        throw "az $($Arguments[0..([Math]::Min(2, $Arguments.Count - 1))] -join ' ') failed: $($errors -join ' ')"
    }
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text | ConvertFrom-Json -Depth 32
}

function ConvertTo-RedactedResource {
    # Reduces a full ARM ID to "<provider>/<type>/<name>" (or the last segment for IDs without /providers/).
    param([Parameter(Mandatory)][string]$Id)
    $marker = '/providers/'
    $index = $Id.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -ge 0) { return $Id.Substring($index + $marker.Length) }
    return ($Id.TrimEnd('/') -split '/')[-1]
}

function ConvertTo-RedactedText {
    # Best-effort redaction of identifiers and credentials in free text; applied to every value written out.
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($match) ConvertTo-RedactedResource -Id $match.Value }
    $result = [regex]::Replace($Text, '/subscriptions/[^\s"''`<>)\]]+', $evaluator)
    $result = [regex]::Replace($result, '(?i)bearer\s+[A-Za-z0-9\-._~+/]+=*', 'Bearer (redacted-token)')
    $result = [regex]::Replace($result, 'eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]*', '(redacted-token)')
    $result = [regex]::Replace($result, '(?i)\b(password|passwd|pwd|secret|client_secret|sharedaccesskey|accountkey|primarykey|secondarykey|connectionstring|sig|access_?token|refresh_?token|api[-_]?key)\b(\s*["'']?\s*[:=]\s*)(?:"[^"]*"|''[^'']*''|[^\s,;&"'']+)', '$1$2(redacted)')
    return [regex]::Replace($result, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '(redacted-guid)')
}

function ConvertTo-RedactedValue {
    # Recursive redaction of deployment outputs: secret-named keys are dropped to "(redacted)", strings are redacted.
    param([AllowNull()]$Value, [string]$Key = '')
    if ($null -eq $Value) { return $null }
    if ($Key -match '(?i)(password|secret|token|connectionstring|sharedaccesskey|accountkey|primarykey|secondarykey|apikey|credential)') { return '(redacted)' }
    if ($Value -is [string]) { return (ConvertTo-RedactedText -Text $Value) }
    if ($Value -is [datetime]) { return $Value.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }
    if ($Value -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($name in $Value.Keys) { $copy[[string]$name] = ConvertTo-RedactedValue -Value $Value[$name] -Key ([string]$name) }
        return $copy
    }
    if ($Value -is [PSCustomObject]) {
        $copy = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) { $copy[$property.Name] = ConvertTo-RedactedValue -Value $property.Value -Key $property.Name }
        return $copy
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        return , @($Value | ForEach-Object { ConvertTo-RedactedValue -Value $_ })
    }
    return $Value
}

function ConvertTo-TableCell {
    # Redacts, then neutralizes characters that could break a Markdown table row or inject markup.
    param([AllowNull()][AllowEmptyString()][string]$Text)
    $clean = ConvertTo-RedactedText -Text $Text
    $clean = [regex]::Replace($clean, '\r\n|\r|\n', ' ')
    $clean = $clean.Replace('\', '\\').Replace('|', '\|').Replace('`', "'").Replace('<', '&lt;').Replace('>', '&gt;').Replace('[', '\[').Replace(']', '\]')
    return $clean.Trim()
}

function Get-AzdEnvironmentValue {
    # azd environment values; only resourceGroupName and CONTAINER_IMAGE are ever read from it, and neither is ever secret.
    param([Parameter(Mandatory)][string]$Environment)
    if (-not (Get-Command azd -ErrorAction SilentlyContinue)) { return $null }
    $text = & azd env get-values --environment $Environment --output json 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    $joined = ($text -join "`n").Trim()
    if ([string]::IsNullOrWhiteSpace($joined)) { return $null }
    return $joined | ConvertFrom-Json -Depth 8
}

function Get-DeploymentEvidence {
    # Selects the observed subscription deployment for the azd environment and verifies its resource group association.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Environment, $AzdValues)

    $evidence = [PSCustomObject]@{ Association = 'Absent'; Reason = ''; Detail = $null; ResourceGroup = $null }
    $all = @(Invoke-AzJson -Arguments @('deployment', 'sub', 'list'))
    $candidates = @($all | Where-Object {
            $_ -and ($_.name -eq $Environment -or $_.name -like "$Environment-*" -or (Get-OptionalValue $_ 'tags.azd-env-name') -eq $Environment)
        })
    if ($candidates.Count -eq 0) {
        $evidence.Reason = "no subscription-scope deployment is associated with azd environment '$Environment'"
        return $evidence
    }
    $sorted = @($candidates | Sort-Object -Property { [datetime](Get-OptionalValue $_ 'properties.timestamp') } -Descending)
    if ($sorted.Count -gt 1 -and ([datetime](Get-OptionalValue $sorted[0] 'properties.timestamp')) -eq ([datetime](Get-OptionalValue $sorted[1] 'properties.timestamp'))) {
        $evidence.Association = 'Ambiguous'
        $evidence.Reason = "$($sorted.Count) deployments match azd environment '$Environment' and the two most recent share one timestamp"
        return $evidence
    }
    $detail = Invoke-AzJson -Arguments @('deployment', 'sub', 'show', '--name', ([string]$sorted[0].name))
    $evidence.Detail = $detail
    $deployedGroup = Get-OptionalValue $detail 'properties.outputs.resourceGroupName.value'
    $azdGroup = Get-OptionalValue $AzdValues 'resourceGroupName'
    $evidence.ResourceGroup = $deployedGroup
    if (-not $deployedGroup) {
        $evidence.Association = 'Unverified'
        $evidence.Reason = 'the deployment record has no resourceGroupName output to associate with the azd environment'
        return $evidence
    }
    if (-not $azdGroup) {
        $evidence.Association = 'Unverified'
        $evidence.Reason = 'the azd environment values are unavailable, so the resource group association cannot be checked'
        return $evidence
    }
    if ([string]$deployedGroup -ine [string]$azdGroup) {
        $evidence.Association = 'Unverified'
        $evidence.Reason = 'the deployment record resourceGroupName output differs from the azd environment resourceGroupName'
        return $evidence
    }
    $group = Invoke-AzJson -Arguments @('group', 'show', '--name', [string]$deployedGroup) -AllowFailure
    if (-not $group) {
        $evidence.Association = 'Unverified'
        $evidence.Reason = 'the target resource group could not be read'
        return $evidence
    }
    $evidence.Association = 'Verified'
    return $evidence
}

function Get-RecallEligibility {
    # apex-recall must already show an authorized Step 6 in progress; this script never starts or advances a step.
    $recall = Get-Command apex-recall -ErrorAction SilentlyContinue
    if (-not $recall) { return [PSCustomObject]@{ Eligible = $false; Reason = 'apex-recall is not on PATH' } }
    $text = & apex-recall show $ProjectName --json 2>$null
    if ($LASTEXITCODE -ne 0) { return [PSCustomObject]@{ Eligible = $false; Reason = 'apex-recall show failed' } }
    try { $show = ($text -join "`n") | ConvertFrom-Json -Depth 32 } catch { return [PSCustomObject]@{ Eligible = $false; Reason = 'apex-recall show returned unreadable output' } }
    $status = Get-OptionalValue $show 'session.steps.6.status'
    if ($status -notin @('in_progress', 'in-progress')) {
        return [PSCustomObject]@{ Eligible = $false; Reason = 'apex-recall does not show Step 6 in progress' }
    }
    $readiness = Get-OptionalValue $show 'session.gate_readiness'
    if ($readiness -and @($readiness.PSObject.Properties).Count -gt 0) {
        $deployGate = Get-OptionalValue $readiness 'deploy.status'
        if ($deployGate -notin @('current', 'exception-authorized')) {
            return [PSCustomObject]@{ Eligible = $false; Reason = 'the apex-recall deploy gate is not current' }
        }
    }
    return [PSCustomObject]@{ Eligible = $true; Reason = 'apex-recall shows Step 6 in progress with a current gate' }
}

if ([string]::IsNullOrWhiteSpace($EnvName)) {
    throw 'EnvName is required (AZURE_ENV_NAME is not set). Run this from azd, or pass -EnvName explicitly.'
}
if ($EnvName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$') {
    throw "EnvName '$EnvName' contains characters that are not valid in an azd environment name."
}

$knownStatuses = @('Passed', 'Pending', 'Failed')
$results = @(Get-OptionalValue $Outcome 'Results' | Where-Object { $_ } | ForEach-Object {
        $status = [string](Get-OptionalValue $_ 'Status')
        [PSCustomObject]@{
            Name   = [string](Get-OptionalValue $_ 'Name')
            Status = if ($status -in $knownStatuses) { $status } else { 'Unverified' }
            Detail = [string](Get-OptionalValue $_ 'Detail')
        }
    })
$containerImage = [string](Get-OptionalValue $Outcome 'ContainerImage')

Write-Host "Reading the deployment record for azd environment '$EnvName'..."
$azdValues = Get-AzdEnvironmentValue -Environment $EnvName
$evidence = Get-DeploymentEvidence -Environment $EnvName -AzdValues $azdValues
$verified = $evidence.Association -eq 'Verified'
$detail = if ($verified) { $evidence.Detail } else { $null }

# Provisioning state is read from ARM; nothing here is assumed to have succeeded.
$provisioningState = if ($verified) { [string](Get-OptionalValue $detail 'properties.provisioningState') } else { 'Unverified' }
if ([string]::IsNullOrWhiteSpace($provisioningState)) { $provisioningState = 'Unverified' }

$telemetryRow = $results | Where-Object { $_.Name -eq $TelemetryTestName } | Select-Object -First 1
$readinessRows = @($results | Where-Object { $_.Name -ne $TelemetryTestName })
$readiness = if ($readinessRows.Count -eq 0) { 'Unverified' }
elseif (@($readinessRows | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) { 'Failed' }
elseif (@($readinessRows | Where-Object { $_.Status -in @('Pending', 'Unverified') }).Count -gt 0) { 'Pending' }
else { 'Passed' }
$telemetry = if (-not $telemetryRow) { 'Unverified' }
elseif ($telemetryRow.Status -eq 'Pending') { 'Pending (the app image, B06/B10)' }
else { $telemetryRow.Status }

$statusColor = switch ($provisioningState) { 'Succeeded' { 'success' } 'Failed' { 'critical' } 'Canceled' { 'critical' } 'Unverified' { 'lightgrey' } default { 'yellow' } }
$statusBadge = [uri]::EscapeDataString($provisioningState).Replace('-', '--').Replace('_', '__')

$azdImage = [string](Get-OptionalValue $azdValues 'CONTAINER_IMAGE')
$imageRecord = if (-not $containerImage) { 'unverified (the tests reported no image)' }
elseif (-not $azdImage) { 'unverified (CONTAINER_IMAGE is not readable from the azd environment)' }
elseif ($azdImage -eq $containerImage) { 'CONTAINER_IMAGE in the azd environment matches the tested image' }
else { 'CONTAINER_IMAGE in the azd environment differs from the tested image' }

$recall = Get-RecallEligibility
$recallLine = if ($recall.Eligible) {
    "eligible ($(ConvertTo-TableCell $recall.Reason)); the artifact is recorded with apex-recall checkpoint after this file is written and the result is reported on the console only; recording is not workflow completion"
}
else {
    "not attempted ($(ConvertTo-TableCell $recall.Reason)); this summary remains evidence only"
}

$generatedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$lines = [System.Collections.Generic.List[string]]::new()
function Add-Line { param([string]$Text = '') $lines.Add($Text) }

Add-Line "# 🚀 Step 6: Deployment Summary - $ProjectName"
Add-Line
Add-Line '![Step](https://img.shields.io/badge/Step-6-blue?style=for-the-badge)'
Add-Line "![Status](https://img.shields.io/badge/Status-$statusBadge-$($statusColor)?style=for-the-badge)"
Add-Line '![Agent](https://img.shields.io/badge/Agent-azd%20postprovision-purple?style=for-the-badge)'
Add-Line
Add-Line '<details open>'
Add-Line '<summary><strong>📑 Deployment Contents</strong></summary>'
Add-Line
Add-Line '- [✅ Preflight Validation](#-preflight-validation)'
Add-Line '- [📋 Deployment Details](#-deployment-details)'
Add-Line '- [🏗️ Deployed Resources](#-deployed-resources)'
Add-Line '- [📤 Outputs (Expected)](#-outputs-expected)'
Add-Line '- [🚀 To Actually Deploy](#-to-actually-deploy)'
Add-Line '- [📝 Post-Deployment Tasks](#-post-deployment-tasks)'
Add-Line '- [References](#references)'
Add-Line
Add-Line '</details>'
Add-Line
Add-Line "> Generated by write-deployment-summary.ps1 (azd postprovision hook) | $generatedAt"
Add-Line "> Status: **$(ConvertTo-TableCell $provisioningState)** (ARM provisioning state as observed; readiness and telemetry are reported separately)"
Add-Line
Add-Line '| ⬅️ Previous | 📑 Index | Next ➡️ |'
Add-Line '| --- | --- | --- |'
Add-Line '| [05-implementation-reference.md](05-implementation-reference.md) | [README](README.md) | [07-documentation-index.md](07-documentation-index.md) |'
Add-Line
Add-Line '## ✅ Preflight Validation'
Add-Line
Add-Line '| Property | Value | Status |'
Add-Line '| --- | --- | --- |'
Add-Line '| **Project Type** | azd-project | ℹ️ |'
Add-Line '| **Deployment Scope** | subscription | ℹ️ |'
Add-Line ('| **Deployment Record** | {0} | {1} |' -f $(if ($verified) { 'observed and associated with the azd environment' } else { ConvertTo-TableCell "$($evidence.Association.ToLowerInvariant()): $($evidence.Reason)" }), $(if ($verified) { '✅' } else { '⚠️' }))
Add-Line '| **Bicep Build** | unverified (not observed by this script) | ⚠️ |'
Add-Line '| **Bicep Lint** | unverified (not observed by this script) | ⚠️ |'
Add-Line '| **What-If Status** | unverified (no preview evidence was supplied to this script) | ⚠️ |'
Add-Line
Add-Line '## 📋 Deployment Details'
Add-Line
Add-Line '| Field | Value |'
Add-Line '| --- | --- |'
if ($verified) {
    $timestamp = Get-OptionalValue $detail 'properties.timestamp'
    $timestampText = if ($timestamp) { ([datetime]$timestamp).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } else { 'unverified' }
    $duration = Get-OptionalValue $detail 'properties.duration'
    Add-Line "| **Deployment Name** | $(ConvertTo-TableCell ([string]$detail.name)) |"
    Add-Line "| **Resource Group** | $(ConvertTo-TableCell ([string]$evidence.ResourceGroup)) |"
    Add-Line "| **Location** | $(ConvertTo-TableCell ([string](Get-OptionalValue $detail 'location'))) |"
    Add-Line "| **Timestamp (UTC)** | $timestampText |"
    Add-Line "| **Duration** | $(if ($duration) { ConvertTo-TableCell ([string]$duration) } else { 'unverified' }) |"
}
else {
    Add-Line '| **Deployment Name** | unverified |'
    Add-Line '| **Resource Group** | unverified |'
    Add-Line '| **Location** | unverified |'
    Add-Line '| **Timestamp (UTC)** | unverified |'
    Add-Line '| **Duration** | unverified |'
}
Add-Line "| **Provisioning State** | $(ConvertTo-TableCell $provisioningState) |"
Add-Line "| **Readiness** | $readiness |"
Add-Line "| **Application Telemetry** | $(ConvertTo-TableCell $telemetry) |"
Add-Line "| **Container Image** | $(ConvertTo-TableCell $containerImage); $imageRecord |"
Add-Line "| **APEX Recall Recording** | $recallLine |"
Add-Line
Add-Line 'Resource IDs are reduced to type and name. Tenant, subscription and identity IDs, full ARM IDs, tokens and secret-looking values are redacted from outputs and test details.'

if ($verified -and $provisioningState -ne 'Succeeded') {
    Add-Line
    Add-Line '### Deployment Errors'
    Add-Line
    $deploymentError = Get-OptionalValue $detail 'properties.error'
    if ($deploymentError) {
        $errorJson = (ConvertTo-RedactedValue -Value $deploymentError | ConvertTo-Json -Depth 6) -replace '`{3,}', "'''"
        Add-Line '``````json'
        Add-Line $errorJson
        Add-Line '``````'
    }
    else {
        Add-Line 'The record reports a non-succeeded provisioning state without error details.'
    }
    $operations = Invoke-AzJson -Arguments @('deployment', 'operation', 'sub', 'list', '--name', ([string]$detail.name)) -AllowFailure
    $failedOperations = @($operations | Where-Object { $_ -and (Get-OptionalValue $_ 'properties.provisioningState') -eq 'Failed' })
    Add-Line
    if ($null -eq $operations) {
        Add-Line 'Failed deployment operations could not be read (unverified).'
    }
    elseif ($failedOperations.Count -eq 0) {
        Add-Line 'No failed deployment operations were listed.'
    }
    else {
        Add-Line '| Failed resource | Message |'
        Add-Line '| --- | --- |'
        foreach ($operation in $failedOperations) {
            $targetId = [string](Get-OptionalValue $operation 'properties.targetResource.id')
            $target = if ($targetId) { ConvertTo-RedactedResource -Id $targetId } else { 'unknown' }
            $message = Get-OptionalValue $operation 'properties.statusMessage'
            $messageText = if ($message) { ($message | ConvertTo-Json -Depth 6 -Compress) } else { '' }
            Add-Line "| $(ConvertTo-TableCell $target) | $(ConvertTo-TableCell $messageText) |"
        }
    }
}

Add-Line
Add-Line '## 🏗️ Deployed Resources'
Add-Line
$outputResources = @()
if ($verified) {
    $outputResources = @((Get-OptionalValue $detail 'properties.outputResources') | Where-Object { $_ } | ForEach-Object { ConvertTo-RedactedResource -Id ([string]$_.id) } | Sort-Object -Unique)
}
if ($outputResources.Count -gt 0) {
    Add-Line '| Resource (type/name) |'
    Add-Line '| --- |'
    foreach ($resource in $outputResources) { Add-Line "| $(ConvertTo-TableCell $resource) |" }
    Add-Line
    Add-Line 'Listed from the output resources of the deployment record; per-resource provisioning state is not read.'
}
else {
    Add-Line 'unverified: no output resources were observed for this deployment.'
}

Add-Line
Add-Line '## 📤 Outputs (Expected)'
Add-Line
$outputs = if ($verified) { Get-OptionalValue $detail 'properties.outputs' } else { $null }
if ($outputs) {
    $redactedOutputs = [ordered]@{}
    foreach ($property in $outputs.PSObject.Properties) {
        $redactedOutputs[$property.Name] = ConvertTo-RedactedValue -Value (Get-OptionalValue $property.Value 'value') -Key $property.Name
    }
    $outputsJson = ($redactedOutputs | ConvertTo-Json -Depth 8) -replace '`{3,}', "'''"
    Add-Line '<details>'
    Add-Line '<summary><strong>Deployment Outputs JSON</strong></summary>'
    Add-Line
    Add-Line '``````json'
    Add-Line $outputsJson
    Add-Line '``````'
    Add-Line
    Add-Line '</details>'
}
else {
    Add-Line 'unverified: no deployment outputs were observed.'
}

Add-Line
Add-Line '## 🚀 To Actually Deploy'
Add-Line
Add-Line 'These are the commands for another provision; this summary does not say whether a deployment is current.'
Add-Line
Add-Line '<details>'
Add-Line '<summary><strong>🚀 azd</strong></summary>'
Add-Line
Add-Line '```bash'
Add-Line 'cd infra/bicep/university'
Add-Line "azd env select $EnvName"
Add-Line 'azd provision --preview'
Add-Line 'azd provision'
Add-Line '```'
Add-Line
Add-Line '</details>'

Add-Line
Add-Line '## 📝 Post-Deployment Tasks'
Add-Line
$counts = @('Passed', 'Pending', 'Failed', 'Unverified') | ForEach-Object { $status = $_; "$(@($results | Where-Object { $_.Status -eq $status }).Count) $($status.ToLowerInvariant())" }
Add-Line "Test results: $($counts -join ', ')."
Add-Line
if ($results.Count -gt 0) {
    Add-Line '| Task (test) | Status | Detail |'
    Add-Line '| --- | --- | --- |'
    foreach ($result in $results) {
        Add-Line "| $(ConvertTo-TableCell $result.Name) | $($result.Status) | $(ConvertTo-TableCell $result.Detail) |"
    }
}
else {
    Add-Line 'unverified: no test results were supplied.'
}
Add-Line
Add-Line 'Pending diagnostics rows come from asynchronous DeployIfNotExists evaluation; application telemetry stays pending the app image (B06/B10).'

Add-Line
Add-Line '---'
Add-Line
Add-Line '## References'
Add-Line
Add-Line '| Topic | Link |'
Add-Line '| --- | --- |'
Add-Line '| azd provision | [azd provision](https://learn.microsoft.com/azure/developer/azure-developer-cli/reference#azd-provision) |'
Add-Line '| ARM deployment record | [az deployment sub show](https://learn.microsoft.com/cli/azure/deployment/sub#az-deployment-sub-show) |'
Add-Line '| What-If Operations | [Preview Changes](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-what-if) |'
Add-Line
Add-Line '---'
Add-Line
Add-Line "_Deployment summary for $ProjectName, generated from observed evidence only._"
Add-Line
Add-Line '---'
Add-Line
Add-Line '<div align="center">'
Add-Line
Add-Line '| ⬅️ [05-implementation-reference.md](05-implementation-reference.md) | 🏠 [Project Index](README.md) | ➡️ [07-documentation-index.md](07-documentation-index.md) |'
Add-Line '| --- | --- | --- |'
Add-Line
Add-Line '</div>'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..' '..' '..' '..'))
$summaryPath = Join-Path $repoRoot $SummaryRelativePath
$summaryDirectory = Split-Path -Parent $summaryPath
if (-not (Test-Path -LiteralPath $summaryDirectory)) { New-Item -ItemType Directory -Path $summaryDirectory -Force | Out-Null }
Set-Content -LiteralPath $summaryPath -Value (($lines -join "`n") + "`n") -Encoding utf8NoBOM
Write-Host "Wrote $SummaryRelativePath (provisioning state: $provisioningState; readiness: $readiness; telemetry: $telemetry)."
if (-not $verified) {
    Write-Warning "The summary was written without a verified deployment record ($($evidence.Reason)); it does not claim success."
}

if ($recall.Eligible) {
    Push-Location -LiteralPath $repoRoot
    try {
        $recorded = & apex-recall checkpoint $ProjectName 6 phase_6_artifact --artifact $SummaryRelativePath --json 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host 'Recorded the summary artifact with apex-recall checkpoint. This is not step completion.'
        }
        else {
            Write-Warning "apex-recall checkpoint exited $LASTEXITCODE; the summary is written but not recorded. Retry: apex-recall checkpoint $ProjectName 6 phase_6_artifact --artifact $SummaryRelativePath --json. Advancing a step belongs to the owning APEX workflow after its gates and human authorization. Output: $((($recorded | Out-String).Trim()))"
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Warning "The summary was not recorded with apex-recall: $($recall.Reason). The file remains as evidence; step state was not touched."
}
