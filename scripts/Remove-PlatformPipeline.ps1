#Requires -Version 7.4

<#
.SYNOPSIS
Removes the platform pipeline's identity, its roles and the GitHub environment, then verifies each is gone.
.DESCRIPTION
The finalizer for scripts/Initialize-PlatformPipeline.ps1. Run it last, as a separate admin (Owner where
the roles were granted, admin of the repo), after the platform's own teardown. It never runs as the
pipeline identity: an identity can't reliably remove the roles it runs with. In order it:
1. removes the identity's Owner role assignments at the parent management group, Tenant Root and both
   subscriptions;
2. deletes the federated credential and the identity, then rg-cicd (only if nothing else is in it);
3. deletes the GitHub environment with its variables and secrets, and the repository variables MEMBER_INDEXES and PIPELINE_PROFILE;
4. verifies with queries that each is gone, and reports anything left.
It prompts once before changing anything; -Force skips the prompt and -WhatIf only prints the plan. It
does not delete subscriptions, the sandbox group or anything the pipeline deployed: use
Remove-FactoryEnvironment.ps1 for that.
.PARAMETER SettingsPath
The settings file. Defaults to .local/settings.json in the kit folder.
.PARAMETER ParentManagementGroupId
The parent used at setup. Empty means Tenant Root.
.PARAMETER Repository
owner/name of the GitHub repo. Defaults to the git remote.
.PARAMETER Environment
The GitHub environment. Default gh-lab.
.PARAMETER PipelineProfile
Lead (default) or Member. Member removes the identity that Initialize-PlatformPipeline.ps1 -Profile Member created in your
own workload subscription (its Owner role, rg-cicd) and your repo's gh-lab environment.
.PARAMETER SkipGitHub
Remove the Azure side only.
.PARAMETER Force
Skip the confirmation prompt.
.EXAMPLE
./scripts/Remove-PlatformPipeline.ps1 -WhatIf
.EXAMPLE
./scripts/Remove-PlatformPipeline.ps1 -SettingsPath .local/ci-lab.json -Force
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string] $SettingsPath = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', 'settings.json'),
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId = '',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $WorkloadSubscriptionId = '',
    [ValidatePattern('^$|^[A-Za-z0-9._()-]{1,90}$')]
    [string] $ParentManagementGroupId = '',
    [ValidatePattern('^$|^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $Repository = '',
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $Environment = 'gh-lab',
    [switch] $SkipGitHub,
    [Alias('Profile')]
    [ValidateSet('Lead', 'Member')]
    [string] $PipelineProfile = 'Lead',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$identityName = 'id-factory-pipeline'
$resourceGroupName = 'rg-cicd'
$repositoryVariables = @('MEMBER_INDEXES', 'PIPELINE_PROFILE')

function Invoke-AzureCli {
    param([string[]] $Arguments, [switch] $AllowFailure)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($AllowFailure) { return $null }
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE): $(($output | ForEach-Object { $_.ToString() }) -join ' ')"
    }
    $text = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Get-Setting {
    param($Settings, [string[]] $Name)
    foreach ($key in $Name) {
        if ($Settings -and $Settings.PSObject.Properties[$key] -and $Settings.$key) { return [string] $Settings.$key }
    }
    return ''
}

$settings = if (Test-Path $SettingsPath) { Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json } else { $null }
$account = Invoke-AzureCli -Arguments @('account', 'show')
$tenantId = $account.tenantId
$SharedSubscriptionId = if ($SharedSubscriptionId) { $SharedSubscriptionId } else { Get-Setting $settings 'sharedSubscriptionId' }
$WorkloadSubscriptionId = if ($WorkloadSubscriptionId) { $WorkloadSubscriptionId } else { Get-Setting $settings 'workloadSubscriptionId', 'subscriptionId' }
$ParentManagementGroupId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { Get-Setting $settings 'sandboxManagementGroup', 'parentManagementGroup' }
$memberProfile = $PipelineProfile -eq 'Member'
if ($memberProfile) {
    # A member's identity lives in their own workload subscription and holds Owner there only.
    $SharedSubscriptionId = ''
    $ParentManagementGroupId = ''
    if (-not $WorkloadSubscriptionId) { throw 'The workload subscription is missing. Pass -WorkloadSubscriptionId or fix the settings file.' }
    $identitySubscription = $WorkloadSubscriptionId
}
else {
    if (-not $SharedSubscriptionId) { throw 'The shared services subscription is missing. Pass -SharedSubscriptionId or fix the settings file.' }
    $identitySubscription = $SharedSubscriptionId
}
if (-not $Repository -and -not $SkipGitHub) {
    $remote = (& git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/]([^/]+/[^/.]+?)(\.git)?$') { $Repository = $Matches[1] }
    if (-not $Repository) { throw 'Pass -Repository owner/name.' }
}

$scopes = [System.Collections.Generic.List[string]]::new()
if ($memberProfile) {
    $scopes.Add("/subscriptions/$WorkloadSubscriptionId")
}
else {
    $scopes.Add("/providers/Microsoft.Management/managementGroups/$tenantId")
    if ($ParentManagementGroupId) { $scopes.Add("/providers/Microsoft.Management/managementGroups/$ParentManagementGroupId") }
    $scopes.Add("/subscriptions/$SharedSubscriptionId")
    if ($WorkloadSubscriptionId) { $scopes.Add("/subscriptions/$WorkloadSubscriptionId") }
}

$identity = Invoke-AzureCli -Arguments @('identity', 'show', '--subscription', $identitySubscription, '-g', $resourceGroupName, '-n', $identityName) -AllowFailure
$plan = [System.Collections.Generic.List[string]]::new()
if ($identity) {
    foreach ($scope in $scopes) {
        $found = @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $scope) -AllowFailure | Where-Object { $_.principalId -eq $identity.principalId })
        foreach ($ra in $found) { $plan.Add("Remove role '$($ra.roleDefinitionName)' at $($scope -replace '[0-9a-f-]{36}', '<id>')") }
    }
    $plan.Add("Delete the identity $identityName and its federated credentials")
}
$rgContent = @(Invoke-AzureCli -Arguments @('resource', 'list', '--subscription', $identitySubscription, '-g', $resourceGroupName) -AllowFailure)
if ((Invoke-AzureCli -Arguments @('group', 'exists', '--subscription', $identitySubscription, '-n', $resourceGroupName)) -eq $true) {
    $extra = @($rgContent | Where-Object { $_.name -ne $identityName })
    if ($extra.Count -gt 0) { $plan.Add("Keep $resourceGroupName ($($extra.Count) other resource(s) in it)") } else { $plan.Add("Delete the resource group $resourceGroupName") }
}
if (-not $SkipGitHub) { $plan.Add("Delete the GitHub environment $Environment on $Repository, with its variables and secrets, and the repository variables MEMBER_INDEXES and PIPELINE_PROFILE") }

Write-Information "Plan:`n  $($plan -join "`n  ")"
if ($WhatIfPreference) { Write-Information 'WhatIf: nothing was changed.'; return }
if ($plan.Count -eq 0) { return }
if (-not $Force -and -not $PSCmdlet.ShouldContinue('Remove the pipeline identity, its roles and the GitHub environment?', 'Remove-PlatformPipeline')) { return }

if ($identity) {
    foreach ($scope in $scopes) {
        foreach ($ra in @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $scope) -AllowFailure | Where-Object { $_.principalId -eq $identity.principalId })) {
            $null = Invoke-AzureCli -Arguments @('role', 'assignment', 'delete', '--ids', $ra.id)
        }
    }
    $null = Invoke-AzureCli -Arguments @('identity', 'delete', '--subscription', $identitySubscription, '-g', $resourceGroupName, '-n', $identityName)
}
if ((Invoke-AzureCli -Arguments @('group', 'exists', '--subscription', $identitySubscription, '-n', $resourceGroupName)) -eq $true) {
    $left = @(Invoke-AzureCli -Arguments @('resource', 'list', '--subscription', $identitySubscription, '-g', $resourceGroupName))
    if ($left.Count -eq 0) {
        $null = Invoke-AzureCli -Arguments @('group', 'delete', '--subscription', $identitySubscription, '-n', $resourceGroupName, '--yes')
    }
}
if (-not $SkipGitHub) {
    $PSNativeCommandUseErrorActionPreference = $false
    & gh api -X DELETE "repos/$Repository/environments/$Environment" 2>$null | Out-Null
    foreach ($variable in $repositoryVariables) { & gh variable delete $variable --repo $Repository 2>$null | Out-Null }
}

# Verify.
$problems = [System.Collections.Generic.List[string]]::new()
if (Invoke-AzureCli -Arguments @('identity', 'show', '--subscription', $identitySubscription, '-g', $resourceGroupName, '-n', $identityName) -AllowFailure) { $problems.Add('The identity still exists.') }
if ((Invoke-AzureCli -Arguments @('group', 'exists', '--subscription', $identitySubscription, '-n', $resourceGroupName)) -eq $true) { $problems.Add("$resourceGroupName still exists.") }
if ($identity) {
    foreach ($scope in $scopes) {
        if (@(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $scope) -AllowFailure | Where-Object { $_.principalId -eq $identity.principalId }).Count -gt 0) {
            $problems.Add("A role assignment for the identity remains at $($scope -replace '[0-9a-f-]{36}', '<id>').")
        }
    }
}
if (-not $SkipGitHub) {
    & gh api "repos/$Repository/environments/$Environment" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $problems.Add("The GitHub environment $Environment still exists.") }
    foreach ($variable in $repositoryVariables) {
        & gh api "repos/$Repository/actions/variables/$variable" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $problems.Add("The repository variable $variable still exists.") }
    }
}
if ($problems.Count -gt 0) { throw "Not everything was removed:`n  $($problems -join "`n  ")" }
Write-Information 'Verified: the identity, its roles, rg-cicd, the GitHub environment and the repository variables are gone.'
