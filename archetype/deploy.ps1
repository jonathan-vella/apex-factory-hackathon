#Requires -Version 7.4

<#
.SYNOPSIS
Deploys the CoE archetype (the Contoso University platform) into an already-vended spoke, without APEX.
.DESCRIPTION
The no-agent fallback for B09 requirement 14: a plain `az deployment sub create` of this folder's
infra/bicep/university/main.bicep (subscription-scope; the template creates its own resource group,
rg-university-<suffix>), using the same three inputs as APEX Deploy. Everything else is discovered,
not asked for:
- the region, from the hub's vnet-hub in the shared services subscription (found via vnet-spoke's peering);
- the spoke and its subnets (rg-spoke, vnet-spoke, snet-app, snet-pe, snet-sqlmi), by the backlog naming
  convention -- this script never creates them; run scripts/Deploy-Vending.ps1 (B08) first if they're missing;
- the central Log Analytics workspace (log-management in rg-management), by the ALZ-lite name, in the
  shared services subscription;
- the SQL Managed Instance's Entra admin, from the signed-in user.
Resource names follow the kit convention: CAF abbreviation + "university" + suffix.
Use -WhatIf to preview the deployment without applying it.
.PARAMETER TenantId
The Entra tenant the workload subscription is in.
.PARAMETER SubscriptionId
The workload subscription. Must already have a vended spoke (rg-spoke, vnet-spoke, snet-app, snet-pe,
snet-sqlmi) -- run scripts/Deploy-Vending.ps1 first if it doesn't.
.PARAMETER Suffix
4-6 lowercase letters/digits, unique per member.
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./archetype/deploy.ps1 -TenantId $s.tenantId -SubscriptionId $s.subscriptionId -Suffix $s.suffix -WhatIf
.EXAMPLE
./archetype/deploy.ps1 -TenantId '<tenant-id>' -SubscriptionId '<subscription-id>' -Suffix 'ab12cd'
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $TenantId,
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SubscriptionId,
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9]{4,6}$')]
    [string] $Suffix
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$template = Join-Path -Path $PSScriptRoot -ChildPath 'infra', 'bicep', 'university', 'main.bicep'
$deploymentName = "archetype-university-$Suffix"

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
        Write-Verbose "Resource not found: $($Arguments -join ' ') ($($_.Exception.Message))"
        return $null
    }
}

if (-not (Test-Path $template)) {
    throw "Bicep template not found at $template. This script expects APEX's generated Bicep to already be in infra/bicep/university/ alongside this script (B09 packaging)."
}

$account = Invoke-AzureCli -Arguments @('account', 'show')
if ($account.tenantId -ne $TenantId) {
    throw "Signed in to tenant $($account.tenantId), not $TenantId. Run az login --tenant $TenantId and az account set --subscription $SubscriptionId first."
}
$null = Invoke-AzureCli -Arguments @('account', 'set', '--subscription', $SubscriptionId)
$deployer = Invoke-AzureCli -Arguments @('ad', 'signed-in-user', 'show')
if (-not $deployer) {
    throw 'No interactive Entra user is signed in. The SQL Managed Instance needs an Entra user as its admin; sign in with az login (not a service principal) and retry.'
}

# The vended spoke, by the backlog naming convention. This script never creates it.
$spokeVnet = Get-OptionalResource -Arguments @('network', 'vnet', 'show', '-g', 'rg-spoke', '-n', 'vnet-spoke')
if (-not $spokeVnet) {
    throw "rg-spoke/vnet-spoke not found in subscription $SubscriptionId. Run scripts/Deploy-Vending.ps1 (B08) first; this script never creates the spoke."
}
$subnetNames = @($spokeVnet.subnets | ForEach-Object { $_.name })
foreach ($required in 'snet-app', 'snet-pe', 'snet-sqlmi') {
    if ($subnetNames -notcontains $required) {
        throw "$required is missing from vnet-spoke. Re-run scripts/Deploy-Vending.ps1 (B08) to repair the spoke."
    }
}

# The hub, discovered through the spoke's peering, so the region always matches the team's hub.
$peering = $spokeVnet.virtualNetworkPeerings | Where-Object { $_.remoteVirtualNetwork.id -match '/virtualNetworks/vnet-hub$' } | Select-Object -First 1
if (-not $peering) {
    throw 'vnet-spoke has no peering to a hub VNet named vnet-hub. Run scripts/Deploy-Vending.ps1 (B08) first.'
}
$hubSubscriptionId = ($peering.remoteVirtualNetwork.id -split '/')[2]
$hubVnet = Invoke-AzureCli -Arguments @('network', 'vnet', 'show', '--subscription', $hubSubscriptionId, '-g', 'rg-hub', '-n', 'vnet-hub')
$location = $hubVnet.location
$workspace = Invoke-AzureCli -Arguments @('resource', 'show', '--subscription', $hubSubscriptionId, '-g', 'rg-management', '-n', 'log-management',
    '--resource-type', 'Microsoft.OperationalInsights/workspaces')

# The shared SQL MI directory identity (PR #46), discovered by name in the shared services subscription.
# The signed-in user needs Managed Identity Operator on it (granted to all members by vending); this
# script never creates it.
$directoryIdentity = Get-OptionalResource -Arguments @('identity', 'show', '--subscription', $hubSubscriptionId, '-g', 'rg-management', '-n', 'id-sqlmi-directory')
if (-not $directoryIdentity) {
    throw "rg-management/id-sqlmi-directory not found in the shared services subscription. Run scripts/Deploy-AlzLite.ps1 (PR #46) first; this script never creates it."
}

Write-Information @"

Archetype inputs for member suffix '$Suffix':
  Region                    $location (from the hub)
  Spoke                     $($spokeVnet.id)
  Log Analytics workspace   $($workspace.id)
  SQL MI directory identity $($directoryIdentity.id)
  SQL MI Entra admin        $($deployer.userPrincipalName)
Cost while deployed: about `$4.63/hour (SQL MI GP 4 vCores ~`$0.68, Service Bus Premium ~`$0.93, App Service
P0v3 ~`$0.10, ACR Premium ~`$0.07, private endpoints ~`$0.05). The SQL MI provisions in the background after
the rest of the platform is ready; expect it to still be "Updating" for several minutes after this script
returns.
"@

# main.bicep is a subscription-scope deployment: it creates rg-university-<suffix> itself and derives the
# vended spoke's subnet IDs from the signed-in subscription, so the spoke is never passed in by ID.
$parametersFile = Join-Path ([System.IO.Path]::GetTempPath()) "archetype-university-$([guid]::NewGuid()).parameters.json"
@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        suffix = @{ value = $Suffix }
        tenantId = @{ value = $TenantId }
        location = @{ value = $location }
        logAnalyticsWorkspaceId = @{ value = $workspace.id }
        sqlMiDirectoryIdentityId = @{ value = $directoryIdentity.id }
        deployerObjectId = @{ value = $deployer.id }
        deployerPrincipalName = @{ value = $deployer.userPrincipalName }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $parametersFile -Encoding utf8NoBOM -WhatIf:$false

$deploymentArgs = @('--name', $deploymentName, '--location', $location, '--template-file', $template,
    '--parameters', "@$parametersFile")
try {
    if (-not $PSCmdlet.ShouldProcess("subscription $SubscriptionId", 'Deploy the CoE archetype')) {
        $PSNativeCommandUseErrorActionPreference = $false
        & az deployment sub what-if @deploymentArgs --only-show-errors
        return
    }
    $started = Get-Date
    Write-Information "Deployment started at $($started.ToString('HH:mm'))."
    $null = Invoke-AzureCli -Arguments (@('deployment', 'sub', 'create') + $deploymentArgs)
    $elapsed = (Get-Date) - $started
    Write-Information "Archetype deployed in $([int] $elapsed.TotalMinutes) minutes (excluding the SQL MI, which keeps provisioning in the background)."
}
finally {
    Remove-Item -Path $parametersFile -Force -ErrorAction SilentlyContinue -WhatIf:$false
}
