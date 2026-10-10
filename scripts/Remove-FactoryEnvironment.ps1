#Requires -Version 7.4

<#
.SYNOPSIS
Removes the named kit resources for one member or one event team.
.DESCRIPTION
Use -Scope Member once for each workload subscription, then -Scope Team once for the shared services
subscription and kit management groups. The member scope removes only the archetype resource group
derived from the suffix, rg-spoke and rg-datacenter, plus the matching Arc metadata and vending budget.
It waits for SQL MI to release snet-sqlmi before deleting the spoke and purges only the matching
soft-deleted Key Vault.

The team scope discovers workload subscriptions only as direct children of <MgPrefix>-corp and the
shared subscription only as a direct child of <MgPrefix>-platform. It removes named vending and policy
artifacts, deletes rg-hub and the log-management workspace, preserves rg-management/id-sqlmi-directory
and its Microsoft Graph grant, moves the discovered subscriptions to the return management group, and
deletes only <MgPrefix>-corp, <MgPrefix>-platform and <MgPrefix>. It refuses to delete those groups
if unexpected children remain. The active Azure CLI tenant must match the shared-services subscription.

Each member runs the member scope from their own factory/ folder, with Owner on their own workload subscription.
The platform lead, with Owner at Tenant Root, runs the team scope once, after every member has finished.

The script prints its exact plan and prompts once before changes. -WhatIf prints the plan without
changing Azure. -Force skips the confirmation prompt, but does not override -WhatIf. It never deletes
a subscription, an unrelated management group or a resource group outside the kit's explicit names.
.PARAMETER Scope
Member removes one member's workload resources; Team removes one team's platform resources.
.PARAMETER SubscriptionId
The workload subscription for -Scope Member.
.PARAMETER MemberIndex
The member index, 1-20, for -Scope Member.
.PARAMETER Suffix
The archetype suffix, 4-6 lowercase letters or digits, for -Scope Member.
.PARAMETER SharedSubscriptionId
The team's shared-services subscription for -Scope Team.
.PARAMETER MgPrefix
The kit management-group prefix for -Scope Team. Defaults to mg-factory.
.PARAMETER ReturnManagementGroupId
Management-group name to return the kit subscriptions to. Defaults to Tenant Root.
.PARAMETER Location
Region used to purge the archetype Key Vault if its resource group is already gone.
.PARAMETER Force
Skip the one cleanup confirmation prompt after reviewing the printed plan.
.EXAMPLE
$s = Get-Content (Join-Path '.local' 'settings.json') | ConvertFrom-Json
./scripts/Remove-FactoryEnvironment.ps1 -Scope Member -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Suffix $s.suffix -Location $s.location -WhatIf
.EXAMPLE
./scripts/Remove-FactoryEnvironment.ps1 -Scope Team -SharedSubscriptionId $s.sharedSubscriptionId -MgPrefix 'mg-factory' -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Member', 'Team')]
    [string] $Scope,
    [string] $SubscriptionId,
    [int] $MemberIndex,
    [string] $Suffix,
    [string] $SharedSubscriptionId,
    [ValidatePattern('^[A-Za-z0-9-]{2,40}$')]
    [string] $MgPrefix = 'mg-factory',
    [string] $ReturnManagementGroupId,
    [string] $Location = 'swedencentral',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$cleanupPlan = [System.Collections.Generic.List[string]]::new()

function Invoke-AzureCli {
    param([Parameter(Mandatory)][string[]] $Arguments)

    $PSNativeCommandUseErrorActionPreference = $false
    $output = & az @Arguments --only-show-errors --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $operation = ($Arguments | Select-Object -First 3) -join ' '
        $detail = ($output | ForEach-Object { $_.ToString() }) -join ' '
        throw "Azure CLI '$operation' failed (exit $LASTEXITCODE): $detail"
    }

    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    if (-not $text.Trim()) {
        return $null
    }
    return $text | ConvertFrom-Json
}

function Add-CleanupPlan {
    param([Parameter(Mandatory)][string] $Item)
    [void] $cleanupPlan.Add($Item)
}

function Test-ResourceGroup {
    param(
        [Parameter(Mandatory)][string] $TargetSubscription,
        [Parameter(Mandatory)][string] $Name
    )
    return [bool] (Invoke-AzureCli -Arguments @('group', 'exists', '--subscription', $TargetSubscription, '--name', $Name))
}

function Get-KitBudget {
    param([Parameter(Mandatory)][string] $TargetSubscription)
    $budgets = @(Invoke-AzureCli -Arguments @('consumption', 'budget', 'list', '--subscription', $TargetSubscription))
    return @($budgets | Where-Object { $_.name -eq 'budget-factory-workload' })
}

function Get-DirectSubscription {
    param([Parameter(Mandatory)][string] $ManagementGroupName)

    $managementGroup = Invoke-AzureCli -Arguments @('account', 'management-group', 'show', '--name', $ManagementGroupName, '--expand')
    $children = @($managementGroup.children)
    $unexpected = @($children | Where-Object { $_.type -notmatch 'subscription' })
    if ($unexpected.Count -gt 0) {
        throw "Management group '$ManagementGroupName' contains a child management group or an unexpected child. Review it manually; it will not be moved or deleted."
    }

    $subscriptions = [System.Collections.Generic.List[string]]::new()
    foreach ($child in $children) {
        $match = [regex]::Match([string] $child.id, '/subscriptions/([^/]+)$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if (-not $match.Success) {
            throw "A child of '$ManagementGroupName' is not a subscription resource. No cleanup was started."
        }
        [void] $subscriptions.Add($match.Groups[1].Value)
    }
    return @($subscriptions | Sort-Object -Unique)
}

function Test-KitWorkloadGroup {
    param([Parameter(Mandatory)][string] $TargetSubscription)

    $groups = @(Invoke-AzureCli -Arguments @('group', 'list', '--subscription', $TargetSubscription))
    return @($groups | Where-Object {
        $_.name -in @('rg-datacenter', 'rg-spoke') -or
        $_.name -match '^rg-university-[a-z0-9]{4,6}$'
    })
}

function Invoke-ResourceGroupDeletionAndWait {
    param(
        [Parameter(Mandatory)][string] $TargetSubscription,
        [Parameter(Mandatory)][string] $Name
    )

    if (-not (Test-ResourceGroup -TargetSubscription $TargetSubscription -Name $Name)) {
        return
    }

    Write-Information "Deleting the named kit resource group '$Name'. SQL MI deletion can take a while."
    $null = Invoke-AzureCli -Arguments @('group', 'delete', '--subscription', $TargetSubscription, '--name', $Name, '--yes', '--no-wait')
    $deadline = (Get-Date).AddHours(3)
    while (Test-ResourceGroup -TargetSubscription $TargetSubscription -Name $Name) {
        if ((Get-Date) -ge $deadline) {
            throw "Timed out waiting for the named resource group '$Name' to finish deleting. It was not followed by broader cleanup."
        }
        Start-Sleep -Seconds 30
    }
}

function Wait-ForSqlSubnetRelease {
    param([Parameter(Mandatory)][string] $TargetSubscription)

    if (-not (Test-ResourceGroup -TargetSubscription $TargetSubscription -Name 'rg-spoke')) {
        return
    }

    $deadline = (Get-Date).AddHours(2)
    do {
        $subnets = @(Invoke-AzureCli -Arguments @(
            'network', 'vnet', 'subnet', 'list',
            '--subscription', $TargetSubscription,
            '--resource-group', 'rg-spoke',
            '--vnet-name', 'vnet-spoke'
        ))
        $subnet = $subnets | Where-Object { $_.name -eq 'snet-sqlmi' } | Select-Object -First 1
        if (-not $subnet) {
            return
        }
        $sqlLinks = @($subnet.serviceAssociationLinks | Where-Object { $_.serviceName -match 'Microsoft\.Sql' })
        if ($sqlLinks.Count -eq 0) {
            return
        }
        if ((Get-Date) -ge $deadline) {
            throw "SQL MI has not released snet-sqlmi. The spoke VNet was left in place; wait for the association to clear and rerun cleanup."
        }
        Start-Sleep -Seconds 30
    } while ($true)
}

function Invoke-SoftDeletedArchetypeVaultPurge {
    param(
        [Parameter(Mandatory)][string] $TargetSubscription,
        [Parameter(Mandatory)][string] $VaultName,
        [Parameter(Mandatory)][string] $FallbackLocation
    )

    $deletedVaults = @(Invoke-AzureCli -Arguments @('keyvault', 'list-deleted', '--subscription', $TargetSubscription))
    $vault = $deletedVaults | Where-Object { $_.name -eq $VaultName } | Select-Object -First 1
    if (-not $vault) {
        return
    }

    $vaultLocation = $vault.location
    if (-not $vaultLocation) {
        $vaultLocation = $vault.properties.location
    }
    if (-not $vaultLocation) {
        $vaultLocation = $FallbackLocation
    }
    Write-Information "Purging only the matching soft-deleted Key Vault '$VaultName'."
    $null = Invoke-AzureCli -Arguments @(
        'keyvault', 'purge',
        '--subscription', $TargetSubscription,
        '--name', $VaultName,
        '--location', $vaultLocation
    )
}

function Invoke-KitBudgetDeletionIfPresent {
    param([Parameter(Mandatory)][string] $TargetSubscription)

    if (@(Get-KitBudget -TargetSubscription $TargetSubscription).Count -eq 0) {
        return
    }
    $null = Invoke-AzureCli -Arguments @(
        'consumption', 'budget', 'delete',
        '--subscription', $TargetSubscription,
        '--budget-name', 'budget-factory-workload'
    )
}

function ConvertTo-ManagementGroupName {
    param([Parameter(Mandatory)][string] $Value)
    $normalized = $Value.TrimEnd('/')
    if ($normalized -match '/providers/Microsoft\.Management/managementGroups/([^/]+)$') {
        return $Matches[1]
    }
    return $normalized
}

function Get-RoleAssignmentsAtScope {
    param([Parameter(Mandatory)][string] $TargetScope)
    return @(Invoke-AzureCli -Arguments @('role', 'assignment', 'list', '--scope', $TargetScope))
}

if ($Scope -eq 'Member') {
    if ($SubscriptionId -notmatch '^[0-9a-fA-F-]{36}$') {
        throw 'For -Scope Member, provide the member workload -SubscriptionId.'
    }
    if ($MemberIndex -lt 1 -or $MemberIndex -gt 20) {
        throw 'For -Scope Member, -MemberIndex must be between 1 and 20.'
    }
    if ($Suffix -notmatch '^[a-z0-9]{4,6}$') {
        throw 'For -Scope Member, -Suffix must contain 4-6 lowercase letters or digits.'
    }

    $null = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SubscriptionId)
    $archetypeGroup = "rg-university-$Suffix"
    $vaultName = "kv-university-$Suffix"
    $archetypeLocation = $Location

    if (Test-ResourceGroup -TargetSubscription $SubscriptionId -Name $archetypeGroup) {
        $resourceGroup = Invoke-AzureCli -Arguments @('group', 'show', '--subscription', $SubscriptionId, '--name', $archetypeGroup)
        if ($resourceGroup.location) {
            $archetypeLocation = $resourceGroup.location
        }
        Add-CleanupPlan "Delete resource group $archetypeGroup in the member workload subscription, then purge only its matching soft-deleted Key Vault if present."
    }
    $deletedArchetypeVaults = @(Invoke-AzureCli -Arguments @('keyvault', 'list-deleted', '--subscription', $SubscriptionId) |
        Where-Object { $_.name -eq $vaultName })
    if ($deletedArchetypeVaults.Count -gt 0) {
        Add-CleanupPlan "Purge only the matching soft-deleted Key Vault $vaultName."
    }

    if (Test-ResourceGroup -TargetSubscription $SubscriptionId -Name 'rg-spoke') {
        Add-CleanupPlan 'Delete rg-spoke after SQL MI releases snet-sqlmi.'
    }
    if (Test-ResourceGroup -TargetSubscription $SubscriptionId -Name 'rg-datacenter') {
        Add-CleanupPlan 'Delete the named rg-datacenter, including the member VMs, Bastion Standard, NAT gateway and network.'
        $sqlInstances = @(Invoke-AzureCli -Arguments @(
            'resource', 'list', '--subscription', $SubscriptionId,
            '--resource-group', 'rg-datacenter',
            '--resource-type', 'Microsoft.AzureArcData/sqlServerInstances'
        ) | Where-Object { $_.name -match '^vm-app01(?:$|/)' })
        foreach ($instance in $sqlInstances) {
            Add-CleanupPlan "Delete Arc SQL Server instance $($instance.name) in rg-datacenter."
        }
        $arcMachines = @(Invoke-AzureCli -Arguments @(
            'resource', 'list', '--subscription', $SubscriptionId,
            '--resource-group', 'rg-datacenter',
            '--resource-type', 'Microsoft.HybridCompute/machines'
        ) | Where-Object { $_.name -eq 'vm-app01' })
        foreach ($machine in $arcMachines) {
            Add-CleanupPlan 'Delete the Arc machine vm-app01 in rg-datacenter.'
        }
    }
    if (@(Get-KitBudget -TargetSubscription $SubscriptionId).Count -gt 0) {
        Add-CleanupPlan 'Delete the exact vending budget budget-factory-workload.'
    }
}
else {
    if ($SharedSubscriptionId -notmatch '^[0-9a-fA-F-]{36}$') {
        throw "For -Scope Team, provide the team's shared-services -SharedSubscriptionId."
    }

    $account = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $SharedSubscriptionId)
    $activeAccount = Invoke-AzureCli -Arguments @('account', 'show')
    if ($activeAccount.tenantId -ne $account.tenantId) {
        throw 'The active Azure CLI tenant does not match the shared-services subscription. Sign in to the event tenant and retry.'
    }
    $rootGroupName = $MgPrefix
    $platformGroupName = "$MgPrefix-platform"
    $corpGroupName = "$MgPrefix-corp"
    $managementGroups = @(Invoke-AzureCli -Arguments @('account', 'management-group', 'list'))
    $managementGroupNames = @($managementGroups | ForEach-Object { $_.name })
    $platformSubscriptions = @()
    $workloadSubscriptions = @()
    $platformGroupExists = $managementGroupNames -contains $platformGroupName
    if ($platformGroupExists) {
        $platformSubscriptions = @(Get-DirectSubscription -ManagementGroupName $platformGroupName)
    }
    if ($managementGroupNames -contains $corpGroupName) {
        $workloadSubscriptions = @(Get-DirectSubscription -ManagementGroupName $corpGroupName)
    }
    $teamSubscriptions = @($platformSubscriptions + $workloadSubscriptions | Sort-Object -Unique)
    if (-not $platformGroupExists -and
        $managementGroupNames -notcontains $rootGroupName -and
        $managementGroupNames -notcontains $corpGroupName) {
        Write-Output 'The kit management groups are already absent; no team kit hierarchy remains to clean.'
        return
    }
    if ($platformSubscriptions.Count -gt 1 -or
        ($platformSubscriptions.Count -eq 1 -and $platformSubscriptions[0] -ne $SharedSubscriptionId)) {
        throw "The supplied shared-services subscription is not a direct child of '$platformGroupName'. No cleanup was started."
    }
    if ($platformSubscriptions.Count -eq 0 -and
        -not (Test-ResourceGroup -TargetSubscription $SharedSubscriptionId -Name 'rg-management') -and
        -not (Test-ResourceGroup -TargetSubscription $SharedSubscriptionId -Name 'rg-hub')) {
        throw "The supplied shared-services subscription cannot be matched to the kit's retained rg-management or rg-hub. No cleanup was started."
    }

    foreach ($workloadSubscription in $workloadSubscriptions) {
        $null = Invoke-AzureCli -Arguments @('account', 'show', '--subscription', $workloadSubscription)
        $leftoverGroups = @(Test-KitWorkloadGroup -TargetSubscription $workloadSubscription)
        if ($leftoverGroups.Count -gt 0) {
            $names = ($leftoverGroups.name | Sort-Object -Unique) -join ', '
            throw "Member kit groups remain in a workload subscription ($names). Run and verify -Scope Member for every member before team cleanup."
        }
    }

    $tenantRootName = $account.tenantId
    $returnGroupName = if ($ReturnManagementGroupId) {
        ConvertTo-ManagementGroupName -Value $ReturnManagementGroupId
    } else {
        $tenantRootName
    }
    $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'show', '--name', $returnGroupName)
    if ($returnGroupName -in @($rootGroupName, $platformGroupName, $corpGroupName)) {
        throw 'The return management group cannot be one of the kit management groups being deleted.'
    }

    if ($managementGroupNames -contains $rootGroupName) {
        $rootGroup = Invoke-AzureCli -Arguments @('account', 'management-group', 'show', '--name', $rootGroupName, '--expand')
        $unexpectedChildren = @($rootGroup.children | Where-Object { $_.name -notin @($platformGroupName, $corpGroupName) })
        if ($unexpectedChildren.Count -gt 0) {
            throw "The kit root management group contains an unexpected child. No kit management group will be deleted."
        }
    }

    foreach ($workloadSubscription in $workloadSubscriptions) {
        Add-CleanupPlan "Return workload subscription $workloadSubscription to management group $returnGroupName."
    }
    foreach ($platformSubscription in $platformSubscriptions) {
        Add-CleanupPlan "Return shared/platform subscription $platformSubscription to management group $returnGroupName."
    }
    $workloadExemptions = [System.Collections.Generic.List[object]]::new()
    foreach ($workloadSubscription in $workloadSubscriptions) {
        $exemptions = @(Invoke-AzureCli -Arguments @(
            'policy', 'exemption', 'list',
            '--subscription', $workloadSubscription,
            '--scope', "/subscriptions/$workloadSubscription/resourceGroups/rg-datacenter"
        ) | Where-Object { $_.name.StartsWith('exempt-datacenter-', [System.StringComparison]::OrdinalIgnoreCase) })
        foreach ($exemption in $exemptions) {
            [void] $workloadExemptions.Add([pscustomobject]@{ subscription = $workloadSubscription; name = $exemption.name })
            Add-CleanupPlan "Delete datacenter exemption $($exemption.name) from its member workload subscription."
        }
        if (@(Get-KitBudget -TargetSubscription $workloadSubscription).Count -gt 0) {
            Add-CleanupPlan "Delete budget-factory-workload from member workload subscription $workloadSubscription."
        }
    }

    $corpScope = "/providers/Microsoft.Management/managementGroups/$corpGroupName"
    $policyAssignments = @()
    if ($managementGroupNames -contains $corpGroupName) {
        $policyAssignments = @(Invoke-AzureCli -Arguments @('policy', 'assignment', 'list', '--scope', $corpScope) |
            Where-Object { $_.name.StartsWith('alzl-', [System.StringComparison]::OrdinalIgnoreCase) })
    }
    foreach ($assignment in $policyAssignments) {
        Add-CleanupPlan "Delete kit policy assignment $($assignment.name) at $corpGroupName."
    }

    $managementGroupResourceRoles = @()
    $managedIdentityRoles = @()
    $memberOwnerRoles = [System.Collections.Generic.List[object]]::new()
    $memberReaderRoles = [System.Collections.Generic.List[object]]::new()
    $diagnosticPrincipals = @($policyAssignments |
        Where-Object { $_.name.StartsWith('alzl-diag-', [System.StringComparison]::OrdinalIgnoreCase) -and $_.identity.principalId } |
        ForEach-Object { $_.identity.principalId } | Sort-Object -Unique)
    $managementGroupExists = Test-ResourceGroup -TargetSubscription $SharedSubscriptionId -Name 'rg-management'
    if ($managementGroupExists) {
        $managementRg = Invoke-AzureCli -Arguments @('group', 'show', '--subscription', $SharedSubscriptionId, '--name', 'rg-management')
        if ($diagnosticPrincipals.Count -gt 0) {
            $managementRoles = Get-RoleAssignmentsAtScope -TargetScope $managementRg.id
            $managementGroupResourceRoles = @($managementRoles | Where-Object {
                $_.scope -eq $managementRg.id -and
                $_.roleDefinitionName -eq 'Log Analytics Contributor' -and
                $_.principalId -in $diagnosticPrincipals
            })
            foreach ($role in $managementGroupResourceRoles) {
                Add-CleanupPlan 'Delete the ALZ-lite diagnostics policy role assignment on rg-management; keep the directory identity and its Graph grant.'
            }
        }

        $identities = @(Invoke-AzureCli -Arguments @(
            'identity', 'list', '--subscription', $SharedSubscriptionId, '--resource-group', 'rg-management'
        ) | Where-Object { $_.name -eq 'id-sqlmi-directory' })
        if ($identities.Count -gt 0) {
            $identity = $identities[0]
            $identityRoles = Get-RoleAssignmentsAtScope -TargetScope $identity.id
            $managedIdentityRoles = @($identityRoles | Where-Object {
                $_.scope -eq $identity.id -and $_.roleDefinitionName -eq 'Managed Identity Operator'
            })
            foreach ($role in $managedIdentityRoles) {
                Add-CleanupPlan 'Delete vending-created Managed Identity Operator access on id-sqlmi-directory; preserve its Microsoft Graph grant.'
            }
            $managedIdentityPrincipals = @($managedIdentityRoles | ForEach-Object { $_.principalId } | Sort-Object -Unique)
            $sharedScope = "/subscriptions/$SharedSubscriptionId"
            foreach ($role in @(Get-RoleAssignmentsAtScope -TargetScope $sharedScope | Where-Object {
                $_.scope -eq $sharedScope -and $_.roleDefinitionName -eq 'Reader' -and $_.principalId -in $managedIdentityPrincipals
            })) {
                [void] $memberReaderRoles.Add($role)
                Add-CleanupPlan 'Delete the vending-created Reader assignment for a member on the shared services subscription.'
            }
            foreach ($workloadSubscription in $workloadSubscriptions) {
                if ($managedIdentityPrincipals.Count -eq 0) {
                    break
                }
                $subscriptionScope = "/subscriptions/$workloadSubscription"
                $ownerRoles = Get-RoleAssignmentsAtScope -TargetScope $subscriptionScope
                $matchingOwnerRoles = @($ownerRoles | Where-Object {
                    $_.scope -eq $subscriptionScope -and
                    $_.roleDefinitionName -eq 'Owner' -and
                    $_.principalId -in $managedIdentityPrincipals
                })
                foreach ($role in $matchingOwnerRoles) {
                    [void] $memberOwnerRoles.Add($role)
                    Add-CleanupPlan "Delete the vending-created Owner assignment for a member in workload subscription $workloadSubscription."
                }
            }
        }
    }

    $firewallGroups = @()
    $hubPeerings = @()
    if (Test-ResourceGroup -TargetSubscription $SharedSubscriptionId -Name 'rg-hub') {
        $firewallGroups = @(Invoke-AzureCli -Arguments @(
            'network', 'firewall', 'policy', 'rule-collection-group', 'list',
            '--subscription', $SharedSubscriptionId, '--resource-group', 'rg-hub', '--policy-name', 'afwp-hub'
        ) | Where-Object { $_.name -match '^rcg-member-(?:[1-9]|1[0-9]|20)$' })
        foreach ($group in $firewallGroups) {
            Add-CleanupPlan "Delete the kit firewall rule collection group $($group.name) from afwp-hub."
        }

        $hubPeerings = @(Invoke-AzureCli -Arguments @(
            'network', 'vnet', 'peering', 'list',
            '--subscription', $SharedSubscriptionId, '--resource-group', 'rg-hub', '--vnet-name', 'vnet-hub'
        ) | Where-Object {
            $_.name -match '^peer-hub-to-(?:spoke|datacenter)-(?:[1-9]|1[0-9]|20)$'
        })
        foreach ($peering in $hubPeerings) {
            Add-CleanupPlan "Delete the kit hub peering $($peering.name)."
        }
        Add-CleanupPlan 'Delete the kit-owned rg-hub after removing the named firewall rules and peerings.'
    }

    $workspaceResources = @()
    if ($managementGroupExists) {
        $workspaceResources = @(Invoke-AzureCli -Arguments @(
            'resource', 'list', '--subscription', $SharedSubscriptionId,
            '--resource-group', 'rg-management',
            '--resource-type', 'Microsoft.OperationalInsights/workspaces'
        ) | Where-Object { $_.name -eq 'log-management' })
        foreach ($workspace in $workspaceResources) {
            Add-CleanupPlan 'Delete the exact log-management workspace but preserve rg-management and id-sqlmi-directory.'
        }
    }

    foreach ($managementGroupName in @($corpGroupName, $platformGroupName)) {
        if ($managementGroupNames -contains $managementGroupName) {
            Add-CleanupPlan "Delete the kit management group $managementGroupName after its subscriptions are moved."
        }
    }
    if ($managementGroupNames -contains $rootGroupName) {
        Add-CleanupPlan "Delete the empty kit root management group $rootGroupName after its child groups are removed."
    }
}

if ($Scope -eq 'Member') {
    if ($cleanupPlan.Count -eq 0) {
        Write-Output 'No matching member kit resources were found.'
        return
    }
    Write-Output "Member cleanup plan (member $MemberIndex):"
    $cleanupPlan | ForEach-Object { Write-Output "  - $_" }
    $oldConfirmPreference = $ConfirmPreference
    if ($Force) {
        $ConfirmPreference = 'None'
    }
    try {
        $approved = $PSCmdlet.ShouldProcess("the listed kit resources for member $MemberIndex", 'Remove member environment')
    }
    finally {
        $ConfirmPreference = $oldConfirmPreference
    }
    if (-not $approved) {
        return
    }

    if (Test-ResourceGroup -TargetSubscription $SubscriptionId -Name 'rg-datacenter') {
        $sqlInstances = @(Invoke-AzureCli -Arguments @(
            'resource', 'list', '--subscription', $SubscriptionId,
            '--resource-group', 'rg-datacenter',
            '--resource-type', 'Microsoft.AzureArcData/sqlServerInstances'
        ) | Where-Object { $_.name -match '^vm-app01(?:$|/)' })
        foreach ($instance in $sqlInstances) {
            $null = Invoke-AzureCli -Arguments @('resource', 'delete', '--ids', $instance.id)
        }
        $arcMachines = @(Invoke-AzureCli -Arguments @(
            'resource', 'list', '--subscription', $SubscriptionId,
            '--resource-group', 'rg-datacenter',
            '--resource-type', 'Microsoft.HybridCompute/machines'
        ) | Where-Object { $_.name -eq 'vm-app01' })
        foreach ($machine in $arcMachines) {
            $null = Invoke-AzureCli -Arguments @('resource', 'delete', '--ids', $machine.id)
        }
    }

    Invoke-ResourceGroupDeletionAndWait -TargetSubscription $SubscriptionId -Name "rg-university-$Suffix"
    Invoke-SoftDeletedArchetypeVaultPurge -TargetSubscription $SubscriptionId -VaultName "kv-university-$Suffix" -FallbackLocation $archetypeLocation
    Wait-ForSqlSubnetRelease -TargetSubscription $SubscriptionId
    Invoke-ResourceGroupDeletionAndWait -TargetSubscription $SubscriptionId -Name 'rg-spoke'
    Invoke-ResourceGroupDeletionAndWait -TargetSubscription $SubscriptionId -Name 'rg-datacenter'
    Invoke-KitBudgetDeletionIfPresent -TargetSubscription $SubscriptionId
    Write-Output 'Member cleanup completed. Then work through the verification checklist in facilitator/cleanup.md in the kit repository (it is not copied into factory/); your facilitator has it.'
    return
}

if ($cleanupPlan.Count -eq 0) {
    Write-Output 'No matching team kit resources were found.'
    return
}
Write-Output "Team cleanup plan for prefix '$MgPrefix':"
$cleanupPlan | ForEach-Object { Write-Output "  - $_" }
$oldConfirmPreference = $ConfirmPreference
if ($Force) {
    $ConfirmPreference = 'None'
}
try {
    $approved = $PSCmdlet.ShouldProcess("the listed kit resources for team '$MgPrefix'", 'Remove team environment')
}
finally {
    $ConfirmPreference = $oldConfirmPreference
}
if (-not $approved) {
    return
}

foreach ($workloadSubscription in $workloadSubscriptions) {
    foreach ($exemption in $workloadExemptions | Where-Object { $_.subscription -eq $workloadSubscription }) {
        $null = Invoke-AzureCli -Arguments @(
            'policy', 'exemption', 'delete',
            '--subscription', $exemption.subscription,
            '--name', $exemption.name,
            '--scope', "/subscriptions/$($exemption.subscription)/resourceGroups/rg-datacenter"
        )
    }
    Invoke-KitBudgetDeletionIfPresent -TargetSubscription $workloadSubscription
}

foreach ($role in $memberOwnerRoles) {
    $null = Invoke-AzureCli -Arguments @('role', 'assignment', 'delete', '--ids', $role.id)
}
foreach ($role in $memberReaderRoles) {
    $null = Invoke-AzureCli -Arguments @('role', 'assignment', 'delete', '--ids', $role.id)
}
foreach ($role in $managedIdentityRoles) {
    $null = Invoke-AzureCli -Arguments @('role', 'assignment', 'delete', '--ids', $role.id)
}
foreach ($role in $managementGroupResourceRoles) {
    $null = Invoke-AzureCli -Arguments @('role', 'assignment', 'delete', '--ids', $role.id)
}
foreach ($assignment in $policyAssignments) {
    $null = Invoke-AzureCli -Arguments @('policy', 'assignment', 'delete', '--name', $assignment.name, '--scope', $corpScope)
}
foreach ($group in $firewallGroups) {
    $null = Invoke-AzureCli -Arguments @(
        'network', 'firewall', 'policy', 'rule-collection-group', 'delete',
        '--subscription', $SharedSubscriptionId,
        '--resource-group', 'rg-hub',
        '--policy-name', 'afwp-hub',
        '--name', $group.name
    )
}
foreach ($peering in $hubPeerings) {
    $null = Invoke-AzureCli -Arguments @(
        'network', 'vnet', 'peering', 'delete',
        '--subscription', $SharedSubscriptionId,
        '--resource-group', 'rg-hub',
        '--vnet-name', 'vnet-hub',
        '--name', $peering.name
    )
}
foreach ($workspace in $workspaceResources) {
    $null = Invoke-AzureCli -Arguments @('resource', 'delete', '--ids', $workspace.id)
}
Invoke-ResourceGroupDeletionAndWait -TargetSubscription $SharedSubscriptionId -Name 'rg-hub'

foreach ($targetSubscription in $teamSubscriptions) {
    $null = Invoke-AzureCli -Arguments @(
        'account', 'management-group', 'subscription', 'add',
        '--name', $returnGroupName,
        '--subscription', $targetSubscription
    )
}

foreach ($managementGroupName in @($corpGroupName, $platformGroupName)) {
    if ($managementGroupNames -contains $managementGroupName) {
        $children = Get-DirectSubscription -ManagementGroupName $managementGroupName
        if ($children.Count -gt 0) {
            throw "Management group '$managementGroupName' still contains subscriptions. It was not deleted."
        }
        $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'delete', '--name', $managementGroupName)
    }
}
if ($managementGroupNames -contains $rootGroupName) {
    $remainingRoot = Invoke-AzureCli -Arguments @('account', 'management-group', 'show', '--name', $rootGroupName, '--expand')
    if (@($remainingRoot.children).Count -gt 0) {
        throw "Kit management group '$rootGroupName' still has children. It was not deleted."
    }
    $null = Invoke-AzureCli -Arguments @('account', 'management-group', 'delete', '--name', $rootGroupName)
}

Write-Output 'Team cleanup completed. rg-management and id-sqlmi-directory were preserved. Work through the verification checklist in facilitator/cleanup.md in the kit repository (it is not copied into factory/).'
