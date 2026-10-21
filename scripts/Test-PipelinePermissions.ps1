#Requires -Version 7.4

<#
.SYNOPSIS
Probes what the signed-in identity can do for the platform pipeline, then cleans up after itself.
.DESCRIPTION
Run it as the pipeline's managed identity (platform-smoke.yml does) or as yourself. It exercises, one step
at a time, the operations ALZ-lite and vending need, in a throwaway child management group under the
deployment parent:
- read the roles it holds at the parent;
- a management-group-scope deployment (an empty template);
- creating a child management group;
- moving the empty workload subscription into it and back;
- a policy assignment with a system-assigned identity and the role assignment for that identity;
- deleting everything it created.
With -DenySettingsPath it also checks that the identity can NOT read the subscriptions in that file (the
live lab): a denied read is a PASS. It only reads those subscriptions. Prints a PASS/FAIL table and exits 1
if a step fails. Don't run it against a workload subscription that holds resources.
.PARAMETER WorkloadSubscriptionId
The empty workload subscription used for the placement check.
.PARAMETER ParentManagementGroupId
The deployment parent. Empty means Tenant Root.
.PARAMETER MgPrefix
Prefix of the probe group (<prefix>-probe). Default mg-factory-ci.
.PARAMETER Location
Region for the deployment records and the policy identity.
.PARAMETER DenySettingsPath
A settings file (sharedSubscriptionId, subscriptionId) of subscriptions the identity must not be able to read.
.PARAMETER DeniedSubscriptionId
Subscription IDs the identity must not be able to read (the same check as -DenySettingsPath, for a pipeline).
.PARAMETER SkipCreate
Only read: roles and denied reads. Changes nothing.
.EXAMPLE
./scripts/Test-PipelinePermissions.ps1 -WorkloadSubscriptionId '<workload-subscription-id>' -ParentManagementGroupId mg-ci-sandbox
#>

[CmdletBinding()]
param(
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $WorkloadSubscriptionId = '',
    [ValidatePattern('^$|^[A-Za-z0-9._()-]{1,90}$')]
    [string] $ParentManagementGroupId = '',
    [ValidatePattern('^[A-Za-z0-9-]{2,40}$')]
    [string] $MgPrefix = 'mg-factory-ci',
    [string] $Location = 'swedencentral',
    [string] $DenySettingsPath = '',
    [string[]] $DeniedSubscriptionId = @(),
    [switch] $SkipCreate
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$results = [System.Collections.Generic.List[object]]::new()
$probeGroup = "$MgPrefix-probe"
$deploymentLocation = $Location
$assignmentName = 'factory-probe-audit'

function Invoke-AzureCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        $detail = (($output | ForEach-Object { $_.ToString() }) -join ' ') -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '<id>'
        throw "Azure CLI '$operation' failed: $detail"
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Add-Step {
    param([string] $Name, [scriptblock] $Action, [switch] $ExpectDenied)
    try {
        $detail = & $Action
        if ($ExpectDenied) {
            $results.Add([pscustomobject]@{ Step = $Name; Result = 'FAIL'; Detail = 'Access was NOT denied.' })
        }
        else {
            $results.Add([pscustomobject]@{ Step = $Name; Result = 'PASS'; Detail = "$detail" })
        }
    }
    catch {
        if ($ExpectDenied) {
            $results.Add([pscustomobject]@{ Step = $Name; Result = 'PASS'; Detail = 'Denied, as expected.' })
        }
        else {
            $results.Add([pscustomobject]@{ Step = $Name; Result = 'FAIL'; Detail = $_.Exception.Message })
        }
    }
}

$account = Invoke-AzureCli -Arguments @('account', 'show')
$tenantId = $account.tenantId
$parentId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { $tenantId }
$parentScope = "/providers/Microsoft.Management/managementGroups/$parentId"
$probeScope = "/providers/Microsoft.Management/managementGroups/$probeGroup"
$token = Invoke-AzureCli -Arguments @('account', 'get-access-token', '--resource', 'https://management.azure.com/', '--query', 'accessToken')
$payload = $token.Split('.')[1].Replace('-', '+').Replace('_', '/')
$payload += '=' * ((4 - $payload.Length % 4) % 4)
$objectId = ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json).oid
Write-Information "Probing as a $($account.user.type) at $(if ($parentId -eq $tenantId) { 'Tenant Root' } else { "management group '$parentId'" })."

Add-Step 'Roles at the parent' {
    $roles = @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $parentScope, '--include-inherited') |
            Where-Object { $_.principalId -eq $objectId } | ForEach-Object { $_.roleDefinitionName } | Sort-Object -Unique)
    if (-not $roles) { throw 'No role at the parent.' }
    "Holds: $($roles -join ', ')"
}

if (-not $SkipCreate) {
    $template = Join-Path ([System.IO.Path]::GetTempPath()) "probe-$([guid]::NewGuid()).json"
    @{
        '$schema' = 'https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#'
        contentVersion = '1.0.0.0'
        resources = @()
        outputs = @{ ok = @{ type = 'string'; value = 'ok' } }
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $template -Encoding utf8NoBOM
    try {
        Add-Step 'Deployment at the parent management group' {
            $null = Invoke-AzureCli -Arguments @('deployment', 'mg', 'create', '--management-group-id', $parentId, '--name', "$probeGroup-deploy",
                '--location', $deploymentLocation, '--template-file', $template)
            'An empty deployment succeeded.'
        }
        Add-Step 'Create a child management group' {
            $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'create', '--name', $probeGroup, '--display-name', $probeGroup, '--parent', $parentId)
            "Created $probeGroup."
        }
        if ($WorkloadSubscriptionId) {
            Add-Step 'Move the workload subscription into it and back' {
                $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'subscription', 'add', '--name', $probeGroup, '--subscription', $WorkloadSubscriptionId)
                $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'subscription', 'add', '--name', $parentId, '--subscription', $WorkloadSubscriptionId)
                'Placement worked both ways.'
            }
        }
        Add-Step 'Policy assignment with a system-assigned identity and its role assignment' {
            $audit = '/providers/Microsoft.Authorization/policyDefinitions/0a914e76-4921-4c19-b460-a2d36003525a'
            $null = Invoke-AzureCli -Arguments @('policy', 'assignment', 'create', '--name', $assignmentName, '--scope', $probeScope, '--policy', $audit,
                '--mi-system-assigned', '--location', $deploymentLocation, '--role', 'Reader', '--identity-scope', $probeScope)
            'Assigned a policy with an identity and granted it Reader.'
        }
    }
    finally {
        Remove-Item -Path $template -Force -ErrorAction SilentlyContinue
        Add-Step 'Clean up' {
            $PSNativeCommandUseErrorActionPreference = $false
            $assignment = & az policy assignment show --name $assignmentName --scope $probeScope --only-show-errors --output json 2>$null | ConvertFrom-Json
            if ($assignment) {
                $principal = $assignment.identity.principalId
                foreach ($ra in @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $probeScope) | Where-Object { $_.principalId -eq $principal })) {
                    $null = Invoke-AzureCli -Arguments @('role', 'assignment', 'delete', '--ids', $ra.id)
                }
                $null = Invoke-AzureCli -Arguments @('policy', 'assignment', 'delete', '--name', $assignmentName, '--scope', $probeScope)
            }
            if ($WorkloadSubscriptionId) {
                $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'subscription', 'add', '--name', $parentId, '--subscription', $WorkloadSubscriptionId)
            }
            & az account management-group delete --name $probeGroup --only-show-errors 2>$null | Out-Null
            $left = & az account management-group show --name $probeGroup --only-show-errors --output json 2>$null
            if ($left) { throw "The probe group $probeGroup is still there." }
            'The probe group, policy assignment and role assignment are gone.'
        }
    }
}

$protected = @($DeniedSubscriptionId)
if ($DenySettingsPath -and (Test-Path $DenySettingsPath)) {
    $deny = Get-Content -Raw -Path $DenySettingsPath | ConvertFrom-Json
    $protected += @($deny.sharedSubscriptionId, $deny.subscriptionId)
}
$index = 0
foreach ($id in $protected | Where-Object { $_ }) {
    $index++
    Add-Step "Denied: read of protected subscription $index" -ExpectDenied {
        $null = Invoke-AzureCli -Arguments @('group', 'list', '--subscription', $id)
    }
}

$results | Format-Table -AutoSize -Wrap | Out-String | Write-Information
$failed = @($results | Where-Object { $_.Result -eq 'FAIL' })
if ($failed.Count -gt 0) {
    throw "$($failed.Count) probe step(s) failed."
}
Write-Information 'All probe steps passed.'
