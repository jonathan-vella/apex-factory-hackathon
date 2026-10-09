# Event cost estimate

These are approximate list-price estimates in USD for `swedencentral`, with Azure Hybrid Benefit (AHB) on where supported. Use the actual deployment and cleanup times to replace the planning hours below. The sample team has four members; the supported team size is three to five.

## Hourly rates

| Component | Scope | Running | Stopped / deallocated | Notes |
|---|---|---:|---:|---|
| Datacenter | Per member | $1.55/hour | $0.78/hour | B04 estimate and B10 live actual; stopped cost remains for Bastion Standard, disks, NAT and IP |
| ALZ-lite foundation | Per team | $1.30/hour | Not applicable | B08 estimate and B10 live actual; Azure Firewall is the main continuing charge |
| CoE archetype | Per member | $1.83/hour | Not applicable | B09 estimate and B10 live actual; SQL MI, Service Bus, App Service, ACR and private endpoints |
| Full stack, one member plus shared foundation | Per member + team share | $4.68/hour | Not applicable | Actual component sum: $1.30 + $1.55 + $1.83 |

The datacenter estimate is about **$2.30/hour running** without AHB. Turning AHB off adds about **$0.75 per running hour per member**; it does not reduce the stopped rate because the VMs are deallocated. AHB assumes eligible Windows Server licences. AHB does not apply to ALZ-lite or the archetype's other PaaS services. Keep the MI on the paid General Purpose offer; the free offer is not part of this event.

## Event-window estimate

Planning window: 120 elapsed hours from T-3 at 09:00 through cleanup at T+2 at 09:00. The datacenter is assumed to run 22 hours (4 hours of pre-work, 8 hours on each event day and 2 hours during cleanup) and remain deployed but deallocated for 98 hours. ALZ-lite is assumed deployed for 48 hours from Day 1 through cleanup; the archetype for 44 hours from its Day 1 deployment through cleanup.

| Charge | Calculation | Estimate |
|---|---|---:|
| Datacenter per member | 22 × $1.55 + 98 × $0.78 | $110.54 |
| Archetype per member | 44 × $1.83 | $80.52 |
| Member total | Datacenter + archetype | **$191.06** |
| Shared ALZ-lite foundation per team | 48 × $1.30 | **$62.40** |

| Team size | Member charges | Shared foundation | Whole event |
|---:|---:|---:|---:|
| 3 members | 3 × $191.06 = $573.18 | $62.40 | **$635.58** |
| 4 members | 4 × $191.06 = $764.24 | $62.40 | **$826.64** |
| 5 members | 5 × $191.06 = $955.30 | $62.40 | **$1,017.70** |

For a four-member team, turning off AHB for the 22 assumed running hours adds about **$66**. If the datacenter runs longer, add $0.75 for each additional running hour per affected member. If a member leaves the archetype running longer, add $1.83 per additional hour. The MI schedule only applies after cutover removes the link. Keep it stopped outside event hours where the schedule allows; a linked MI cannot be stopped.

These figures exclude small variable costs such as Log Analytics ingestion, peering traffic, egress, taxes, support plans and price changes. The B08/B09 validation stacks included the datacenter, while the component table above separates each charge to avoid double-counting shared foundation costs.

## Estimate and actual reconciliation

- **B04:** the datacenter estimate is $1.55/hour running and $0.78/hour deallocated with AHB; the B10 live actuals confirm approximately $1.55/hour.
- **B08:** the $1.30/hour ALZ-lite estimate is the shared foundation component. B08's $2.85/hour validation figure includes the $1.55/hour datacenter as well.
- **B09:** the archetype estimate is $1.83/hour. B09's $4.63–$4.66/hour full-stack estimate is within rounding of the B10 measured component sum of $4.68/hour.
- **B10:** the prior runbook line of $3.95/hour for the validation stack did not match the measured components. It has been corrected to $4.68/hour, the sum of the validated $1.30 foundation, $1.55 datacenter and $1.83 archetype rates.
- **Observed lifecycle:** B10's live validation was about $4.68/hour with all components deployed; a complete validation-and-teardown cycle cost about $11 over roughly 2.5–3 hours per resource group. Those short validation cycles are actuals, not the longer event-window estimate above.

Rate sources were reconciled against the B04, B08 and B09 runbooks and the B10 live validation actuals recorded on **2026-10-08**. Recheck regional prices before each event; do not treat this estimate as a current Azure quote.
