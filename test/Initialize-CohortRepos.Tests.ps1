#Requires -Version 7.4

<#
.SYNOPSIS
Runs offline unit tests for Initialize-CohortRepos.ps1 with a stateful fake gh CLI, never touching GitHub or Azure.
.DESCRIPTION
Exercises a 25-member cohort setup (verifying unbounded member indexes, suffix persistence, private repo creation,
coach pull vs student push permissions, handoff cards with -WriteLabCredentials, and zero raw GUIDs in console output),
template repository fail-closed validation, existing repository privacy/provenance fail-closed guards and idempotency,
and per-member readiness evidence uploads without cross-member overwrites.
.EXAMPLE
./test/Initialize-CohortRepos.Tests.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$pwsh = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$work = Join-Path ([System.IO.Path]::GetTempPath()) "cohort-test-$([guid]::NewGuid().ToString('N'))"
$bin = Join-Path $work 'bin'
$kitScripts = Join-Path $work 'kit' 'scripts'
New-Item -ItemType Directory -Path $bin -Force | Out-Null
New-Item -ItemType Directory -Path $kitScripts -Force | Out-Null

Copy-Item (Join-Path $repoRoot 'scripts/Initialize-CohortRepos.ps1') $kitScripts
Copy-Item (Join-Path $repoRoot 'scripts/Get-PipelineEvidence.ps1') $kitScripts
$cohortScript = Join-Path $kitScripts 'Initialize-CohortRepos.ps1'

$ghStubScript = Join-Path $bin 'gh-stub.ps1'
if (-not $IsWindows) {
    $ghShim = Join-Path $bin 'gh'
    Set-Content -Path $ghShim -Value "#!/bin/sh`nexec `"$pwsh`" -NoProfile -File `"`$(dirname `"`$0`")/gh-stub.ps1`" `"`$@`"`n"
    chmod +x $ghShim
}

Set-Content -Path $ghStubScript -Value @'
$ErrorActionPreference = 'Stop'
$global:LASTEXITCODE = 0
$statePath = $env:FAKE_GH_STATE
$logPath = $env:FAKE_GH_LOG
Add-Content -Path $logPath -Value ($args -join ' ')

$state = Get-Content -Raw -Path $statePath | ConvertFrom-Json -AsHashtable

function Save-State {
    param([hashtable] $Data)
    ConvertTo-Json -InputObject $Data -Depth 15 | Set-Content -Path $statePath -Encoding utf8NoBOM
}

if ($args.Count -ge 2 -and $args[0] -eq 'repo' -and $args[1] -eq 'create') {
    $fullRepo = $args[2]
    $tplIdx = [Array]::IndexOf($args, '--template')
    $tplName = if ($tplIdx -ge 0) { $args[$tplIdx + 1] } else { '' }
    $isPrivate = $args -contains '--private'
    $state['repos'][$fullRepo] = @{
        private            = [bool] $isPrivate
        topics             = @()
        template_full_name = $tplName
        commits            = @(@{ sha = 'abc12345def67890' })
        collaborators      = @{}
        teams              = @{}
        contents           = @{}
    }
    Save-State -Data $state
    Write-Output "https://github.com/$fullRepo"
    return
}

if ($args.Count -ge 2 -and $args[0] -eq 'repo' -and $args[1] -eq 'edit') {
    $fullRepo = $args[2]
    if (-not $state['repos'].ContainsKey($fullRepo)) {
        Write-Output "HTTP 404: Not Found ($fullRepo)"
        $global:LASTEXITCODE = 1
        return
    }
    $topicIdx = [Array]::IndexOf($args, '--add-topic')
    if ($topicIdx -ge 0) {
        $topic = $args[$topicIdx + 1]
        $existingTopics = @($state['repos'][$fullRepo]['topics'])
        if ($existingTopics -notcontains $topic) {
            $state['repos'][$fullRepo]['topics'] = @($existingTopics + $topic)
        }
    }
    Save-State -Data $state
    return
}

if ($args.Count -ge 2 -and $args[0] -eq 'run' -and $args[1] -eq 'list') {
    if ($state.ContainsKey('runs')) {
        ConvertTo-Json -InputObject @($state['runs']) -Compress | Write-Output
    }
    else {
        Write-Output '[{"databaseId":9001}]'
    }
    return
}

if ($args.Count -ge 2 -and $args[0] -eq 'run' -and $args[1] -eq 'download') {
    $runIdArg = $args[2]
    $dirIdx = [Array]::IndexOf($args, '--dir')
    $targetDir = $args[$dirIdx + 1]
    $nameIdx = [Array]::IndexOf($args, '--name')
    if ($nameIdx -lt 0) {
        Write-Output 'Expected --name for targeted download'
        $global:LASTEXITCODE = 1
        return
    }
    $artifactName = $args[$nameIdx + 1]
    $artifactMap = if ($state.ContainsKey('run_artifacts') -and $state['run_artifacts'].ContainsKey($runIdArg)) {
        $state['run_artifacts'][$runIdArg]
    }
    else {
        $state['artifacts']
    }
    if (-not $artifactMap.ContainsKey($artifactName)) {
        Write-Output "Artifact $artifactName not found in run $runIdArg"
        $global:LASTEXITCODE = 1
        return
    }
    $destFolder = Join-Path $targetDir $artifactName
    New-Item -ItemType Directory -Force -Path $destFolder | Out-Null
    Set-Content -Path (Join-Path $destFolder 'test-datacenter.txt') -Value $artifactMap[$artifactName] -NoNewline -Encoding utf8NoBOM
    return
}

if ($args.Count -ge 2 -and $args[0] -eq 'api') {
    $method = 'GET'
    $methodIdx = [Array]::IndexOf($args, '-X')
    if ($methodIdx -ge 0) {
        $method = $args[$methodIdx + 1]
    }
    $endpoint = ''
    foreach ($idx in 1..($args.Count - 1)) {
        $tok = $args[$idx]
        $prev = $args[$idx - 1]
        if ($prev -in @('-X', '--jq', '-f', '-F')) { continue }
        if ($tok -in @('-X', '--jq', '-f', '-F', '--paginate')) { continue }
        $endpoint = $tok
        break
    }

    $fields = @{}
    for ($i = 1; $i -lt $args.Count - 1; $i++) {
        if ($args[$i] -eq '-f') {
            $kv = $args[$i + 1] -split '=', 2
            $fields[$kv[0]] = $kv[1]
        }
    }

    if ($method -eq 'GET' -and $endpoint -match '^repos/([^/]+/[^/]+)/actions/runs/(\d+)/artifacts\?per_page=100&name=(.+)$') {
        $runKey = $Matches[2]
        $wantedName = $Matches[3]
        $artifactMap = if ($state.ContainsKey('run_artifacts') -and $state['run_artifacts'].ContainsKey($runKey)) {
            $state['run_artifacts'][$runKey]
        }
        elseif ($runKey -eq '9001') {
            $state['artifacts']
        }
        else {
            @{}
        }
        if ($artifactMap.ContainsKey($wantedName)) {
            Write-Output $wantedName
        }
        return
    }

    if ($method -eq 'GET' -and $endpoint -match '^repos/([^/]+/[^/]+)/collaborators/([^/]+)/permission$') {
        $repoKey = $Matches[1]
        $username = $Matches[2]
        if ($state['repos'].ContainsKey($repoKey) -and $state['repos'][$repoKey]['collaborators'].ContainsKey($username)) {
            $savedPerm = $state['repos'][$repoKey]['collaborators'][$username]
            $apiPerm = if ($savedPerm -eq 'push') { 'write' } elseif ($savedPerm -eq 'pull') { 'read' } else { $savedPerm }
            [ordered]@{ permission = $apiPerm } | ConvertTo-Json -Compress | Write-Output
            return
        }
        Write-Output 'HTTP 404: Not Found'
        $global:LASTEXITCODE = 1
        return
    }

    if ($method -eq 'GET' -and $endpoint -match '^repos/([^/]+/[^/?]+)$') {
        $repoKey = $Matches[1]
        if ($state['template']['full_name'] -eq $repoKey) {
            [ordered]@{
                full_name      = $repoKey
                is_template    = [bool] $state['template']['is_template']
                private        = $true
                default_branch = $state['template']['default_branch']
                topics         = @()
            } | ConvertTo-Json -Compress | Write-Output
            return
        }
        if ($state['repos'].ContainsKey($repoKey)) {
            $repoEntry = $state['repos'][$repoKey]
            $payload = [ordered]@{
                full_name      = $repoKey
                is_template    = $false
                private        = [bool] $repoEntry['private']
                default_branch = 'main'
                topics         = @($repoEntry['topics'])
            }
            if ($repoEntry['template_full_name']) {
                $payload['template_repository'] = @{ full_name = $repoEntry['template_full_name'] }
            }
            $payload | ConvertTo-Json -Depth 5 -Compress | Write-Output
            return
        }
        Write-Output 'HTTP 404: Not Found'
        $global:LASTEXITCODE = 1
        return
    }

    if ($method -eq 'GET' -and $endpoint -match '^repos/([^/]+/[^/]+)/commits') {
        $repoKey = $Matches[1]
        if (-not $state['repos'].ContainsKey($repoKey)) {
            Write-Output 'HTTP 404: Not Found'
            $global:LASTEXITCODE = 1
            return
        }
        ConvertTo-Json -InputObject @($state['repos'][$repoKey]['commits']) -Compress | Write-Output
        return
    }

    if ($method -eq 'GET' -and $endpoint -match '^repos/([^/]+/[^/]+)/contents/([^?]+)(\?ref=(.+))?$') {
        $repoKey = $Matches[1]
        $filePath = $Matches[2]
        if ($state['template']['full_name'] -eq $repoKey) {
            if (@($state['template']['files']) -contains $filePath) {
                [ordered]@{ path = $filePath; sha = 'tpl-sha-1' } | ConvertTo-Json -Compress | Write-Output
                return
            }
            Write-Output 'HTTP 404: Not Found'
            $global:LASTEXITCODE = 1
            return
        }
        if ($state['repos'].ContainsKey($repoKey) -and $state['repos'][$repoKey]['contents'].ContainsKey($filePath)) {
            $entry = $state['repos'][$repoKey]['contents'][$filePath]
            [ordered]@{
                path    = $filePath
                sha     = $entry['sha']
                content = $entry['content']
            } | ConvertTo-Json -Compress | Write-Output
            return
        }
        Write-Output 'HTTP 404: Not Found'
        $global:LASTEXITCODE = 1
        return
    }

    if ($method -eq 'PUT' -and $endpoint -match '^orgs/([^/]+)/teams/([^/]+)/repos/([^/]+/[^/]+)$') {
        $teamSlug = $Matches[2]
        $repoKey = $Matches[3]
        $state['repos'][$repoKey]['teams'][$teamSlug] = $fields['permission']
        Save-State -Data $state
        Write-Output '{}'
        return
    }

    if ($method -eq 'PUT' -and $endpoint -match '^repos/([^/]+/[^/]+)/collaborators/([^/]+)$') {
        $repoKey = $Matches[1]
        $username = $Matches[2]
        $state['repos'][$repoKey]['collaborators'][$username] = $fields['permission']
        Save-State -Data $state
        Write-Output '{}'
        return
    }

    if ($method -eq 'PUT' -and $endpoint -match '^repos/([^/]+/[^/]+)/contents/(.+)$') {
        $repoKey = $Matches[1]
        $filePath = $Matches[2]
        $state['repos'][$repoKey]['contents'][$filePath] = @{
            sha     = "sha-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            content = $fields['content']
            message = $fields['message']
        }
        Save-State -Data $state
        Write-Output '{"content":{"sha":"updated"}}'
        return
    }
}

Write-Output "Unhandled fake gh invocation: $($args -join ' ')"
$global:LASTEXITCODE = 1
'@

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
}

function Get-TestGuid {
    param([int] $Number)
    return ('{0:x8}-1111-2222-3333-444444444444' -f $Number)
}

function Get-DefaultState {
    $artifacts = @{}
    foreach ($idx in 1..35) {
        $artifacts["readiness-test-datacenter-member-$idx"] = "PASS datacenter member $idx marker-$idx"
    }
    return @{
        template  = @{
            full_name      = 'contoso/factory-template'
            is_template    = $true
            default_branch = 'main'
            files          = @(
                'factory/scripts/Initialize-Settings.ps1',
                'app/ContosoUniversity/ContosoUniversity.csproj',
                '.github/workflows/platform.yml',
                'infra/bicep/university/azure.yaml'
            )
        }
        repos     = @{}
        artifacts = $artifacts
    }
}

function Invoke-CohortRun {
    param(
        [string] $ScenarioName,
        [hashtable] $State,
        [string] $CommandText
    )
    $scenarioDir = Join-Path $work $ScenarioName
    New-Item -ItemType Directory -Force -Path $scenarioDir | Out-Null
    $stateFile = Join-Path $scenarioDir 'state.json'
    $logFile = Join-Path $scenarioDir 'gh.log'
    ConvertTo-Json -InputObject $State -Depth 15 | Set-Content -Path $stateFile -Encoding utf8NoBOM
    Set-Content -Path $logFile -Value '' -NoNewline

    $oldPath = $env:PATH
    $env:PATH = "$bin$([System.IO.Path]::PathSeparator)$oldPath"
    $env:FAKE_GH_STATE = $stateFile
    $env:FAKE_GH_LOG = $logFile
    $env:FAKE_GH_SCRIPT = $ghStubScript
    try {
        $wrappedCommand = @"
`$ErrorActionPreference = 'Stop'
function global:gh { & `$env:FAKE_GH_SCRIPT @args }
try {
    & { $CommandText } *>&1 | ForEach-Object { `$_.ToString() }
    exit 0
}
catch {
    Write-Output `$_.Exception.Message
    exit 1
}
"@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wrappedCommand))
        $output = & $pwsh -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
        $finalState = Get-Content -Raw -Path $stateFile | ConvertFrom-Json -AsHashtable
        $calls = @(Get-Content -Path $logFile | Where-Object { $_ })
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output   = $output
            State    = $finalState
            Calls    = $calls
            Dir      = $scenarioDir
        }
    }
    finally {
        $env:PATH = $oldPath
        Remove-Item Env:FAKE_GH_STATE -ErrorAction SilentlyContinue
        Remove-Item Env:FAKE_GH_LOG -ErrorAction SilentlyContinue
        Remove-Item Env:FAKE_GH_SCRIPT -ErrorAction SilentlyContinue
    }
}

$tenantGuid = Get-TestGuid -Number 900
$sharedGuid = Get-TestGuid -Number 901
$guidRegex = '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}'
$passed = 0

try {
    # 1. Happy path across a 25-member roster (> 20 members, suffix persistence, permissions, handoff cards, zero GUIDs in output).
    $state25 = Get-DefaultState
    $roster25Dir = Join-Path $work 's1-input'
    $handoff25Dir = Join-Path $work 's1-handoff'
    New-Item -ItemType Directory -Force -Path $roster25Dir | Out-Null
    $roster25Path = Join-Path $roster25Dir 'roster.json'
    $roster25 = @(1..25 | ForEach-Object {
        [ordered]@{
            index             = $_
            subscriptionId    = (Get-TestGuid -Number $_)
            memberPrincipalId = $(if ($_ -eq 25) { '' } else { Get-TestGuid -Number (100 + $_) })
            budgetEmail       = "member$_@example.test"
            githubUsername    = "student-$('{0:D2}' -f $_)"
        }
    })
    ConvertTo-Json -InputObject $roster25 -Depth 5 | Set-Content -Path $roster25Path -Encoding utf8NoBOM

    $cmd1 = "& '$cohortScript' -RosterPath '$roster25Path' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -Location 'swedencentral' -CoachTeamSlug 'coaches-team' -CoachUsername 'coach-anna' -HandoffDirectory '$handoff25Dir'"
    $res1 = Invoke-CohortRun -ScenarioName 'happy-25' -State $state25 -CommandText $cmd1
    Assert-True ($res1.ExitCode -eq 0) "25-member cohort setup failed (exit $($res1.ExitCode)): $($res1.Output)"
    Assert-True ($res1.Output -notmatch $guidRegex) "Console output leaked a raw GUID: $($res1.Output)"
    Assert-True ($res1.Output -match 'Member index\(es\) 25 have an empty memberPrincipalId') "Expected warning for empty memberPrincipalId on member 25: $($res1.Output)"

    $savedRoster = @(Get-Content -Raw -Path $roster25Path | ConvertFrom-Json)
    Assert-True ($savedRoster.Count -eq 25) "Expected 25 persisted roster rows, got $($savedRoster.Count)"
    $suffixes = @($savedRoster | ForEach-Object { $_.suffix })
    Assert-True (@($suffixes | Where-Object { $_ -cmatch '^[a-z][a-z0-9]{5}$' }).Count -eq 25) 'Every generated suffix must match ^[a-z][a-z0-9]{5}$.'
    Assert-True (@($suffixes | Sort-Object -Unique).Count -eq 25) 'Generated suffixes must be unique across all 25 members.'
    Assert-True ($savedRoster[0].repoName -eq 'factory-student-01' -and $savedRoster[24].repoName -eq 'factory-student-25') 'Generated repo names should format 01..25.'

    Assert-True ($res1.State['repos'].Count -eq 25) "Expected 25 created repos, got $($res1.State['repos'].Count)"
    $repo25 = $res1.State['repos']['contoso/factory-student-25']
    Assert-True ($null -ne $repo25 -and $repo25['private'] -eq $true) 'factory-student-25 must be private.'
    Assert-True (@($repo25['topics']) -contains 'apex-factory-student') 'factory-student-25 must have topic apex-factory-student.'
    Assert-True ($repo25['collaborators']['student-25'] -eq 'push') 'Student must receive push permission (never admin).'
    Assert-True ($repo25['collaborators']['coach-anna'] -eq 'pull') 'Coach user must receive pull permission.'
    Assert-True ($repo25['teams']['coaches-team'] -eq 'pull') 'Coach team must receive pull permission.'
    Assert-True (-not ($res1.Calls | Where-Object { $_ -match 'permission=admin' })) 'No collaborator or team call may grant admin.'

    $handoff25Text = Get-Content -Raw -Path (Join-Path $handoff25Dir 'member-25.md')
    $member25Sub = Get-TestGuid -Number 25
    $member25Suffix = $savedRoster[24].suffix
    Assert-True ($handoff25Text -match 'https://github\.com/contoso/factory-student-25') 'Handoff card missing repo URL.'
    Assert-True ($handoff25Text -match 'do not create another GitHub repo') 'Handoff card missing single-repo reminder.'
    Assert-True ($handoff25Text -match 'https://github\.com/contoso/factory-student-25/invitations') 'Handoff card missing invitations URL.'
    Assert-True ($handoff25Text -match 'https://factory\.apexops\.pro/deploy/lead-setup/student-onboarding/') 'Handoff card missing onboarding URL.'
    Assert-True ($handoff25Text -match [regex]::Escape("./scripts/Initialize-Settings.ps1 -TenantId '$tenantGuid' -SubscriptionId '$member25Sub' -SharedSubscriptionId '$sharedGuid' -MemberIndex 25 -Location 'swedencentral' -Suffix '$member25Suffix' -WriteLabCredentials")) "Handoff card missing exact Initialize-Settings one-liner: $handoff25Text"
    Write-Output 'PASS: 25-member cohort creates private repos, persists suffixes, sets push/pull permissions, writes handoff cards, and prints zero GUIDs'
    $passed++

    # 2a. Fails closed when TemplateRepository has is_template = false.
    $stateNotTemplate = Get-DefaultState
    $stateNotTemplate['template']['is_template'] = $false
    $smallRosterPath = Join-Path $work 'small-roster.json'
    ConvertTo-Json -InputObject @([ordered]@{
        index          = 1
        subscriptionId = (Get-TestGuid -Number 1)
        suffix         = 'abc123'
    }) -Depth 5 | Set-Content -Path $smallRosterPath -Encoding utf8NoBOM

    $cmd2a = "& '$cohortScript' -RosterPath '$smallRosterPath' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -HandoffDirectory '$(Join-Path $work 's2a-handoff')'"
    $res2a = Invoke-CohortRun -ScenarioName 'not-template' -State $stateNotTemplate -CommandText $cmd2a
    Assert-True ($res2a.ExitCode -ne 0 -and $res2a.Output -match '--template') "Expected --template failure: $($res2a.Output)"
    Assert-True ($res2a.State['repos'].Count -eq 0) 'No student repo may be created when template check fails.'
    $passed++

    # 2b. Fails closed when TemplateRepository lacks factory/scripts/Initialize-Settings.ps1.
    $stateMissingKit = Get-DefaultState
    $stateMissingKit['template']['files'] = @(
        'app/ContosoUniversity/ContosoUniversity.csproj',
        '.github/workflows/platform.yml',
        'infra/bicep/university/azure.yaml'
    )
    $cmd2b = "& '$cohortScript' -RosterPath '$smallRosterPath' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -HandoffDirectory '$(Join-Path $work 's2b-handoff')'"
    $res2b = Invoke-CohortRun -ScenarioName 'missing-kit-file' -State $stateMissingKit -CommandText $cmd2b
    Assert-True ($res2b.ExitCode -ne 0 -and $res2b.Output -match 'factory/scripts/Initialize-Settings\.ps1') "Expected missing file failure: $($res2b.Output)"
    Assert-True ($res2b.State['repos'].Count -eq 0) 'No student repo may be created when template lacks kit files.'
    Write-Output 'PASS: template repository validation fails closed before touching student repositories'
    $passed++

    # 3a. Fails closed when existing target repo is public (private = false).
    $statePublicExisting = Get-DefaultState
    $statePublicExisting['repos']['contoso/factory-student-01'] = @{
        private            = $false
        topics             = @('apex-factory-student')
        template_full_name = 'contoso/factory-template'
        commits            = @(@{ sha = 'abc' })
        collaborators      = @{}
        teams              = @{}
        contents           = @{}
    }
    $cmd3a = "& '$cohortScript' -RosterPath '$smallRosterPath' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -HandoffDirectory '$(Join-Path $work 's3a-handoff')'"
    $res3a = Invoke-CohortRun -ScenarioName 'existing-public' -State $statePublicExisting -CommandText $cmd3a
    Assert-True ($res3a.ExitCode -ne 0 -and $res3a.Output -match 'not private') "Expected refusal on public existing repo: $($res3a.Output)"
    $passed++

    # 3b. Fails closed when existing target repo is private but lacks provenance topic and template origin.
    $stateUnrelated = Get-DefaultState
    $stateUnrelated['repos']['contoso/factory-student-01'] = @{
        private            = $true
        topics             = @('unrelated-project')
        template_full_name = ''
        commits            = @(@{ sha = 'abc' })
        collaborators      = @{}
        teams              = @{}
        contents           = @{}
    }
    $cmd3b = "& '$cohortScript' -RosterPath '$smallRosterPath' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -HandoffDirectory '$(Join-Path $work 's3b-handoff')'"
    $res3b = Invoke-CohortRun -ScenarioName 'existing-unrelated' -State $stateUnrelated -CommandText $cmd3b
    Assert-True ($res3b.ExitCode -ne 0 -and $res3b.Output -match 'apex-factory-student') "Expected refusal on unrelated existing repo: $($res3b.Output)"
    $passed++

    # 3c. Succeeds idempotently when existing repo is private and carries apex-factory-student topic.
    $stateValidExisting = Get-DefaultState
    $stateValidExisting['repos']['contoso/factory-student-01'] = @{
        private            = $true
        topics             = @('apex-factory-student')
        template_full_name = ''
        commits            = @(@{ sha = 'abc' })
        collaborators      = @{}
        teams              = @{}
        contents           = @{}
    }
    $cmd3c = "& '$cohortScript' -RosterPath '$smallRosterPath' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -CoachUsername 'coach-bob' -HandoffDirectory '$(Join-Path $work 's3c-handoff')'"
    $res3c = Invoke-CohortRun -ScenarioName 'existing-valid' -State $stateValidExisting -CommandText $cmd3c
    Assert-True ($res3c.ExitCode -eq 0) "Expected idempotent reuse of valid private student repo: $($res3c.Output)"
    Assert-True (-not ($res3c.Calls | Where-Object { $_ -like 'repo create*' })) 'Must not call gh repo create for an existing valid repo.'
    Assert-True ($res3c.State['repos']['contoso/factory-student-01']['collaborators']['coach-bob'] -eq 'pull') 'Collaborators should still converge on existing valid repo.'
    Write-Output 'PASS: existing repository privacy and provenance checks fail closed and converge idempotently'
    $passed++

    # 4. -PushReadinessEvidence uploads each member's distinct test-datacenter.txt without cross-member overwrites.
    $stateEvidence = Get-DefaultState
    $evidenceRosterPath = Join-Path $work 'evidence-roster.json'
    ConvertTo-Json -InputObject @(
        [ordered]@{ index = 1; subscriptionId = (Get-TestGuid -Number 1); memberPrincipalId = (Get-TestGuid -Number 101); suffix = 'mem001' },
        [ordered]@{ index = 2; subscriptionId = (Get-TestGuid -Number 2); memberPrincipalId = (Get-TestGuid -Number 102); suffix = 'mem002' },
        [ordered]@{ index = 35; subscriptionId = (Get-TestGuid -Number 35); memberPrincipalId = (Get-TestGuid -Number 135); suffix = 'mem035' }
    ) -Depth 5 | Set-Content -Path $evidenceRosterPath -Encoding utf8NoBOM

    $cmd4 = "& '$cohortScript' -RosterPath '$evidenceRosterPath' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -PushReadinessEvidence -LeadRepository 'contoso/factory-lead' -HandoffDirectory '$(Join-Path $work 's4-handoff')'"
    $res4 = Invoke-CohortRun -ScenarioName 'push-evidence-1' -State $stateEvidence -CommandText $cmd4
    Assert-True ($res4.ExitCode -eq 0) "-PushReadinessEvidence failed: $($res4.Output)"
    Assert-True ($res4.Output -notmatch $guidRegex) "-PushReadinessEvidence output leaked a GUID: $($res4.Output)"

    $evPath = 'factory/evidence/readiness/test-datacenter.txt'
    foreach ($pair in @(@(1, '01'), @(2, '02'), @(35, '35'))) {
        $mIdx = $pair[0]
        $mPad = $pair[1]
        $b64 = $res4.State['repos']["contoso/factory-student-$mPad"]['contents'][$evPath]['content']
        Assert-True ([bool] $b64) "Missing uploaded evidence for member $mIdx"
        $decoded = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
        Assert-True ($decoded -eq "PASS datacenter member $mIdx marker-$mIdx") "Member $mIdx received wrong evidence '$decoded'"
    }

    # Re-running with identical content skips redundant PUTs.
    $res4Rerun = Invoke-CohortRun -ScenarioName 'push-evidence-2' -State $res4.State -CommandText $cmd4
    Assert-True ($res4Rerun.ExitCode -eq 0) "Idempotent -PushReadinessEvidence rerun failed: $($res4Rerun.Output)"
    $putEvidenceCalls = @($res4Rerun.Calls | Where-Object { $_ -like 'api -X PUT repos/*/contents/factory/evidence/readiness/test-datacenter.txt*' })
    Assert-True ($putEvidenceCalls.Count -eq 0) "Expected 0 redundant evidence PUTs on rerun, got $($putEvidenceCalls.Count)"
    Write-Output 'PASS: -PushReadinessEvidence uploads distinct per-member artifacts (including >30) and skips identical reruns'
    $passed++

    # 5. CSV roster persists generated suffixes across reruns, skips owner/admin collaborator downgrade, and resolves partial-matrix + single-slot recovery evidence.
    $stateRecovery = Get-DefaultState
    $stateRecovery['runs'] = @(@{ databaseId = 9002 }, @{ databaseId = 9001 })
    $stateRecovery['run_artifacts'] = @{
        '9001' = @{
            'readiness-test-datacenter-member-1' = "PASS: all 46 checks passed. Member 1 from matrix run 9001"
            'readiness-test-datacenter-member-2' = "Checking datacenter...`nFAIL: 1 of 46 checks failed."
        }
        '9002' = @{
            'readiness-test-datacenter-member-2' = "PASS: all 46 checks passed. Member 2 from recovery run 9002"
        }
    }
    $stateRecovery['repos']['contoso/factory-student-01'] = @{
        private            = $true
        topics             = @('apex-factory-student')
        template_full_name = 'contoso/factory-template'
        commits            = @(@{ sha = 'abc' })
        collaborators      = @{ 'lead-admin' = 'admin' }
        teams              = @{}
        contents           = @{}
    }
    $csvRosterPath = Join-Path $work 'cohort.csv'
    @(
        [pscustomobject]@{
            'Member index'             = '1'
            'Workload subscription ID' = (Get-TestGuid -Number 1)
            'Entra object ID'          = (Get-TestGuid -Number 101)
            'Budget email'             = 'lead@example.test'
            'GitHub handle'            = 'lead-admin'
        },
        [pscustomobject]@{
            'Member index'             = '2'
            'Workload subscription ID' = (Get-TestGuid -Number 2)
            'Entra object ID'          = (Get-TestGuid -Number 102)
            'Budget email'             = 'owner@example.test'
            'GitHub handle'            = 'contoso'
        }
    ) | Export-Csv -Path $csvRosterPath -NoTypeInformation -Encoding utf8NoBOM

    $cmd5 = "& '$cohortScript' -RosterPath '$csvRosterPath' -TemplateRepository 'contoso/factory-template' -TenantId '$tenantGuid' -SharedSubscriptionId '$sharedGuid' -CoachUsername 'contoso','lead-admin' -PushReadinessEvidence -LeadRepository 'contoso/factory-lead' -HandoffDirectory '$(Join-Path $work 's5-handoff')'"
    $res5 = Invoke-CohortRun -ScenarioName 'csv-and-recovery-1' -State $stateRecovery -CommandText $cmd5
    Assert-True ($res5.ExitCode -eq 0) "CSV & partial-matrix recovery scenario failed: $($res5.Output)"
    Assert-True ($res5.State['repos']['contoso/factory-student-01']['collaborators']['lead-admin'] -eq 'admin') 'Existing admin collaborator must not be downgraded to push or pull.'
    Assert-True (-not $res5.State['repos']['contoso/factory-student-02']['collaborators'].ContainsKey('contoso')) 'Repository owner handle must not receive student or coach collaborator PUT.'

    $csvAfter1 = @(Import-Csv -Path $csvRosterPath)
    Assert-True ($csvAfter1[0].suffix -cmatch '^[a-z][a-z0-9]{5}$' -and $csvAfter1[1].suffix -cmatch '^[a-z][a-z0-9]{5}$') 'CSV roster must persist generated suffixes.'
    $res5Rerun = Invoke-CohortRun -ScenarioName 'csv-and-recovery-2' -State $res5.State -CommandText $cmd5
    Assert-True ($res5Rerun.ExitCode -eq 0) "CSV rerun failed: $($res5Rerun.Output)"
    $csvAfter2 = @(Import-Csv -Path $csvRosterPath)
    Assert-True ($csvAfter2[0].suffix -eq $csvAfter1[0].suffix -and $csvAfter2[1].suffix -eq $csvAfter1[1].suffix) 'CSV rerun must preserve persisted suffixes without drifting.'

    $ev1 = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($res5.State['repos']['contoso/factory-student-01']['contents'][$evPath]['content']))
    $ev2 = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($res5.State['repos']['contoso/factory-student-02']['contents'][$evPath]['content']))
    Assert-True ($ev1 -match 'run 9001' -and $ev2 -match 'run 9002') "Expected member 1 from 9001 and member 2 from 9002, got '$ev1' and '$ev2'"
    Write-Output 'PASS: CSV suffix persistence, owner/admin collaborator preservation, and partial-failure recovery evidence lookup'
    $passed++

    Write-Output "PASS: $passed Initialize-CohortRepos scenarios (no GitHub or Azure calls)."
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
