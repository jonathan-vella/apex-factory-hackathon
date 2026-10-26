#Requires -Version 7.4

<#
.SYNOPSIS
Vends every member of a team, one after another, for the platform pipeline.
.DESCRIPTION
The vending stage of platform.yml. For each member index, in the order given, it:
1. runs the guard for that member's subscription;
2. logs in again with a fresh OIDC token, so a long run never outlives its token;
3. checks that the member's datacenter exists (the datacenter comes before vending, and vending connects it);
4. runs Deploy-Vending.ps1, restarts both VMs so they pick up the hub's DNS, runs New-DatacenterExemptions.ps1
   and runs Test-Connectivity.ps1.
Members are vended strictly one at a time, because every run updates the shared firewall policy afwp-hub. It stops
at the first member that fails, and says which. It prints no subscription ID. Needs the foundation (ALZ-lite).
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

        if ($env:ACTIONS_ID_TOKEN_REQUEST_URL -and $ClientId -and $TenantId) {
            $token = (Invoke-RestMethod -Uri "$($env:ACTIONS_ID_TOKEN_REQUEST_URL)&audience=api://AzureADTokenExchange" `
                    -Headers @{ Authorization = "Bearer $($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN)" }).value
            Write-Information "::add-mask::$token"
            Invoke-Native -Step 'The fresh login' -Command {
                az login --service-principal --username $ClientId --tenant $TenantId --federated-token $token --allow-no-subscriptions --only-show-errors --output none
            }
        }

        $PSNativeCommandUseErrorActionPreference = $false
        & az network vnet show --subscription $workload -g rg-datacenter -n vnet-datacenter --only-show-errors --output none 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Member $index has no datacenter. Deploy it first: the datacenter comes before ALZ-lite and vending."
        }

        $vending = @{
            WorkloadSubscriptionId = $workload; SharedSubscriptionId = $SharedSubscriptionId; MemberIndex = $index
            MgPrefix = $MgPrefix; ParentManagementGroupId = $ParentManagementGroupId; Location = $Location; BudgetEmail = [string] $member.budgetEmail
        }
        if (-not $vending.BudgetEmail) { throw "The roster has no budget email for member $index." }
        if ($member.memberPrincipalId) { $vending['MemberPrincipalId'] = [string] $member.memberPrincipalId }
        & (Join-Path $PSScriptRoot 'Deploy-Vending.ps1') @vending

        # Both VMs restart at once (the restart of the SQL VM can take many minutes); the exemptions need them back up.
        $restarts = foreach ($vm in 'vm-app01', 'vm-dev01') {
            Start-ThreadJob -Name $vm -ScriptBlock {
                & az vm restart --subscription $using:workload -g rg-datacenter -n $using:vm --only-show-errors
                $LASTEXITCODE
            }
        }
        $restartExit = @($restarts | Wait-Job | Receive-Job | Where-Object { $_ -is [int] })
        $restarts | Remove-Job -Force
        if ($restartExit.Count -ne 2 -or ($restartExit | Where-Object { $_ -ne 0 })) { throw 'Restarting the VMs failed.' }
        # New-DatacenterExemptions.ps1 signals failure by throwing, and its nothing-to-do path returns with whatever
        # $LASTEXITCODE an earlier az call left behind, so its exit code isn't checked.
        Write-Information 'The policy exemptions'
        & (Join-Path $PSScriptRoot 'New-DatacenterExemptions.ps1') -SubscriptionId $workload -Owner 'GitHub Actions pipeline'
        $global:LASTEXITCODE = 0
        Invoke-Native -Step 'The connectivity test' -Command {
            & (Join-Path $PSScriptRoot 'Test-Connectivity.ps1') -SubscriptionId $workload -SharedSubscriptionId $SharedSubscriptionId -MemberIndex $index
        }
        $summary.Add("Member ${index}: vended and connected to the hub.")
    }
    catch {
        Write-Information '::endgroup::'
        throw "Vending stopped at member $index (members before it are done): $($_.Exception.Message)"
    }
    Write-Information '::endgroup::'
}

$summary.Add('A datacenter redeploy resets its DNS and routes: run the vending stage again for that member.')
if ($env:GITHUB_STEP_SUMMARY) { $summary -join "`n" | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append }
$summary | ForEach-Object { Write-Information $_ }
exit 0
