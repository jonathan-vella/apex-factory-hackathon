# B07 spike: Arc onboarding and MI link migration

| Field | Value |
|---|---|
| Date | 2026-10-02 to in progress |
| Result | In progress |
| Region | swedencentral |
| Versions | To be recorded |

## Question

Can `vm-app01` be onboarded to Azure Arc in the portal and with an unattended kit script, and does `ContosoUniversity` migrate online to SQL Managed Instance through the Arc portal migration with MI link: link created, seeded, read-only replica validated, aborted and re-created, planned cutover, link removed?

## What we did

In progress.

### Target MI

Deployed with [infra/main.bicep](infra/main.bicep) into `rg-spike-b07`. A **paid** General Purpose MI, not the free offer (owner decision, 2026-10-02):

| Setting | Value |
|---|---|
| Name | `sqlmi-university-<suffix>-b07` |
| SKU | General Purpose, Standard-series (Gen5), 4 vCores, 64 GB storage |
| Licence | `licenseType: 'BasePrice'`: Azure Hybrid Benefit on, which assumes eligible SQL Server licences with Software Assurance. Turn it off with `az sql mi update -g rg-spike-b07 -n <mi-name> --license-type LicenseIncluded` |
| Update policy | SQL Server 2022 (`databaseFormat: 'SQLServer2022'`), which a failback to SQL Server 2022 needs |
| Authentication | Entra-only, the owner as Entra admin |
| Network | `snet-sqlmi` `10.20.n.128/26` in `vnet-spike-mi` `10.20.n.0/24`, delegated to `Microsoft.Sql/managedInstances`, with `nsg-sqlmi` and `rt-sqlmi`; peered both ways with `vnet-datacenter`. Public endpoint off |
| Zones | No zone, zone redundancy off |
| Time zone | `W. Europe Standard Time` |
| Cost | About $0.68/hour (compute $0.67/hour with AHB, storage $0.14/GB-month, about $9/month for 64 GB), about $16/day. It bills from creation and **can't be stopped while the link is active**; stop it after cutover |

### MI link network rules

Only what MI link needs, from [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation) (checked 2026-10-02). `n` is the member index.

| Where | Direction | Protocol and ports | From | To |
|---|---|---|---|---|
| `nsg-sqlmi` | Inbound | TCP 5022, 11000–11999 | `10.10.n.4` (`vm-app01`) | `10.20.n.128/26` |
| `nsg-sqlmi` | Outbound | TCP 5022 | `10.20.n.128/26` | `10.10.n.4` |
| `nsg-servers` | Inbound | TCP 5022 | `10.20.n.128/26` | `10.10.n.4` |
| `nsg-servers` | Outbound | TCP 5022, 11000–11999 | `10.10.n.4` | `10.20.n.128/26` |
| Windows Firewall on `vm-app01` | Inbound | TCP 5022 | `10.20.n.128/26` | local |

## What-if summaries

Every deployment ran `az deployment ... what-if` first and was checked: only B07-owned resources created or changed, nothing deleted, nothing in `rg-datacenter` changed except what the runbook prescribes, no zones or zone redundancy, no public endpoints.

| Deployment | What-if result | Checked |
|---|---|---|
| `infra/main.bicep` into `rg-spike-b07` (2026-10-02) | 11 creates, nothing modified or deleted. `rg-spike-b07`: `nsg-sqlmi` with the two MI link rules, `rt-sqlmi`, `vnet-spike-mi` with `snet-sqlmi` and its peering, and the MI (GP_Gen5, 4 vCores, 64 GB, `BasePrice`, `SQLServer2022`, zone redundancy off, public endpoint off, Entra-only, no `zones`). `rg-datacenter`: the peering `peer-datacenter-to-spike-mi` and the two MI link rules in `nsg-servers` | ✅ |
| `Deploy-Datacenter.ps1 -ScriptsRef <this branch>` (requirement 3, 2026-10-02) | 1 create (run command `app-07-arc-prep`); every run command modified (new script URL and run ID, which re-runs them); the rest no change or what-if noise: read-only and default properties, secure parameters. Two real side effects, owner-approved: `vm-dev01`'s system-assigned identity is removed (finding 2), and the MI link rules in `nsg-servers` are removed (finding 1). It also lists `vnet-datacenter`'s `virtualNetworkPeerings` as deleted; a test with two throwaway VNets in `rg-spike-b07` showed that a VNet redeploy without the property keeps the peering `Connected`, so that's noise | ✅ owner-approved |

## Timings

In progress.

## Findings

1. **A datacenter redeploy wipes NSG rules that later items add.** `nsg-servers` lists its rules inline in B04's Bicep, so `Deploy-Datacenter.ps1` removes the MI link rules this spike adds as child `securityRules`. B07 re-applies them with [infra/main.bicep](infra/main.bicep) after every datacenter redeploy.
2. **A policy above the kit changes the VMs, and each datacenter redeploy undoes part of it.** `vm-dev01` has a system-assigned managed identity and the Guest Configuration extension `AzurePolicyforWindows`, and `vm-app01` has `MDE.Windows` (Defender for Servers). None of them is in B04's template. A redeploy removes `vm-dev01`'s identity until the policy adds it back.
3. **The MI provisioned in 7 minutes** (11:42–11:49): a new General Purpose instance in a new subnet, with `licenseType: 'BasePrice'` accepted. Backup storage redundancy is the default, Geo, because the template doesn't set it.

## Decisions

- **Paid MI, not the free offer** (owner, 2026-10-02). A regular General Purpose MI with Azure Hybrid Benefit replaces the SQL MI free offer in B07. Changes [B07](../../backlog/B07-spike-arc-mi-link.md) (Cost, Outcome, Before you start, requirements 13, 14, 24 and 25, Stop and ask if, Notes and traps); the PRD, roadmap, B09, B10 and the backlog README change in a separate PR.

## Evidence

In progress.

## Follow-ups

- **B08 and B11: NSG rules added after the datacenter** (finding 1). Move `nsg-servers`' rules to child `securityRules` in B04, or add the MI link rules to B04, so a datacenter redeploy keeps them. B08 moves the MI link rules to the hub firewall anyway.
- **B04 or B11: the policy-added identity** (finding 2). Declare a system-assigned identity on the datacenter VMs in B04, or document that a redeploy removes it.
- **B09: MI backup redundancy** (finding 3). Decide `requestedBackupStorageRedundancy` (the kit's storage convention is LRS; the default is Geo).
