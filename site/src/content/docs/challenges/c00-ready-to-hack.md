---
title: "C0: Ready to hack"
description: Pre-work. Preflight, datacenter, Arc onboarding, the first migration assessment and a first sign-in to vm-dev01.
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

   **Platform lead only:** also check the shared services subscription and your Tenant Root rights. Enter the shared services subscription ID in your settings (`./scripts/Initialize-Settings.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'`, press Enter at each prompt to keep your other values, then reload `$s`), and add `-SharedSubscriptionId $s.sharedSubscriptionId` to the command above. Treat a WARN on the "Management groups" row as a blocker too: tell your coach before the event.

   Fix every FAIL it reports (the Owner role on your subscription is an automated check, not a manual one). Work through the five MANUAL rows yourself: MFA, GitHub Copilot, GitHub repositories, APEX and Azure Hybrid Benefit. [Prerequisites](../../getting-started/prerequisites/) says how to confirm each. Then re-run with `-Fix` to let it register missing resource providers (it waits up to 15 minutes). Done when the verdict is GO and no row is FAIL.
2. **Deploy your datacenter.** Run:

   ```powershell
   ./scripts/Deploy-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

   This creates `rg-datacenter` with `vm-app01` (legacy Contoso University on IIS, SQL Server 2022, MSMQ) and `vm-dev01` (your workstation for the rest of the kit). It takes up to 60 minutes and runs unattended. Done when the script reports the datacenter is deployed and `rg-datacenter` lists both VMs.
3. **Confirm the datacenter is healthy, before Arc.** Both VMs must be running. Run:

   ```powershell
   ./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex
   ```

   It checks VM state and size, licence type, Trusted Launch, no public IPs, Bastion Standard, and the in-VM checks (IIS site up, SQL Server up, the perf kit's planted data and objects present). Every row must be PASS. Save the output: it's your evidence. **Do this before task 4.** Arc onboarding turns off the run commands that the in-VM checks use, so `Test-Datacenter.ps1` can't pass for `vm-app01` after it.
4. **Onboard `vm-app01` to Azure Arc.** Run:

   ```powershell
   ./scripts/Connect-DatacenterArc.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

   This is the kit's only onboarding path; there are no manual portal steps. It takes 10 to 20 minutes. Done when `vm-app01` shows as Connected under Azure Arc > Machines and the script lists the Arc-enabled SQL Server instance.
5. **Run the first Arc SQL migration assessment.** In the Azure portal, open the SQL Server instance under `vm-app01` (Azure Arc > SQL Server instances), then **Migration** > **Database migration** > **Assess source instance** > **View report**. If there's no result yet, choose **Run assessment** with Azure SQL Managed Instance as the target and wait for it to finish. Export the report and skim the findings for `ContosoUniversity`. C3 is where you triage them. Done when you have the exported report or a screenshot of its findings.
6. **Check you can work on `vm-dev01`.** From C3 you work on this VM, so confirm now that you can reach it and that Copilot works there. Both VMs must be running. In your dev container, from `factory/`, get the password (the user is `labadmin`):

   ```powershell
   (Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json).adminPassword
   ```

   In the Azure portal open `rg-datacenter` > `vm-dev01` > **Connect** > **Bastion**, sign in, and wait a few minutes after the first sign-in: VS Code's extensions install per user then. Open VS Code on the VM, sign in to GitHub when it asks, then open Copilot Chat and send "hello". Done when Copilot Chat answers in VS Code on `vm-dev01`. Do nothing else on the VM now: the [GitHub Copilot upgrade guide](../../guides/ghcp-upgrade/#switching-to-vm-dev01) sets up the rest in C3. If Copilot is blocked by your organization's policy, tell your coach before the event.
7. **Control cost.** Azure Hybrid Benefit is on by default for `vm-app01`'s Windows Server licence, which assumes your partner holds eligible licences with Software Assurance or subscriptions. If you don't, deploy with `-NoHybridBenefit` (and run `Test-Datacenter.ps1` with `-NoHybridBenefit`) and tell your coach; otherwise don't turn it off. Before the event, you can stop both VMs when you're not working (`az vm deallocate -g rg-datacenter -n vm-app01` and `-n vm-dev01`); the datacenter bills while running, and Bastion, the NAT gateway and the disks bill even when the VMs are stopped. Start both again before day one (`az vm start -g rg-datacenter -n vm-app01`, then `-n vm-dev01`). Don't re-run `Test-Datacenter.ps1` after Arc: it needs the run commands. During the event, never stop `vm-dev01`: it's your workstation.

## Evidence

Save your evidence in a local folder as you go, because the team repo doesn't exist until C1. On day one, copy it to the team repo as `evidence/c00/member-<n>/` (`<n>` is your member index), then commit and push as [C1](../c01-define-the-opportunity/#the-team-repo-what-it-is-and-how-to-set-it-up) describes. Redact subscription, tenant and object IDs from anything you commit.

- `Test-Preflight.ps1` output: every automated check green. `.local/preflight.json` is git-ignored, so save the console output or a screenshot instead.
- `Test-Datacenter.ps1` output from before Arc onboarding: every check green (or an explained FAIL your coach has already seen).
- The Arc resource for `vm-app01`, with Azure Connected Machine agent connected, and the SQL Server extension showing the instance.
- The Arc migration assessment's first output (screenshot or exported report) — you don't need to act on it yet.
- Your Azure Hybrid Benefit confirmation: on for `vm-app01`'s Windows Server licence, or why it isn't (you deployed with `-NoHybridBenefit` and your coach agreed). Add a screenshot of `az vm list -g rg-datacenter -d -o table` showing both VMs and their power state.
- A screenshot of Copilot Chat answering in VS Code on `vm-dev01`, signed in to GitHub (task 6).

## Hints

<details>
<summary>I'm stuck on preflight</summary>

Most preflight failures are missing resource provider registrations or a role assignment that hasn't propagated yet. Re-run with `-Fix` and wait a few minutes before re-checking; propagation can take up to 15 minutes.
</details>

<details>
<summary>Arc onboarding doesn't finish</summary>

`Connect-DatacenterArc.ps1` needs outbound internet from `vm-app01` to Arc's endpoints — the datacenter's NAT gateway should already allow this. Don't just run the script again if it timed out after it started: it refuses a second run once the guest agent is off. Connect to `vm-app01` through Bastion and read `C:\LabTools\logs\Connect-AppArc.log`. If onboarding didn't finish, tell your coach: the fix is to redeploy `vm-app01` with `Deploy-Datacenter.ps1`, then run the Arc script again.
</details>

## Bonus

None for C0.

## Learn more

- [Connect hybrid machines to Azure using a deployment script](https://learn.microsoft.com/azure/azure-arc/servers/onboard-portal)
- [SQL Server registration with Azure Arc overview](https://learn.microsoft.com/sql/sql-server/azure-arc/overview)
- [Azure Hybrid Benefit for Windows Server](https://learn.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing)
