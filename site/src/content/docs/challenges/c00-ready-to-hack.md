---
title: "C0: Ready to hack"
description: Pre-work. Preflight, datacenter, Arc onboarding and the first migration assessment.
---

:::danger[Pre-work: finish before the event]
C0 is done **before the event starts**: preflight by T-14, datacenter and Arc onboarding by T-3. Complete [Prerequisites](../../getting-started/prerequisites/) first: your own repo from the `apex-accelerator` template, the dev container, the kit imported into `factory/`, and `.local/settings.json` written. Every command below runs from there.
:::

## Goal

Arrive at the event with your Azure prerequisites green, your "on-premises" datacenter deployed, `vm-app01` onboarded to Azure Arc, and a first look at what an Arc SQL migration assessment finds.

## Scope and time box

Member. **150 min** (pre-work, done before the event; not on the two-day agenda).

## Points

**10 pts** (member).

## Inputs

None. This is the first challenge: your workload subscription, assigned at onboarding.

## Where to run

Everything runs in the dev container of your own repo, from the `factory/` folder, as set up in [Prerequisites](../../getting-started/prerequisites/). Open a terminal there (`pwsh`), then:

```powershell
cd factory
az login --use-device-code
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId
```

Reuse that `$s` in every command below (re-run the `$s = ...` line in any new terminal).

## Your tasks

1. **Preflight.** Run:

   ```powershell
   ./scripts/Test-Preflight.ps1 -WorkloadSubscriptionId $s.subscriptionId -Location $s.location -OutFile .local/preflight.json
   ```

   Fix every FAIL it reports. Work through the MANUAL rows yourself (RBAC, MFA, GitHub Copilot policy, APEX runtime access). Then re-run with `-Fix` to let it register missing resource providers (it waits up to 15 minutes). Done when the verdict is GO and no row is FAIL.
2. **Deploy your datacenter.** Run:

   ```powershell
   ./scripts/Deploy-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

   This creates `rg-datacenter` with `vm-app01` (legacy Contoso University on IIS, SQL Server 2022, MSMQ) and `vm-dev01` (your workstation for the rest of the kit).
3. **Onboard `vm-app01` to Azure Arc.** Run:

   ```powershell
   ./scripts/Connect-DatacenterArc.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

   This is the kit's only onboarding path; there's no manual portal steps. Done when `vm-app01` shows as Connected under Azure Arc > Machines.
4. **Run the first Arc SQL migration assessment.** In the Azure portal, open the SQL Server instance under `vm-app01` (Azure Arc > SQL Server instances), go to its **Migration** assessment page and run an assessment targeting Azure SQL Managed Instance. Wait for it to finish, export the report, and skim the findings. C3 is where you triage them.
5. **Confirm the datacenter is healthy.** Run:

   ```powershell
   ./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex
   ```

   It checks VM state and size, licence type, Trusted Launch, no public IPs, Bastion Standard, and the in-VM checks (IIS site up, SQL Server up, the perf kit's planted data and objects present). Every row must be PASS.
6. **Control cost.** Azure Hybrid Benefit is on by default for `vm-app01`'s Windows Server licence; don't turn it off. Stop both VMs when you're not working (`az vm deallocate -g rg-datacenter -n vm-app01` and `-n vm-dev01`); the datacenter bills while running.

## Evidence

- `Test-Preflight.ps1` output: every automated check green.
- `Test-Datacenter.ps1` output: every check green (or an explained FAIL your coach has already seen).
- The Arc resource for `vm-app01`, with Azure Connected Machine agent connected, and the SQL Server extension showing the instance.
- The Arc migration assessment's first output (screenshot or exported report) — you don't need to act on it yet.

## Hints

<details>
<summary>I'm stuck on preflight</summary>

Most preflight failures are missing resource provider registrations or a role assignment that hasn't propagated yet. Re-run with `-Fix` and wait a few minutes before re-checking; propagation can take up to 15 minutes.
</details>

<details>
<summary>Arc onboarding doesn't finish</summary>

`Connect-DatacenterArc.ps1` needs outbound internet from `vm-app01` to Arc's endpoints — the datacenter's NAT gateway should already allow this. If the script times out, check that the VM can resolve `*.his.arc.azure.com` before re-running.
</details>

## Lifeline

Not applicable — pre-work has no in-event lifeline. If you're stuck, ask your coach before the event starts; don't wait for T-3.

## Bonus

None for C0.

## Learn more

- [Connect hybrid machines to Azure using a deployment script](https://learn.microsoft.com/azure/azure-arc/servers/onboard-portal)
- [SQL Server registration with Azure Arc overview](https://learn.microsoft.com/sql/sql-server/azure-arc/overview)
- [Azure Hybrid Benefit for Windows Server](https://learn.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing)
