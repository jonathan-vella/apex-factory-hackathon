#Requires -Version 7.4

<#
.SYNOPSIS
Vends every member of a team, one after another, for the platform pipeline.
.DESCRIPTION
The vending stage of platform.yml, in three phases, each starting with a fresh OIDC login so a long run never outlives
its token:
1. For each member index, in the order given: the guard for that member's subscription, a check that the member's
   datacenter exists and vm-app01 is Arc-connected (the member stage comes before vending, and vending connects it), then
   Deploy-Vending.ps1. Members are vended strictly one at a time, because every run updates the shared firewall policy afwp-hub.
2. Every VM of every member restarts at once, and the script waits once, so the VMs pick up the hub's DNS. The SQL VM alone
   takes about 25 minutes, so restarting member by member would multiply that wait.
3. New-DatacenterExemptions.ps1 and Test-Connectivity.ps1 for all members in parallel, each on its own subscription.
It stops at the first member that fails to vend and says which. After a failure in phase 2 or 3 the members are already
vended: run the stage again for the ones that failed. It prints no subscription ID. Needs the foundation (ALZ-lite).
.PARAMETER RosterJson
The roster: a JSON array of objects with index, subscriptionId, memberPrincipalId and budgetEmail.
.PARAMETER MemberIndex
The members to vend, in order.
.PARAMETER SharedSubscriptionId
The team's shared services subscription.
.PARAMETER ClientId
The pipeline identity's client ID, for the fresh login. Skipped when not running in GitHub Actions.
.PARAMETER TenantId
The tenant ID, for the fresh login.
.PARAMETER MgPrefix
The kit's management-group prefix.
.PARAMETER ParentManagementGroupId
The parent group, empty for Tenant Root.
.PARAMETER Location
The Azure region.
.PARAMETER AllowedSubscriptionId
The guard's allowlist.
.PARAMETER DeniedSubscriptionId
The guard's deny list.
.PARAMETER DeniedMgPrefix
The guard's denied prefixes.
.EXAMPLE
./scripts/Invoke-PipelineVending.ps1 -RosterJson $roster -MemberIndex 1, 2 -SharedSubscriptionId $shared -MgPrefix mg-factory -AllowedSubscriptionId $allowed
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $RosterJson,
    [Parameter(Mandatory)]
    [int[]] $MemberIndex,
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId,
    [string] $ClientId = '',
    [string] $TenantId = '',
    [Parameter(Mandatory)]
    [string] $MgPrefix,
    [string] $ParentManagementGroupId = '',
    [string] $Location = 'swedencentral',
    [string[]] $AllowedSubscriptionId = @(),
    [string[]] $DeniedSubscriptionId = @(),
    [string[]] $DeniedMgPrefix = @()
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$roster = @($RosterJson | ConvertFrom-Json)
$summary = [System.Collections.Generic.List[string]]::new()
$allowed = $AllowedSubscriptionId
$denied = $DeniedSubscriptionId
$deniedPrefixes = $DeniedMgPrefix

function Invoke-Native {
    param([scriptblock] $Command, [string] $Step)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Step failed (exit $LASTEXITCODE)." }
}

# Every phase starts with a fresh OIDC login, so a long stage never outlives its token.
function Connect-Pipeline {
    param([string] $Client, [string] $Tenant)
    if ($env:ACTIONS_ID_TOKEN_REQUEST_URL -and $Client -and $Tenant) {
        $token = (Invoke-RestMethod -Uri "$($env:ACTIONS_ID_TOKEN_REQUEST_URL)&audience=api://AzureADTokenExchange" `
                    -Headers @{ Authorization = "Bearer $($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN)" }).value
            Write-Information "::add-mask::$token"
        Invoke-Native -Step 'The fresh login' -Command {
            az login --service-principal --username $Client --tenant $Tenant --federated-token $token --allow-no-subscriptions --only-show-errors --output none
        }
    }
}

# Phase 1: vend every member, strictly one after another, because every run updates the shared firewall policy.
$vended = [System.Collections.Generic.List[object]]::new()
foreach ($index in $MemberIndex) {
    $member = $roster | Where-Object { [int] $_.index -eq $index } | Select-Object -First 1
    if (-not $member -or -not $member.subscriptionId) { throw "Member $index is not in the roster." }
    $workload = [string] $member.subscriptionId
    Write-Information "::group::Member $index"
    try {
        Invoke-Native -Step "The guard for member $index" -Command {
            & (Join-Path $PSScriptRoot 'Assert-PipelineGuard.ps1') -SubscriptionId $SharedSubscriptionId, $workload `
                -AllowedSubscriptionId $allowed -DeniedSubscriptionId $denied `
                -MgPrefix $MgPrefix -AllowedMgPrefix $MgPrefix -DeniedMgPrefix $deniedPrefixes
        }
        Connect-Pipeline -Client $ClientId -Tenant $TenantId

        $PSNativeCommandUseErrorActionPreference = $false
        & az network vnet show --subscription $workload -g rg-datacenter -n vnet-datacenter --only-show-errors --output none 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Member $index has no datacenter. Complete the member's Step 3 datacenter setup before Step 4 vending; the team foundation must already be deployed at Step 2."
        }
        $arcStatus = (& az resource show --subscription $workload -g rg-datacenter --resource-type Microsoft.HybridCompute/machines -n vm-app01 --query properties.status -o tsv --only-show-errors 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $arcStatus -ne 'Connected') {
            $seen = if ($arcStatus) { $arcStatus } else { 'missing' }
            throw "Member $index is not ready for vending: vm-app01 in rg-datacenter is not Arc-connected (status: $seen). Finish Step 3 (the member stage) first."
        }

        $vending = @{
            WorkloadSubscriptionId = $workload; SharedSubscriptionId = $SharedSubscriptionId; MemberIndex = $index
            MgPrefix = $MgPrefix; ParentManagementGroupId = $ParentManagementGroupId; Location = $Location; BudgetEmail = [string] $member.budgetEmail
        }
        if (-not $vending.BudgetEmail) { throw "The roster has no budget email for member $index." }
        if ($member.memberPrincipalId) { $vending['MemberPrincipalId'] = [string] $member.memberPrincipalId }
        & (Join-Path $PSScriptRoot 'Deploy-Vending.ps1') @vending
        $vended.Add([pscustomobject]@{ Index = $index; Workload = $workload })
    }
    catch {
        Write-Information '::endgroup::'
        throw "Vending stopped at member $index (members before it are vended, nothing has been restarted or probed): $($_.Exception.Message)"
    }
    Write-Information '::endgroup::'
}

# Phase 2: restart every VM of every member at once and wait once, so the VMs pick up the hub's DNS. The SQL VM alone
# takes about 25 minutes, so restarting member by member would multiply that wait by the number of members.
Write-Information '::group::Restarting the datacenter VMs of every member'
Connect-Pipeline -Client $ClientId -Tenant $TenantId
$restartJobs = foreach ($vendedMember in $vended) {
    foreach ($vmName in 'vm-app01', 'vm-dev01') {
        $sub = $vendedMember.Workload; $idx = $vendedMember.Index
        Start-ThreadJob -ThrottleLimit 64 -ScriptBlock {
            $text = (& az vm restart --subscription $using:sub -g rg-datacenter -n $using:vmName --only-show-errors 2>&1 | Out-String)
            $masked = $text -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '<id>'
            [pscustomobject]@{ Index = $using:idx; Vm = $using:vmName; Exit = $LASTEXITCODE; Detail = $masked.Trim() }
        }
    }
}
$restartResults = @($restartJobs | Wait-Job | Receive-Job)
$restartJobs | Remove-Job -Force
$restartFailures = @($restartResults | Where-Object { $_.Exit -ne 0 })
if ($restartResults.Count -ne @($restartJobs).Count -or $restartFailures.Count -gt 0) {
    Write-Information '::endgroup::'
    $which = ($restartFailures | ForEach-Object { "member $($_.Index) $($_.Vm)" }) -join ', '
    throw "Restarting the VMs failed ($which). The members are vended; run the vending stage again to finish them."
}
Write-Information "Restarted $($restartResults.Count) VMs for $($vended.Count) member(s)."
Write-Information '::endgroup::'

# Phase 3: the exemptions and the connectivity probe, for all members in parallel (each touches its own subscription).
Connect-Pipeline -Client $ClientId -Tenant $TenantId
$exemptionsScript = Join-Path $PSScriptRoot 'New-DatacenterExemptions.ps1'
$connectivityScript = Join-Path $PSScriptRoot 'Test-Connectivity.ps1'
$sharedId = $SharedSubscriptionId
$probeJobs = foreach ($vendedMember in $vended) {
    $sub = $vendedMember.Workload; $idx = $vendedMember.Index
    Start-ThreadJob -ThrottleLimit 64 -ScriptBlock {
        $InformationPreference = 'Continue'
        $state = @{ Code = 1 }
        $output = & {
            try {
                # New-DatacenterExemptions.ps1 signals failure by throwing, and its nothing-to-do path returns with whatever
                # $LASTEXITCODE an earlier az call left behind, so its exit code isn't checked.
                & $using:exemptionsScript -SubscriptionId $using:sub -Owner 'GitHub Actions pipeline'
                $global:LASTEXITCODE = 0
                & $using:connectivityScript -SubscriptionId $using:sub -SharedSubscriptionId $using:sharedId -MemberIndex $using:idx
                $state.Code = $LASTEXITCODE
            }
            catch { "ERROR: $($_.Exception.Message)" }
        } *>&1 | Out-String
        [pscustomobject]@{ Index = $using:idx; Exit = $state.Code; Output = $output }
    }
}
$probeResults = @($probeJobs | Wait-Job | Receive-Job | Sort-Object Index)
$probeJobs | Remove-Job -Force
$failedMembers = [System.Collections.Generic.List[int]]::new()
foreach ($result in $probeResults) {
    Write-Information "::group::Member $($result.Index): exemptions and connectivity"
    Write-Information $result.Output
    Write-Information '::endgroup::'
    if ($result.Exit -eq 0) { $summary.Add("Member $($result.Index): vended and connected to the hub.") } else { $failedMembers.Add($result.Index) }
}
if ($probeResults.Count -ne $vended.Count) { throw 'Not every member reported a result from the exemptions and probes.' }
if ($failedMembers.Count -gt 0) {
    $summary | ForEach-Object { Write-Information $_ }
    throw "The exemptions or the connectivity test failed for member(s) $($failedMembers -join ', '). They are vended: fix the cause and run the vending stage again for them."
}

$summary.Add('A datacenter redeploy resets its DNS and routes: run the vending stage again for that member.')
if ($env:GITHUB_STEP_SUMMARY) { $summary -join "`n" | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append }
$summary | ForEach-Object { Write-Information $_ }
exit 0
