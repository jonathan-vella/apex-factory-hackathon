#Requires -Version 7.4

<#
.SYNOPSIS
Bootstraps or reconciles the kit's Entra reader group using delegated Microsoft Graph access.
.DESCRIPTION
Bootstrap creates or verifies an assigned-membership security group and optionally publishes its ID.
Sync reconciles the entire private JSON/CSV roster and publishes verification when Repository is set.
Verify is read-only and checks a specific nested group for a manual vending repair.
Use MemberIndex, WorkloadSubscriptionId, MemberPrincipalId and BudgetEmail for a single-member lab
without a roster file. The Entra operator must be authorized in the named tenant; GitHub writes
require an authorized lead and an existing gh-lab environment. Preview changes with -WhatIf.
.EXAMPLE
./Sync-FactoryReaderGroup.ps1 -Mode Bootstrap -TenantId '<tenant-id>' -MgPrefix mg-factory -OwnerId '<lead-object-id>' -Repository 'owner/repo' -WhatIf
.EXAMPLE
./Sync-FactoryReaderGroup.ps1 -Mode Sync -TenantId '<tenant-id>' -MgPrefix mg-factory -RosterPath .local/roster.json -Repository 'owner/repo'
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap', 'Sync', 'Verify')][string] $Mode,
    [Parameter(Mandatory)][guid] $TenantId,
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9-]{2,40}$')][string] $MgPrefix,
    [guid[]] $OwnerId,
    [guid] $ExpectedGroupId,
    [string] $RosterPath,
    [ValidateRange(1, [int]::MaxValue)][int] $MemberIndex = 1,
    [guid] $WorkloadSubscriptionId,
    [guid] $MemberPrincipalId,
    [string] $BudgetEmail,
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')][string] $Repository,
    [guid] $GraphClientId,
    [switch] $UseExistingSession
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
. (Join-Path $PSScriptRoot 'FactoryRoster.ps1')
$key = "$($MgPrefix.ToLowerInvariant())-readers"
$marker = "Partner Modernization Factory reader group: $key"
$groupUri = "/v1.0/groups(uniqueName='$key')"
$groupProperties = 'id,uniqueName,displayName,description,securityEnabled,mailEnabled,groupTypes,membershipRule,isAssignableToRole,onPremisesSyncEnabled'

function Invoke-ReaderGraphRequest {
    param([string] $Method = 'GET', [string] $Uri, $Body, [hashtable] $Headers = @{}, [int[]] $Accept = @(), [switch] $RetryReplication)
    if ($Uri -notmatch '^(/v1\.0/|https://graph\.microsoft\.com/v1\.0/)') { throw 'Unexpected Microsoft Graph response link.' }
    if ($Uri.StartsWith('/')) { $Uri = "https://graph.microsoft.com$Uri" }
    $requestArgs = @{
        Method = $Method; Uri = $Uri; Headers = $Headers; OutputType = 'HttpResponseMessage'
        SkipHttpErrorCheck = $true
    }
    if ($null -ne $Body) { $requestArgs.Body = ConvertTo-Json -InputObject $Body -Depth 6 -Compress; $requestArgs.ContentType = 'application/json' }
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try { $response = Invoke-MgGraphRequest @requestArgs }
        catch { throw "Microsoft Graph $Method failed. Check the delegated sign-in and tenant consent." }
        try {
            $status = [int] $response.StatusCode
            $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $data = if ($text) { $text | ConvertFrom-Json -AsHashtable }
            $replication = $RetryReplication -and ($status -eq 404 -or
                ($status -eq 400 -and $data.error.message -match 'source resource object or one of the objects being referenced'))
            if ($response.IsSuccessStatusCode -or ($status -in $Accept -and -not $replication)) {
                return @{ Status = $status; Data = $data }
            }
            if ($attempt -eq 4 -or ($status -notin 429, 502, 503, 504 -and -not $replication)) {
                throw "Microsoft Graph $Method failed (HTTP $status). Verify the target and delegated permissions."
            }
            $delay = [math]::Pow(2, $attempt + 1)
            if ($response.Headers.RetryAfter.Delta) { $delay = [math]::Max($delay, $response.Headers.RetryAfter.Delta.TotalSeconds) }
            elseif ($response.Headers.RetryAfter.Date) {
                $delay = [math]::Max($delay, ($response.Headers.RetryAfter.Date - [datetimeoffset]::UtcNow).TotalSeconds)
            }
            if ($delay -gt 60) { throw 'Microsoft Graph requested a retry later. Re-run the reader group operation after throttling clears.' }
        }
        finally { $response.Dispose() }
        Start-Sleep -Seconds $delay
    }
}

function Get-ReaderGraphSet {
    param([string] $Uri)
    do {
        $page = (Invoke-ReaderGraphRequest -Uri $Uri).Data
        $page.value | Where-Object { $_ }
        $Uri = $page.'@odata.nextLink'
    } while ($Uri)
}

function Assert-ReaderGroup {
    param($Group)
    if (-not $Group.id -or $Group.uniqueName -ne $key -or $Group.displayName -ne $key -or
        $Group.description -cne $marker -or $Group.securityEnabled -ne $true -or $Group.mailEnabled -ne $false -or
        $Group.groupTypes.Count -or $Group.membershipRule -or $Group.isAssignableToRole -or $Group.onPremisesSyncEnabled) {
        throw 'The Entra group does not meet the kit identity and security requirements. Review it with its owner; no group was adopted.'
    }
    if ($ExpectedGroupId -and $ExpectedGroupId -ne [guid] $Group.id) {
        throw 'The resolved Entra group does not match the expected reader group. Review the configured group ID.'
    }
}

function Set-ReaderGitHubValue {
    [CmdletBinding(SupportsShouldProcess)]
    param([ValidateSet('secret', 'variable')][string] $Kind, [string] $Name, [string] $Value)
    if (-not $PSCmdlet.ShouldProcess($Repository, "Publish $Name")) { return }
    $ghArgs = @($Kind, 'set', $Name, '--repo', $Repository)
    if ($Kind -eq 'secret') { $ghArgs += @('--env', 'gh-lab') }
    $PSNativeCommandUseErrorActionPreference = $false
    $ghErr = ($Value | & gh @ghArgs 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        if ($ghErr -match 'HTTP 401|HTTP 403|authentication|not logged into') {
            throw "GitHub CLI is not authorized to publish $Name in '$Repository'. Refresh scopes (gh auth refresh --hostname github.com --scopes repo,workflow) and retry."
        }
        throw "Could not publish $Name. Verify your GitHub repository and environment permissions."
    }
}

function Assert-ReaderRepository {
    $PSNativeCommandUseErrorActionPreference = $false
    $pipelineProfile = (& gh variable get PIPELINE_PROFILE --repo $Repository 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        if ($pipelineProfile -match 'HTTP 401|HTTP 403|authentication|not logged into') {
            throw "GitHub CLI cannot read variables in '$Repository'. Refresh scopes (gh auth refresh --hostname github.com --scopes repo,workflow) and retry."
        }
        throw "Could not read PIPELINE_PROFILE in '$Repository'. Run Initialize-PlatformPipeline.ps1 first or verify repository access."
    }
    if ($pipelineProfile -ne 'lead') { throw 'The target repository is not configured for the lead pipeline.' }
    $prefix = (& gh variable get MG_PREFIX --env gh-lab --repo $Repository 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        if ($prefix -match 'HTTP 401|HTTP 403|authentication|not logged into') {
            throw "GitHub CLI cannot read the gh-lab environment in '$Repository'. Refresh scopes (gh auth refresh --hostname github.com --scopes repo,workflow) and retry."
        }
        throw "Could not read MG_PREFIX from the gh-lab environment in '$Repository'. Run Initialize-PlatformPipeline.ps1 first."
    }
    if ($prefix -ne $MgPrefix) { throw 'The target GitHub environment does not match the kit management group prefix.' }
}

if ($TenantId -eq [guid]::Empty) { throw 'Specify the intended Entra tenant.' }
if ($Mode -eq 'Verify' -and (-not $ExpectedGroupId -or $ExpectedGroupId -eq [guid]::Empty -or
        -not $MemberPrincipalId -or $MemberPrincipalId -eq [guid]::Empty -or $Repository)) {
    throw 'Verify requires the expected reader group and nested group object IDs and cannot publish to GitHub.'
}
if ($Mode -eq 'Bootstrap' -and (-not $OwnerId.Count -or [guid]::Empty -in $OwnerId)) {
    throw 'Bootstrap requires at least one authorized owner object ID.'
}
if ($Repository) { Assert-ReaderRepository }

$members = if ($Mode -eq 'Sync') {
    if ($RosterPath) { Import-FactoryRoster -Path $RosterPath }
    else {
        [pscustomobject]@{
            index = $MemberIndex; subscriptionId = [string] $WorkloadSubscriptionId
            memberPrincipalId = [string] $MemberPrincipalId; budgetEmail = $BudgetEmail
        }
    }
}
if ($Mode -eq 'Sync') {
    $members = @($members | Where-Object { $_ })
    $digest = Get-FactoryRosterDigest -Members $members
    $subscriptions = [Collections.Generic.HashSet[guid]]::new()
    foreach ($member in $members) {
        $subscription = [guid]::Empty
        if (-not [guid]::TryParseExact($member.subscriptionId, 'D', [ref] $subscription) -or $subscription -eq [guid]::Empty -or
            -not $subscriptions.Add($subscription) -or $member.budgetEmail -notmatch '^[^@\s]+@[^@\s]+$') {
            throw "Member $($member.index) needs a unique workload subscription and valid budget address."
        }
    }
}

$scopes = switch ($Mode) {
    'Bootstrap' { 'Group.ReadWrite.All' }
    'Sync' { 'GroupMember.ReadWrite.All'; 'Directory.Read.All' }
    'Verify' { 'GroupMember.Read.All' }
}

if (-not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
    throw 'Install Microsoft.Graph.Authentication for the delegated reader group operation.'
}
$openedSession = $false
try {
    if (-not $UseExistingSession) {
        $connect = @{ TenantId = [string] $TenantId; Scopes = $scopes; ContextScope = 'Process'; NoWelcome = $true }
        if ($GraphClientId -and $GraphClientId -ne [guid]::Empty) { $connect.ClientId = [string] $GraphClientId }
        $null = Connect-MgGraph @connect
        $openedSession = $true
    }
    $context = Get-MgContext
    if (-not $context -or $context.AuthType -ne 'Delegated' -or $context.TenantId -ne [string] $TenantId -or
        $context.ContextScope -ne 'Process' -or
        ($GraphClientId -and $GraphClientId -ne [guid]::Empty -and $context.ClientId -ne [string] $GraphClientId)) {
        throw 'Use an approved process-scoped delegated Microsoft Graph session in the intended tenant.'
    }

    $group = (Invoke-ReaderGraphRequest -Uri "${groupUri}?`$select=$groupProperties" -Accept 404).Data
    if ($group.id) { Assert-ReaderGroup -Group $group }

    if ($Mode -eq 'Bootstrap') {
        $owners = @($OwnerId | Sort-Object -Unique | ForEach-Object { [string] $_ })
        if (-not $group.id) {
            if ($ExpectedGroupId -and $ExpectedGroupId -ne [guid]::Empty) {
                throw 'The expected reader group could not be located. Review its identity before creating a replacement.'
            }
            if (-not $PSCmdlet.ShouldProcess($key, 'Create the Entra security group with explicit owners')) { return }
            $body = @{
                displayName = $key; description = $marker; mailNickname = $key
                securityEnabled = $true; mailEnabled = $false; groupTypes = @()
                'owners@odata.bind' = @($owners | ForEach-Object { "https://graph.microsoft.com/v1.0/users/$_" })
            }
            $null = Invoke-ReaderGraphRequest -Method PATCH -Uri $groupUri -Headers @{ Prefer = 'create-if-missing' } -Body $body
            $group = (Invoke-ReaderGraphRequest -Uri "${groupUri}?`$select=$groupProperties" -RetryReplication).Data
            Assert-ReaderGroup -Group $group
        }
        $existingOwners = @(Get-ReaderGraphSet -Uri "/v1.0/groups/$($group.id)/owners?`$select=id")
        if (@($owners | Where-Object { $_ -notin $existingOwners.id }).Count) {
            throw 'The reader group is missing an expected owner. Have an authorized administrator review ownership before continuing.'
        }
        if ($Repository -and $PSCmdlet.ShouldProcess($Repository, 'Publish READER_GROUP_ID to gh-lab')) {
            Set-ReaderGitHubValue -Kind secret -Name READER_GROUP_ID -Value $group.id
        }
        Write-Information 'Reader group and expected owners verified. No roster membership was changed.'
        return
    }

    if (-not $group.id) { throw 'The kit reader group is absent. Run Bootstrap before syncing or verifying it.' }
    $groupId = [string] $group.id
    $membersUri = "/v1.0/groups/$groupId/members?`$select=id"
    if ($Mode -eq 'Verify') {
        $nested = (Invoke-ReaderGraphRequest -Uri "/v1.0/groups/${MemberPrincipalId}?`$select=id,securityEnabled,mailEnabled").Data
        if (-not $nested.securityEnabled -or $nested.mailEnabled -or
            [string] $MemberPrincipalId -notin @(Get-ReaderGraphSet -Uri $membersUri).id) {
            throw 'The requested security group is not a direct member of the kit reader group. Sync the full roster before vending.'
        }
        return $true
    }

    $ids = @($members.memberPrincipalId | ForEach-Object { ([guid] $_).ToString() } | Sort-Object -Unique)
    if ($groupId -in $ids) { throw 'The reader group cannot be a member of itself. Correct the roster.' }
    $objects = @{}
    for ($i = 0; $i -lt $ids.Count; $i += 1000) {
        $chunk = @($ids | Select-Object -Skip $i -First 1000)
        $result = Invoke-ReaderGraphRequest -Method POST -Uri '/v1.0/directoryObjects/getByIds' -Body @{ ids = $chunk; types = @('user', 'group') }
        foreach ($item in $result.Data.value) { $objects[$item.id] = $item }
    }
    $groupIndexes = @(foreach ($member in $members) {
        $item = $objects[$member.memberPrincipalId]
        if ($item.'@odata.type' -eq '#microsoft.graph.user') { continue }
        if ($item.'@odata.type' -eq '#microsoft.graph.group' -and $item.securityEnabled -eq $true -and $item.mailEnabled -eq $false) {
            [int] $member.index
            continue
        }
        throw "Member $($member.index) must refer to a user or a non-mail-enabled Entra security group in the intended tenant."
    })

    $current = @(Get-ReaderGraphSet -Uri $membersUri).id
    $add = @($ids | Where-Object { $_ -notin $current })
    $remove = @($current | Where-Object { $_ -and $_ -notin $ids })
    Write-Information "Reader group drift: $($add.Count) membership additions and $($remove.Count) removals."
    if (-not $PSCmdlet.ShouldProcess($key, 'Reconcile and verify the full roster')) { return }
    if ($Repository) { Set-ReaderGitHubValue -Kind secret -Name READER_ROSTER_VERIFICATION -Value '{}' }
    for ($i = 0; $i -lt $add.Count; $i += 20) {
        $batch = @($add | Select-Object -Skip $i -First 20)
        $body = @{ 'members@odata.bind' = @($batch | ForEach-Object { "https://graph.microsoft.com/v1.0/directoryObjects/$_" }) }
        $result = Invoke-ReaderGraphRequest -Method PATCH -Uri "/v1.0/groups/$groupId" -Body $body -RetryReplication -Accept 400
        if ($result.Status -eq 400) {
            $now = @(Get-ReaderGraphSet -Uri $membersUri).id
            foreach ($id in $batch | Where-Object { $_ -notin $now }) {
                $single = Invoke-ReaderGraphRequest -Method POST -Uri "/v1.0/groups/$groupId/members/`$ref" `
                    -Body @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" } -RetryReplication -Accept 400
                if ($single.Status -eq 400 -and $id -notin @(Get-ReaderGraphSet -Uri $membersUri).id) {
                    $indexes = ($members | Where-Object memberPrincipalId -eq $id).index -join ', '
                    throw "Microsoft Graph rejected membership for roster index(es) $indexes. No removals or verification publication were attempted."
                }
            }
        }
    }
    foreach ($id in $remove) {
        # /$ref is required: DELETE without it can delete the directory object, not just its membership.
        $null = Invoke-ReaderGraphRequest -Method DELETE -Uri "/v1.0/groups/$groupId/members/$id/`$ref" -Accept 404
    }
    $verified = $false
    for ($attempt = 0; $attempt -lt 5 -and -not $verified; $attempt++) {
        $actual = @(Get-ReaderGraphSet -Uri $membersUri).id
        $verified = @($actual).Count -eq $ids.Count -and -not @($ids | Where-Object { $_ -notin $actual }).Count
        if (-not $verified -and $attempt -lt 4) { Start-Sleep -Seconds ([math]::Pow(2, $attempt + 1)) }
    }
    if (-not $verified) { throw 'Reader group membership has not converged; no verification was published. Review group ownership and re-run Sync.' }
    if ($Repository) {
        Set-ReaderGitHubValue -Kind secret -Name READER_GROUP_ID -Value $groupId
        Set-ReaderGitHubValue -Kind secret -Name ROSTER_JSON -Value (ConvertTo-FactoryRosterJson -Members $members)
        Set-ReaderGitHubValue -Kind variable -Name MEMBER_INDEXES -Value (($members.index | Sort-Object) -join ',')
        $verification = @{ version = 1; tenantId = [string] $TenantId; groupId = $groupId; mgPrefix = $MgPrefix; digest = $digest; groupIndexes = $groupIndexes }
        Set-ReaderGitHubValue -Kind secret -Name READER_ROSTER_VERIFICATION -Value (ConvertTo-Json -InputObject $verification -Compress)
    }
    Write-Information "Verified reader group membership for $($members.Count) roster entries."
}
finally {
    if ($openedSession) { $null = Disconnect-MgGraph }
}
