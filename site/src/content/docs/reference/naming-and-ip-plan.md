---
title: Naming and IP plan
description: Resource naming conventions and the kit's IP address ranges.
---

## Naming convention

| Resource | Pattern | Example |
|---|---|---|
| Resource group | `rg-<purpose>[-<suffix>]` | `rg-datacenter`, `rg-university-<suffix>` |
| Virtual network | `vnet-<role>` | `vnet-hub`, `vnet-spoke` |
| Subnet | `snet-<purpose>` | `snet-app`, `snet-pe`, `snet-sqlmi` |
| Azure Firewall | `afw-hub` | — |
| Firewall policy | `afwp-hub` | — |
| User-assigned managed identity | `id-<purpose>` | `id-sqlmi-directory` |
| Log Analytics workspace | `log-management` | — |

Member-scoped resources append the member's suffix (an index or short string assigned at onboarding) so every member's resources are distinguishable inside a shared naming pattern.

## IP address plan

| Range | Purpose |
|---|---|
| `10.100.0.0/16` | Hub VNet (shared services subscription) |
| `10.100.0.0/26` | `AzureFirewallSubnet` inside the hub |
| `10.20.n.0/24` | Member `n`'s spoke VNet (workload subscription) |

Spoke subnets (`snet-app`, `snet-pe`, `snet-sqlmi`, `snet-servers`) are carved out of each member's `/24`. The SQL Managed Instance subnet (`snet-sqlmi`) must not carry an inline NSG or custom route table — SQL MI's own network intent policy manages both, and an inline rule conflicts with it.
