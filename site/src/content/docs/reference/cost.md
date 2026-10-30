---
title: Cost
description: Running and stopped cost per member and per team.
sidebar:
  order: 3
---

Figures are approximate list-price estimates in USD for `swedencentral`, checked on **2026-10-08**, with Azure Hybrid Benefit applied where it is on by default. Actual cost depends on usage and regional pricing; recheck before each event.

## Per member

| Component | Running | Stopped (deallocated) |
|---|---|---|
| Datacenter (`vm-app01` + `vm-dev01`, Bastion Standard, NAT gateway) | About $1.55/hour with AHB; about $1.92/hour without Windows Server AHB on `vm-app01` | About $0.78/hour: VM compute stops, but Bastion Standard, the NAT gateway, public IPs and managed disks keep billing |
| CoE archetype (App Service P0v3, SQL MI General Purpose Standard-series, 4 virtual cores (`vCores`), Service Bus Premium, Key Vault, ACR Premium, storage account and four private endpoints) | About $1.83/hour, including about $0.67/hour for the SQL MI | Application Insights and Log Analytics ingestion are usage-based extras. App Service and the other services have no stopped state that avoids billing. The SQL MI can be stopped and started, but not while the MI link exists, so the kit's stop/start schedule only applies after cutover removes the link. Deleting the resource group stops the rest |

The full stack for one member is about **$3.38 per running hour**: the datacenter ($1.55) plus the archetype ($1.83). Add the shared foundation below ($1.30 per team-hour). Without Windows Server AHB, only `vm-app01` changes: add about **$0.37 per running hour per affected member**; the Windows 11 workstation is not part of this AHB setting.

## Per team

ALZ-lite, the shared services subscription's hub (Azure Firewall Standard with DNS proxy), the central private DNS zones and the Log Analytics workspace, costs about $1.30 per hour. It is shared once per team, not per member. The charge starts at T-7 when the team lead deploys the foundation and continues until the `teardown` stage at T+2. Vending's per-member networking (VNet peering, UDRs) adds little. A UDR is a user-defined route, a rule that sends a subnet's traffic through the hub firewall.

## When charges start and stop

| Component | Starts | Stops |
|---|---|---|
| Shared ALZ-lite foundation | Step 2 at T-7 | Team's `teardown` at T+2 |
| Datacenter | Step 3 at T-3 | Member's `teardown` at T+2; stopping the VM prevents only compute charges |
| CoE archetype | C5 | Member's `teardown` at T+2 |

For the planning window, the foundation runs for 216 hours, each datacenter is running for 39 hours and deallocated for 81 hours, and each archetype is deployed for 44 hours. Actual deployment and cleanup times change the bill.

| Team size | Estimated member charges | Shared foundation | Estimated event total |
|---:|---:|---:|---:|
| 3 members | 3 × $204.15 = $612.45 | $280.80 | **$893.25** |
| 4 members | 4 × $204.15 = $816.60 | $280.80 | **$1,097.40** |
| 5 members | 5 × $204.15 = $1,020.75 | $280.80 | **$1,301.55** |

If all members in a four-person team lack Windows Server AHB, the 39 assumed running hours add about $57.72 ($0.37 × 39 × 4). Add $0.37 for each additional running hour per affected member.

## Reducing cost between sessions

Stop both datacenter VMs only outside the event: in the gaps before the event and after it. Never stop `vm-dev01` during the event, because it is your workstation, and keep `vm-app01` running until the MI link is removed. Deallocating the VMs saves their compute, not the $0.78 per hour that Bastion, the NAT gateway and the disks cost.

After cutover (the moment you switch from the source database to the managed instance in C7), the SQL MI's stop/start schedule runs the instance Monday to Friday, 07:30 to 18:30 `W. Europe Standard Time` by default, so it may be stopped outside that window. For a long gap before cutover, deleting and redeploying the archetype may cost less than leaving it running, but it repeats the MI link work from C7. Weigh that against the time cost.

## Where to go next

See [Tear down](../../deploy/tear-down/) for the cleanup steps that stop these charges. For licensing, read [Azure Hybrid Benefit](../azure-hybrid-benefit/). Continue with [Requirements](../../getting-started/requirements/) or [Member steps](../../deploy/member-steps/).
