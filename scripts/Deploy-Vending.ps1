#Requires -Version 7.4

<#
.SYNOPSIS
Vends a member's workload subscription: places it under <MgPrefix>-corp and connects it to the hub.
.DESCRIPTION
Deploys infra/foundation/vending/main.bicep at the Tenant Root management group. It finds the team's hub
in the shared services subscription by the ALZ-lite names (vnet-hub, afw-hub, afwp-hub, rg-hub,
log-management) and prints what it found. Then it:
- moves the workload subscription into <MgPrefix>-corp;
- creates rg-spoke with vnet-spoke 10.20.n.0/24: snet-app (delegated to Microsoft.Web/serverFarms),
  snet-pe, snet-sqlmi (delegated to Microsoft.Sql/managedInstances, with nsg-sqlmi and rt-sqlmi);
- peers vnet-spoke and, if rg-datacenter exists, vnet-datacenter with vnet-hub, both ways;
- points both VNets' DNS at the firewall, and adds the UDRs: snet-app and snet-pe send everything to the
  firewall, snet-sqlmi sends the datacenter range, snet-servers sends the spoke range and keeps internet
  egress on the NAT gateway;
- adds rule collection group rcg-member-n to afwp-hub;
- gives the member Owner on the workload subscription (if -MemberPrincipalId is set), adds a monthly
  budget with an alert at 80%, and sets Defender for Cloud to Foundational CSPM only.
The platform lead runs it for every member, because it writes to the shared services subscription;
members need no role there. It needs Owner at the Tenant Root management group. Run it after the
datacenter exists, and again after any datacenter redeploy, which resets the datacenter's DNS servers
and route table. A re-run converges. Use -WhatIf to see the changes without deploying.
.PARAMETER WorkloadSubscriptionId
The member's workload subscription.
.PARAMETER SharedSubscriptionId
The team's shared services subscription, which holds the hub.
.PARAMETER MemberIndex
The member index n, 1-20.
.PARAMETER Location
The Azure region. Fallback: germanywestcentral.
.PARAMETER MgPrefix
Prefix of the kit's management groups, as passed to Deploy-AlzLite.ps1.
.PARAMETER MemberPrincipalId
Object ID of the member (user or group), who gets Owner on the workload subscription. Optional.
.PARAMETER BudgetAmount
Monthly budget on the workload subscription, in the billing currency.
.PARAMETER BudgetEmail
Email address for the budget alert at 80%.
.EXAMPLE
./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId '<workload-subscription-id>' -SharedSubscriptionId '<shared-services-subscription-id>' -MemberIndex 1 -BudgetEmail 'lead@contoso.com'
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex -BudgetEmail 'lead@contoso.com' -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $WorkloadSubscriptionId,
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId,
    [ValidateRange(1, 20)]
    [int] $MemberIndex = 1,
    [string] $Location = 'swedencentral',
    [ValidatePattern('^[A-Za-z0-9-]{2,40}$')]
    [string] $MgPrefix = 'mg-factory',
    [ValidatePattern('^$|^[0-9a-fA-F-]{36}$')]
    [string] $MemberPrincipalId = '',
    [ValidateRange(1, 1000000)]
    [int] $BudgetAmount = 500,
    [Parameter(Mandatory)]
    [ValidatePattern('^[^@\s]+@[^@\s]+$')]
    [string] $BudgetEmail
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$template = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'infra', 'foundation', 'vending', 'main.bicep'
$budgetName = 'budget-factory-workload'

function Invoke-AzureCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        $message = ($output | ForEach-Object { $_.ToString() }) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE): $message"
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
}

function Get-OptionalResource {
    param([string[]] $Arguments)
    try {
        return Invoke-AzureCli -Arguments $Arguments
    }
    catch {
        return $null
    }
}

function Assert-TenantRootOwner {
    param([string] $TenantId)
    $scope = "/providers/Microsoft.Management/managementGroups/$TenantId"
    $userId = (Invoke-AzureCli -Arguments @('ad', 'signed-in-user', 'show')).id
    $roles = @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--assignee', $userId, '--scope', $scope,
            '--include-inherited', '--include-groups') | ForEach-Object { $_.roleDefinitionName })
    if ($roles -notcontains 'Owner') {
        throw @"
You need Owner at the Tenant Root management group to move the workload subscription and write to
both subscriptions. You have: $(if ($roles) { $roles -join ', ' } else { 'no role' }).
The platform lead runs vending; see scripts/Deploy-AlzLite.ps1 for how to get the role.
"@
    }
}

$account = Invoke-AzureCli -Arguments @('account', 'show')
$tenantId = $account.tenantId
$null = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $WorkloadSubscriptionId)
$null = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SharedSubscriptionId)
Assert-TenantRootOwner -TenantId $tenantId

# The hub, by the ALZ-lite names.
$hubVnet = Get-OptionalResource -Arguments @('network', 'vnet', 'show', '--subscription', $SharedSubscriptionId, '-g', 'rg-hub', '-n', 'vnet-hub')
$firewall = Get-OptionalResource -Arguments @('resource', 'show', '--subscription', $SharedSubscriptionId, '-g', 'rg-hub', '-n', 'afw-hub',
    '--resource-type', 'Microsoft.Network/azureFirewalls')
$workspace = Get-OptionalResource -Arguments @('resource', 'show', '--subscription', $SharedSubscriptionId, '-g', 'rg-management', '-n', 'log-management',
    '--resource-type', 'Microsoft.OperationalInsights/workspaces')
if (-not ($hubVnet -and $firewall -and $workspace)) {
    throw 'The hub is incomplete in the shared services subscription (vnet-hub, afw-hub or log-management missing). Run scripts/Deploy-AlzLite.ps1 first.'
}
$hubRgId = (Invoke-AzureCli -Arguments @('group', 'show', '--subscription', $SharedSubscriptionId, '-n', 'rg-hub')).id
$firewallIp = $firewall.properties.ipConfigurations[0].properties.privateIPAddress
$firewallPolicyId = $firewall.properties.firewallPolicy.id

$datacenterVnet = Get-OptionalResource -Arguments @('network', 'vnet', 'show', '--subscription', $WorkloadSubscriptionId, '-g', 'rg-datacenter', '-n', 'vnet-datacenter')
$connectDatacenter = [bool] $datacenterVnet

# A budget's start date can't change: keep the existing one on re-runs.
$budgetUri = "https://management.azure.com/subscriptions/$WorkloadSubscriptionId/providers/Microsoft.Consumption/budgets/${budgetName}?api-version=2024-08-01"
$budget = Get-OptionalResource -Arguments @('rest', '--method', 'get', '--uri', $budgetUri)
$budgetStart = if ($budget) { ([datetime] $budget.properties.timePeriod.startDate).ToString('yyyy-MM-dd') } else { (Get-Date).ToUniversalTime().ToString('yyyy-MM-01') }

Write-Information @"

Hub found in the shared services subscription:
  Hub VNet           $($hubVnet.id)
  Firewall           afw-hub, private IP $firewallIp
  Firewall policy    $firewallPolicyId
  DNS zones in       $hubRgId
  Workspace          $($workspace.id)
Vending member $MemberIndex to ${Location}:
  Placement          workload subscription into $MgPrefix-corp
  Spoke              rg-spoke, vnet-spoke 10.20.$MemberIndex.0/24: snet-app .0/26, snet-pe .64/26, snet-sqlmi .128/26
  Datacenter         $(if ($connectDatacenter) { 'vnet-datacenter peered with the hub, DNS and rt-servers set' } else { 'not found: not connected. Re-run after deploying it.' })
  Firewall rules     rcg-member-$MemberIndex in afwp-hub
  Owner              $(if ($MemberPrincipalId) { $MemberPrincipalId } else { 'skipped (no -MemberPrincipalId)' })
  Budget             $BudgetAmount a month from $budgetStart, alert at 80% to $BudgetEmail
  Defender for Cloud Foundational CSPM only on the workload subscription
Cost: no hourly cost. Peering traffic is billed per GB, and the hub's firewall processes it.

"@

$parametersFile = Join-Path ([System.IO.Path]::GetTempPath()) "vending-$([guid]::NewGuid()).parameters.json"
@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        location = @{ value = $Location }
        memberIndex = @{ value = $MemberIndex }
        mgPrefix = @{ value = $MgPrefix }
        workloadSubscriptionId = @{ value = $WorkloadSubscriptionId }
        sharedSubscriptionId = @{ value = $SharedSubscriptionId }
        hubVnetId = @{ value = $hubVnet.id }
        firewallPrivateIp = @{ value = $firewallIp }
        firewallPolicyId = @{ value = $firewallPolicyId }
        dnsZoneResourceGroupId = @{ value = $hubRgId }
        logAnalyticsWorkspaceId = @{ value = $workspace.id }
        memberPrincipalId = @{ value = $MemberPrincipalId }
        budgetAmount = @{ value = $BudgetAmount }
        budgetEmail = @{ value = $BudgetEmail }
        budgetStartDate = @{ value = $budgetStart }
        connectDatacenter = @{ value = $connectDatacenter }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $parametersFile -Encoding utf8NoBOM -WhatIf:$false

$deploymentArgs = @('--management-group-id', $tenantId, '--name', "vending-$MgPrefix-$MemberIndex", '--location', $Location,
    '--template-file', $template, '--parameters', "@$parametersFile")
try {
    if (-not $PSCmdlet.ShouldProcess("workload subscription of member $MemberIndex", 'Vend and connect to the hub')) {
        $PSNativeCommandUseErrorActionPreference = $false
        & az deployment mg what-if @deploymentArgs --only-show-errors
        return
    }
    $started = Get-Date
    Write-Information "Deployment started at $($started.ToString('HH:mm'))."
    $null = Invoke-AzureCli -Arguments (@('deployment', 'mg', 'create') + $deploymentArgs)
}
finally {
    Remove-Item -Path $parametersFile -Force -ErrorAction SilentlyContinue -WhatIf:$false
}

# Policy evaluation lags a subscription move: start a scan now rather than wait for the next cycle.
$PSNativeCommandUseErrorActionPreference = $false
& az policy state trigger-scan --subscription $WorkloadSubscriptionId --no-wait --only-show-errors
$elapsed = (Get-Date) - $started
Write-Information @"

Member $MemberIndex is vended ($([int] $elapsed.TotalMinutes) minutes). A policy compliance scan is running.
$(if ($connectDatacenter) { @"
The datacenter now uses the hub's DNS. Running VMs pick it up after a restart or ipconfig /renew:
  az vm restart --subscription <subscription-id> -g rg-datacenter -n vm-app01 --no-wait
  az vm restart --subscription <subscription-id> -g rg-datacenter -n vm-dev01 --no-wait
Then record the datacenter's policy exemptions and run the probes:
  ./scripts/New-DatacenterExemptions.ps1 -SubscriptionId <subscription-id> -Owner '<owner name>'
  ./scripts/Test-Connectivity.ps1 -SubscriptionId <subscription-id> -SharedSubscriptionId <shared-services-subscription-id> -MemberIndex $MemberIndex
"@ } else { 'Deploy the datacenter, then run this script again to connect it.' })
"@
