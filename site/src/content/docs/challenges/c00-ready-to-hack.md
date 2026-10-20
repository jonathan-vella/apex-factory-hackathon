---
title: "C0: Ready to hack"
description: Pre-work. Preflight, datacenter, Arc onboarding, the first migration assessment and a complete setup of vm-dev01.
---

:::danger[Pre-work: finish before the event]
C0 is done **before the event starts**: preflight by T-14, datacenter and Arc onboarding by T-3. Complete [Prerequisites](../../getting-started/prerequisites/) first: your own repo from the `apex-accelerator` template, the dev container, the kit imported into `factory/` and merged into `main`, and `.local/settings.json` written. Every command below runs from there.
:::

## Goal

Arrive at the event with your Azure prerequisites green, your "on-premises" datacenter deployed, `vm-app01` onboarded to Azure Arc, a first look at what an Arc SQL migration assessment finds, and `vm-dev01` set up so that C3 opens on a ready VM.

## Scope and time box

Member. **150 min** (pre-work, done before the event; not on the two-day agenda). That's pacing, not a limit: most of it is waiting for unattended deployments, and the hands-on VM setup in task 7 (about 30 minutes) comes on top.

## Points

**10 pts** (member).

## Inputs

None. This is the first challenge: your workload subscription, assigned at onboarding.

## Where to run

- **Tasks 1 to 4 and 6:** the dev container of your own repo, from the `factory/` folder, as set up in [Prerequisites](../../getting-started/prerequisites/).
- **Task 5:** the Azure portal, on your own computer.
- **Task 7:** the dev container for one lookup, the Azure portal, then `vm-dev01` itself through Bastion.

Open a terminal in the dev container and start `pwsh`. Check you're signed in and load your settings:

```powershell
cd factory   # only if your terminal isn't in factory/ yet
az account show --output table
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId
```

If `az account show` fails, sign in again with `az login --use-device-code`. `$s` is your `factory/.local/settings.json`: `$s.subscriptionId`, `$s.memberIndex`, `$s.suffix` and `$s.location` are the values the commands below use. Re-run the `$s = ...` line in any new terminal.

## Your tasks

1. **Preflight (about 15 min, plus up to 15 min waiting).** Run:

   ```powershell
   ./scripts/Test-Preflight.ps1 -WorkloadSubscriptionId $s.subscriptionId -Location $s.location -OutFile .local/preflight.json
   ```

   **Platform lead only:** also check the shared services subscription and your Tenant Root rights. (Tenant Root is the top management group of your Microsoft Entra tenant, and a management group is a container above subscriptions that policy and access flow down from.) Your settings already hold the shared services subscription ID from Prerequisites, so just add `-SharedSubscriptionId $s.sharedSubscriptionId` to the command above. If `$s.sharedSubscriptionId` is empty, record the ID once with `./scripts/Initialize-Settings.ps1 -SharedSubscriptionId '<shared-services-subscription-id>'`, which asks nothing, then reload `$s`. Treat a WARN on the "Management groups" row as a blocker too: tell your coach before the event.

   Fix every FAIL it reports (the Owner role on your subscription is an automated check, not a manual one). Work through the five MANUAL rows yourself: MFA, GitHub Copilot, GitHub repositories, APEX and Azure Hybrid Benefit. The manual checks in [Prerequisites](../../getting-started/prerequisites/) say how to confirm each. Then re-run with `-Fix` to let it register missing resource providers (it waits up to 15 minutes). Done when the verdict is GO and no row is FAIL.
2. **Deploy your datacenter (30 to 60 min, unattended).** Azure Hybrid Benefit, a discount for Windows Server licenses you already own, is on by default for `vm-app01`. If you don't hold eligible licenses, add `-NoHybridBenefit` to the command and to the one in task 3 (the [Azure Hybrid Benefit](../../reference/azure-hybrid-benefit/) page has the details). Run:

   ```powershell
   ./scripts/Deploy-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

   This creates `rg-datacenter` with `vm-app01` (legacy Contoso University on IIS, SQL Server 2022, MSMQ) and `vm-dev01` (your workstation for the rest of the kit). It takes up to 60 minutes. Keep the terminal open and your computer awake. Done when the script reports the datacenter is deployed and `rg-datacenter` lists both VMs.

   **If this fails:** the script is safe to run again until Arc onboarding (task 4): run the same command and it picks up where it stopped. Do the same if your terminal closed or your computer went to sleep. If it fails twice, stop and message your coach with the error text.
3. **Confirm the datacenter is healthy, before Arc (about 5 min).** Both VMs must be running. Run:

   ```powershell
   ./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex
   ```

   It checks VM state and size, license type, Trusted Launch (a VM security setting: secure boot and a virtual TPM chip), no public IPs, Azure Bastion Standard (the portal-based way into your VMs, which have no public IP), and the in-VM checks (IIS site up, SQL Server up, the perf kit's planted data and objects present). The in-VM checks use run commands: an Azure feature that runs a script inside a VM without you signing in to it. Every row must be PASS. Save the output: it's your evidence. **Do this before task 4.** Arc onboarding turns off the guest agent (the Azure agent on the VM that receives run commands), so `Test-Datacenter.ps1` can't pass for `vm-app01` after it. Done when every row is PASS.

   **If this fails:** run it again; it's safe to repeat. If an in-VM row still fails, run `Deploy-Datacenter.ps1` again (task 2), then this check. If it still fails, message your coach before you start task 4: Arc can't be undone.
4. **Onboard `vm-app01` to Azure Arc (10 to 20 min, unattended).** Arc shows a server outside Azure (here, your simulated datacenter) as an Azure resource. Run:

   ```powershell
   ./scripts/Connect-DatacenterArc.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex -Location $s.location
   ```

   This is the kit's only onboarding path; there are no manual portal steps. Done when `vm-app01` shows as Connected under Azure Arc > Machines and the script lists the Arc-enabled SQL Server instance. If it doesn't finish, see the hint "Arc onboarding doesn't finish" below, and don't run it again.
5. **Run the first Arc SQL migration assessment (about 15 min).** In the Azure portal on your own computer, search for **Azure Arc**. In its left menu choose **SQL Server instances** and select the instance on `vm-app01`. In the instance's left menu choose **Migration** > **Database migration**, then **Assess source instance** > **View report**. If there's no result yet, choose **Run assessment** with Azure SQL Managed Instance as the target and wait for it to finish. Export the report and skim the findings for `ContosoUniversity`. C3 is where you triage them. Done when you have the exported report or a screenshot of its findings.
6. **Confirm Azure Hybrid Benefit and what running the datacenter costs (about 5 min).** In your dev container, from `factory/`:

   ```powershell
   az vm list -g rg-datacenter -d -o table
   az vm show -g rg-datacenter -n vm-app01 --query licenseType -o tsv
   ```

   Done when the table lists both VMs running and the second command prints `Windows_Server` (Hybrid Benefit on), or prints nothing or `None` because you deployed with `-NoHybridBenefit` and your coach agreed. Otherwise don't change it yourself: tell your coach. The datacenter bills while it runs, and Bastion, the NAT gateway and the disks bill even when the VMs are stopped: see the hint "Save money between sessions".
7. **Set up `vm-dev01`, once (about 30 min).** From C3 you work on this VM, so set it up completely now; then C3 opens on a ready VM and you do nothing on it on event day except open VS Code. Both VMs must be running. Follow steps 1 to 9 of [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) in order: the password lookup, Bastion, the GitHub and Azure sign-ins, git identity, `AZURE_TOKEN_CREDENTIALS`, the kit clone, the `member` remote and `vm-dev01-work` branch, a plain clone of your own repo at `C:\src\<your-repo>`, VS Code on `C:\src\factory` with Copilot signed in, and the Upgrade agent in the **Local** harness. Done when every line of the guide's [Check your setup](../../guides/ghcp-upgrade/#check-your-setup) is true:

   - GitHub, Azure and git identity are set on the VM, and `AZURE_TOKEN_CREDENTIALS` is `AzureCliCredential`.
   - `C:\src\factory` has `origin` (the public kit) and `member` (your repo), and is on `vm-dev01-work` tracking `member/vm-dev01-work`.
   - `C:\src\<your-repo>` is a plain clone of your own repo on `main`.
   - VS Code is open on `C:\src\factory`, the agent picker lists **Upgrade**, the harness is **Local**, and Copilot Chat answers "hello".

   If Copilot is blocked by your organization's policy, tell your coach before the event. If a step fails, the guide says what to check; after two attempts, ask your coach.

## Evidence

Save your evidence in `factory/evidence/c00/` in your own repo (create the folder if it isn't there). The rule is the same everywhere:

- **Dev container:** evidence goes in `factory/evidence/` on `main`; run `git pull` first.
- **`vm-dev01`:** evidence goes in `C:\src\<your-repo>\factory\evidence\...` (the plain clone of your own repo) on `main`; run `git pull --rebase` first.

Commit with a conventional commit message such as `docs: C0 evidence`, and push. [C1](../c01-define-the-opportunity/#where-your-evidence-goes) later sets up the rest of the `factory/evidence/` folders around what you already saved. Redact subscription, tenant and object IDs from anything you commit.

- `Test-Preflight.ps1` output: every automated check green. `.local/preflight.json` is git-ignored, so save the console output or a screenshot instead.
- `Test-Datacenter.ps1` output from before Arc onboarding: every check green (or an explained FAIL your coach has already seen).
- The Arc resource for `vm-app01`, with Azure Connected Machine agent connected, and the SQL Server extension showing the instance.
- The Arc migration assessment's first output (screenshot or exported report). You don't need to act on it yet.
- Your Azure Hybrid Benefit confirmation (task 6): on for `vm-app01`'s Windows Server license, or why it isn't (you deployed with `-NoHybridBenefit` and your coach agreed). Add a screenshot of `az vm list -g rg-datacenter -d -o table` showing both VMs and their power state.
- A screenshot of Copilot Chat answering in VS Code on `vm-dev01`, signed in to GitHub (task 7). Take it on the VM and save it in `C:\src\<your-repo>\factory\evidence\c00\`, then commit and push from there as in [Copy your evidence to your repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo).

## Hints

<details>
<summary>I'm stuck on preflight</summary>

Most preflight failures are missing resource provider registrations or a role assignment that hasn't propagated yet. Re-run with `-Fix` and wait a few minutes before re-checking; propagation can take up to 15 minutes.
</details>

<details>
<summary>Arc onboarding doesn't finish</summary>

`Connect-DatacenterArc.ps1` needs outbound internet from `vm-app01` to Arc's endpoints; the datacenter's NAT gateway (its shared outbound path) should already allow this. Don't run the script again if it timed out after it started: it refuses a second run once the guest agent is off, and re-running `Deploy-Datacenter.ps1` can't recover it either. To see what happened, connect to `vm-app01` through Bastion as in [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) (steps 1 and 2, `vm-app01` instead of `vm-dev01`, same password) and open `C:\LabTools\logs\Connect-AppArc.log` in Notepad.

If onboarding didn't finish, there are two ways out. Message your coach, who may have a faster fix. Or start over: delete `rg-datacenter` in the Azure portal (**Resource groups** > `rg-datacenter` > **Delete resource group**, in your own workload subscription), run `Deploy-Datacenter.ps1` again (task 2), `Test-Datacenter.ps1` (task 3), then Arc (task 4). Deleting `rg-datacenter` also deletes `vm-dev01`, so repeat task 7 afterwards.
</details>

<details>
<summary>Save money between sessions</summary>

Before the event you can stop both VMs when you're not working: `az vm deallocate -g rg-datacenter -n vm-app01`, then the same with `-n vm-dev01`. Deallocating releases the VM's compute and stops its compute billing. Shutting Windows down from inside the VM does not. Start both again before day one: `az vm start -g rg-datacenter -n vm-app01`, then `-n vm-dev01`. Don't re-run `Test-Datacenter.ps1` after Arc: it needs the run commands. During the event, never stop `vm-dev01`: it's your workstation.
</details>

## If you need to start over

Run `Deploy-Datacenter.ps1` again to repair the datacenter after a failure: it converges to the same result. If your datacenter was already vended (C2), the re-run resets its DNS servers and routes, so your platform lead must vend you again, and you restart both VMs. `Connect-DatacenterArc.ps1` can't be re-run: it refuses once `vm-app01` is an Arc machine or its guest agent is off. If onboarding didn't finish, or you need to start over after Arc, delete `rg-datacenter` and deploy again (see the hint "Arc onboarding doesn't finish"). That removes `vm-app01`, `vm-dev01` and everything on them, so you repeat tasks 2 to 7. Ask your coach before you do either.

## Bonus

None for C0.

## Learn more

- [Connect hybrid machines to Azure using a deployment script](https://learn.microsoft.com/azure/azure-arc/servers/onboard-portal)
- [SQL Server registration with Azure Arc overview](https://learn.microsoft.com/sql/sql-server/azure-arc/overview)
- [Azure Hybrid Benefit for Windows Server](https://learn.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing)
