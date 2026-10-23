#Requires -Version 7.4

<#
.SYNOPSIS
Checks that the platform pipeline is set up, and says how to fix what isn't. Read-only.
.DESCRIPTION
The doctor for scripts/Initialize-PlatformPipeline.ps1, which runs it last. It checks, in order: your
sign-ins, the managed identity and its federated credential (against the subject your repo really presents),
the identity's Owner roles, the workflows in the repo, and the GitHub environment (reviewer, branch policy,
variables, secrets). Each row is PASS, WARN or FAIL, with a fix for every FAIL. It changes nothing and never
prints an ID. It can't prove the OIDC login itself: run the smoke test for that.
.PARAMETER SettingsPath
The settings file. Defaults to .local/settings.json in the kit folder.
.PARAMETER ParentManagementGroupId
The parent used at setup. Empty means Tenant Root.
.PARAMETER Repository
owner/name of the GitHub repo. Defaults to the git remote.
.PARAMETER Environment
The GitHub environment. Default gh-lab.
.PARAMETER PipelineProfile
Lead (default) or Member: which pipeline to check. Member looks for the identity in your own workload subscription and
for Owner on that subscription only.
.EXAMPLE
./scripts/Test-PipelineSetup.ps1
.EXAMPLE
./scripts/Test-PipelineSetup.ps1 -PipelineProfile Member
#>

[CmdletBinding()]
param(
    [string] $SettingsPath = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', 'settings.json'),
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId = '',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $WorkloadSubscriptionId = '',
    [string[]] $WorkloadSubscriptionIds = @(),
    [ValidatePattern('^$|^[A-Za-z0-9._()-]{1,90}$')]
    [string] $ParentManagementGroupId = '',
    [ValidatePattern('^$|^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $Repository = '',
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $Environment = 'gh-lab',
    [Alias('Profile')]
    [ValidateSet('Lead', 'Member')]
    [string] $PipelineProfile = 'Lead'
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$environmentName = $Environment
$workloadList = $WorkloadSubscriptionIds
$identityName = 'id-factory-pipeline'
$resourceGroupName = 'rg-cicd'
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string] $Check, [ValidateSet('PASS', 'WARN', 'FAIL')] [string] $Status, [string] $Reason, [string] $Fix = '')
    $results.Add([pscustomobject]@{ Check = $Check; Status = $Status; Reason = $Reason; Fix = $Fix })
}

function Invoke-AzureCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Azure CLI call failed.' }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) { return $text | ConvertFrom-Json }
}

function Invoke-GitHubCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & gh @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'GitHub CLI call failed.' }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim().StartsWith('{') -or $text.Trim().StartsWith('[')) { return $text | ConvertFrom-Json }
    return $text
}

function Invoke-Check {
    param([string] $Name, [scriptblock] $Action, [string] $Fix)
    try { & $Action }
    catch { Add-Result -Check $Name -Status FAIL -Reason $_.Exception.Message -Fix $Fix }
}

function Get-Setting {
    param($Settings, [string[]] $Name)
    foreach ($key in $Name) {
        if ($Settings -and $Settings.PSObject.Properties[$key] -and $Settings.$key) { return [string] $Settings.$key }
    }
    return ''
}

$settings = if (Test-Path $SettingsPath) { Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json } else { $null }
$SharedSubscriptionId = if ($SharedSubscriptionId) { $SharedSubscriptionId } else { Get-Setting $settings 'sharedSubscriptionId' }
$WorkloadSubscriptionId = if ($WorkloadSubscriptionId) { $WorkloadSubscriptionId } else { Get-Setting $settings 'workloadSubscriptionId', 'subscriptionId' }
$ParentManagementGroupId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { Get-Setting $settings 'sandboxManagementGroup', 'parentManagementGroup' }
if (-not $Repository) {
    $remote = (& git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/]([^/]+/[^/.]+?)(\.git)?$') { $Repository = $Matches[1] }
}
$tenantId = ''
$identity = $null
$memberProfile = $PipelineProfile -eq 'Member'
# The identity lives in the shared services subscription for the platform lead, in your own workload subscription for a member.
$identitySubscription = if ($memberProfile) { $WorkloadSubscriptionId } else { $SharedSubscriptionId }
$identityWhere = if ($memberProfile) { 'workload' } else { 'shared services' }

Invoke-Check -Name 'Azure sign-in' -Fix 'Run az login in the tenant, then az account set --subscription <subscription-id>.' -Action {
    $account = Invoke-AzureCli @('account', 'show')
    $script:tenantId = $account.tenantId
    if (-not $identitySubscription) { throw "The $identityWhere subscription is not in the settings. Run Initialize-Settings.ps1 or pass it as a parameter." }
    $sub = Invoke-AzureCli @('account', 'show', '--subscription', $identitySubscription)
    if ($sub.tenantId -ne $tenantId) { throw "The $identityWhere subscription is in another tenant." }
    Add-Result -Check 'Azure sign-in' -Status PASS -Reason "Signed in, and the $identityWhere subscription is in the tenant."
}

Invoke-Check -Name 'GitHub sign-in' -Fix 'Run gh auth login as an admin of the repo.' -Action {
    if (-not $Repository) { throw 'No repository: pass -Repository owner/name or set a git remote.' }
    if (-not ((Invoke-GitHubCli @('api', "repos/$Repository", '--jq', '.permissions.admin')) -eq 'true')) { throw 'gh is not signed in as an admin of the repo.' }
    Add-Result -Check 'GitHub sign-in' -Status PASS -Reason 'gh is signed in as an admin of the repo.'
}

Invoke-Check -Name 'Managed identity' -Fix 'Run ./scripts/Initialize-PlatformPipeline.ps1.' -Action {
    $script:identity = Invoke-AzureCli @('identity', 'show', '--subscription', $identitySubscription, '-g', $resourceGroupName, '-n', $identityName)
    if (-not $identity) { throw "$identityName is missing in $resourceGroupName." }
    Add-Result -Check 'Managed identity' -Status PASS -Reason "$identityName exists in $resourceGroupName."
}

Invoke-Check -Name 'Federated credential' -Fix 'Run ./scripts/Initialize-PlatformPipeline.ps1: it rebuilds the credential from the subject the repo presents.' -Action {
    $oidc = Invoke-GitHubCli @('api', "repos/$Repository/actions/oidc/customization/sub")
    if ($oidc.use_default -eq $false) { throw 'The repo customizes its OIDC subject claim. Reset it to the default.' }
    $prefix = if ($oidc.sub_claim_prefix) { $oidc.sub_claim_prefix } else { "repo:$Repository" }
    $expected = "${prefix}:environment:${environmentName}"
    $creds = @(Invoke-AzureCli @('identity', 'federated-credential', 'list', '--subscription', $identitySubscription, '-g', $resourceGroupName, '--identity-name', $identityName))
    if (-not ($creds | Where-Object { $_.subject -eq $expected -and $_.issuer -eq 'https://token.actions.githubusercontent.com' })) {
        throw 'No federated credential matches this repo and environment.'
    }
    Add-Result -Check 'Federated credential' -Status PASS -Reason 'A credential matches the subject the repo presents.'
}

Invoke-Check -Name 'Roles' -Fix 'Run ./scripts/Initialize-PlatformPipeline.ps1 as an Owner where the pipeline will deploy.' -Action {
    if (-not $identity) { throw 'The identity is missing, so its roles can''t be checked.' }
    if ($memberProfile) {
        $scopes = @("/subscriptions/$WorkloadSubscriptionId")
    }
    else {
        $parentScopeId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { $tenantId }
        $scopes = @("/providers/Microsoft.Management/managementGroups/$parentScopeId")
        if ($ParentManagementGroupId) {
            $scopes += "/subscriptions/$SharedSubscriptionId"
            $members = if ($workloadList) { $workloadList } elseif ($WorkloadSubscriptionId) { @($WorkloadSubscriptionId) } else { @() }
            $scopes += @($members | ForEach-Object { "/subscriptions/$_" })
        }
    }
    $missing = 0
    foreach ($scope in $scopes) {
        $have = @(Invoke-AzureCli @('role', 'assignment', 'list', '--scope', $scope, '--role', 'Owner') | Where-Object { $_.principalId -eq $identity.principalId })
        if ($have.Count -eq 0) { $missing++ }
    }
    if ($missing -gt 0) { throw "The identity lacks Owner at $missing of $($scopes.Count) scope(s)." }
    $where = if ($memberProfile) { 'your workload subscription only' } elseif ($ParentManagementGroupId) { 'the sandbox group and the subscriptions' } else { 'Tenant Root' }
    Add-Result -Check 'Roles' -Status PASS -Reason "The identity is Owner at $($scopes.Count) scope(s): $where."
}

Invoke-Check -Name 'Workflows' -Fix 'In an imported repo, run Import-Kit.ps1 again (-Force); it installs them. Then commit and push to the default branch.' -Action {
    $root = (& git rev-parse --show-toplevel 2>$null)
    if (-not $root) { throw 'Not inside a git repo.' }
    $missing = @('platform.yml') | Where-Object { -not (Test-Path (Join-Path $root ".github/workflows/$_")) }
    foreach ($action in 'guard', 'platform-session') {
        if (-not (Test-Path (Join-Path $root ".github/actions/$action/action.yml"))) { $missing += "the $action action" }
    }
    if ($missing) { throw "Missing in .github: $($missing -join ', ')." }
    Add-Result -Check 'Workflows' -Status PASS -Reason 'platform.yml and its guard and session actions are in .github.'
}

Invoke-Check -Name 'GitHub environment' -Fix 'Run ./scripts/Initialize-PlatformPipeline.ps1.' -Action {
    $state = Invoke-GitHubCli @('api', "repos/$Repository/environments/$environmentName")
    if (-not $state.deployment_branch_policy.custom_branch_policies) { throw 'The environment has no deployment-branch policy.' }
    $branches = @((Invoke-GitHubCli @('api', "repos/$Repository/environments/$environmentName/deployment-branch-policies", '--jq', '.branch_policies[].name')) -split "`n" | Where-Object { $_ })
    if ($branches.Count -eq 0) { throw 'No branch may deploy to the environment.' }
    $vars = @((Invoke-GitHubCli @('variable', 'list', '--env', $environmentName, '--repo', $Repository, '--json', 'name', '--jq', '.[].name')) -split "`n")
    $secrets = @((Invoke-GitHubCli @('secret', 'list', '--env', $environmentName, '--repo', $Repository, '--json', 'name', '--jq', '.[].name')) -split "`n")
    $needSecrets = @('AZURE_TENANT_ID', 'AZURE_CLIENT_ID', 'ALLOWED_SUBSCRIPTIONS', 'ROSTER_JSON')
    if (-not $memberProfile) { $needSecrets += 'SHARED_SUBSCRIPTION_ID' }
    $missing = @('LOCATION', 'MG_PREFIX' | Where-Object { $_ -notin $vars }) + @($needSecrets | Where-Object { $_ -notin $secrets })
    $repoVars = @((Invoke-GitHubCli @('variable', 'list', '--repo', $Repository, '--json', 'name', '--jq', '.[].name')) -split "`n")
    foreach ($repoVar in 'MEMBER_INDEXES', 'PIPELINE_PROFILE') { if ($repoVar -notin $repoVars) { $missing += "$repoVar (repository variable)" } }
    if ($missing) { throw "Missing: $($missing -join ', ')." }
    Add-Result -Check 'GitHub environment' -Status PASS -Reason "Branch policy ($($branches -join ', ')), variables and secrets are set."
    if ([bool] ($state.protection_rules | Where-Object { $_.type -eq 'required_reviewers' })) {
        Add-Result -Check 'Reviewer gate' -Status PASS -Reason 'A required reviewer approves every run.'
    }
    else {
        Add-Result -Check 'Reviewer gate' -Status WARN -Reason 'No required reviewer: anyone with write access can run the pipeline. This is the accepted gate for a private repo on a plan without reviewers.' -Fix 'On a public repo or a paid plan, run Initialize-PlatformPipeline.ps1 again without -NoReviewer.'
    }
}

$results | Format-Table -Property Check, Status, Reason -AutoSize -Wrap | Out-String | Write-Information
$failed = @($results | Where-Object { $_.Status -eq 'FAIL' })
foreach ($warning in @($results | Where-Object { $_.Status -eq 'WARN' })) { Write-Information "WARN $($warning.Check): $($warning.Fix)" }
if ($failed.Count -gt 0) {
    Write-Information "NOT READY: $($failed.Count) failure(s). Fix them in order, then run this again."
    foreach ($f in $failed) { Write-Information "  $($f.Check): $($f.Fix)" }
    exit 1
}
Write-Information 'READY. Run the first check: gh workflow run platform.yml -f stage=whatif   (then approve it in the Actions tab if GitHub asks)'
exit 0
