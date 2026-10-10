---
title: Naming and IP plan
description: Resource naming conventions and the kit's IP address ranges.
sidebar:
  order: 1
---

## Naming convention

| Resource | Pattern | Example |
|---|---|---|
| Resource group | `rg-<purpose>[-<suffix>]` | `rg-datacenter`, `rg-spoke`, `rg-hub`, `rg-management`, `rg-university-<suffix>` |
| Virtual network | `vnet-<role>` | `vnet-hub`, `vnet-datacenter`, `vnet-spoke` |
| Subnet | `snet-<purpose>` | `snet-servers`, `snet-app`, `snet-pe`, `snet-sqlmi` |
| Bastion subnet | `AzureBastionSubnet` | Fixed name required by Azure |
| Bastion | `bas-datacenter` | — |
| NAT gateway | `nat-datacenter` | — |
| Azure Firewall | `afw-hub` | — |
| Firewall policy | `afwp-hub` | — |
| User-assigned managed identity | `id-<purpose>` | `id-sqlmi-directory` |
| Log Analytics workspace | `log-management` | — |

## Member index and suffix

Two different values name member-scoped things:

- The **member index** `n` (1 to 20) is a number your coach assigns. It sets your IP ranges and appears in names such as `rcg-member-<n>`. It is unique within a team.
- The **suffix** is a random six-character string that `Initialize-Settings.ps1` generates once and never changes. It names your archetype resources, for example `rg-university-<suffix>`.

Both are saved in `factory/.local/settings.json`.

## IP address plan

| Range | Purpose |
|---|---|
| `10.100.0.0/16` | Hub VNet (shared services subscription) |
| `10.100.0.0/26` | `AzureFirewallSubnet` inside the hub |
| `10.10.n.0/24` | Member `n`'s datacenter VNet `vnet-datacenter` (workload subscription) |
| `10.10.n.0/25` | `snet-servers` inside the datacenter: `vm-app01` at `.4`, `vm-dev01` at `.5` |
| `10.10.n.192/26` | `AzureBastionSubnet` inside the datacenter |
| `10.20.n.0/24` | Member `n`'s spoke VNet `vnet-spoke` (workload subscription) |
| `10.20.n.0/26`, `.64/26`, `.128/26` | Spoke subnets `snet-app`, `snet-pe` and `snet-sqlmi` |

`snet-servers` belongs to the datacenter, not the spoke. The datacenter and the spoke aren't peered with each other: traffic between them goes through the hub firewall.

`snet-sqlmi` has the network security group `nsg-sqlmi` and the route table `rt-sqlmi`. Vending creates both once, empty, and SQL MI's network intent policy then adds its own rules and routes. Don't redeploy them inline, because that would remove the MI's rules. The kit adds its MI link rules as separate child resources.
