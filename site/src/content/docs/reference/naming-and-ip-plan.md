---
title: Naming and IP plan
description: Resource naming conventions and the kit's IP address ranges.
sidebar:
  order: 4
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
| Firewall rule collection group (one per member) | `rcg-member-<n>` | `rcg-member-3` in `afwp-hub` |
| App Service plan and web app | `asp-university-<suffix>`, `app-university-<suffix>` | C5 archetype |
| Container registry | `cruniversity<suffix>` | C5 archetype |
| SQL Managed Instance | `sqlmi-university-<suffix>` | C5 archetype |
| Storage account | `stuniversity<suffix>` | C5 archetype, container `teaching-materials` |
| Service Bus namespace | `sbns-university-<suffix>` | C5 archetype, queue `notifications` |
| Key Vault | `kv-university-<suffix>` | C5 archetype |
| Application Insights | `appi-university-<suffix>` | C5 archetype |
| Web app identity | `id-university-<suffix>` | C5 archetype |

## Member index and suffix

Two different values name member-scoped things. Both are saved in `factory/.local/settings.json`, and later pages show them as `$s.memberIndex` and `$s.suffix`:

- The **member index** `n` (1 to 20) is a number your team lead assigns (1 to 20, usually 1 to 5 with the lead as 1). It sets your IP ranges and appears in names such as `rcg-member-<n>`, your firewall rule collection group in the hub. It is unique within a team.
- The **suffix** is a random six-character string that `Initialize-Settings.ps1` generates once and never changes. It names your archetype resources, for example `rg-university-<suffix>`.

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

<details>
<summary>How you reach the VMs and how they reach the internet</summary>

Bastion is the only way in to the datacenter VMs, and the NAT gateway only carries their outbound traffic. Traffic from the datacenter to the spoke doesn't use the NAT gateway: it goes through the hub firewall.

<figure class="doc-figure">
  <a class="doc-figure__link" href="/diagrams/diagram-06-bastion-vs-nat.svg" target="_blank" rel="noopener">
    <img src="/diagrams/diagram-06-bastion-vs-nat.svg" alt="Two separate paths in the datacenter network. Azure Bastion Standard gives administrators remote desktop access to vm-app01 and vm-dev01 over public HTTPS from the portal, with no direct public RDP. A NAT Gateway attached to the server subnet carries the VMs' outbound internet traffic only. Datacenter-to-spoke traffic uses a route to the hub firewall, not the NAT Gateway." width="3840" height="2160" loading="lazy" decoding="async" />
  </a>
  <figcaption>Bastion brings you in, the NAT gateway takes VM traffic out. <a href="/diagrams/diagram-06-bastion-vs-nat.svg" target="_blank" rel="noopener">Open full size</a></figcaption>
</figure>

</details>

<details>
<summary>How private names resolve</summary>

Your apps and VMs use the standard service host names. The hub firewall acts as the DNS server, and central private DNS zones answer with the private endpoint address. Never use `privatelink` names or IP addresses.

<figure class="doc-figure">
  <a class="doc-figure__link" href="/diagrams/diagram-07-private-dns.svg" target="_blank" rel="noopener">
    <img src="/diagrams/diagram-07-private-dns.svg" alt="How a standard service name resolves to a private address. A caller on the datacenter network or the spoke asks the hub firewall's DNS proxy, which forwards the query to Azure-provided DNS in the hub network. The central private DNS zones for Blob, Service Bus, the container registry and Key Vault supply the private endpoint record, and the caller then connects to a private address in the private endpoint subnet. SQL Managed Instance has no private endpoint and is reached by its standard host name." width="3840" height="2160" loading="lazy" decoding="async" />
  </a>
  <figcaption>Standard service names resolve through central private DNS. <a href="/diagrams/diagram-07-private-dns.svg" target="_blank" rel="noopener">Open full size</a></figcaption>
</figure>

</details>

## Where to go next

See the [glossary](../glossary/) for the terms used here, or go back to [Requirements](../../getting-started/requirements/).
