#Requires -Version 7.4

<#
.SYNOPSIS
Deploys ALZ-lite, the team's landing zone, with the shared services subscription.
.DESCRIPTION
Deploys infra/foundation/alz-lite/main.bicep at the Tenant Root management group:
- management groups <MgPrefix> (under Tenant Root), <MgPrefix>-platform and <MgPrefix>-corp;
- the shared services subscription moved into <MgPrefix>-platform;
- in it: rg-management with log-management (30-day retention), and rg-hub with vnet-hub 10.100.0.0/16,
  afw-hub (Azure Firewall Standard, no zones) with pip-afw-hub and afwp-hub (DNS proxy on), and the
  privatelink zones for Blob, Service Bus, ACR and Key Vault linked to vnet-hub;
- Microsoft Defender for Cloud on Foundational CSPM only (every paid plan off);
- the core policies at <MgPrefix>-corp (built-in definitions, display names prefixed ALZ-lite:).
The platform lead runs it once per team, then scripts/Deploy-Vending.ps1 for every member. It needs
Owner at the Tenant Root management group and checks that first. A re-run converges. Use -WhatIf to
see the changes (az deployment mg what-if) without deploying. Azure Firewall takes 10-15 minutes.
.PARAMETER SharedSubscriptionId
The team's shared services subscription.
.PARAMETER Location
The Azure region. Fallback: germanywestcentral.
.PARAMETER MgPrefix
Prefix of the kit's management groups, so several kits can coexist in one tenant.
.PARAMETER AdditionalAllowedLocation
Regions to allow at <MgPrefix>-corp besides Location and global, for example the fallback region.
.EXAMPLE
./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $SharedSubscriptionId,
    [string] $Location = 'swedencentral',
    [ValidatePattern('^[A-Za-z0-9-]{2,40}$')]
    [string] $MgPrefix = 'mg-factory',
    [string[]] $AdditionalAllowedLocation = @()
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$template = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'infra', 'foundation', 'alz-lite', 'main.bicep'

function Invoke-AzureCli {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE)."
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
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
You need Owner at the Tenant Root management group to create management groups, move subscriptions and
assign policies there. You have: $(if ($roles) { $roles -join ', ' } else { 'no role' }).
Ask a Global Administrator to elevate access (Microsoft Entra ID > Properties > Access management for
Azure resources: Yes), then to give you Owner at Tenant Root:
  az role assignment create --assignee <your-object-id> --role Owner --scope $scope
Sign out and in again (az logout; az login), then re-run this script.
"@
    }
}

$account = Invoke-AzureCli -Arguments @('account', 'show')
$tenantId = $account.tenantId
$null = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SharedSubscriptionId)
Assert-TenantRootOwner -TenantId $tenantId
Write-Information 'Permissions: Owner at the Tenant Root management group.'

Write-Information @"

Deploying ALZ-lite to ${Location}:
  Management groups  $MgPrefix > $MgPrefix-platform (shared services subscription), $MgPrefix-corp (workload subscriptions)
  rg-management      log-management (30-day retention)
  rg-hub             vnet-hub 10.100.0.0/16, afw-hub (Azure Firewall Standard, no zones) with pip-afw-hub,
                     afwp-hub (DNS proxy on), privatelink zones for Blob, Service Bus, ACR and Key Vault
  Defender for Cloud Foundational CSPM only: every paid plan off on the shared services subscription
  Policies           at $MgPrefix-corp: allowed locations ($(@($Location, 'global') + $AdditionalAllowedLocation -join ', ')),
                     no public IPs on NICs, public network access off (Storage, Key Vault, Service Bus, ACR,
                     SQL MI), private DNS registration and diagnostics to log-management
Cost: about `$1.30/hour while it exists: Azure Firewall Standard about `$1.25/hour plus its public IP,
  and Log Analytics at low volume. The firewall bills until rg-hub is deleted.
This takes 15-25 minutes, mostly Azure Firewall.

"@

$parametersFile = Join-Path ([System.IO.Path]::GetTempPath()) "alz-lite-$([guid]::NewGuid()).parameters.json"
@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        location = @{ value = $Location }
        mgPrefix = @{ value = $MgPrefix }
        sharedSubscriptionId = @{ value = $SharedSubscriptionId }
        additionalAllowedLocations = @{ value = @($AdditionalAllowedLocation) }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $parametersFile -Encoding utf8NoBOM

$deploymentArgs = @('--management-group-id', $tenantId, '--name', "alz-lite-$MgPrefix", '--location', $Location,
    '--template-file', $template, '--parameters', "@$parametersFile")
try {
    if (-not $PSCmdlet.ShouldProcess("Tenant Root management group, shared services subscription", 'Deploy ALZ-lite')) {
        $PSNativeCommandUseErrorActionPreference = $false
        & az deployment mg what-if @deploymentArgs --only-show-errors
        return
    }
    $started = Get-Date
    Write-Information "Deployment started at $($started.ToString('HH:mm'))."
    $deployment = Invoke-AzureCli -Arguments (@('deployment', 'mg', 'create') + $deploymentArgs)
}
finally {
    Remove-Item -Path $parametersFile -Force -ErrorAction SilentlyContinue
}

$elapsed = (Get-Date) - $started
$outputs = $deployment.properties.outputs
Write-Information @"

ALZ-lite is deployed ($([int] $elapsed.TotalMinutes) minutes).
  Management groups  $($outputs.rootManagementGroup.value), $($outputs.platformManagementGroup.value), $($outputs.corpManagementGroup.value)
  Hub firewall       afw-hub, private IP $($outputs.firewallPrivateIp.value): the DNS server and next hop for spokes and datacenters
  Workspace          log-management in rg-management
Policies can take up to 30 minutes to take effect.
Next, for every member (after their datacenter exists):
  ./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId <workload-subscription-id> -SharedSubscriptionId <shared-services-subscription-id> -MemberIndex <n> -BudgetEmail <email>
"@
