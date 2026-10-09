---
title: "C2: Secure, AI-ready foundation"
description: ALZ-lite, vending, exemptions and probes — the team's landing zone.
---

## Goal

Stand up the team's landing zone: a live portal ALZ demo first, then ALZ-lite deployed for real, every member's subscription vended into it, and the result proven with probes.

## Scope and time box

Team. **120 min**.

## Points

**35 pts** (team).

## Inputs

C1's opportunity canvas (context only — C2 doesn't depend on its content).

## Your tasks

1. Watch the coach's live demo of a full portal-based Azure Landing Zone, and note what ALZ-lite deliberately leaves out (it's a comparison table in the [ALZ-lite guide](../../guides/alz-lite/), not a gap to fix).
2. The platform lead deploys ALZ-lite into the team's shared services subscription with `scripts/Deploy-AlzLite.ps1`: management groups, the hub (Azure Firewall Standard with DNS proxy, central private DNS zones), the central Log Analytics workspace, and the core policies at `mg-factory-corp`.
3. The platform lead runs `scripts/Deploy-Vending.ps1` for every member, connecting each workload subscription to the hub: spoke, subnets, peering, UDRs, DNS, firewall rules, RBAC and a budget.
4. Record the datacenter's deliberate policy exceptions with `scripts/New-DatacenterExemptions.ps1` — each exemption needs an owner, a reason and an expiry.
5. Run `scripts/Test-Connectivity.ps1` from inside the datacenter and confirm every applicable check passes.

## Evidence

- `Deploy-AlzLite.ps1` output: management groups, hub and policies in place.
- `Deploy-Vending.ps1` output for every member in the team.
- The exemptions table, with owner, reason and expiry for each.
- `Test-Connectivity.ps1`: PASS on every applicable check.

## Hints

<details>
<summary>Vending fails to find the hub</summary>

`Deploy-Vending.ps1` discovers the hub by the ALZ-lite naming convention (`vnet-hub`, `afw-hub`, `afwp-hub`, `rg-hub`) in the shared services subscription. Confirm ALZ-lite finished and those names exist before running vending.
</details>

<details>
<summary>Policy evaluation shows the datacenter as non-compliant</summary>

That's expected until exemptions run — the datacenter was deployed before the workload subscription moved under `mg-factory-corp`. Record it as deferred work, don't fight the policy.
</details>

<details>
<summary>DNS stops resolving for a running VM after vending</summary>

VNet DNS servers changed, but running VMs cache their old settings. Restart the VM or run `ipconfig /renew`.
</details>

## Lifeline

Ask your coach if the platform lead is blocked on management group permissions or cross-subscription peering rights — this needs Owner at Tenant Root, which only the platform lead should have. Using the lifeline caps C2 at partial credit for the team.

## Bonus

Up to 5 pts for running the negative tests from the B08 report yourself (a public storage account denied, a NIC with a public IP denied, a private endpoint auto-registering in the central DNS zone) and recording the results.

## Learn more

- [What is an Azure landing zone?](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Firewall DNS proxy](https://learn.microsoft.com/azure/firewall/dns-settings)
- [Azure Policy exemption structure](https://learn.microsoft.com/azure/governance/policy/concepts/exemption-structure)
