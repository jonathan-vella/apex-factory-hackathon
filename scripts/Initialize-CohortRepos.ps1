#Requires -Version 7.4

<#
.SYNOPSIS
Creates private student repositories from a pre-imported template repository and generates git-ignored student handoff cards.
.DESCRIPTION
For the lead-provisioned cohort path (Path B), stamps out one private student repository per roster member from a template
repository that already has the Partner Modernization Factory kit imported, grants coaches pull access and attendees push
(Write, never admin) access with zero Member pipelines on student repositories, optionally pushes each member's
test-datacenter.txt readiness evidence from the lead pipeline run, and writes git-ignored handoff cards under
.local/handoff/member-<index>.md. Re-running converges idempotently and refuses to touch any public or unrelated existing
repository. Never prints tenant or subscription GUIDs to the console.
.PARAMETER RosterPath
Path to the cohort roster file (.json or .csv). Supports keys or columns: index / Member index,
subscriptionId / Workload subscription ID, memberPrincipalId / Entra object ID, budgetEmail / Budget email, plus optional
githubUsername / GitHub handle / GitHub username, suffix / Suffix, and repoName / Repository.
.PARAMETER TemplateRepository
owner/name of the GitHub template repository that already has the kit imported on its default branch.
.PARAMETER Organization
GitHub organization or owner where student repositories are created. Defaults to the owner segment of TemplateRepository.
.PARAMETER RepoPrefix
Prefix used when a roster row omits repoName / Repository (for example factory-student -> factory-student-01).
.PARAMETER SettingsPath
Path to .local/settings.json used as a fallback for TenantId, SharedSubscriptionId and Location.
.PARAMETER TenantId
Entra tenant ID written into the git-ignored student handoff cards. Defaults to tenantId in SettingsPath.
.PARAMETER SharedSubscriptionId
Shared services subscription ID written into the git-ignored student handoff cards. Defaults to sharedSubscriptionId in SettingsPath.
.PARAMETER Location
Azure region written into the student handoff cards. Defaults to location in SettingsPath, or swedencentral.
.PARAMETER CoachTeamSlug
Optional GitHub organization team slugs granted pull (Read) access on every student repository.
.PARAMETER CoachUsername
Optional GitHub usernames granted pull (Read) access on every student repository.
.PARAMETER PushReadinessEvidence
Downloads each member's readiness-test-datacenter-member-<index> artifact from LeadRepository and commits
factory/evidence/readiness/test-datacenter.txt to that member's student repository.
.PARAMETER LeadRepository
owner/name of the platform lead repository whose Actions runs hold the readiness artifacts. Defaults to the git origin remote.
.PARAMETER EvidenceRunId
Optional specific Actions run ID on LeadRepository from which to fetch readiness artifacts.
.PARAMETER MemberIndex
Optional list of member indexes to process (after validating the full roster). When omitted, processes every member in RosterPath.
.PARAMETER HandoffDirectory
Directory where git-ignored member-<index>.md handoff cards are written. Defaults to .local/handoff next to scripts/.
.EXAMPLE
./scripts/Initialize-CohortRepos.ps1 -RosterPath .local/roster.json -TemplateRepository 'contoso/factory-template' -WhatIf
.EXAMPLE
./scripts/Initialize-CohortRepos.ps1 -RosterPath .local/roster.json -TemplateRepository 'contoso/factory-template' -CoachTeamSlug 'coaches' -PushReadinessEvidence
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string] $RosterPath,
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $TemplateRepository,
    [ValidatePattern('^$|^[A-Za-z0-9._-]+$')]
    [string] $Organization = '',
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $RepoPrefix = 'factory-student',
    [string] $SettingsPath = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', 'settings.json'),
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $TenantId = '',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId = '',
    [string] $Location = '',
    [string[]] $CoachTeamSlug = @(),
    [string[]] $CoachUsername = @(),
    [switch] $PushReadinessEvidence,
    [ValidatePattern('^$|^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$')]
    [string] $LeadRepository = '',
    [long] $EvidenceRunId = 0,
    [int[]] $MemberIndex = @(),
    [string] $HandoffDirectory = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', 'handoff')
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$guidRegex = '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'
$strictGuidPattern = "^$guidRegex$"
$githubUsernamePattern = '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$'

function Protect-SensitiveText {
    param([string] $Text)
    if (-not $Text) { return '' }
    return ($Text -replace $guidRegex, '<id>')
}

function Get-Setting {
    param($Settings, [string[]] $Names)
    foreach ($key in $Names) {
        if ($null -ne $Settings -and $Settings.PSObject.Properties[$key] -and "$($Settings.$key)".Trim()) {
            return "$($Settings.$key)".Trim()
        }
    }
    return ''
}

function Invoke-GitHubCli {
    param(
        [string[]] $Arguments,
        [switch] $AllowFailure,
        [switch] $AllowNotFound
    )
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($exitCode -ne 0) {
        if ($AllowFailure) { return $null }
        if ($AllowNotFound -and $text -match '(?i)\b404\b|Not Found') { return $null }
        $operation = Protect-SensitiveText -Text (($Arguments | Select-Object -First 3) -join ' ')
        $safeDetail = Protect-SensitiveText -Text (($output | ForEach-Object { $_.ToString() }) -join ' ')
        throw "GitHub CLI '$operation' failed (exit $exitCode): $safeDetail"
    }
    $trimmed = $text.Trim()
    if ($trimmed.StartsWith('{') -or $trimmed.StartsWith('[')) {
        return ($trimmed | ConvertFrom-Json)
    }
    return $text
}

if (-not $Organization) {
    $Organization = ($TemplateRepository -split '/')[0]
}

$settings = if ($SettingsPath -and (Test-Path -Path $SettingsPath)) {
    Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json
}
else {
    $null
}

$TenantId = if ($TenantId) { $TenantId.Trim() } else { Get-Setting -Settings $settings -Names @('tenantId') }
$SharedSubscriptionId = if ($SharedSubscriptionId) { $SharedSubscriptionId.Trim() } else { Get-Setting -Settings $settings -Names @('sharedSubscriptionId') }
$Location = if ($Location) { $Location.Trim() } elseif (Get-Setting -Settings $settings -Names @('location')) { Get-Setting -Settings $settings -Names @('location') } else { 'swedencentral' }

if ($TenantId -and $TenantId -notmatch $strictGuidPattern) {
    throw 'TenantId is not a valid GUID.'
}
if ($SharedSubscriptionId -and $SharedSubscriptionId -notmatch $strictGuidPattern) {
    throw 'SharedSubscriptionId is not a valid GUID.'
}
if (-not $WhatIfPreference) {
    if (-not $TenantId) {
        throw 'TenantId is required to write student handoff cards. Pass -TenantId or populate tenantId in .local/settings.json.'
    }
    if (-not $SharedSubscriptionId) {
        throw 'SharedSubscriptionId is required to write student handoff cards. Pass -SharedSubscriptionId or populate sharedSubscriptionId in .local/settings.json.'
    }
}

if (-not (Test-Path -Path $RosterPath)) {
    throw "Roster file not found: $(Protect-SensitiveText -Text $RosterPath)"
}
$rawRoster = Get-Content -Raw -Path $RosterPath
$isCsv = $RosterPath -match '\.csv$'
$isJson = $RosterPath -match '\.json$'
$rawRows = if ($isCsv) { @($rawRoster | ConvertFrom-Csv) } else { @($rawRoster | ConvertFrom-Json) }
if ($rawRows.Count -lt 1) {
    throw 'The roster must contain at least 1 member.'
}

$members = [System.Collections.Generic.List[object]]::new()
foreach ($row in $rawRows) {
    $pick = {
        param([string[]] $ColumnNames)
        foreach ($col in $ColumnNames) {
            $prop = $row.PSObject.Properties | Where-Object { $_.Name -ieq $col } | Select-Object -First 1
            if ($null -ne $prop -and $null -ne $prop.Value -and "$($prop.Value)".Trim()) {
                return "$($prop.Value)".Trim()
            }
        }
        return ''
    }

    $rawIndex = & $pick @('index', 'Member index')
    $parsedIndex = 0
    if ($rawIndex -notmatch '^[1-9]\d*$' -or -not [int]::TryParse($rawIndex, [ref] $parsedIndex) -or $parsedIndex -lt 1) {
        throw 'Every roster row must have a positive whole-number member index (1 or greater).'
    }

    $subId = & $pick @('subscriptionId', 'Workload subscription ID')
    if ($subId -notmatch $strictGuidPattern) {
        throw "Member $parsedIndex has no valid workload subscription ID."
    }
    if ($SharedSubscriptionId -and $subId -ieq $SharedSubscriptionId) {
        throw "Member $parsedIndex uses the shared services subscription: each member needs a distinct workload subscription."
    }

    $principalId = & $pick @('memberPrincipalId', 'Entra object ID')
    if ($principalId -and $principalId -notmatch $strictGuidPattern) {
        throw "Member $parsedIndex has an invalid memberPrincipalId."
    }

    $ghUser = & $pick @('githubUsername', 'GitHub handle', 'GitHub username')
    if ($ghUser -and $ghUser -notmatch $githubUsernamePattern) {
        throw "Member $parsedIndex has an invalid GitHub username '$ghUser'."
    }

    $explicitSuffix = & $pick @('suffix', 'Suffix')
    if ($explicitSuffix -and $explicitSuffix -cnotmatch '^[a-z0-9]{4,6}$') {
        throw "Member $parsedIndex has an invalid suffix '$explicitSuffix'. Expected 4 to 6 lowercase letters or digits."
    }

    $explicitRepoName = & $pick @('repoName', 'Repository')
    if ($explicitRepoName -and $explicitRepoName -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Member $parsedIndex has an invalid repository name '$explicitRepoName'."
    }

    $members.Add([pscustomobject]@{
        index             = $parsedIndex
        subscriptionId    = $subId
        memberPrincipalId = $principalId
        budgetEmail       = (& $pick @('budgetEmail', 'Budget email'))
        githubUsername    = $ghUser
        suffix            = $explicitSuffix
        repoName          = $explicitRepoName
    })
}

if (@($members | ForEach-Object { $_.index } | Sort-Object -Unique).Count -ne $members.Count) {
    throw 'Two members share an index in the roster. Every member needs a unique positive index.'
}
if (@($members | ForEach-Object { $_.subscriptionId.ToLowerInvariant() } | Sort-Object -Unique).Count -ne $members.Count) {
    throw 'Two members share a workload subscription in the roster. Every member needs a distinct workload subscription.'
}

$missingPrincipalIndexes = @($members | Where-Object { -not $_.memberPrincipalId } | ForEach-Object { $_.index })
if ($missingPrincipalIndexes.Count -gt 0) {
    $safeRosterDisplay = Protect-SensitiveText -Text $RosterPath
    Write-Warning "Member index(es) $($missingPrincipalIndexes -join ', ') have an empty memberPrincipalId. Populate memberPrincipalId in '$safeRosterDisplay', then run Initialize-PlatformPipeline.ps1 -RosterPath '$safeRosterDisplay' and stage=vending before students can deploy C5."
}

$usedSuffixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($member in $members) {
    if ($member.suffix -and -not $usedSuffixes.Add($member.suffix)) {
        throw "Duplicate suffix '$($member.suffix)' in the roster. Every member needs a unique suffix."
    }
}

$letters = [char[]]'abcdefghijklmnopqrstuvwxyz'
$alnum = [char[]]'abcdefghijklmnopqrstuvwxyz0123456789'
$rosterMutated = $false
for ($idx = 0; $idx -lt $members.Count; $idx++) {
    $member = $members[$idx]
    if (-not $member.repoName) {
        $member.repoName = "$RepoPrefix-$('{0:D2}' -f $member.index)"
        if ($member.repoName -notmatch '^[A-Za-z0-9._-]+$') {
            throw "Generated repository name '$($member.repoName)' for member $($member.index) is not valid."
        }
        $rawRows[$idx] | Add-Member -NotePropertyName 'repoName' -NotePropertyValue $member.repoName -Force
        $rosterMutated = $true
    }
    if (-not $member.suffix) {
        do {
            $candidateSuffix = (Get-Random -InputObject $letters) + (-join (1..5 | ForEach-Object { Get-Random -InputObject $alnum }))
        } while (-not $usedSuffixes.Add($candidateSuffix))
        $member.suffix = $candidateSuffix
        $rawRows[$idx] | Add-Member -NotePropertyName 'suffix' -NotePropertyValue $member.suffix -Force
        $rosterMutated = $true
    }
}

if (@($members | ForEach-Object { $_.repoName.ToLowerInvariant() } | Sort-Object -Unique).Count -ne $members.Count) {
    throw 'Two members resolve to the same student repository name.'
}

if ($PushReadinessEvidence -and -not $LeadRepository) {
    $remote = (& git remote get-url origin 2>$null)
    if ($remote -match 'github\.com[:/]([^/]+/[^/.]+?)(\.git)?$') {
        $LeadRepository = $Matches[1]
    }
    if (-not $LeadRepository) {
        throw 'Pass -LeadRepository owner/name when using -PushReadinessEvidence.'
    }
}

# Verify the template repository before creating or updating any student repository or persisting generated suffixes.
$templateInfo = Invoke-GitHubCli -Arguments @('api', "repos/$TemplateRepository")
if ($null -eq $templateInfo -or $templateInfo.is_template -ne $true) {
    throw "Repository '$TemplateRepository' is not enabled as a template repository. Run: gh repo edit $TemplateRepository --template"
}
$defaultBranch = if ($templateInfo.PSObject.Properties['default_branch'] -and "$($templateInfo.default_branch)".Trim()) {
    "$($templateInfo.default_branch)".Trim()
}
else {
    'main'
}

$requiredTemplateFiles = @(
    'factory/scripts/Initialize-Settings.ps1',
    '.devcontainer/devcontainer.json',
    '.github/workflows/platform.yml',
    'infra/bicep/university/azure.yaml'
)
foreach ($requiredFile in $requiredTemplateFiles) {
    $fileCheck = Invoke-GitHubCli -Arguments @('api', "repos/$TemplateRepository/contents/$($requiredFile)?ref=$defaultBranch") -AllowNotFound
    if ($null -eq $fileCheck) {
        throw "Template repository '$TemplateRepository' is missing '$requiredFile' on '$defaultBranch'. Run Import-Kit.ps1 in '$TemplateRepository', commit, and merge to '$defaultBranch' first."
    }
}

if ($isJson -and (-not $WhatIfPreference) -and $rosterMutated) {
    ConvertTo-Json -InputObject @($rawRows) -Depth 10 | Set-Content -Path $RosterPath -Encoding utf8NoBOM
}
elseif ($isCsv -and (-not $WhatIfPreference) -and $rosterMutated) {
    $rawRows | Export-Csv -Path $RosterPath -NoTypeInformation -Encoding utf8NoBOM
}

$targetMembers = if ($MemberIndex.Count -gt 0) {
    foreach ($wantedIdx in $MemberIndex) {
        if ($wantedIdx -lt 1 -or -not ($members | Where-Object { $_.index -eq $wantedIdx })) {
            throw "Member index $wantedIdx is not in the roster."
        }
    }
    @($members | Where-Object { $_.index -in $MemberIndex })
}
else {
    @($members)
}

$evidenceScript = Join-Path -Path $PSScriptRoot -ChildPath 'Get-PipelineEvidence.ps1'

foreach ($member in $targetMembers) {
    $fullRepo = "$Organization/$($member.repoName)"
    $existingRepo = Invoke-GitHubCli -Arguments @('api', "repos/$fullRepo") -AllowNotFound

    if ($null -ne $existingRepo) {
        if ($existingRepo.private -ne $true) {
            throw "Existing repository '$fullRepo' is not private. Refusing to use a non-private repository for student work."
        }
        $topics = if ($existingRepo.PSObject.Properties['topics'] -and $null -ne $existingRepo.topics) {
            @($existingRepo.topics | ForEach-Object { "$_" })
        }
        else {
            @()
        }
        $templateOrigin = if (
            $existingRepo.PSObject.Properties['template_repository'] -and
            $null -ne $existingRepo.template_repository -and
            $existingRepo.template_repository.PSObject.Properties['full_name']
        ) {
            "$($existingRepo.template_repository.full_name)"
        }
        else {
            ''
        }
        if (-not (($topics -contains 'apex-factory-student') -or ($templateOrigin -ieq $TemplateRepository))) {
            throw "Existing repository '$fullRepo' lacks the 'apex-factory-student' topic and was not created from '$TemplateRepository'. Refusing to reuse an unrelated existing repository."
        }
    }
    elseif ($PSCmdlet.ShouldProcess($fullRepo, "Create private student repository from $TemplateRepository")) {
        $null = Invoke-GitHubCli -Arguments @('repo', 'create', $fullRepo, '--private', '--template', $TemplateRepository)
        $populated = $false
        for ($attempt = 1; $attempt -le 12; $attempt++) {
            $commits = Invoke-GitHubCli -Arguments @('api', "repos/$fullRepo/commits?per_page=1") -AllowFailure
            $commitItems = @($commits | Where-Object { $null -ne $_ -and $_.PSObject.Properties['sha'] })
            if ($commitItems.Count -ge 1) {
                $populated = $true
                break
            }
            if ($attempt -lt 12) {
                Start-Sleep -Seconds 2
            }
        }
        if (-not $populated) {
            throw "Repository '$fullRepo' was created, but template commit population did not finish in time. Re-run the script to converge."
        }
        $null = Invoke-GitHubCli -Arguments @('repo', 'edit', $fullRepo, '--add-topic', 'apex-factory-student')
    }

    foreach ($rawSlug in $CoachTeamSlug) {
        $slug = "$rawSlug".Trim()
        if (-not $slug) { continue }
        if ($PSCmdlet.ShouldProcess("$fullRepo (team $slug)", 'Grant coach team pull access')) {
            $null = Invoke-GitHubCli -Arguments @('api', '-X', 'PUT', "orgs/$Organization/teams/$slug/repos/$fullRepo", '-f', 'permission=pull')
        }
    }

    foreach ($rawCoach in $CoachUsername) {
        $coach = "$rawCoach".Trim()
        if (-not $coach -or $coach -ieq $Organization) { continue }
        $existingCoachPerm = Invoke-GitHubCli -Arguments @('api', "repos/$fullRepo/collaborators/$coach/permission") -AllowFailure
        $alreadyHasReadOrHigher = (
            $null -ne $existingCoachPerm -and
            $existingCoachPerm.PSObject.Properties['permission'] -and
            "$($existingCoachPerm.permission)" -in @('admin', 'maintain', 'write', 'triage', 'read')
        )
        if (-not $alreadyHasReadOrHigher -and $PSCmdlet.ShouldProcess("$fullRepo (coach $coach)", 'Grant coach pull access')) {
            $null = Invoke-GitHubCli -Arguments @('api', '-X', 'PUT', "repos/$fullRepo/collaborators/$coach", '-f', 'permission=pull')
        }
    }

    if ($member.githubUsername -and $member.githubUsername -ine $Organization) {
        $existingPerm = Invoke-GitHubCli -Arguments @('api', "repos/$fullRepo/collaborators/$($member.githubUsername)/permission") -AllowFailure
        $alreadyHasWriteOrAdmin = (
            $null -ne $existingPerm -and
            $existingPerm.PSObject.Properties['permission'] -and
            "$($existingPerm.permission)" -in @('admin', 'write')
        )
        if (-not $alreadyHasWriteOrAdmin -and $PSCmdlet.ShouldProcess("$fullRepo (student $($member.githubUsername))", 'Grant student push access')) {
            $null = Invoke-GitHubCli -Arguments @('api', '-X', 'PUT', "repos/$fullRepo/collaborators/$($member.githubUsername)", '-f', 'permission=push')
        }
    }

    if ($PushReadinessEvidence) {
        $evidenceRepoPath = 'factory/evidence/readiness/test-datacenter.txt'
        if ($PSCmdlet.ShouldProcess("$fullRepo/$evidenceRepoPath", "Push readiness evidence for member $($member.index)")) {
            $tempBase = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.local', ".tmp-cohort-evidence-$([guid]::NewGuid().ToString('N'))"
            $tempMemberDir = Join-Path -Path $tempBase -ChildPath "member-$($member.index)"
            try {
                $evidenceArgs = @{
                    Repository   = $LeadRepository
                    MemberIndex  = $member.index
                    OutDirectory = $tempMemberDir
                }
                if ($EvidenceRunId -gt 0) {
                    $evidenceArgs['RunId'] = $EvidenceRunId
                }
                & $evidenceScript @evidenceArgs
                $downloadedEvidence = Join-Path -Path $tempMemberDir -ChildPath 'test-datacenter.txt'
                if (-not (Test-Path -Path $downloadedEvidence)) {
                    throw "Readiness evidence file test-datacenter.txt was not downloaded for member $($member.index)."
                }
                $evidenceBytes = [System.IO.File]::ReadAllBytes($downloadedEvidence)
                $base64Content = [Convert]::ToBase64String($evidenceBytes)

                $existingFile = Invoke-GitHubCli -Arguments @('api', "repos/$fullRepo/contents/$evidenceRepoPath") -AllowNotFound
                $skipUpload = $false
                $putArgs = @(
                    'api', '-X', 'PUT', "repos/$fullRepo/contents/$evidenceRepoPath",
                    '-f', 'message=docs: add readiness datacenter test evidence',
                    '-f', "content=$base64Content"
                )
                if ($null -ne $existingFile -and $existingFile.PSObject.Properties['sha'] -and "$($existingFile.sha)") {
                    $existingBase64 = ("$($existingFile.content)" -replace '\s+', '')
                    if ($existingBase64 -eq $base64Content) {
                        $skipUpload = $true
                    }
                    else {
                        $putArgs += @('-f', "sha=$($existingFile.sha)")
                    }
                }
                if (-not $skipUpload) {
                    $null = Invoke-GitHubCli -Arguments $putArgs
                }
            }
            finally {
                Remove-Item -Path $tempBase -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    $handoffFile = Join-Path -Path $HandoffDirectory -ChildPath "member-$($member.index).md"
    if ($PSCmdlet.ShouldProcess((Protect-SensitiveText -Text $handoffFile), "Write handoff card for member $($member.index)")) {
        New-Item -ItemType Directory -Force -Path $HandoffDirectory | Out-Null
        $repoUrl = "https://github.com/$fullRepo"
        $inviteUrl = "https://github.com/$fullRepo/invitations"
        $initCmd = "./scripts/Initialize-Settings.ps1 -TenantId '$TenantId' -SubscriptionId '$($member.subscriptionId)' -SharedSubscriptionId '$SharedSubscriptionId' -MemberIndex $($member.index) -Location '$Location' -Suffix '$($member.suffix)' -WriteLabCredentials"
        $handoffContent = @(
            "# Student handoff - Member $($member.index)"
            ""
            "- **Assigned repository:** $repoUrl *(your single GitHub repo for the dev container, ``vm-dev01-work`` app branch, and ``main`` evidence; do not create another GitHub repo)*"
            "- **Accept your GitHub invitation first:** $inviteUrl"
            "- **Member index:** ``$($member.index)``"
            "- **Archetype suffix:** ``$($member.suffix)``"
            "- **Student onboarding guide:** https://factory.apexops.pro/deploy/lead-setup/student-onboarding/"
            ""
            "## Initialize local settings"
            ""
            "Open your repository in a dev container or GitHub Codespace, change into ``factory/``, and run:"
            ""
            '```powershell'
            $initCmd
            '```'
        ) -join "`n"
        "$handoffContent`n" | Set-Content -Path $handoffFile -Encoding utf8NoBOM
    }

    Write-Information "Prepared $fullRepo for member $($member.index) (suffix $($member.suffix))."
}

Write-Information "Cohort setup finished for $($members.Count) member(s). Handoff cards are in $(Protect-SensitiveText -Text $HandoffDirectory) (git-ignored)."
