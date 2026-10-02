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

This first what-if checks requirement 5. The owner chose to leave the build subscriptions' Defender plans untouched (owner decision 2026-10-02: they host unrelated workloads; event subscriptions are dedicated), so the deployment uses `-SkipDefender`.

### ALZ-lite with `-SkipDefender` (2026-10-02)

61 to create, 0 to modify, 0 to delete, no `Microsoft.Security/pricings` changes. The same creates as above.

### Datacenter (`infra/datacenter/main.bicep`, the parameters `Deploy-Datacenter.ps1` passes, 2026-10-02)

27 to create, nothing modified or deleted: `rg-datacenter` with B04's network (`vnet-datacenter` and its two subnets, `nsg-servers`, `nat-datacenter`, `bas-datacenter` Standard, `pip-nat-datacenter`, `pip-bas-datacenter`), both VMs with their NICs, and their run commands (including B07's `app-07-arc-prep`). The two public IPs are the datacenter's documented ones. No zones.

## ALZ-lite deployment (requirement 16)

| Step | Result |
|---|---|
| `Deploy-AlzLite.ps1 -SkipDefender` | ✅ 9 minutes (15:44–15:53) |
| Re-run what-if | ✅ Converges: 49 "modify" lines are what-if noise only (read-only defaults such as `definitionVersion`, `resolutionPolicy`, `retentionPolicy`, and role assignment principal IDs shown as unevaluated references), 12 no change, nothing deleted |
| Management groups | ✅ `mg-factory` > `mg-factory-platform` (holds the shared services subscription), `mg-factory-corp` |
| Policy assignments at `mg-factory-corp` | ✅ 18 |
| `afwp-hub` | ✅ Standard, DNS proxy on, 45 SNAT private ranges without `snet-pe` |
| `afw-hub` | ✅ Standard, no zones |

## Datacenter deployment (requirement 17)

`Deploy-Datacenter.ps1 -MemberIndex 1`: ✅ 29 minutes (15:45–16:14), while the workload subscription was still under Tenant Root.

## Vending what-if (`Deploy-Vending.ps1 -SkipDefender -WhatIf`, member 1, 2026-10-02)

22 to create, 2 to modify, 0 to delete (28 "ignore" are the subscriptions' other resource groups). No zones, no public IPs.

| Scope | Changes |
|---|---|
| Tenant | Move the workload subscription into `mg-factory-corp` |
| Workload subscription | Create `rg-spoke`, the member's Owner role assignment and `budget-factory-workload` |
| `rg-spoke` | Create `vnet-spoke` with `snet-app`, `snet-pe`, `snet-sqlmi` and `peer-spoke-to-hub`; `nsg-sqlmi` with the two MI link rules and its diagnostic setting; `rt-app`, `rt-pe`, `rt-sqlmi` with its datacenter route |
| `rg-hub` | Create `peer-hub-to-spoke-1`, `peer-hub-to-datacenter-1` and `rcg-member-1` in `afwp-hub` |
| `rg-datacenter` (this item's fresh datacenter) | Create `rt-servers` and `peer-datacenter-to-hub`. Modify `snet-servers` (adds `rt-servers`; keeps its prefix, NAT gateway, NSG and `privateEndpointNetworkPolicies`, read from the live subnet) and `vnet-datacenter` (adds the DNS server; no subnets property, so its subnets and peerings stay). The rest of those two diffs is what-if noise: unevaluated references and read-only defaults |

The first what-if showed the `snet-servers` PUT turning `privateEndpointNetworkPolicies` from `Disabled` to `Enabled`; vending now carries the live value over.

## Vending deployment (requirement 17)

`Deploy-Vending.ps1 -SkipDefender`, member 1, with the owner as the member principal: ✅ 4 minutes (16:17–16:22). Both datacenter VMs were restarted to pick up the hub DNS.

## Exemptions (requirement 18)

`rg-datacenter` violates **no ALZ-lite assignment**. It's compliant with `alzl-allowed-locations` (29 resources) and `alzl-deny-nic-pip` (2 NICs); the other core policies don't apply to its resource types. The only violations come from the build tenant's own assignments, outside the kit: "Azure Security Baseline" (4 resources) and "MCAPSGov Audit Policies" (1).

Owner decision (2026-10-02): create no exemptions in the build tenant and never waive its own policies; the `-WhatIf` runs are the evidence. The script now exempts only ALZ-lite assignments by default, with `-IncludeAssignment` to opt in named ones. No exemption exists in `rg-datacenter`.

Default (`-Owner 'Jonathan Vella' -ExpiresOn 2026-10-16 -WhatIf`):

```text
Violated but not exempted (not ALZ-lite; name them with -IncludeAssignment to exempt them):
  Azure Security Baseline (Azure_Security_Baseline)
  MCAPSGov Audit Policies (MCAPSGovAuditPolicies)
rg-datacenter violates no assignment to exempt: nothing to do.
```

With `-IncludeAssignment 'Azure Security Baseline'`:

```text
What if: Performing the operation "Create policy exemption" on target "rg-datacenter for 'Azure Security Baseline'".
Violated but not exempted (not ALZ-lite; name them with -IncludeAssignment to exempt them):
  MCAPSGov Audit Policies (MCAPSGovAuditPolicies)

Paste this into your deferred-work register:

| Policy assignment | Non-compliant resources | Exemption | Category | Owner | Reason | Target date |
|---|---|---|---|---|---|---|
| Azure Security Baseline | 4 | exempt-datacenter-Azure-Security-Baseline | Waiver | Jonathan Vella | pre-existing on-premises simulation, migrating in C7 | 2026-10-16 |

The exemptions expire on 2026-10-16. Extend them with this script and a new -ExpiresOn, or migrate first.
```

## Negative tests (requirement 20)

| Test | Result |
|---|---|
| Storage account with public network access, in `rg-spoke` | ⚠️ Not denied, environment-specific: the build tenant's `MCAPSGovDeployPolicies` Modify policy ("SFI - Disable public network access on Storage accounts") sets `publicNetworkAccess` to `Disabled` before Deny is evaluated, so the account is created private. `alzl-deny-pna-storage` (Deny, enforced) never sees a public request. In a tenant without that Modify policy, the deny applies |
| Container registry (Premium) with public network access, in `rg-spoke` (supplementary deny check) | ✅ Denied by `alzl-deny-pna-acr` (`RequestDisallowedByPolicy`) |
| NIC with a public IP, in `snet-pe` | ✅ Denied by `alzl-deny-nic-pip` (`RequestDisallowedByPolicy`) |
