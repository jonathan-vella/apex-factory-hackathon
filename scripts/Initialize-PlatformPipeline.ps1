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
Its management-group prefix (mgPrefix, default mg-factory) is denied too, unless -DeniedMgPrefix says otherwise.
.PARAMETER DeniedMgPrefix
Management-group prefixes the guard refuses.
.PARAMETER RosterPath
The team's roster, JSON or CSV: one row per member with index, subscriptionId, memberPrincipalId and budgetEmail (or the
event owner's headings: Member index, Workload subscription ID, Entra object ID, Budget email). A team has one shared
services subscription and one workload subscription per member, so list every member. Without it, the settings hold one
member. The roster goes into an environment secret, never into the repo. The object ID and address are only needed for
vending, so you can run this again with the full roster in C2.
.PARAMETER PipelineProfile
Lead (default) sets up the platform lead pipeline: the identity lives in the shared services subscription and the
roster covers the team. Member (-Profile Member) sets up your own C0 pipeline in your own repo: the identity lives in your
workload subscription and is Owner there only; there is no shared subscription, management group or roster. Run it from
your own repo, with your own az login and gh login.
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
    [string[]] $DeniedMgPrefix = @(),
    [int] $MemberIndex = 0,
    [string] $RosterPath = '',
    [switch] $SkipGitHub,
    [Alias('Profile')]
    [ValidateSet('Lead', 'Member')]
    [string] $PipelineProfile = 'Lead',
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
$member0Profile = $PipelineProfile -eq 'Member'
if ($member0Profile) {
    # A member's pipeline has no shared services subscription, no management groups and no roster.
    $SharedSubscriptionId = ''
    $ParentManagementGroupId = ''
    if ($RosterPath) { throw '-PipelineProfile Member covers one member (you). A roster is for the platform lead profile.' }
}
else {
    $SharedSubscriptionId = Read-Value ($SharedSubscriptionId ? $SharedSubscriptionId : (Get-Setting $settings 'sharedSubscriptionId')) 'Shared services subscription ID'
}
$WorkloadSubscriptionId = if ($WorkloadSubscriptionId) { $WorkloadSubscriptionId } else { Get-Setting $settings 'workloadSubscriptionId', 'subscriptionId' }
$Location = if ($Location) { $Location } elseif (Get-Setting $settings 'location') { Get-Setting $settings 'location' } else { 'swedencentral' }
$MgPrefix = if ($MgPrefix) { $MgPrefix } elseif (Get-Setting $settings 'mgPrefix') { Get-Setting $settings 'mgPrefix' } else { 'mg-factory' }
$ParentManagementGroupId = if ($member0Profile) { '' } elseif ($ParentManagementGroupId) { $ParentManagementGroupId } else { Get-Setting $settings 'sandboxManagementGroup', 'parentManagementGroup' }
if ($MemberIndex -eq 0) {
    $settingIndex = Get-Setting $settings 'memberIndex'
    $MemberIndex = if ($settingIndex) { [int] $settingIndex } else { 1 }
}

# The team's members: one workload subscription each. A roster file lists them all (JSON or CSV, with the event owner's
# column names); without one, the settings hold a single member.
function Import-Roster {
    param([string] $Path)
    $raw = Get-Content -Raw -Path $Path
    $rows = if ($Path -match '\.csv$') { @($raw | ConvertFrom-Csv) } else { @($raw | ConvertFrom-Json) }
    foreach ($row in $rows) {
        $pick = {
            param($Names)
            foreach ($name in $Names) {
                $property = $row.PSObject.Properties | Where-Object { $_.Name -ieq $name } | Select-Object -First 1
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

$members = if ($RosterPath) {
    @(Import-Roster -Path $RosterPath)
}
else {
    $WorkloadSubscriptionId = Read-Value $WorkloadSubscriptionId 'Workload subscription ID'
    # Your object ID comes from the ARM token, so no Microsoft Graph call is needed (and none can be challenged).
    $callerOid = ''
    if ($account.user.type -ne 'servicePrincipal') {
        $armToken = Invoke-AzureCli -Arguments @('account', 'get-access-token', '--resource', 'https://management.azure.com/', '--query', 'accessToken')
        $tokenPayload = $armToken.Split('.')[1].Replace('-', '+').Replace('_', '/')
        $tokenPayload += '=' * ((4 - $tokenPayload.Length % 4) % 4)
        $callerOid = ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($tokenPayload)) | ConvertFrom-Json).oid
    }
    @([pscustomobject]@{
            index = $MemberIndex
            subscriptionId = $WorkloadSubscriptionId
            memberPrincipalId = $callerOid
            budgetEmail = if ($callerOid) { $account.user.name } else { '' }
        })
}
if ($members.Count -eq 0 -or $members.Count -gt 20) { throw 'A team has 1 to 20 members.' }
$guidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
foreach ($member in $members) {
    if ($member.index -lt 1 -or $member.index -gt 20) { throw 'Every member needs an index from 1 to 20.' }
    if ($member.subscriptionId -notmatch $guidPattern) { throw "Member $($member.index) has no valid workload subscription ID." }
    if ($member.subscriptionId -eq $SharedSubscriptionId) { throw "Member $($member.index) uses the shared services subscription: each member needs a workload subscription of their own." }
}
if (@($members.index | Sort-Object -Unique).Count -ne $members.Count) { throw 'Two members share an index. Each index sets the address ranges, so they must differ.' }
if (@($members.subscriptionId | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique).Count -ne $members.Count) { throw 'Two members share a workload subscription.' }
$workloadIds = @($members.subscriptionId)
# The identity lives where the pipeline's own resources go: the shared services subscription for the platform lead,
# the member's own workload subscription for a member.
$identitySubscription = if ($member0Profile) { $workloadIds[0] } else { $SharedSubscriptionId }
if (-not $Repository -and -not $SkipGitHub) {
    $remote = (& git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/]([^/]+/[^/.]+?)(\.git)?$') { $Repository = $Matches[1] }
    $Repository = Read-Value $Repository 'GitHub repository (owner/name)'
}
$parentScopeId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { $TenantId }
$parentScope = "/providers/Microsoft.Management/managementGroups/$parentScopeId"
$sandbox = [bool] $ParentManagementGroupId
$subjectPrefix = "repo:$Repository"
if (-not $SkipGitHub) {
    # GitHub may issue immutable subject claims (repo:owner@id/repo@id), so ask the repo what it will present.
    $oidc = Invoke-GitHubCli -Arguments @('api', "repos/$Repository/actions/oidc/customization/sub") -AllowFailure
    if ($oidc -and $oidc.use_default -eq $false) {
        throw "The repo customizes its OIDC subject claim ($($oidc.include_claim_keys -join ', ')). Reset it to the default: gh api -X PUT repos/$Repository/actions/oidc/customization/sub -F use_default=true"
    }
    if ($oidc -and $oidc.sub_claim_prefix) { $subjectPrefix = $oidc.sub_claim_prefix }
}
$subject = "${subjectPrefix}:environment:${Environment}"

$denied = @()
if ($DenySettingsPath -and (Test-Path $DenySettingsPath)) {
    $deny = Get-Content -Raw -Path $DenySettingsPath | ConvertFrom-Json
    $denied = @((Get-Setting $deny 'sharedSubscriptionId'), (Get-Setting $deny 'subscriptionId', 'workloadSubscriptionId') | Where-Object { $_ })
    if (-not $DeniedMgPrefix) { $DeniedMgPrefix = @(if (Get-Setting $deny 'mgPrefix') { Get-Setting $deny 'mgPrefix' } else { 'mg-factory' }) }
}
if ($DeniedMgPrefix -contains $MgPrefix) { throw 'The management-group prefix is on the deny list. Refusing.' }
if ($denied | Where-Object { $_ -in (@($SharedSubscriptionId) + $workloadIds) }) {
    throw 'A subscription for this pipeline is also on the deny list. Refusing.'
}

$callerLogin = (& gh api user --jq .login 2>$null)
$ReviewerLogin = if ($ReviewerLogin) { $ReviewerLogin } else { $callerLogin }

Write-Information @"

Platform pipeline setup ($PipelineProfile profile):
  Repository         $Repository, environment $Environment, branches: $($AllowedBranch -join ', ')
  Identity           $identityName in $resourceGroupName ($(if ($member0Profile) { 'your own workload subscription' } else { 'shared services subscription' })), federated credential for
                     $subject
  Owner granted at   $(if ($member0Profile) { 'your workload subscription only: no management group, no other subscription' } elseif ($sandbox) { "management group '$ParentManagementGroupId', the shared services subscription and $($workloadIds.Count) workload subscription(s) (not at Tenant Root)" } else { 'the Tenant Root management group' })
  Members            $($members.Count) (indexes $($members.index -join ', ')); $(if ($member0Profile) { 'just you' } else { 'one workload subscription each, one shared services subscription for the team' })
  Reviewer           $(if ($NoReviewer) { 'none (-NoReviewer)' } else { $ReviewerLogin })
  Never touched      $($denied.Count) subscription(s) on the deny list
$(if (-not $member0Profile) { "  Management groups  prefix $MgPrefix$(if ($sandbox) { " under '$ParentManagementGroupId'" })" })

"@

# Subscriptions are in the signed-in tenant.
foreach ($id in @(@($SharedSubscriptionId) + $workloadIds | Where-Object { $_ })) {
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
    # Subscriptions that ALZ-lite and vending already moved into the kit's child groups still count as placed.
    $parent = Invoke-AzureCli -Arguments @('account', 'management-group', 'show', '--name', $ParentManagementGroupId, '--expand', '--recurse') -AllowFailure
    $present = [System.Collections.Generic.List[string]]::new()
    $queue = [System.Collections.Generic.Queue[object]]::new()
    if ($parent) { $queue.Enqueue($parent) }
    while ($queue.Count -gt 0) {
        foreach ($child in @($queue.Dequeue().children | Where-Object { $_ })) {
            if ($child.type -like '*subscriptions') { $present.Add(($child.id -split '/')[-1]) } else { $queue.Enqueue($child) }
        }
    }
    foreach ($id in @($SharedSubscriptionId) + $workloadIds) {
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
$providerState = Invoke-AzureCli -Arguments @('provider', 'show', '--subscription', $identitySubscription, '--namespace', 'Microsoft.ManagedIdentity', '--query', 'registrationState')
if ($providerState -ne 'Registered' -and $PSCmdlet.ShouldProcess('Microsoft.ManagedIdentity', 'Register the resource provider')) {
    $null = Invoke-AzureCli -Arguments @('provider', 'register', '--subscription', $identitySubscription, '--namespace', 'Microsoft.ManagedIdentity', '--wait')
}
$identity = Invoke-AzureCli -Arguments @('identity', 'show', '--subscription', $identitySubscription, '-g', $resourceGroupName, '-n', $identityName) -AllowFailure
if (-not $identity -and $PSCmdlet.ShouldProcess("$identityName in $resourceGroupName", 'Create the resource group and the managed identity')) {
    $null = Invoke-AzureCli -Arguments @('group', 'create', '--subscription', $identitySubscription, '-n', $resourceGroupName, '-l', $Location, '--tags', 'purpose=platform-pipeline')
    $identity = Invoke-AzureCli -Arguments @('identity', 'create', '--subscription', $identitySubscription, '-g', $resourceGroupName, '-n', $identityName, '-l', $Location)
}
if ($identity) {
    $credName = "gh-$($Repository -replace '[^A-Za-z0-9_-]', '-')-$Environment"
    if ($credName.Length -gt 120) { $credName = $credName.Substring(0, 120) }
    $creds = @(Invoke-AzureCli -Arguments @('identity', 'federated-credential', 'list', '--subscription', $identitySubscription, '-g', $resourceGroupName, '--identity-name', $identityName))
    $current = $creds | Where-Object { $_.subject -eq $subject -and $_.issuer -eq $issuer } | Select-Object -First 1
    $stale = $creds | Where-Object { $_.name -eq $credName -and -not ($_.subject -eq $subject -and $_.issuer -eq $issuer) }
    if ($stale) {
        $null = Invoke-AzureCli -Arguments @('identity', 'federated-credential', 'delete', '--subscription', $identitySubscription, '-g', $resourceGroupName, '--identity-name', $identityName, '--name', $credName, '--yes')
    }
    if (-not $current -and $PSCmdlet.ShouldProcess($subject, 'Create the federated credential')) {
        $null = Invoke-AzureCli -Arguments @('identity', 'federated-credential', 'create', '--subscription', $identitySubscription, '-g', $resourceGroupName,
            '--identity-name', $identityName, '--name', $credName, '--issuer', $issuer, '--subject', $subject, '--audiences', 'api://AzureADTokenExchange')
    }
}

# 3. Roles. Platform lead: Owner at the parent (Tenant Root, or the sandbox group plus every subscription). Member: Owner on
# their own workload subscription and nowhere else.
$scopes = @(if ($member0Profile) { "/subscriptions/$($workloadIds[0])" } else { $parentScope })
if ($sandbox) { $scopes += "/subscriptions/$SharedSubscriptionId"; $scopes += @($workloadIds | ForEach-Object { "/subscriptions/$_" }) }
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
        # Every member's subscription, index and, for vending, object ID and budget address. The workflows read it
        # inside a gated job: a secret can't feed a job matrix.
        $roster = ConvertTo-Json -Compress -InputObject @($members | ForEach-Object {
                @{ index = $_.index; subscriptionId = $_.subscriptionId; memberPrincipalId = $_.memberPrincipalId; budgetEmail = $_.budgetEmail }
            })
        # Identifiers are secrets, not variables: a public repo's workflow logs print variables, and secrets are masked.
        $secrets = [ordered]@{
            AZURE_TENANT_ID = $TenantId
            AZURE_CLIENT_ID = $identity.clientId
            ALLOWED_SUBSCRIPTIONS = (@($SharedSubscriptionId) + $workloadIds | Where-Object { $_ }) -join ','
            ROSTER_JSON = $roster
        }
        if (-not $member0Profile) { $secrets['SHARED_SUBSCRIPTION_ID'] = $SharedSubscriptionId }
        $variables = [ordered]@{
            LOCATION = $Location
            MG_PREFIX = $MgPrefix
        }
        # A value can't be empty: leave out what isn't set, and the workflows read a missing one as empty.
        if ($denied) { $secrets['DENIED_SUBSCRIPTIONS'] = $denied -join ',' }
        if ($ParentManagementGroupId) { $variables['PARENT_MG'] = $ParentManagementGroupId }
        if ($DeniedMgPrefix) { $variables['DENIED_MG_PREFIXES'] = $DeniedMgPrefix -join ',' }
        foreach ($name in $variables.Keys) {
            $null = Invoke-GitHubCli -Arguments @('variable', 'set', $name, '--env', $Environment, '--repo', $Repository, '--body', ([string] $variables[$name]))
        }
        foreach ($name in $secrets.Keys) {
            $null = Invoke-GitHubCli -Arguments @('secret', 'set', $name, '--env', $Environment, '--repo', $Repository, '--body', ([string] $secrets[$name]))
        }
        # The member indexes and the profile aren't sensitive, and the plan job (no environment) can only read repository variables.
        $null = Invoke-GitHubCli -Arguments @('variable', 'set', 'MEMBER_INDEXES', '--repo', $Repository, '--body', (@($members.index | Sort-Object) -join ','))
        $null = Invoke-GitHubCli -Arguments @('variable', 'set', 'PIPELINE_PROFILE', '--repo', $Repository, '--body', $PipelineProfile.ToLowerInvariant())
        # Earlier versions kept identifiers in variables, which a public repo's logs print.
        foreach ($legacy in 'AZURE_TENANT_ID', 'AZURE_CLIENT_ID', 'SHARED_SUBSCRIPTION_ID', 'ALLOWED_SUBSCRIPTIONS', 'DENIED_SUBSCRIPTIONS') {
            $null = Invoke-GitHubCli -Arguments @('variable', 'delete', $legacy, '--env', $Environment, '--repo', $Repository) -AllowFailure
        }

        # Verify the final state rather than trusting the calls.
        $state = Invoke-GitHubCli -Arguments @('api', $apiEnv)
        $hasReviewer = [bool] ($state.protection_rules | Where-Object { $_.type -eq 'required_reviewers' })
        if ($reviewerId -and -not $hasReviewer) { throw 'The environment has no required reviewer.' }
        if (-not $state.deployment_branch_policy.custom_branch_policies) { throw 'The environment has no deployment-branch policy.' }
        $haveVars = @(Invoke-GitHubCli -Arguments @('variable', 'list', '--env', $Environment, '--repo', $Repository, '--json', 'name', '--jq', '.[].name')) -split "`n"
        $haveSecrets = @(Invoke-GitHubCli -Arguments @('secret', 'list', '--env', $Environment, '--repo', $Repository, '--json', 'name', '--jq', '.[].name')) -split "`n"
        $missing = @($variables.Keys | Where-Object { $_ -notin $haveVars }) + @($secrets.Keys | Where-Object { $_ -notin $haveSecrets })
        if ($missing) { throw "Missing environment variables or secrets: $($missing -join ', ')" }
        Write-Information "GitHub environment verified: $(if ($hasReviewer) { 'reviewer required' } else { 'no reviewer (write access is the gate)' }), branches $($AllowedBranch -join ', '), $($variables.Count) variables, $($secrets.Count) secrets."
    }
}

# 5. Doctor check and smoke test.
if (-not $WhatIfPreference -and -not $SkipGitHub) {
    & (Join-Path $PSScriptRoot 'Test-PipelineSetup.ps1') -SettingsPath $SettingsPath -SharedSubscriptionId $SharedSubscriptionId `
        -WorkloadSubscriptionId $workloadIds[0] -ParentManagementGroupId $ParentManagementGroupId -Repository $Repository -Environment $Environment `
        -WorkloadSubscriptionIds $workloadIds -PipelineProfile $PipelineProfile
    if ($LASTEXITCODE -ne 0) { throw 'Setup finished, but the doctor check found problems. Fix them as listed, then run ./scripts/Test-PipelineSetup.ps1.' }
}
if ($SmokeTest -and -not $WhatIfPreference -and -not $SkipGitHub) {
    $ref = (& git branch --show-current)
    $dispatched = Invoke-GitHubCli -Arguments @('workflow', 'run', 'platform-smoke.yml', '--repo', $Repository, '--ref', $ref) -AllowFailure
    if ($null -eq $dispatched) {
        Write-Warning "platform-smoke.yml can't be dispatched yet: GitHub only dispatches a workflow that is on the default branch. Merge the import to main, or push this branch to ci-test/<name> to run it (git push origin HEAD:refs/heads/ci-test/smoke)."
        return
    }
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

Write-Information $(if ($member0Profile) {
        @"

Done. Next, your preflight (it also registers any Azure providers and features your subscription is missing; approve it in the Actions tab if GitHub asks)
  gh workflow run platform.yml --repo $Repository -f stage=whatif
Then your datacenter, test and Arc onboarding (C0 tasks 2 to 4, about 45 minutes, unattended):
  gh workflow run platform.yml --repo $Repository -f stage=member
Fetch the C0 evidence afterwards with ./scripts/Get-PipelineEvidence.ps1.
Check the setup any time with ./scripts/Test-PipelineSetup.ps1 -PipelineProfile Member. To remove the identity later:
./scripts/Remove-PlatformPipeline.ps1 -PipelineProfile Member
"@
    }
    else {
        @"

Done. Next, the preflight (it also registers any Azure providers and features the subscriptions are missing; approve it in the Actions tab if GitHub asks):
  gh workflow run platform.yml --repo $Repository -f stage=whatif
Then the foundation: gh workflow run platform.yml --repo $Repository -f stage=foundation
Check the setup any time with ./scripts/Test-PipelineSetup.ps1. To remove everything later, as an admin and
after the platform's own teardown: ./scripts/Remove-PlatformPipeline.ps1
"@
    })
