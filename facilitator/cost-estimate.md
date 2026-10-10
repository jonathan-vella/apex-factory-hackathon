# Event cost estimate

These are approximate list-price estimates in USD for `swedencentral`, with Azure Hybrid Benefit (AHB) on where supported. Use the actual deployment and cleanup times to replace the planning hours below. The sample team has four members; the supported team size is three to five.

## Hourly rates

| Component | Scope | Running | Stopped / deallocated | Notes |
|---|---|---:|---:|---|
| Datacenter | Per member | $1.55/hour | $0.78/hour | Estimate confirmed by live validation; stopped cost remains for Bastion Standard, disks, NAT and IP |
| ALZ-lite foundation | Per team | $1.30/hour | Not applicable | Estimate confirmed by live validation; Azure Firewall is the main continuing charge |
| CoE archetype | Per member | $1.83/hour | Not applicable | Estimate confirmed by live validation; SQL MI, Service Bus, App Service, ACR and private endpoints |
| Full stack, one member plus shared foundation | Per member + team share | $4.68/hour | Not applicable | Actual component sum: $1.30 + $1.55 + $1.83 |

The datacenter estimate is about **$2.30/hour running** without AHB. Turning AHB off adds about **$0.75 per running hour per member**; it does not reduce the stopped rate because the VMs are deallocated. AHB assumes eligible Windows Server licences. AHB does not apply to ALZ-lite or the archetype's other PaaS services. Keep the MI on the paid General Purpose offer; the free offer is not part of this event.

## Event-window estimate

Planning window: 120 elapsed hours from T-3 at 09:00 through cleanup at T+2 at 09:00. The datacenter is assumed to run 39 hours (4 hours of pre-work, 33 hours from Day 1 kickoff to the end of Day 2, because `vm-dev01` is never stopped during the event and `vm-app01` runs until the link is removed, and 2 hours during cleanup) and remain deployed but deallocated for 81 hours. The rate is per datacenter, so the estimate assumes both VMs run together. ALZ-lite is assumed deployed for 48 hours from Day 1 through cleanup; the archetype for 44 hours from its Day 1 deployment through cleanup.

| Charge | Calculation | Estimate |
|---|---|---:|
| Datacenter per member | 39 × $1.55 + 81 × $0.78 | $123.63 |
| Archetype per member | 44 × $1.83 | $80.52 |
| Member total | Datacenter + archetype | **$204.15** |
| Shared ALZ-lite foundation per team | 48 × $1.30 | **$62.40** |

| Team size | Member charges | Shared foundation | Whole event |
|---:|---:|---:|---:|
| 3 members | 3 × $204.15 = $612.45 | $62.40 | **$674.85** |
| 4 members | 4 × $204.15 = $816.60 | $62.40 | **$879.00** |
| 5 members | 5 × $204.15 = $1,020.75 | $62.40 | **$1,083.15** |

For a four-member team, turning off AHB for the 39 assumed running hours adds about **$117**. If the datacenter runs longer, add $0.75 for each additional running hour per affected member. If a member leaves the archetype running longer, add $1.83 per additional hour. The MI schedule (Monday to Friday, 07:30 to 18:30, `W. Europe Standard Time` by default, set with the archetype's `sqlMiSchedule*` parameters) only applies after cutover removes the link; a linked MI cannot be stopped. A live APEX demo adds the archetype rate for as long as it runs (see the [APEX demo](apex-demo.md)).

These figures exclude small variable costs such as Log Analytics ingestion, peering traffic, egress, taxes, support plans and price changes. The validation stacks included the datacenter, while the component table above separates each charge to avoid double-counting shared foundation costs.

## Estimate and actual reconciliation

- **Datacenter:** the estimate is $1.55/hour running and $0.78/hour deallocated with AHB; live validation confirmed approximately $1.55/hour.
- **ALZ-lite:** the $1.30/hour estimate is the shared foundation component. The $2.85/hour validation figure for that stack includes the $1.55/hour datacenter as well.
- **Archetype:** the estimate is $1.83/hour. The $4.63–$4.66/hour full-stack estimate is within rounding of the measured component sum of $4.68/hour.
- **Validation stack:** an earlier runbook line of $3.95/hour did not match the measured components. It has been corrected to $4.68/hour, the sum of the validated $1.30 foundation, $1.55 datacenter and $1.83 archetype rates.
- **Observed lifecycle:** live validation was about $4.68/hour with all components deployed; a complete validation-and-teardown cycle cost about $11 over roughly 2.5–3 hours per resource group. Those short validation cycles are actuals, not the longer event-window estimate above.

Rates were reconciled against the validation runbooks and the live validation actuals recorded on **2026-10-08**. Recheck regional prices before each event; do not treat this estimate as a current Azure quote.
