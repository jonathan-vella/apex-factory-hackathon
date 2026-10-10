---
title: "C2: Secure, AI-ready foundation"
description: ALZ-lite, vending, exemptions and probes — the team's landing zone.
---

## Goal

Stand up the team's landing zone: a live portal ALZ demo first, then ALZ-lite deployed for real, every member's subscription vended into it, and the result proven with probes.

## Scope and time box

Team. **120 min**. The platform lead does tasks 2 and 3; every member does tasks 4 and 5 for their own datacenter.

## Points

**35 pts** (team).

## Inputs

C1's opportunity canvas (context only — C2 doesn't depend on its content).

## Where to run

Every command on this page runs in the dev container of your own repo, from the `factory/` folder, unless a task says otherwise. Open a terminal there, start PowerShell, and go to `factory`:

```bash
pwsh
cd factory
```

Check you're signed in (run `az login --use-device-code` if this fails), and load your settings. In any new terminal, repeat the `$s = ...` line; you only re-run `Initialize-Settings.ps1` when you add or change a value (task 1):

```powershell
az account show --output table
$s = Get-Content .local/settings.json | ConvertFrom-Json
```

Task 2 is a demo; there's nothing to run.

## Your tasks

1. **Everyone: get the shared services subscription ID.** The platform lead posts it in the team channel at the start of C2. In the terminal above, add it to your settings (it keeps your other values), then reload `$s`:

   ```powershell
   ./scripts/Initialize-Settings.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
   $s = Get-Content .local/settings.json | ConvertFrom-Json
   $s.sharedSubscriptionId
   ```

   The last line prints the ID you just saved. The platform lead already has it; run the same command once to record it.
2. Watch the coach's live demo of a full portal-based Azure Landing Zone, and note what ALZ-lite deliberately leaves out (it's a comparison table in the [ALZ-lite guide](../../guides/alz-lite/), not a gap to fix).
3. **Platform lead: deploy ALZ-lite.** In the same terminal (dev container, `factory/`), against the **shared services** subscription:

   ```powershell
   az account set --subscription $s.sharedSubscriptionId
   ./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location -WhatIf
   ./scripts/Deploy-AlzLite.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -Location $s.location
   ```

   It creates the management groups, the hub (Azure Firewall Standard with DNS proxy, central private DNS zones), the central Log Analytics workspace, and the core policies at `mg-factory-corp`. The other members wait for this before task 4.
4. **Platform lead: vend every member, yourself included.** You are also a student with one workload subscription like everyone else, and you need to be vended too. Collect from each member their workload subscription ID, member index and Entra object ID, then run once per member, from the same `factory/` folder:

   ```powershell
   ./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId '<member-subscription-id>' -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <member-index> -MemberPrincipalId '<member-object-id>' -BudgetEmail '<member-email>' -WhatIf
   ```

   Re-run without `-WhatIf` once the plan looks right. Each run connects that workload subscription to the hub: spoke, subnets, peering, UDRs, DNS, firewall rules, RBAC and a budget.
5. **Every member (including the platform lead): record your datacenter's exemptions.** After you've been vended, run this from your own `factory/` folder against your workload subscription. Each exemption needs an owner, a reason and an expiry (the default is 14 days):

   ```powershell
   az account set --subscription $s.subscriptionId
   ./scripts/New-DatacenterExemptions.ps1 -SubscriptionId $s.subscriptionId -Owner '<your name>' -WhatIf
   ```

   Re-run without `-WhatIf` to create them.
6. **Every member: prove connectivity.** Run this from your own dev container, from `factory/`. It runs its checks inside your datacenter VMs through Azure, so you don't sign in to the VMs:

   ```powershell
   ./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex
   ```

   Every applicable check must PASS.

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
