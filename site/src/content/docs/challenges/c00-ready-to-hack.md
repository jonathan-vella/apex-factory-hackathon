---
title: "C0: Ready to hack"
description: Pre-work. Preflight, datacenter, Arc onboarding, the first migration assessment and a complete setup of vm-dev01.
---

:::danger[Pre-work: finish before the event]
C0 is done **before the event starts**: preflight by T-14, datacenter and Arc onboarding by T-3. A coach reviews your C0 output, and then your platform lead vends your subscription at T-1 (see [C2](../c02-secure-ai-ready-foundation/)). Complete [Prerequisites](../../getting-started/prerequisites/) first: your own repo from the `apex-accelerator` template, the dev container, the kit imported into `factory/` and merged into `main`, and `.local/settings.json` written. Every command below runs from there.
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

- **Tasks 1 to 4:** the dev container of your own repo, from the `factory/` folder, as set up in [Prerequisites](../../getting-started/prerequisites/). You start the stages there with `gh`, and the **Actions** tab shows the runs.
- **Task 6:** the same dev container.
- **Task 5:** the Azure portal, on your own computer.
- **Task 7:** the dev container for the password lookup in step 1, the Azure portal, then `vm-dev01` itself through Bastion.

Open a terminal in the dev container and start `pwsh`. Check you're signed in and load your settings:

```powershell
cd factory   # only if your terminal isn't in factory/ yet
az account show --output table
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId
```

If `az account show` fails, sign in again with `az login --use-device-code`. `$s` is your `factory/.local/settings.json`: `$s.subscriptionId`, `$s.memberIndex`, `$s.suffix` and `$s.location` are the values the commands below use. Re-run the `$s = ...` line in any new terminal.

## Your tasks

You deploy with GitHub Actions: tasks 1 to 4 run the `whatif` and `member` stages of your own repo's pipeline, unattended. [Deploy with GitHub Actions](../../guides/deploy-with-actions/#member) has the one-time setup and the full steps.

1. **Preflight (about 15 min, plus up to 15 min waiting).** If you haven't yet, set up the member pipeline once, then run the preflight stage:

   ```powershell
   ./scripts/Initialize-PlatformPipeline.ps1 -Profile Member
   ```

   ```bash
   gh workflow run platform.yml -f stage=whatif
   ```

   Open the **Actions** tab and approve the run if GitHub asks. The stage checks your subscription and registers missing resource providers for you (propagation can take up to 15 minutes). **Platform lead:** the same stage also checks the shared services subscription, your Tenant Root rights and every member in the roster. (Tenant Root is the top management group of your Microsoft Entra tenant, and a management group is a container above subscriptions that policy and access flow down from.) Treat a warning on the "Management groups" row as a blocker too: tell your coach before the event.

   Fix every FAIL the run log reports (the Owner role on your subscription is an automated check, not a manual one). Work through the five MANUAL rows yourself: MFA, GitHub Copilot, GitHub repositories, APEX and Azure Hybrid Benefit. The manual checks in [Prerequisites](../../getting-started/prerequisites/) say how to confirm each. Done when the run is green and no row is FAIL. Then send the event owner, in the private event channel and never in a repo, your workload subscription ID, member index, Entra object ID (`az ad signed-in-user show --query id -o tsv`) and email: the platform lead needs them to vend you at T-1.
2. **Deploy your datacenter (30 to 60 min, unattended).** Run the `member` stage. Azure Hybrid Benefit, a discount for Windows Server licenses you already own, is on by default for `vm-app01`. If you don't hold eligible licenses, tell your coach and add `-f no-hybrid-benefit=true`. It covers `vm-app01` only, so ask your coach what to do for the SQL Managed Instance in C5. The rule is on the [Azure Hybrid Benefit](../../reference/azure-hybrid-benefit/) page.

   ```bash
   gh workflow run platform.yml -f stage=member
   # without Hybrid Benefit:
   gh workflow run platform.yml -f stage=member -f no-hybrid-benefit=true
   ```

   The stage creates `rg-datacenter` with `vm-app01` (legacy Contoso University on IIS, SQL Server 2022, MSMQ) and `vm-dev01` (your workstation for the rest of the kit). It takes up to 60 minutes: you don't need to keep anything open. Done when `rg-datacenter` lists both VMs and the run's deploy step is green.

   **If this fails:** the stage is safe to run again until Arc onboarding (task 4): read the run log, then run it again and it picks up where it stopped. If it fails twice, stop and message your coach with the error text.
3. **Confirm the datacenter is healthy, before Arc (about 5 min).** The `member` stage does this for you: after the deploy it tests the datacenter, and it onboards Arc only if every row passes. The test checks VM state and size, license type, Trusted Launch (a VM security setting: secure boot and a virtual TPM chip), no public IPs, Azure Bastion Standard (the portal-based way into your VMs, which have no public IP), and the in-VM checks (IIS site up, SQL Server up, the perf kit's planted data and objects present). The in-VM checks use run commands: an Azure feature that runs a script inside a VM without you signing in to it. The test must run before Arc onboarding because Arc turns off the guest agent (the Azure agent on the VM that receives run commands), so the test can't pass for `vm-app01` after it. Done when the test's step in the run summary shows every row PASS (an explained FAIL counts only if your coach has seen it and agrees).

   **If this fails:** the stage stops before Arc, so nothing is lost. Read the run log and run the `member` stage again; it's safe to repeat. If it still fails, message your coach before it gets to Arc: Arc can't be undone.
4. **Onboard `vm-app01` to Azure Arc, and save your evidence (10 to 20 min, unattended).** Arc shows a server outside Azure (here, your simulated datacenter) as an Azure resource. The same `member` run does this after the test passes. There are no manual portal steps. Done when the run is green and `vm-app01` shows as Connected under Azure Arc > Machines with the Arc-enabled SQL Server instance. If it doesn't finish, see the hint "Arc onboarding doesn't finish" below, and don't run the stage again. Then, from `factory/` in the dev container, download the test output the run kept:

   ```powershell
   ./scripts/Get-PipelineEvidence.ps1
   ```

   It saves `evidence/c00/test-datacenter.txt`, and creates `.local/<subscription-id>/datacenter.json` with the lab credentials that tasks later in the kit read (task 7, C7, C8, C9). Commit the evidence file as described under Evidence.
5. **Run the first Arc SQL migration assessment (about 15 min).** In the Azure portal on your own computer, search for **Azure Arc**. In its left menu choose **SQL Server instances** and select the instance on `vm-app01`. In the instance's left menu choose **Migration** > **Database migration**, then **Assess source instance** > **View report**. If there's no result yet, choose **Run assessment** with Azure SQL Managed Instance as the target and wait for it to finish. Export the report and skim the findings for `ContosoUniversity`. C3 is where you triage them. Done when you have the exported report or a screenshot of its findings.
6. **Confirm Azure Hybrid Benefit and what running the datacenter costs (about 5 min).** In your dev container, from `factory/`:

   ```powershell
   az vm list -g rg-datacenter -d -o table
   az vm show -g rg-datacenter -n vm-app01 --query licenseType -o tsv
   ```

   Done when the table lists both VMs running and the second command prints `Windows_Server` (Hybrid Benefit on), or prints nothing or `None` because you deployed with `no-hybrid-benefit` and your coach agreed. Otherwise don't change it yourself: tell your coach. The datacenter bills while it runs, and Bastion, the NAT gateway and the disks bill even when the VMs are stopped: see the hint "Save money between sessions".
7. **Set up `vm-dev01`, once (about 30 min).** From C3 you work on this VM, so set it up completely now; then C3 opens on a ready VM and you do nothing on it on event day except open VS Code. Both VMs must be running. Follow steps 1 to 9 of [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) in order: the password lookup, Bastion, the GitHub and Azure sign-ins, git identity, `AZURE_TOKEN_CREDENTIALS`, the kit clone, the `member` remote and `vm-dev01-work` branch, a plain clone of your own repo at `C:\src\<your-repo>`, VS Code on `C:\src\factory` with Copilot signed in, and the Upgrade agent in the **Local** harness. Done when every line of the guide's [Check your setup](../../guides/ghcp-upgrade/#check-your-setup) is true:

   - GitHub, Azure and git identity are set on the VM, and `AZURE_TOKEN_CREDENTIALS` is `AzureCliCredential`.
   - `C:\src\factory` has `origin` (the public kit) and `member` (your repo), and is on `vm-dev01-work` tracking `member/vm-dev01-work`.
   - `C:\src\<your-repo>` is a plain clone of your own repo on `main`.
   - VS Code is open on `C:\src\factory`, the agent picker lists **Upgrade**, the harness is **Local**, and Copilot Chat answers "hello".

   If Copilot is blocked by your organization's policy, tell your coach before the event. If a step fails, the guide says what to check; after two attempts, ask your coach.

## Evidence

Save your evidence in `factory/evidence/c00/` in your own repo (create the folder if it isn't there). To save a screenshot or a file from your laptop, drag it into that folder in VS Code's Explorer, in the dev container. The rule is the same everywhere:

- **Dev container:** evidence goes in `factory/evidence/` on `main`; run `git pull` first.
- **`vm-dev01`:** evidence goes in `C:\src\<your-repo>\factory\evidence\...` (the plain clone of your own repo) on `main`; run `git pull --rebase` first.

Commit with a conventional commit message such as `docs: C0 evidence`, and push. [C1](../c01-define-the-opportunity/#where-your-evidence-goes) later sets up the rest of the `factory/evidence/` folders around what you already saved. Redact subscription, tenant and object IDs from anything you commit.

- The `whatif` run summary or a screenshot of the green preflight run: every automated check green.
- `evidence/c00/test-datacenter.txt` from `Get-PipelineEvidence.ps1`, the test output from before Arc onboarding: every check PASS. An explained FAIL counts only if your coach has seen it and agrees.
- The Arc resource for `vm-app01`, with Azure Connected Machine agent connected, and the SQL Server extension showing the instance.
- The Arc migration assessment's first output (screenshot or exported report). You don't need to act on it yet.
- Your Azure Hybrid Benefit confirmation (task 6): on for `vm-app01`'s Windows Server license, or why it isn't (you deployed with `no-hybrid-benefit` and your coach agreed). Add a screenshot of `az vm list -g rg-datacenter -d -o table` showing both VMs and their power state.
- A screenshot of Copilot Chat answering in VS Code on `vm-dev01`, signed in to GitHub (task 7). Take it on the VM and save it in `C:\src\<your-repo>\factory\evidence\c00\`, then commit and push from there as in [Copy your evidence to your repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo).

## Hints

<details>
<summary>I'm stuck on preflight</summary>

Most preflight failures are missing resource provider registrations or a role assignment that hasn't propagated yet. The stage registers providers for you. Wait a few minutes (propagation can take up to 15 minutes), run the `whatif` stage again, and read the failing row in the run log.
</details>

<details>
<summary>Arc onboarding doesn't finish</summary>

Arc onboarding needs outbound internet from `vm-app01` to Arc's endpoints; the datacenter's NAT gateway (its shared outbound path) should already allow this. Don't run the `member` stage again if it timed out after Arc onboarding started: it refuses once `vm-app01` is an Arc machine or its guest agent is off, and it can't recover the machine either. To see what happened, read the run log, then connect to `vm-app01` through Bastion as in [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) (steps 1 and 2, `vm-app01` instead of `vm-dev01`, same password) and open `C:\LabTools\logs\Connect-AppArc.log` in Notepad.

If onboarding didn't finish, there are two ways out. Message your coach, who may have a faster fix. Or start over: run `gh workflow run platform.yml -f stage=teardown`, then the `member` stage again (tasks 2 to 4). Deleting the datacenter also deletes `vm-dev01`, so repeat task 7 afterward.

:::caution
After C5, the `teardown` stage also removes your archetype, including the SQL Managed Instance, which takes hours to provision again. Never run it after C5 without asking your coach first.
:::
</details>

<details>
<summary>Save money between sessions</summary>

Before the event you can stop both VMs when you're not working: `az vm deallocate -g rg-datacenter -n vm-app01`, then the same with `-n vm-dev01`. Deallocating releases the VM's compute and stops its compute billing. Shutting Windows down from inside the VM does not. Start both again before your platform lead vends you at T-1 (`az vm start -g rg-datacenter -n vm-app01`, then `-n vm-dev01`), because vending restarts them and the connectivity probes run inside them. Don't re-run the `member` stage after Arc. During the event, never stop `vm-dev01`: it's your workstation.
</details>

## If you need to start over

Run the `member` stage again to repair the datacenter after a failure before Arc: it converges to the same result. If your datacenter was already vended (at T-1 or later), the re-run resets its DNS servers and routes, so your platform lead must vend you again, and you restart both VMs. The `member` stage refuses once `vm-app01` is an Arc machine or its guest agent is off. If onboarding didn't finish, or you need to start over after Arc, run the `teardown` stage, then the `member` stage again (see the hint "Arc onboarding doesn't finish"). That removes `vm-app01`, `vm-dev01` and everything on them, so you repeat tasks 2 to 7. Ask your coach before you do either. After C5, `teardown` also removes the archetype: never run it then without asking your coach.

## Bonus

None for C0.

## Learn more

- [Connect hybrid machines to Azure using a deployment script](https://learn.microsoft.com/azure/azure-arc/servers/onboard-portal)
- [SQL Server registration with Azure Arc overview](https://learn.microsoft.com/sql/sql-server/azure-arc/overview)
- [Azure Hybrid Benefit for Windows Server](https://learn.microsoft.com/azure/virtual-machines/windows/hybrid-use-benefit-licensing)
