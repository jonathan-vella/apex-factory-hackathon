---
title: Cost
description: Running and stopped cost per member and per team.
---

Figures are approximate list-price estimates for `swedencentral`, with Azure Hybrid Benefit applied where it's on by default. Actual cost depends on usage and any regional pricing differences.

## Per member

| Component | Running | Stopped (deallocated) |
|---|---|---|
| Datacenter (`vm-app01` + `vm-dev01`) | Compute billed hourly | Compute cost stops; managed disks still billed |
| CoE archetype (App Service P0v3, SQL MI General Purpose Gen5 4 vCore/64 GB, Service Bus Premium, Key Vault, ACR Premium) | Around $4.63/hour total (per the archetype's own cost note) | SQL MI and App Service don't have a "stopped" state that avoids billing — deleting the deployment (`azd down`) is the only way to stop this cost |

## Per team

Add the shared services subscription's cost: the hub (Azure Firewall Standard, VPN/ExpressRoute not used), the central Log Analytics workspace, and vending's per-member networking (VNet peering, UDRs — all low-cost). This is shared once per team, not per member.

## Reducing cost between sessions

Stop both datacenter VMs when you're not actively working — they bill for compute while running regardless of use. The archetype's resources (App Service, SQL MI, Service Bus, Key Vault, ACR) don't have an equivalent low-cost stopped state; if a long gap is expected, deleting and redeploying the archetype may cost less overall than leaving it running, but reseeds the SQL MI link work from C7 — weigh that against the time cost of redoing C7.
