---
title: Cost
description: Running and stopped cost per member and per team.
sidebar:
  order: 4
---

Figures are approximate list-price estimates for `swedencentral`, with Azure Hybrid Benefit applied where it's on by default. Actual cost depends on usage and any regional pricing differences.

## Per member

| Component | Running | Stopped (deallocated) |
|---|---|---|
| Datacenter (`vm-app01` + `vm-dev01`, Bastion Standard, NAT gateway) | About $1.55/hour | About $0.78/hour: compute stops, but Bastion Standard, the NAT gateway, public IPs and the managed disks keep billing |
| CoE archetype (App Service P0v3, SQL MI General Purpose Standard-series, 4 vCPU, Service Bus Premium, Key Vault, ACR Premium) | About $1.83/hour, of which the SQL MI is about $0.68/hour | App Service and the other services have no stopped state that avoids billing. The SQL MI can be stopped and started, but not while the MI link exists, so the kit's stop/start schedule only applies after cutover removes the link. Deleting the resource group is the way to stop the rest |

The full stack for one member (datacenter, archetype and a share of the team's foundation) is about $4.63 to $4.68 per hour running. The archetype alone is $1.83 per hour, not $4.63.

## Per team

ALZ-lite, the shared services subscription's hub (Azure Firewall Standard with DNS proxy), the central private DNS zones and the Log Analytics workspace, costs about $1.30 per hour. It is shared once per team, not per member. Vending's per-member networking (VNet peering, UDRs) adds little.

The [event cost estimate](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/facilitator/cost-estimate.md) in the facilitator folder has the totals for a whole event.

## Reducing cost between sessions

Stop both datacenter VMs only outside the event: in the gaps during pre-work and after the event. Never stop `vm-dev01` during the event, because it's your workstation, and keep `vm-app01` running until the MI link is removed. Stopping the VMs saves their compute, not the $0.78 per hour that Bastion, the NAT gateway and the disks cost.

After cutover, the SQL MI's stop/start schedule runs the instance Monday to Friday, 07:30 to 18:30 `W. Europe Standard Time` by default, so it may be stopped outside that window. For a long gap before cutover, deleting and redeploying the archetype may cost less than leaving it running, but it repeats the MI link work from C7. Weigh that against the time cost.
