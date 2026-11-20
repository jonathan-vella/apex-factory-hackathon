#Requires -Version 7.4

<#
.SYNOPSIS
Deploys ALZ-lite, the team's landing zone, with the shared services subscription.
.DESCRIPTION
Deploys infra/foundation/alz-lite/main.bicep at the Tenant Root management group:
- management groups <MgPrefix> (under Tenant Root), <MgPrefix>-platform and <MgPrefix>-corp;
- the shared services subscription moved into <MgPrefix>-platform;
- in it: rg-management with log-management (30-day retention) and id-sqlmi-directory (the identity that
  members' SQL Managed Instances use to look up Entra principals), and rg-hub with vnet-hub 10.100.0.0/16,
  afw-hub (Azure Firewall Standard, no zones) with pip-afw-hub and afwp-hub (DNS proxy on), and the
  privatelink zones for Blob, Service Bus, ACR and Key Vault linked to vnet-hub;
- Microsoft Defender for Cloud on Foundational CSPM only (every paid plan off, unless -SkipDefender);
- the core policies at <MgPrefix>-corp (built-in definitions, display names prefixed ALZ-lite:).
The team lead runs it once per team at Step 2 (T-7), then a directory administrator grants the SQL MI identity
its Microsoft Graph read permissions. The team lead runs vending through GitHub Actions at Step 4 (T-1),
after every member completes Step 3; this script does not vend subscriptions. It needs Owner at the Tenant Root
management group and checks that first. A re-run converges. Use -WhatIf to
see the changes (az deployment mg what-if) without deploying. The deployment takes 15-25 minutes, mostly Azure Firewall.
.PARAMETER SharedSubscriptionId
The team's shared services subscription.
.PARAMETER Location
The Azure region. Fallback: germanywestcentral.
.PARAMETER MgPrefix
Prefix of the kit's management groups, so several kits can coexist in one tenant.
.PARAMETER AdditionalAllowedLocation
Regions to allow at <MgPrefix>-corp besides Location and global, for example the fallback region.
.PARAMETER ParentManagementGroupId
The management group to deploy under, instead of Tenant Root. Use it for a sandbox group: you then need Owner there, not at Tenant Root.
Leave it empty at an event. The script also accepts a service principal or managed identity (a pipeline).
.PARAMETER SkipDefender
Leave the subscription's Defender for Cloud plans as they are. Without it, every paid plan is turned off
subscription-wide (Foundational CSPM only), including for resources the kit didn't create. Use it only in
a subscription that hosts other workloads; event subscriptions are dedicated, so leave it off there.
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
    [string[]] $AdditionalAllowedLocation = @(),
    [ValidatePattern('^$|^[A-Za-z0-9._()-]{1,90}$')]
    [string] $ParentManagementGroupId = '',
    [ValidatePattern('^$|^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')]
    [string] $ReaderGroupId = '',
    [switch] $SkipDefender
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
. (Join-Path $PSScriptRoot 'FactoryReaderAccess.ps1')
$template = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'infra', 'foundation', 'alz-lite', 'main.bicep'
if (-not $ReaderGroupId) {
    if (-not $WhatIfPreference) { throw 'Foundation requires the Entra reader group ID. Run Sync-FactoryReaderGroup.ps1 in Bootstrap mode first.' }
    Write-Information 'Reader group assignment is not included in this preview: the group has not been configured.'
}

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

function Get-OptionalResource {
    param([string[]] $Arguments)
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $reason = (($output | ForEach-Object { $_.ToString() }) -join ' ') -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '<id>'
        if ($reason -match 'ResourceGroupNotFound|ResourceNotFound|\(NotFound\)|Not Found') {
            return $null
        }
        $what = ($Arguments | Select-Object -First 3) -join ' '
        throw "Lookup '$what' failed (exit $LASTEXITCODE): $($reason.Substring(0, [Math]::Min(300, $reason.Length)))"
    }
    $text = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() }) -join "`n"
    if ($text.Trim()) {
        return $text | ConvertFrom-Json
    }
    return $null
}

function Get-CallerRoleName {
    param([string] $Scope)
    $account = Invoke-AzureCli -Arguments @('account', 'show')
    if ($account.user.type -ne 'servicePrincipal') {
        $userId = (Invoke-AzureCli -Arguments @('ad', 'signed-in-user', 'show')).id
        return @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--assignee', $userId, '--scope', $Scope,
                '--include-inherited', '--include-groups') | ForEach-Object { $_.roleDefinitionName })
    }
    # A service principal or managed identity (a pipeline): take its object ID from the ARM token, so no Microsoft Graph call is needed.
    $token = Invoke-AzureCli -Arguments @('account', 'get-access-token', '--resource', 'https://management.azure.com/', '--query', 'accessToken')
    $payload = $token.Split('.')[1].Replace('-', '+').Replace('_', '/')
    $payload += '=' * ((4 - $payload.Length % 4) % 4)
    $objectId = ([System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json).oid
    return @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $Scope, '--include-inherited') |
            Where-Object { $_.principalId -eq $objectId } | ForEach-Object { $_.roleDefinitionName })
}

function Initialize-ManagementGroup {
    # ARM can't authorize a nested deployment at a group that the same template creates, for an identity whose
    # Owner is at the parent (Tenant Root included; a person with elevated access at / doesn't hit it). Create the
    # three groups first; the deployment then converges them.
    param([string] $ParentId, [string] $Prefix)
    foreach ($group in @(@{ Name = $Prefix; Parent = $ParentId }, @{ Name = "$Prefix-platform"; Parent = $Prefix }, @{ Name = "$Prefix-corp"; Parent = $Prefix })) {
        $PSNativeCommandUseErrorActionPreference = $false
        & az account management-group show --name $group.Name --only-show-errors --output none 2>$null
        if ($LASTEXITCODE -ne 0) {
            # A new group, or a role granted minutes ago, can take a while to be authorized: retry before giving up.
            for ($attempt = 1; $true; $attempt++) {
                try {
                    $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'create', '--name', $group.Name, '--display-name', $group.Name, '--parent', $group.Parent)
                    break
                }
                catch {
                    if ($attempt -ge 5) { throw }
                    Write-Information "Creating $($group.Name) failed (attempt $attempt of 5); waiting 30 seconds for the authorization to propagate."
                    Start-Sleep -Seconds 30
                }
            }
            Write-Information "Created management group $($group.Name)."
        }
    }
    $corpScope = "/providers/Microsoft.Management/managementGroups/$Prefix-corp"
    for ($attempt = 1; $attempt -le 8; $attempt++) {
        try {
            if (@(Get-CallerRoleName -Scope $corpScope) -contains 'Owner') { break }
        }
        catch {
            Write-Verbose "Waiting for Owner propagation at $corpScope (attempt $attempt)."
        }
        if ($attempt -lt 8) {
            Write-Information "Waiting 15 seconds for Owner role inheritance to propagate to $Prefix-corp (attempt $attempt of 8)."
            Start-Sleep -Seconds 15
        }
    }
}

function Assert-ParentOwner {
    param([string] $TenantId, [string] $ParentId)
    $scope = "/providers/Microsoft.Management/managementGroups/$ParentId"
    $where = if ($ParentId -eq $TenantId) { 'the Tenant Root management group' } else { "the management group '$ParentId'" }
    $roles = @(Get-CallerRoleName -Scope $scope)
    if ($roles -notcontains 'Owner') {
        throw @"
You need Owner at $where to create management groups, move subscriptions and
assign policies there. You have: $(if ($roles) { $roles -join ', ' } else { 'no role' }).
Ask a Global Administrator to elevate access (Microsoft Entra ID > Properties > Access management for
Azure resources: Yes), then to give you Owner at $where`:
  az role assignment create --assignee <your-object-id> --role Owner --scope $scope
Sign out and in again (az logout; az login), then re-run this script.
"@
    }
}

$account = Invoke-AzureCli -Arguments @('account', 'show')
$tenantId = $account.tenantId
$parentId = if ($ParentManagementGroupId) { $ParentManagementGroupId } else { $tenantId }
$null = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SharedSubscriptionId)
Assert-ParentOwner -TenantId $tenantId -ParentId $parentId
Write-Information "Permissions: Owner at $(if ($parentId -eq $tenantId) { 'the Tenant Root management group' } else { "the management group '$parentId'" })."

Write-Information @"

Deploying ALZ-lite to ${Location}:
  Management groups  $MgPrefix > $MgPrefix-platform (shared services subscription), $MgPrefix-corp (workload subscriptions)
  rg-management      log-management (30-day retention), id-sqlmi-directory (SQL MI's directory identity)
  rg-hub             vnet-hub 10.100.0.0/16, afw-hub (Azure Firewall Standard, no zones) with pip-afw-hub,
                     afwp-hub (DNS proxy on), privatelink zones for Blob, Service Bus, ACR and Key Vault
  Defender for Cloud $(if ($SkipDefender) { 'left as it is (-SkipDefender)' } else { 'Foundational CSPM only: every paid plan off on the shared services subscription' })
  Policies           at $MgPrefix-corp: allowed locations, audit ($(@($Location, 'global') + $AdditionalAllowedLocation -join ', ')),
                     resource location matches its resource group (audit), no public IPs on NICs,
                     public network access off (Storage, Key Vault, Service Bus, ACR,
                     SQL MI), private DNS registration and diagnostics to log-management
Cost: about `$1.30/hour while it exists: Azure Firewall Standard about `$1.25/hour plus its public IP,
  and Log Analytics at low volume. The firewall bills until rg-hub is deleted.
This takes 15-25 minutes, mostly Azure Firewall.

"@

$existingPolicy = Get-OptionalResource -Arguments @(
    'resource', 'show',
    '--subscription', $SharedSubscriptionId,
    '-g', 'rg-hub',
    '-n', 'afwp-hub',
    '--resource-type', 'Microsoft.Network/firewallPolicies',
    '--api-version', '2025-09-01'
)
[string[]] $extraSnatPrefixes = @(
    if ($existingPolicy -and $existingPolicy.properties -and $existingPolicy.properties.snat -and $existingPolicy.properties.snat.privateRanges) {
        $existingPolicy.properties.snat.privateRanges | ForEach-Object { [string] $_ }
    }
)

$parametersFile = Join-Path ([System.IO.Path]::GetTempPath()) "alz-lite-$([guid]::NewGuid()).parameters.json"
@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        location = @{ value = $Location }
        mgPrefix = @{ value = $MgPrefix }
        sharedSubscriptionId = @{ value = $SharedSubscriptionId }
        readerGroupId = @{ value = $ReaderGroupId }
        additionalAllowedLocations = @{ value = @($AdditionalAllowedLocation) }
        setDefenderFoundationalOnly = @{ value = -not $SkipDefender.IsPresent }
        extraSnatPrefixes = @{ value = @($extraSnatPrefixes) }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $parametersFile -Encoding utf8NoBOM -WhatIf:$false

$deploymentArgs = @('--management-group-id', $parentId, '--name', "alz-lite-$MgPrefix", '--location', $Location,
    '--template-file', $template, '--parameters', "@$parametersFile")
try {
    if (-not $PSCmdlet.ShouldProcess("Tenant Root management group, shared services subscription", 'Deploy ALZ-lite')) {
        $PSNativeCommandUseErrorActionPreference = $false
        & az deployment mg what-if @deploymentArgs --only-show-errors
        return
    }
    $started = Get-Date
    Write-Information "Deployment started at $($started.ToString('HH:mm'))."
    Initialize-ManagementGroup -ParentId $parentId -Prefix $MgPrefix
    $deployment = Invoke-AzureCli -Arguments (@('deployment', 'mg', 'create') + $deploymentArgs)
}
finally {
    Remove-Item -Path $parametersFile -Force -ErrorAction SilentlyContinue -WhatIf:$false
}

$kitScope = "/providers/Microsoft.Management/managementGroups/$MgPrefix"
$assignments = @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $kitScope, '--fill-principal-name', 'false'))
$staleReaders = @($assignments | Where-Object {
    $_.principalId -ne $ReaderGroupId -and (Test-FactoryReaderAssignment -Assignment $_ -Scope $kitScope)
})
if ($staleReaders.Count) {
    Write-Warning 'An older kit reader group assignment remains. Verify the new binding before reviewing and retiring the older assignment.'
}

$elapsed = (Get-Date) - $started
$outputs = $deployment.properties.outputs
Write-Information @"

ALZ-lite is deployed ($([int] $elapsed.TotalMinutes) minutes).
  Management groups  $($outputs.rootManagementGroup.value), $($outputs.platformManagementGroup.value), $($outputs.corpManagementGroup.value)
  Hub firewall       afw-hub, private IP $($outputs.firewallPrivateIp.value): the DNS server and next hop for spokes and datacenters
  Workspace          log-management in rg-management
  SQL MI identity    id-sqlmi-directory in rg-management
Policies can take up to 30 minutes to take effect.
Once per team, a Privileged Role Administrator grants id-sqlmi-directory its Microsoft Graph read permissions:
  ./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId <shared-services-subscription-id>
At Step 4 (T-1), after Step 2 and every member's Step 3 are complete, the team lead runs the vending stage in GitHub Actions for every member:
  gh workflow run platform.yml -f stage=vending
See https://factory.apexops.pro/deploy/how-it-works/ for stage timings.
"@
