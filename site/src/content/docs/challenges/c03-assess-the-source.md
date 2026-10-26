---
title: "C3: Assess the source"
description: Triage the GHCP and Arc migration assessments, finding by finding.
---

## Goal

Turn raw assessment output into a reviewed, human-authorized list of findings, each triaged as a blocker, an accepted risk, or something to fix.

## Scope and time box

Member. **60 min** (pacing). C3 starts at 10:15 on Day 1, while the team walks through the foundation in C2. If the Upgrade agent runs are slow, do the Arc review (task 2) while they run. Your VM is already set up (C0 task 7), so none of the 60 minutes goes on setup.

## Points

**15 pts** (member).

## Inputs

C0's first Arc migration assessment, and a ready `vm-dev01` from C0 task 7. C2's verification doesn't need to be finished to start this challenge. Both datacenter VMs must be running: in your dev container (with `$s` loaded, as in C0), `az vm list -g rg-datacenter -d -o table` shows their power state, and `az vm start -g rg-datacenter -n vm-app01 --subscription $s.subscriptionId`, then the same with `-n vm-dev01`, starts them if you stopped them.

Your subscription was vended at T-1, so `vm-dev01` already uses the hub's DNS. C2 tasks 6 and 7 (about 15 minutes) are yours to do at a clean point in C3, for example right after the `app: assess and plan` commit (see [C2](../c02-secure-ai-ready-foundation/)). **Restart `vm-dev01` only when no agent run is in progress:** a restart ends your Bastion session and the run in it.

Terms you meet here: the **harness** is where the Upgrade agent runs (**Local** means on `vm-dev01`); a **scenario** is the agent's workflow (`dotnet-version-upgrade`); a **gate** is a point where the agent stops so you can review before it continues (the playbook's Step 1 shows each one); the **dashboard** is the Upgrade view in VS Code, with an **Assessment** tab.

## Where to run

- **Upgrade agent assessment and plan (task 1):** on `vm-dev01`, in VS Code opened on `C:\src\factory`, on your `vm-dev01-work` branch. It's already set up (C0 task 7). If you're not connected, follow steps 1 and 2 of [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01), open PowerShell 7 and run `code C:\src\factory`. Don't use the dev container: the Local harness has to run next to the app. The prompt and the gates are in Step 1 of the playbook, `C:\src\factory\.github\modernization\playbook.md` on the VM.
- **Arc assessment (task 2):** the Azure portal, on your own computer (not in the VM).
- **Paste-ready prompts:** [Assess and plan](../../prompts/vscode/01-assess-and-plan/) for task 1 and [Triage assessment findings](../../prompts/vscode/07-triage-assessment-findings/) for tasks 3 to 6 (optional help; the tasks below are the requirement).
- **Triage record (tasks 3 to 6):** on the VM, in the plain clone of your own repo: `C:\src\<your-repo>\factory\evidence\c03\`. The rule: on `vm-dev01`, evidence goes in `C:\src\<your-repo>\factory\evidence\...` on `main`; run `git pull --rebase` first. Copy `assessment.md` and `plan.md` there as in [Copy your evidence to your repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo), write `triage.md` in the same folder, then commit and push. In your dev container, run `git pull` before the next evidence commit.

## Your tasks

1. **Assess and plan (about 25 min).** Run the GitHub Copilot Upgrade agent against `app/ContosoUniversity` (harness **Local**, agent **Upgrade**, scenario `dotnet-version-upgrade`), by sending the whole of `.github/modernization/plan-prompt.txt` as the playbook's Step 1 says. Review the assessment at the assessment gate first. Then approve planning and check the plan gate (`plan.md` with seven tasks), and commit and push `app: assess and plan` as the playbook's Step 1 says. This is the plan approval for the whole run; don't start task execution: that's C6. Done when `assessment.md` and `plan.md` exist and `git status --short -- app` prints nothing.
2. **Review the Arc assessment.** Review the Arc SQL migration assessment from C0 against the source SQL Server: in the Azure portal, search for **Azure Arc**, choose **SQL Server instances**, open the instance on `vm-app01`, then **Migration** > **Database migration** > **Assess source instance** > **View report**. Run the assessment again if there's no result. Done when you have both reports open side by side and a list of every finding in them.
3. **Triage every finding** from both assessments: blocker, accepted risk, or fix, and what it means for the target state. Done when every finding on your list has a triage and a one-line impact (you write them into the table in task 6).
4. **Work through the trace-flag finding by hand,** not just by ticking it. A trace flag is a SQL Server startup switch. The assessment reports **"Trace flags not supported in Azure SQL Managed Instance"** (warning) for flags `1800` and `9567`. The kit set these on the source on purpose. Find out why in the section **Enable startup trace flags** of the MI link preparation article under Learn more, then decide what to do about the finding. Record your reason, its impact on the target state, and when the flags should be removed (for example "keep until cutover, remove after, because the link needs them"). Done when your triage row for it holds the reason, the impact and the decision.
5. **Tell expected findings from real blockers.** A self-inflicted, expected finding (like the trace flags) has a known cause and a known removal step. A real blocker would force the workload onto SQL Server on an Azure VM instead of SQL MI, for example a feature SQL MI doesn't support at all that the application uses. Done when your triage table marks which findings are which, with a reason for each blocker.
6. **Write the triage table** to `C:\src\<your-repo>\factory\evidence\c03\triage.md`, with the columns finding, source, triage and impact, then commit and push it. Deferrals from it go into the deferred-work register in C4. Done when `triage.md` is on `main` in your own repo.

## Evidence

- The Upgrade agent's `assessment.md` and the dashboard's Assessment tab, reviewed, and the `plan.md` it produced. No task has started.
- A triage table (`triage.md`): finding, source, triage (blocker / accepted risk / fix), and target-state impact.
- The trace-flag finding specifically called out with its reason, impact and decision.
- Nothing in `app/` changed yet.

## Hints

<details>
<summary>How do I tell a self-inflicted finding from a real blocker?</summary>

Ask: does this finding describe something the kit deliberately set up on the source (like the trace flags), or does it describe application behavior that SQL MI genuinely can't support? The first kind has a known cause and a known removal step. The second kind needs a target-state decision in C4.
</details>

<details>
<summary>The Upgrade agent won't produce an assessment</summary>

Check the harness is **Local** (not the Copilot harness) and the agent picker shows **Upgrade**. If the tools report unavailable, reload the VS Code window and start a new chat. If **GitHub Copilot modernization** is enabled for the workspace, or the Upgrade server has no model access, follow step 9 of [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01).
</details>

## If you need to start over

Re-run either assessment: they only read the source, so there is no state to reset. To redo the Upgrade agent's assess and plan from scratch, remove its leftovers first with the `git clean` commands in the guide's [Check your setup](../../guides/ghcp-upgrade/#check-your-setup), then start a new chat. Correct `triage.md` in place rather than starting a new file.

## Bonus

Up to 5 pts for identifying any other finding in the Arc assessment report and writing its own triage, beyond the trace-flag one this challenge requires.

## Learn more

- [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation)
- [Azure SQL Managed Instance feature differences](https://learn.microsoft.com/azure/azure-sql/managed-instance/transact-sql-tsql-differences-sql-server)
