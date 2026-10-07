#Requires -Version 7.0
<#
.SYNOPSIS
    Read-only preflight for the university archetype: validates inputs and the landing-zone prerequisites and derives deployment values.

.DESCRIPTION
    Runs PowerShell 7 and the Azure CLI only (Windows, Linux, macOS, Cloud Shell). It never prompts and never creates,
    changes or deletes an Azure resource. It fails closed with a message naming the missing item, so nothing is deployed
    unless every check passes. Checks, in order: inputs and generated names, spoke, hub and region, central workspace,
    vended budget, hub firewall egress rules, deployer permissions, name availability, the ALZ-lite DeployIfNotExists
    assignments, and the SQL MI directory identity. On success it returns one object with the values the template needs and sets the matching process
    environment variables.

.PARAMETER TenantId
    Entra tenant ID. Defaults to the AZURE_TENANT_ID environment variable.

.PARAMETER SubscriptionId
    Workload subscription ID. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER Suffix
    Member-chosen uniqueness suffix, 4-6 lowercase letters or digits. Defaults to the SUFFIX environment variable.

.EXAMPLE
    ./preflight.ps1 -TenantId $env:AZURE_TENANT_ID -SubscriptionId $env:AZURE_SUBSCRIPTION_ID -Suffix ab12cd

.OUTPUTS
    PSCustomObject with Location, LogAnalyticsWorkspaceId, SqlMiDirectoryIdentityId, DeployerObjectId and DeployerUpn.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$TenantId = $env:AZURE_TENANT_ID,

    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,

    [ValidateNotNullOrEmpty()]
    [string]$Suffix = $env:SUFFIX
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$ProjectName = 'university'
$SpokeResourceGroup = 'rg-spoke'
$SpokeVnet = 'vnet-spoke'
$ApprovedRegions = @('swedencentral', 'germanywestcentral')
$BudgetName = 'budget-factory-workload'
$FirewallPolicyName = 'afwp-hub'
$WorkspaceResourceGroup = 'rg-management'
$WorkspaceName = 'log-management'
$DirectoryIdentityName = 'id-sqlmi-directory'

function Stop-Preflight {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)
    $record = [System.Management.Automation.ErrorRecord]::new(
        [System.InvalidOperationException]::new("Preflight failed: $Message"),
        'UniversityPreflightFailed',
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $null)
    $PSCmdlet.ThrowTerminatingError($record)
}

function Write-Check {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "  [ok] $Message"
}

function Invoke-AzJson {
    # Runs az and returns parsed JSON; stderr is kept apart so warnings cannot corrupt the payload.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )
    $all = & az @Arguments --only-show-errors --output json 2>&1
    $exitCode = $LASTEXITCODE
    $errors = @($all | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() })
    $text = (@($all | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) -join "`n").Trim()
    if ($exitCode -ne 0) {
        if ($AllowFailure) { return $null }
        Stop-Preflight "az $($Arguments[0..([Math]::Min(2, $Arguments.Count - 1))] -join ' ') failed: $($errors -join ' ')"
    }
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text | ConvertFrom-Json -Depth 32
}

function ConvertTo-AzRestBody {
    # az.cmd on Windows needs embedded quotes escaped; other platforms pass the JSON as is.
    param([Parameter(Mandatory)]$Object)
    $json = $Object | ConvertTo-Json -Compress -Depth 5
    if ($IsWindows) { return $json.Replace('"', '\"') }
    return $json
}

function Test-ActionAllowed {
    # Effective-permission match: an action is allowed when some permission entry grants it and does not exclude it.
    param(
        [Parameter(Mandatory)][object[]]$Permissions,
        [Parameter(Mandatory)][string]$Action
    )
    foreach ($entry in $Permissions) {
        $granted = @($entry.actions) | Where-Object { $Action -like $_ }
        if (-not $granted) { continue }
        $denied = @($entry.notActions) | Where-Object { $_ -and ($Action -like $_) }
        if (-not $denied) { return $true }
    }
    return $false
}

function Assert-Permission {
    param(
        [Parameter(Mandatory)][string]$Scope,
        [Parameter(Mandatory)][string]$ScopeLabel,
        [Parameter(Mandatory)][string[]]$Actions,
        [string]$Remedy = 'Ask the facilitator to correct the vended access (B08).'
    )
    $response = Invoke-AzJson -Arguments @('rest', '--method', 'get', '--url', "$Scope/providers/Microsoft.Authorization/permissions?api-version=2022-04-01")
    $permissions = @($response.value)
    foreach ($action in $Actions) {
        if (-not (Test-ActionAllowed -Permissions $permissions -Action $action)) {
            Stop-Preflight "the signed-in user lacks '$action' on $ScopeLabel. $Remedy"
        }
    }
}

function Test-NameOwnedByMember {
    # A name that is taken by this member's own earlier deployment is fine, so re-runs converge.
    param([Parameter(Mandatory)][string]$ResourceGroup, [Parameter(Mandatory)][string]$Name)
    $exists = Invoke-AzJson -Arguments @('group', 'exists', '--name', $ResourceGroup) -AllowFailure
    if ($exists -ne $true) { return $false }
    $found = Invoke-AzJson -Arguments @('resource', 'list', '--resource-group', $ResourceGroup, '--query', "[?name=='$Name'].id") -AllowFailure
    return (@($found).Count -gt 0)
}

function Test-RuleSource {
    param($Rule, [string]$Prefix)
    return (@($Rule.sourceAddresses) -contains $Prefix)
}

function Invoke-UniversityPreflight {
    [CmdletBinding()]
    param()

    Write-Host "Preflight for '$ProjectName' (read-only)"

    # 1. Inputs and names
    if ($Suffix -cnotmatch '^[a-z0-9]{4,6}$') {
        Stop-Preflight "SUFFIX '$Suffix' must be 4-6 lowercase letters or digits."
    }
    $resourceGroup = "rg-$ProjectName-$Suffix"
    $names = [ordered]@{
        Registry   = "cr$ProjectName$Suffix"
        Storage    = "st$ProjectName$Suffix"
        ServiceBus = "sbns-$ProjectName-$Suffix"
        KeyVault   = "kv-$ProjectName-$Suffix"
        WebApp     = "app-$ProjectName-$Suffix"
        SqlMi      = "sqlmi-$ProjectName-$Suffix"
    }
    if ($names.Storage -cnotmatch '^[a-z0-9]{3,24}$') { Stop-Preflight "Storage account name '$($names.Storage)' must be 3-24 lowercase alphanumeric characters." }
    if ($names.KeyVault.Length -gt 24) { Stop-Preflight "Key Vault name '$($names.KeyVault)' exceeds 24 characters." }
    $account = Invoke-AzJson -Arguments @('account', 'show')
    if ($account.tenantId -ne $TenantId) { Stop-Preflight 'the signed-in tenant does not match AZURE_TENANT_ID.' }
    if ($account.id -ne $SubscriptionId) { Stop-Preflight "the active subscription '$($account.name)' does not match AZURE_SUBSCRIPTION_ID; run 'az account set'." }
    Write-Check "inputs valid; signed in to subscription '$($account.name)'; names fit service limits"

    # 2. Spoke
    $vnet = Invoke-AzJson -Arguments @('network', 'vnet', 'show', '--resource-group', $SpokeResourceGroup, '--name', $SpokeVnet)
    $subnets = @{}
    foreach ($subnet in @($vnet.subnets)) { $subnets[$subnet.name] = $subnet }
    $delegations = @{ 'snet-app' = 'Microsoft.Web/serverFarms'; 'snet-pe' = $null; 'snet-sqlmi' = 'Microsoft.Sql/managedInstances' }
    foreach ($name in $delegations.Keys) {
        if (-not $subnets.ContainsKey($name)) { Stop-Preflight "subnet '$name' is missing in $SpokeResourceGroup/$SpokeVnet (rerun vending, B08)." }
        $delegated = @($subnets[$name].delegations | ForEach-Object { $_.serviceName })
        if ($delegations[$name] -and ($delegated -notcontains $delegations[$name])) {
            Stop-Preflight "subnet '$name' is not delegated to $($delegations[$name])."
        }
    }
    $appPrefix = $subnets['snet-app'].addressPrefix
    $clusters = Invoke-AzJson -Arguments @('sql', 'virtual-cluster', 'list') -AllowFailure
    $onMiSubnet = @($clusters) | Where-Object { $_ -and $_.subnetId -ieq $subnets['snet-sqlmi'].id }
    foreach ($cluster in $onMiSubnet) {
        $members = @($cluster.childResources)
        if ($members.Count -eq 0) {
            Stop-Preflight "a SQL virtual cluster from a deleted managed instance still holds snet-sqlmi. The platform releases it later (this can take hours); re-run when it is gone."
        }
        $foreign = @($members | Where-Object { $_ -notmatch "/managedInstances/$([regex]::Escape($names.SqlMi))$" })
        if ($foreign.Count -gt 0) { Stop-Preflight 'snet-sqlmi already hosts another managed instance.' }
    }
    Write-Check 'spoke subnets present with the expected delegations; no leftover SQL virtual cluster'

    # 3. Hub and region
    $peering = @($vnet.virtualNetworkPeerings | Where-Object { $_.peeringState -eq 'Connected' }) | Select-Object -First 1
    if (-not $peering) { Stop-Preflight 'no Connected peering on the spoke VNet (rerun vending, B08).' }
    $hub = Invoke-AzJson -Arguments @('network', 'vnet', 'show', '--ids', $peering.remoteVirtualNetwork.id)
    $location = $hub.location
    if ($ApprovedRegions -notcontains $location) {
        Stop-Preflight "the hub region '$location' is not an approved region ($($ApprovedRegions -join ', ')); stopping rather than moving the deployment."
    }
    $hubSubscriptionId = ($peering.remoteVirtualNetwork.id -split '/')[2]
    Write-Check "hub VNet found through the peering; region '$location' is approved"

    # 4. Central workspace
    $workspace = Invoke-AzJson -Arguments @('monitor', 'log-analytics', 'workspace', 'show', '--subscription', $hubSubscriptionId, '--resource-group', $WorkspaceResourceGroup, '--workspace-name', $WorkspaceName)
    if ($ApprovedRegions -notcontains $workspace.location) {
        Stop-Preflight "workspace '$WorkspaceName' is in '$($workspace.location)', which is not an approved EU region for telemetry."
    }
    Write-Check "workspace '$WorkspaceName' found in approved region '$($workspace.location)'"

    # 5. Budget (cost monitoring is inherited from vending)
    $budget = Invoke-AzJson -Arguments @('rest', '--method', 'get', '--url', "/subscriptions/$SubscriptionId/providers/Microsoft.Consumption/budgets/$($BudgetName)?api-version=2023-05-01")
    $contacts = @($budget.properties.notifications.PSObject.Properties | ForEach-Object { $_.Value.contactEmails } | Where-Object { $_ })
    if ($contacts.Count -lt 1) { Stop-Preflight "budget '$BudgetName' has no contact e-mail (rerun vending, B08)." }
    Write-Check "inherited budget '$BudgetName' present with alert recipients"

    # 6. Hub egress rules owned by vending
    $policy = @(Invoke-AzJson -Arguments @('network', 'firewall', 'policy', 'list', '--subscription', $hubSubscriptionId)) | Where-Object { $_.name -eq $FirewallPolicyName } | Select-Object -First 1
    if (-not $policy) { Stop-Preflight "firewall policy '$FirewallPolicyName' not found (rerun vending, B08)." }
    $groups = Invoke-AzJson -Arguments @('rest', '--method', 'get', '--url', "$($policy.id)/ruleCollectionGroups?api-version=2024-05-01")
    $rules = @($groups.value | ForEach-Object { $_.properties.ruleCollections } | ForEach-Object { $_.rules })
    $requirements = @(
        @{ Name = 'app-to-mcr'; Type = 'ApplicationRule'; Fqdns = @('mcr.microsoft.com', '*.data.mcr.microsoft.com') }
        @{ Name = 'app-to-azure-monitor'; Type = 'ApplicationRule'; Fqdns = @('*.in.applicationinsights.azure.com', 'dc.applicationinsights.azure.com', 'dc.applicationinsights.microsoft.com', 'dc.services.visualstudio.com', 'live.applicationinsights.azure.com', 'rt.applicationinsights.microsoft.com', 'rt.services.visualstudio.com', '*.livediagnostics.monitor.azure.com') }
        @{ Name = 'app-to-entra-id'; Type = 'NetworkRule'; Fqdns = @() }
    )
    foreach ($requirement in $requirements) {
        $rule = $rules | Where-Object { $_.name -eq $requirement.Name -and $_.ruleType -eq $requirement.Type } | Select-Object -First 1
        $ok = $null -ne $rule -and (Test-RuleSource -Rule $rule -Prefix $appPrefix)
        if ($ok -and $requirement.Type -eq 'ApplicationRule') {
            $targets = @($rule.targetFqdns)
            $ok = (@($requirement.Fqdns | Where-Object { $targets -notcontains $_ }).Count -eq 0) -and (@($rule.protocols | Where-Object { $_.protocolType -eq 'Https' -and [int]$_.port -eq 443 }).Count -gt 0)
        }
        elseif ($ok) {
            $ok = (@($rule.destinationAddresses) -contains 'AzureActiveDirectory') -and (@($rule.destinationPorts) -contains '443') -and (@($rule.ipProtocols) -contains 'TCP')
        }
        if (-not $ok) { Stop-Preflight "hub firewall rule '$($requirement.Name)' is missing or does not cover snet-app on port 443 (rerun vending, B08)." }
    }
    Write-Check 'hub firewall allows snet-app to MCR, Azure Monitor ingestion and Entra ID on 443'

    # 7. Deployer
    if ($account.user.type -ne 'user') { Stop-Preflight 'the signed-in principal is not a user; service principals are not supported (SQL MI Entra admin and data-plane roles target a user).' }
    $me = Invoke-AzJson -Arguments @('ad', 'signed-in-user', 'show')
    $deployerObjectId = $me.id
    $deployerUpn = $me.userPrincipalName
    $subscriptionScope = "/subscriptions/$SubscriptionId"
    $spokeScope = "$subscriptionScope/resourceGroups/$SpokeResourceGroup"
    Assert-Permission -Scope $subscriptionScope -ScopeLabel 'the workload subscription' -Actions @(
        'Microsoft.Resources/subscriptions/resourceGroups/write'
        'Microsoft.Resources/deployments/write'
        'Microsoft.Authorization/roleAssignments/write'
        'Microsoft.Consumption/budgets/read'
    )
    foreach ($subnetName in 'snet-app', 'snet-pe', 'snet-sqlmi') {
        Assert-Permission -Scope "$spokeScope/providers/Microsoft.Network/virtualNetworks/$SpokeVnet/subnets/$subnetName" -ScopeLabel "subnet $subnetName" -Actions @('Microsoft.Network/virtualNetworks/subnets/join/action')
    }
    Assert-Permission -Scope $policy.id -ScopeLabel "firewall policy $FirewallPolicyName" -Actions @('Microsoft.Network/firewallPolicies/read', 'Microsoft.Network/firewallPolicies/ruleCollectionGroups/read')
    Assert-Permission -Scope $peering.remoteVirtualNetwork.id -ScopeLabel 'the hub VNet' -Actions @('Microsoft.Network/virtualNetworks/read')
    Assert-Permission -Scope $workspace.id -ScopeLabel "workspace $WorkspaceName" -Actions @('Microsoft.OperationalInsights/workspaces/read', 'Microsoft.OperationalInsights/workspaces/sharedKeys/action')
    Write-Check 'signed-in user holds the deployment, role-assignment, subnet-join, budget, firewall and workspace permissions'

    # 8. Name collisions
    $registryCheck = Invoke-AzJson -Arguments @('acr', 'check-name', '--name', $names.Registry)
    $storageCheck = Invoke-AzJson -Arguments @('storage', 'account', 'check-name', '--name', $names.Storage)
    $busCheck = Invoke-AzJson -Arguments @('rest', '--method', 'post', '--url', "/subscriptions/$SubscriptionId/providers/Microsoft.ServiceBus/checkNameAvailability?api-version=2017-04-01", '--body', (ConvertTo-AzRestBody @{ name = $names.ServiceBus }))
    $webCheck = Invoke-AzJson -Arguments @('rest', '--method', 'post', '--url', "/subscriptions/$SubscriptionId/providers/Microsoft.Web/checkNameAvailability?api-version=2023-12-01", '--body', (ConvertTo-AzRestBody @{ name = $names.WebApp; type = 'Microsoft.Web/sites' }))
    $vaultCheck = Invoke-AzJson -Arguments @('keyvault', 'check-name', '--name', $names.KeyVault)
    $availability = @(
        @{ Label = 'container registry'; Name = $names.Registry; Available = $registryCheck.nameAvailable }
        @{ Label = 'storage account'; Name = $names.Storage; Available = $storageCheck.nameAvailable }
        @{ Label = 'Service Bus namespace'; Name = $names.ServiceBus; Available = $busCheck.nameAvailable }
        @{ Label = 'web app'; Name = $names.WebApp; Available = $webCheck.nameAvailable }
        @{ Label = 'Key Vault'; Name = $names.KeyVault; Available = $vaultCheck.nameAvailable }
    )
    foreach ($item in $availability) {
        if ($item.Available) { continue }
        if (Test-NameOwnedByMember -ResourceGroup $resourceGroup -Name $item.Name) { continue }
        if ($item.Label -eq 'Key Vault') {
            $deleted = @(Invoke-AzJson -Arguments @('keyvault', 'list-deleted', '--query', "[?name=='$($item.Name)']"))
            if ($deleted.Count -gt 0) {
                Stop-Preflight "Key Vault '$($item.Name)' is soft-deleted in this subscription. Purge it yourself if you intend to reuse the name: az keyvault purge --name $($item.Name) --location $location (never purged automatically)."
            }
        }
        Stop-Preflight "the $($item.Label) name '$($item.Name)' is already taken. Choose a different SUFFIX."
    }
    Write-Check 'globally unique names are available or already belong to this deployment'

    # 9. DeployIfNotExists assignments the landing zone must provide
    # `az policy assignment list` omits management-group assignments inherited by the subscription; the ARM atScope() filter returns them.
    $assignmentResponse = Invoke-AzJson -Arguments @('rest', '--method', 'get', '--url', ('/subscriptions/{0}/providers/Microsoft.Authorization/policyAssignments?api-version=2023-04-01&$filter=atScope()' -f $SubscriptionId))
    $assignments = @($assignmentResponse.value) | ForEach-Object {
        [PSCustomObject]@{
            displayName     = $_.properties.PSObject.Properties['displayName']?.Value
            enforcementMode = $_.properties.PSObject.Properties['enforcementMode']?.Value
            parameters      = $_.properties.PSObject.Properties['parameters']?.Value
        }
    }
    $dnsRequirements = @(
        @{ Match = 'Configure Container registries to use private DNS zones'; Zone = 'privatelink.azurecr.io' }
        @{ Match = 'Configure a private DNS Zone ID for blob groupID'; Zone = 'privatelink.blob.core.windows.net' }
        @{ Match = 'Configure Service Bus namespaces to use private DNS zones'; Zone = 'privatelink.servicebus.windows.net' }
        @{ Match = 'Configure Azure Key Vaults to use private DNS zones'; Zone = 'privatelink.vaultcore.azure.net' }
    )
    $diagnosticsRequirements = @(
        'Application Insights', 'Service Bus Namespaces', 'Blob Services', 'Container registries', 'App Service', 'Key vaults', 'SQL managed instances'
    )
    foreach ($requirement in $dnsRequirements) {
        $assignment = $assignments | Where-Object { $_.displayName -like "ALZ-lite:*$($requirement.Match)*" } | Select-Object -First 1
        if (-not $assignment -or $assignment.enforcementMode -ne 'Default') {
            Stop-Preflight "ALZ-lite private DNS assignment '$($requirement.Match)' is missing or not enforced. Re-run ALZ-lite (B08)."
        }
        $parameterText = $assignment.parameters | ConvertTo-Json -Depth 8 -Compress
        if ($parameterText -notmatch ('/resourceGroups/rg-hub/.*/' + [regex]::Escape($requirement.Zone))) {
            Stop-Preflight "ALZ-lite assignment '$($requirement.Match)' does not point at $($requirement.Zone) in rg-hub. Re-run ALZ-lite (B08)."
        }
    }
    foreach ($service in $diagnosticsRequirements) {
        $assignment = $assignments | Where-Object { $_.displayName -like "ALZ-lite:*$service*Log Analytics*" } | Select-Object -First 1
        if (-not $assignment -or $assignment.enforcementMode -ne 'Default') {
            Stop-Preflight "ALZ-lite diagnostics assignment for '$service' is missing or not enforced. Re-run ALZ-lite (B08)."
        }
        $parameterText = $assignment.parameters | ConvertTo-Json -Depth 8 -Compress
        if ($parameterText -notmatch [regex]::Escape("/workspaces/$WorkspaceName")) {
            Stop-Preflight "ALZ-lite diagnostics assignment for '$service' does not target workspace '$WorkspaceName'. Re-run ALZ-lite (B08)."
        }
    }
    Write-Check 'ALZ-lite private DNS and diagnostics assignments are present and enforced'

    # 10. SQL MI directory identity (B08-owned; holds the Microsoft Graph read grant the MI needs to create Entra users)
    $directoryIdentity = Invoke-AzJson -Arguments @('identity', 'show', '--subscription', $hubSubscriptionId, '--resource-group', $WorkspaceResourceGroup, '--name', $DirectoryIdentityName) -AllowFailure
    if (-not $directoryIdentity) {
        Stop-Preflight "managed identity '$DirectoryIdentityName' was not found in $WorkspaceResourceGroup of the shared services subscription, or cannot be read. Re-run ALZ-lite and vending (B08)."
    }
    Assert-Permission -Scope $directoryIdentity.id -ScopeLabel "identity $DirectoryIdentityName" -Actions @('Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action') -Remedy 'Re-run ALZ-lite and vending (B08).'
    Write-Check "SQL MI directory identity '$DirectoryIdentityName' exists and can be assigned by the signed-in user"

    # 11. Outputs
    $result = [PSCustomObject]@{
        Location                = $location
        LogAnalyticsWorkspaceId = $workspace.id
        SqlMiDirectoryIdentityId = $directoryIdentity.id
        DeployerObjectId        = $deployerObjectId
        DeployerUpn             = $deployerUpn
    }
    $env:AZURE_LOCATION = $result.Location
    $env:LOG_ANALYTICS_WORKSPACE_ID = $result.LogAnalyticsWorkspaceId
    $env:SQLMI_DIRECTORY_IDENTITY_ID = $result.SqlMiDirectoryIdentityId
    $env:DEPLOYER_OBJECT_ID = $result.DeployerObjectId
    $env:DEPLOYER_UPN = $result.DeployerUpn
    Write-Host 'Preflight passed.'
    return $result
}

Invoke-UniversityPreflight
