---
title: "C2: Secure, AI-ready foundation"
description: ALZ-lite, vending, exemptions and probes — the team's landing zone.
---

## Goal

Stand up the team's landing zone: a live portal ALZ demo first, then ALZ-lite deployed for real, every member's subscription vended into it, and the result proven with probes.

## Scope and time box

Team. **120 min**. The platform lead does tasks 3 to 5; every member does tasks 6 and 7 for their own datacenter.

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

   It creates the management groups, the hub (Azure Firewall Standard with DNS proxy, central private DNS zones), the central Log Analytics workspace, and the core policies at `mg-factory-corp`. It creates the identity `id-sqlmi-directory` in `rg-management`, which task 4 needs. The other members wait for vending (task 5) before their own tasks.
4. **Platform lead, with a Privileged Role Administrator: grant the SQL MI identity its Graph read, once per team.** Every member's SQL Managed Instance uses `id-sqlmi-directory`, and without this grant C7 can't create the web app's database user (`CREATE USER ... FROM EXTERNAL PROVIDER` fails with "Server identity does not have Azure Active Directory Readers permission"). Only someone with the Privileged Role Administrator (or Global Administrator) directory role can grant it. The platform lead usually can't, so your coach arranges that person (see the facilitator's pre-work): they sign in with `az login` as themselves in the same dev container (or any machine with the kit), and run:

   ```powershell
   ./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId '<shared-services-subscription-id>' -WhatIf
   ./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'
   ```

   Done when the second run reports the three Graph permissions (`User.Read.All`, `GroupMember.Read.All`, `Application.Read.All`) as granted. A re-run skips what is already granted. If the identity lookup is denied, give that person Reader on the shared services subscription first.
5. **Platform lead: vend every member, yourself included.** You are also a student with one workload subscription like everyone else, and you need to be vended too. Collect from each member their workload subscription ID, member index, location (the same as yours unless the coach said otherwise), Entra object ID (`az ad signed-in-user show --query id -o tsv`) and email, then run once per member, from the same `factory/` folder:

   ```powershell
   ./scripts/Deploy-Vending.ps1 -WorkloadSubscriptionId '<member-subscription-id>' -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex <member-index> -MemberPrincipalId '<member-object-id>' -BudgetEmail '<member-email>' -Location $s.location -WhatIf
   ```

   Re-run without `-WhatIf` once the plan looks right. Each run connects that workload subscription to the hub: spoke, subnets, peering, UDRs, DNS, firewall rules, RBAC and a budget. The output names subscription IDs, so don't paste it into the team repo without redacting them.
6. **Every member (including the platform lead): record your datacenter's exemptions.** After you've been vended, run this from your own `factory/` folder against your workload subscription. Each exemption needs an owner, a reason and an expiry (the default is 14 days). Policy changes can take up to 30 minutes to take effect after ALZ-lite, so if the output looks empty, wait and run it again:

   ```powershell
   az account set --subscription $s.subscriptionId
   ./scripts/New-DatacenterExemptions.ps1 -SubscriptionId $s.subscriptionId -Owner '<your name>' -WhatIf
   ```

   Re-run without `-WhatIf` to create them.
7. **Every member: prove connectivity.** Vending changed your datacenter's DNS servers and routes, and running VMs keep their old settings, so first restart both VMs (`az vm restart -g rg-datacenter -n vm-dev01`, then `-n vm-app01`). Then run this from your own dev container, from `factory/`. It runs its checks inside your datacenter VMs through Azure, so you don't sign in to the VMs:

   ```powershell
   ./scripts/Test-Connectivity.ps1 -SubscriptionId $s.subscriptionId -SharedSubscriptionId $s.sharedSubscriptionId -MemberIndex $s.memberIndex
   ```

   Every applicable check must PASS.

## Evidence

- `Deploy-AlzLite.ps1` output: management groups, hub and policies in place.
- `Grant-SqlMiDirectoryRead.ps1` output: the three Graph permissions granted.
- `Deploy-Vending.ps1` output for every member in the team (with subscription IDs redacted).
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

## Bonus

Up to 5 pts for running the negative tests from the B08 report yourself (a public storage account denied, a NIC with a public IP denied, a private endpoint auto-registering in the central DNS zone) and recording the results.

## Learn more

- [What is an Azure landing zone?](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Firewall DNS proxy](https://learn.microsoft.com/azure/firewall/dns-settings)
- [Azure Policy exemption structure](https://learn.microsoft.com/azure/governance/policy/concepts/exemption-structure)
