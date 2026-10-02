# B08 validation record

What-if summaries and results from validating the foundation for real in the build subscriptions (B08, requirements 16–21). IDs, IP addresses and email addresses are left out.

## Before you start

| Check | Result |
|---|---|
| B02 and B07 closed | ✅ |
| `.local/settings.json` keys | ✅ `tenantId`, `sharedSubscriptionId`, `subscriptionId`, `location`, `memberIndex`, `suffix` |
| Signed-in user's roles | ✅ Owner (and User Access Administrator) at Tenant Root and on both subscriptions |
| `rg-hub`, `rg-management` (shared) and `rg-spoke`, `rg-datacenter` (workload) absent | ✅ |
| `mg-factory*` management groups | ✅ none |
| Original placement | Both subscriptions directly under **Tenant Root** |
| Original Defender for Cloud plans | Both subscriptions: every plan `Standard` except `Api` and the deprecated ones (`Dns`, `ContainerRegistry`, `KubernetesService`), which are `Free` |

## What-if summaries

### ALZ-lite (`scripts/Deploy-AlzLite.ps1 -WhatIf`, 2026-10-02)

61 to create, 12 to modify, 1 no change, nothing deleted. No zones, no zone redundancy; the only public IP is `pip-afw-hub`.

| Scope | Changes |
|---|---|
| Tenant | Create `mg-factory`, `mg-factory-platform`, `mg-factory-corp`; move the shared services subscription into `mg-factory-platform` |
| `mg-factory-corp` | Create 18 policy assignments (`alzl-*`: allowed locations, NIC public IPs, 5 public network access denies, 4 private DNS DeployIfNotExists, 7 diagnostics DeployIfNotExists) and 12 role assignments for their identities |
| Shared services subscription | Create `rg-hub` and `rg-management`. **Modify 12 Defender for Cloud plans from `Standard` to `Free`** (requirement 5): AI, AppServices, Arm, CloudPosture, Containers, CosmosDbs, KeyVaults, OpenSourceRelationalDatabases, SqlServerVirtualMachines, SqlServers, StorageAccounts, VirtualMachines. `Api` is already `Free` |
| `rg-hub` | Create `vnet-hub`, `pip-afw-hub`, `afwp-hub`, `afw-hub` with its diagnostic setting, the 4 privatelink zones with their `link-vnet-hub` links, and 4 role assignments (private DNS identities, Network Contributor) |
| `rg-management` | Create `log-management` and 7 role assignments (diagnostics identities, Log Analytics Contributor) |
