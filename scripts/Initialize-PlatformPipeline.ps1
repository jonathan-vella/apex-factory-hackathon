#Requires -Version 7.4

<#
.SYNOPSIS
Sets up the GitHub Actions platform pipeline: an identity, its roles and the GitHub environment.
.DESCRIPTION
Run it once, as the platform lead (an admin of your repo, and Owner where the pipeline will deploy), from
the kit folder. It reads .local/settings.json and the repo from the git remote, asks only for what is
missing, and then, in order:
1. optionally creates a sandbox parent management group and moves the subscriptions into it;
2. creates rg-cicd and the user-assigned managed identity id-factory-pipeline in the shared services
   subscription, with one federated credential for the GitHub environment (OIDC, no secret);
3. gives the identity Owner at the deployment parent (Tenant Root, or the sandbox group plus the
   subscriptions) and nowhere else;
4. creates the GitHub environment with a deployment-branch policy and, if the repo's plan allows it, you
   as the required reviewer; sets its variables and the ROSTER_JSON secret, then verifies the result;
5. optionally runs a smoke test workflow that logs in as the identity.
The roles it grants are the pipeline's accepted lab risk: see facilitator/platform-pipeline.md. A re-run
converges. -WhatIf prints what it would create or grant, and changes nothing.
Remove everything again with scripts/Remove-PlatformPipeline.ps1.
.PARAMETER SettingsPath
The settings file. Defaults to .local/settings.json in the kit folder.
.PARAMETER ParentManagementGroupId
Deploy under this management group instead of Tenant Root. The identity then gets Owner there and on the
subscriptions, and no role at Tenant Root. Leave it empty at an event.
.PARAMETER CreateParentManagementGroup
Create the parent group under Tenant Root if it doesn't exist, and move both subscriptions into it.
.PARAMETER Repository
owner/name of the GitHub repo that runs the workflows. Defaults to the git remote.
.PARAMETER Environment
The GitHub environment. Default gh-lab.
.PARAMETER AllowedBranch
Branch name patterns that may deploy to the environment. Default main.
.PARAMETER ReviewerLogin
GitHub user who must approve gated jobs. Defaults to the signed-in gh user.
.PARAMETER NoReviewer
Skip the required reviewer. It is also skipped, with a warning, when the repo's plan doesn't offer it. Then
anyone with write access can run the pipeline.
.PARAMETER DenySettingsPath
A settings file of subscriptions the pipeline must never touch (the guard refuses them), such as a live lab.
.PARAMETER SkipGitHub
Create the Azure side only.
.PARAMETER SmokeTest
Run platform-smoke.yml on the current branch after setup and wait for it.
.PARAMETER AutoApprove
With -SmokeTest, approve the smoke run's environment gate for you (you are the reviewer). Without it, the
script prints the link to approve in the browser.
.EXAMPLE
./scripts/Initialize-PlatformPipeline.ps1 -WhatIf
.EXAMPLE
./scripts/Initialize-PlatformPipeline.ps1 -SettingsPath .local/ci-lab.json -DenySettingsPath .local/settings.json -AllowedBranch 'feat/*' -SmokeTest
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $SettingsPath = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', 'settings.json'),
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $TenantId = '',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId = '',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $WorkloadSubscriptionId = '',
    [string] $Location = '',
    [ValidatePattern('^$|^[A-Za-z0-9-]{2,40}$')]
    [string] $MgPrefix = '',
    [ValidatePattern('^$|^[A-Za-z0-9._()-]{1,90}$')]
    [string] $ParentManagementGroupId = '',
    [switch] $CreateParentManagementGroup,
    [ValidatePattern('^$|^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $Repository = '',
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $Environment = 'gh-lab',
    [string[]] $AllowedBranch = @('main'),
    [string] $ReviewerLogin = '',
    [switch] $NoReviewer,
    [string] $DenySettingsPath = '',
    [int] $MemberIndex = 0,
    [switch] $SkipGitHub,
    [switch] $SmokeTest,
    [switch] $AutoApprove
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$identityName = 'id-factory-pipeline'
$resourceGroupName = 'rg-cicd'
$issuer = 'https://token.actions.githubusercontent.com'

function Invoke-AzureCli {
    param([string[]] $Arguments, [switch] $AllowFailure)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($AllowFailure) { return $null }
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        $detail = ($output | ForEach-Object { $_.ToString() }) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE): $detail"
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Invoke-GitHubCli {
    param([string[]] $Arguments, [string] $Body, [switch] $AllowFailure)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = if ($Body) { $Body | & gh @Arguments 2>&1 } else { & gh @Arguments 2>&1 }
    if ($LASTEXITCODE -ne 0) {
        if ($AllowFailure) { return $null }
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "GitHub CLI '$operation' failed (exit $LASTEXITCODE): $(($output | ForEach-Object { $_.ToString() }) -join ' ')"
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim().StartsWith('{') -or $text.Trim().StartsWith('[')) {
        return $text | ConvertFrom-Json
    }
    return $text
}

function Read-Value {
    param([string] $Current, [string] $Prompt)
    if ($Current) { return $Current }
    if (-not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
        throw "$Prompt is missing. Pass it as a parameter or add it to the settings file."
    }
    return "$(Read-Host $Prompt)".Trim()
}

function Get-Setting {
    param($Settings, [string[]] $Name)
    foreach ($key in $Name) {
        if ($Settings -and $Settings.PSObject.Properties[$key] -and $Settings.$key) { return [string] $Settings.$key }
    }
    return ''
}

# Settings, with parameters winning.
$settings = if (Test-Path $SettingsPath) { Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json } else { $null }
$account = Invoke-AzureCli -Arguments @('account', 'show')
$TenantId = if ($TenantId) { $TenantId } elseif (Get-Setting $settings 'tenantId') { Get-Setting $settings 'tenantId' } else { $account.tenantId }
if ($TenantId -ne $account.tenantId) {
    throw "The signed-in tenant is not the settings tenant. Run: az login --tenant $TenantId"
}
$SharedSubscriptionId = Read-Value ($SharedSubscriptionId ? $SharedSubscriptionId : (Get-Setting $settings 'sharedSubscriptionId')) 'Shared services subscription ID'
$WorkloadSubscriptionId = Read-Value ($WorkloadSubscriptionId ? $WorkloadSubscriptionId : (Get-Setting $settings 'workloadSubscriptionId', 'subscriptionId')) 'Workload subscription ID'
$Location = if ($Location) { $Location } elseif (Get-Setting $settings 'location') { Get-Setting $settings 'location' } else { 'swedencentral' }
$MgPrefix = if ($MgPrefix) { $MgPrefix } elseif (Get-Setting $settings 'mgPrefix') { Get-Setting $settings 'mgPrefix' } else { 'mg-factory' }
$ParentManagementGroupId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { Get-Setting $settings 'sandboxManagementGroup', 'parentManagementGroup' }
if ($MemberIndex -eq 0) {
    $settingIndex = Get-Setting $settings 'memberIndex'
    $MemberIndex = if ($settingIndex) { [int] $settingIndex } else { 1 }
}
if (-not $Repository -and -not $SkipGitHub) {
    $remote = (& git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/]([^/]+/[^/.]+?)(\.git)?$') { $Repository = $Matches[1] }
    $Repository = Read-Value $Repository 'GitHub repository (owner/name)'
}
$parentScopeId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { $TenantId }
$parentScope = "/providers/Microsoft.Management/managementGroups/$parentScopeId"
$sandbox = [bool] $ParentManagementGroupId
$subject = "repo:${Repository}:environment:${Environment}"

$denied = @()
if ($DenySettingsPath -and (Test-Path $DenySettingsPath)) {
    $deny = Get-Content -Raw -Path $DenySettingsPath | ConvertFrom-Json
    $denied = @((Get-Setting $deny 'sharedSubscriptionId'), (Get-Setting $deny 'subscriptionId', 'workloadSubscriptionId') | Where-Object { $_ })
}
if ($denied | Where-Object { $_ -in @($SharedSubscriptionId, $WorkloadSubscriptionId) }) {
    throw 'A subscription for this pipeline is also on the deny list. Refusing.'
}

$callerLogin = (& gh api user --jq .login 2>$null)
$ReviewerLogin = if ($ReviewerLogin) { $ReviewerLogin } else { $callerLogin }

Write-Information @"

Platform pipeline setup:
  Repository         $Repository, environment $Environment, branches: $($AllowedBranch -join ', ')
  Identity           $identityName in $resourceGroupName (shared services subscription), federated credential for
                     $subject
  Owner granted at   $(if ($sandbox) { "management group '$ParentManagementGroupId' and the two subscriptions (not at Tenant Root)" } else { 'the Tenant Root management group' })
  Reviewer           $(if ($NoReviewer) { 'none (-NoReviewer)' } else { $ReviewerLogin })
  Never touched      $($denied.Count) subscription(s) on the deny list
  Management groups  prefix $MgPrefix$(if ($sandbox) { " under '$ParentManagementGroupId'" })

"@

# Subscriptions are in the signed-in tenant.
foreach ($id in $SharedSubscriptionId, $WorkloadSubscriptionId) {
    $sub = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $id)
    if ($sub.tenantId -ne $TenantId) { throw 'A subscription belongs to a different tenant.' }
}
if (-not $SkipGitHub) {
    if (-not ((Invoke-GitHubCli -Arguments @('api', "repos/$Repository", '--jq', '.permissions.admin')) -eq 'true')) {
        throw "gh isn't signed in as an admin of $Repository. Run: gh auth login"
    }
}

# 1. Parent management group.
if ($sandbox) {
    $parent = Invoke-AzureCli -Arguments @('account', 'management-group', 'show', '--name', $ParentManagementGroupId, '--expand') -AllowFailure
    if (-not $parent) {
        if (-not $CreateParentManagementGroup) {
            throw "Management group '$ParentManagementGroupId' doesn't exist. Create it, or pass -CreateParentManagementGroup."
        }
        if ($PSCmdlet.ShouldProcess($ParentManagementGroupId, 'Create the parent management group')) {
            $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'create', '--name', $ParentManagementGroupId, '--display-name', $ParentManagementGroupId)
            $parent = Invoke-AzureCli -Arguments @('account', 'management-group', 'show', '--name', $ParentManagementGroupId, '--expand')
        }
    }
    $present = @($parent.children | ForEach-Object { ($_.id -split '/')[-1] })
    foreach ($id in $SharedSubscriptionId, $WorkloadSubscriptionId) {
        if ($present -contains $id) { continue }
        if ($CreateParentManagementGroup -and $PSCmdlet.ShouldProcess('subscription', "Move into '$ParentManagementGroupId'")) {
            $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'subscription', 'add', '--name', $ParentManagementGroupId, '--subscription', $id)
        }
        elseif (-not $CreateParentManagementGroup) {
            Write-Warning "A subscription is not yet under '$ParentManagementGroupId'. Move it there, or pass -CreateParentManagementGroup."
        }
    }
}

# 2. Resource group, identity, federated credential.
$providerState = Invoke-AzureCli -Arguments @('provider', 'show', '--subscription', $SharedSubscriptionId, '--namespace', 'Microsoft.ManagedIdentity', '--query', 'registrationState')
if ($providerState -ne 'Registered' -and $PSCmdlet.ShouldProcess('Microsoft.ManagedIdentity', 'Register the resource provider')) {
    $null = Invoke-AzureCli -Arguments @('provider', 'register', '--subscription', $SharedSubscriptionId, '--namespace', 'Microsoft.ManagedIdentity', '--wait')
}
$identity = Invoke-AzureCli -Arguments @('identity', 'show', '--subscription', $SharedSubscriptionId, '-g', $resourceGroupName, '-n', $identityName) -AllowFailure
if (-not $identity -and $PSCmdlet.ShouldProcess("$identityName in $resourceGroupName", 'Create the resource group and the managed identity')) {
    $null = Invoke-AzureCli -Arguments @('group', 'create', '--subscription', $SharedSubscriptionId, '-n', $resourceGroupName, '-l', $Location, '--tags', 'purpose=platform-pipeline')
    $identity = Invoke-AzureCli -Arguments @('identity', 'create', '--subscription', $SharedSubscriptionId, '-g', $resourceGroupName, '-n', $identityName, '-l', $Location)
}
if ($identity) {
    $credName = "gh-$Environment"
    $creds = @(Invoke-AzureCli -Arguments @('identity', 'federated-credential', 'list', '--subscription', $SharedSubscriptionId, '-g', $resourceGroupName, '--identity-name', $identityName))
    $current = $creds | Where-Object { $_.name -eq $credName }
    if ($current -and $current.subject -ne $subject) {
        $null = Invoke-AzureCli -Arguments @('identity', 'federated-credential', 'delete', '--subscription', $SharedSubscriptionId, '-g', $resourceGroupName, '--identity-name', $identityName, '--name', $credName, '--yes')
        $current = $null
    }
    if (-not $current -and $PSCmdlet.ShouldProcess($subject, 'Create the federated credential')) {
        $null = Invoke-AzureCli -Arguments @('identity', 'federated-credential', 'create', '--subscription', $SharedSubscriptionId, '-g', $resourceGroupName,
            '--identity-name', $identityName, '--name', $credName, '--issuer', $issuer, '--subject', $subject, '--audiences', 'api://AzureADTokenExchange')
    }
}

# 3. Roles: Owner at the parent, and on both subscriptions when the parent is a sandbox group.
$scopes = @($parentScope)
if ($sandbox) { $scopes += "/subscriptions/$SharedSubscriptionId", "/subscriptions/$WorkloadSubscriptionId" }
if ($identity) {
    foreach ($scope in $scopes) {
        $have = @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $scope, '--role', 'Owner') | Where-Object { $_.principalId -eq $identity.principalId })
        if ($have.Count -gt 0) { continue }
        if ($PSCmdlet.ShouldProcess($scope, 'Grant Owner to the pipeline identity')) {
            $granted = $false
            for ($attempt = 1; $attempt -le 6 -and -not $granted; $attempt++) {
                $result = Invoke-AzureCli -Arguments @('role', 'assignment', 'create', '--assignee-object-id', $identity.principalId,
                    '--assignee-principal-type', 'ServicePrincipal', '--role', 'Owner', '--scope', $scope) -AllowFailure
                if ($result) { $granted = $true } else { Start-Sleep -Seconds 10 }
            }
            if (-not $granted) { throw "Could not grant Owner at $($scope -replace '[0-9a-f-]{36}', '<id>'). Check you hold Owner there." }
        }
    }
}
elseif ($WhatIfPreference) {
    foreach ($scope in $scopes) { Write-Information "What if: Grant Owner to the pipeline identity at $($scope -replace '[0-9a-f-]{36}', '<id>')" }
}
else {
    throw 'The identity does not exist.'
}

# 4. GitHub environment.
if (-not $SkipGitHub) {
    $reviewerId = if (-not $NoReviewer -and $ReviewerLogin) { [int] (Invoke-GitHubCli -Arguments @('api', "users/$ReviewerLogin", '--jq', '.id')) } else { 0 }
    $apiEnv = "repos/$Repository/environments/$Environment"
    if ($PSCmdlet.ShouldProcess("$Repository environment $Environment", 'Create or update the GitHub environment')) {
        $body = @{ deployment_branch_policy = @{ protected_branches = $false; custom_branch_policies = $true } }
        if ($reviewerId) {
            $body.reviewers = @(@{ type = 'User'; id = $reviewerId })
            $body.prevent_self_review = $false
        }
        $created = Invoke-GitHubCli -Arguments @('api', '-X', 'PUT', $apiEnv, '--input', '-') -Body ($body | ConvertTo-Json -Depth 5) -AllowFailure
        if (-not $created -and $reviewerId) {
            Write-Warning "The repository plan doesn't offer required reviewers here. Anyone with write access can run the pipeline; this is the accepted gate for this repo."
            $null = Invoke-GitHubCli -Arguments @('api', '-X', 'PUT', $apiEnv, '--input', '-') -Body (@{ deployment_branch_policy = $body.deployment_branch_policy } | ConvertTo-Json -Depth 5)
            $reviewerId = 0
        }
        elseif (-not $created) { throw 'Could not create the GitHub environment.' }
        $policies = @((Invoke-GitHubCli -Arguments @('api', "$apiEnv/deployment-branch-policies", '--jq', '.branch_policies')) | ForEach-Object { $_.name })
        foreach ($branch in $AllowedBranch) {
            if ($policies -contains $branch) { continue }
            $null = Invoke-GitHubCli -Arguments @('api', '-X', 'POST', "$apiEnv/deployment-branch-policies", '-f', "name=$branch", '-f', 'type=branch')
        }
        $roster = ConvertTo-Json -Compress -InputObject @(@{
                index = $MemberIndex
                subscriptionId = $WorkloadSubscriptionId
                memberPrincipalId = if ($account.user.type -eq 'user') { Invoke-AzureCli -Arguments @('ad', 'signed-in-user', 'show', '--query', 'id') } else { '' }
                budgetEmail = if ($account.user.type -eq 'user') { $account.user.name } else { '' }
            })
        $variables = [ordered]@{
            AZURE_TENANT_ID = $TenantId
            AZURE_CLIENT_ID = $identity.clientId
            SHARED_SUBSCRIPTION_ID = $SharedSubscriptionId
            ALLOWED_SUBSCRIPTIONS = (@($SharedSubscriptionId, $WorkloadSubscriptionId) -join ',')
            LOCATION = $Location
            MG_PREFIX = $MgPrefix
        }
        # A variable can't be empty: leave out what isn't set, and the workflows read a missing one as empty.
        if ($denied) { $variables['DENIED_SUBSCRIPTIONS'] = $denied -join ',' }
        if ($ParentManagementGroupId) { $variables['PARENT_MG'] = $ParentManagementGroupId }
        foreach ($name in $variables.Keys) {
            $null = Invoke-GitHubCli -Arguments @('variable', 'set', $name, '--env', $Environment, '--repo', $Repository, '--body', ([string] $variables[$name]))
        }
        $null = Invoke-GitHubCli -Arguments @('secret', 'set', 'ROSTER_JSON', '--env', $Environment, '--repo', $Repository, '--body', $roster)

        # Verify the final state rather than trusting the calls.
        $state = Invoke-GitHubCli -Arguments @('api', $apiEnv)
        $hasReviewer = [bool] ($state.protection_rules | Where-Object { $_.type -eq 'required_reviewers' })
        if ($reviewerId -and -not $hasReviewer) { throw 'The environment has no required reviewer.' }
        if (-not $state.deployment_branch_policy.custom_branch_policies) { throw 'The environment has no deployment-branch policy.' }
        $haveVars = @(Invoke-GitHubCli -Arguments @('variable', 'list', '--env', $Environment, '--repo', $Repository, '--json', 'name', '--jq', '.[].name')) -split "`n"
        $missing = @($variables.Keys | Where-Object { $_ -notin $haveVars })
        if ($missing) { throw "Missing environment variables: $($missing -join ', ')" }
        Write-Information "GitHub environment verified: $(if ($hasReviewer) { 'reviewer required' } else { 'no reviewer (write access is the gate)' }), branches $($AllowedBranch -join ', '), $($variables.Count) variables, ROSTER_JSON set."
    }
}

# 5. Smoke test.
if ($SmokeTest -and -not $WhatIfPreference -and -not $SkipGitHub) {
    $ref = (& git branch --show-current)
    $null = Invoke-GitHubCli -Arguments @('workflow', 'run', 'platform-smoke.yml', '--repo', $Repository, '--ref', $ref)
    Start-Sleep -Seconds 8
    $run = Invoke-GitHubCli -Arguments @('run', 'list', '--repo', $Repository, '--workflow', 'platform-smoke.yml', '--branch', $ref, '--limit', '1', '--json', 'databaseId,url,status')
    $runId = $run[0].databaseId
    Write-Information "Smoke test: $($run[0].url)"
    $deadline = (Get-Date).AddMinutes(15)
    $approved = $false
    do {
        Start-Sleep -Seconds 10
        $info = Invoke-GitHubCli -Arguments @('run', 'view', "$runId", '--repo', $Repository, '--json', 'status,conclusion')
        if ($info.status -eq 'waiting' -and -not $approved) {
            if ($AutoApprove) {
                $envId = (Invoke-GitHubCli -Arguments @('api', "repos/$Repository/actions/runs/$runId/pending_deployments"))[0].environment.id
                $null = Invoke-GitHubCli -Arguments @('api', '-X', 'POST', "repos/$Repository/actions/runs/$runId/pending_deployments", '--input', '-') `
                    -Body (@{ environment_ids = @($envId); state = 'approved'; comment = 'Approved by Initialize-PlatformPipeline -AutoApprove' } | ConvertTo-Json)
                $approved = $true
            }
            else {
                Write-Information "Waiting for your approval: open the run and review the deployment."
                $approved = $true
            }
        }
    } while ($info.status -ne 'completed' -and (Get-Date) -lt $deadline)
    if ($info.conclusion -ne 'success') { throw "The smoke test did not succeed ($($info.status), $($info.conclusion)). Open the run for the log." }
    Write-Information 'Smoke test passed: the workflow logged in as the pipeline identity.'
}

Write-Information @"

Done. Next:
  gh workflow run platform-smoke.yml --repo $Repository --ref <branch>   (smoke test and permission probe)
To remove everything later: ./scripts/Remove-PlatformPipeline.ps1 (as an admin, after the platform's own teardown).
"@
