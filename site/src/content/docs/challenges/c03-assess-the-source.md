---
title: "C3: Assess the source"
description: Triage the GHCP and Arc migration assessments, finding by finding.
---

## Goal

Turn raw assessment output into a reviewed, human-authorized list of findings, each triaged as a blocker, an accepted risk, or something to fix.

## Scope and time box

Member. **60 min**. C3 starts at 10:15 on Day 1, while the platform lead vends in C2. If the Upgrade agent runs are slow, do the Arc review (task 2) while they run.

## Points

**15 pts** (member).

## Inputs

C0's first Arc migration assessment. C2's foundation doesn't need to be finished to start this challenge. Both datacenter VMs must be running. In your dev container (with `$s` loaded, as in C0), run `az vm start -g rg-datacenter -n vm-app01 --subscription $s.subscriptionId`, then the same with `-n vm-dev01`. If the platform lead vends your subscription while you work, `vm-dev01` loses DNS until you restart it (`az vm restart`), and your Bastion session drops.

## Where to run

- **Upgrade agent assessment and plan (task 1):** on `vm-dev01`, in VS Code opened on `C:\src\factory`, on your `vm-dev01-work` branch. Connect through Bastion and set up the branch as described in [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01) (steps 1 to 6). Don't use the dev container: the Local harness has to run next to the app. The exact setup and prompt are in Step 0 and Step 1 of the playbook, `C:\src\factory\.github\modernization\playbook.md` on the VM.
- **Arc assessment (task 2):** the Azure portal, in your browser.
- **Triage record (tasks 3 to 6):** the team repo, in `evidence/c03/member-<n>/`. Copy `assessment.md` there from the VM, as in [Copy your evidence to the team repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-the-team-repo), and write the triage table in the same folder (see [the team repo](../c01-define-the-opportunity/#the-team-repo-what-it-is-and-how-to-set-it-up)). If the team repo doesn't exist yet, keep your files in a local folder and copy them in once it does.

## Your tasks

1. Run the GitHub Copilot Upgrade agent against `app/ContosoUniversity` (harness **Local**, agent **Upgrade**, scenario `dotnet-version-upgrade`), by sending the whole of `.github/modernization/plan-prompt.txt` as the playbook's Step 1 says. Review the assessment at the assessment gate first. Then approve planning and check the plan gate (`plan.md` with seven tasks), and commit and push `app: assess and plan` as the playbook's Step 1 says. This is the plan approval for the whole run; don't start task execution: that's C6. Done when `assessment.md` and `plan.md` exist and `git status --short -- app` prints nothing.
2. Review the Arc SQL migration assessment from C0 against the source SQL Server: in the Azure portal, open the instance under `vm-app01` (Azure Arc > SQL Server instances), then **Migration** > **Database migration** > **Assess source instance** > **View report**. Run the assessment again if there's no result.
3. Triage every finding from both assessments: blocker, accepted risk, or fix, and what it means for the target state.
4. Work through the trace-flag finding by hand, not just by ticking it: the assessment reports **"Trace flags not supported in Azure SQL Managed Instance"** (warning) for flags `1800` and `9567`. The kit set these on the source on purpose. Find out why in the MI link preparation article under Learn more, then decide what to do about the finding, and record your reason, its impact on the target state, and when the flags should be removed.
5. Learn to tell this kind of self-inflicted, expected finding apart from one that would genuinely force the workload onto SQL Server on an Azure VM instead of SQL MI (for example, a feature SQL MI doesn't support at all, used by the application).
6. Write the triage table to `evidence/c03/member-<n>/triage.md`, with the columns finding, source, triage and impact. Deferrals from it go into the deferred-work register in C4.

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

Check the harness is **Local** (not the Copilot harness) and the agent picker shows **Upgrade**. If the tools report unavailable, reload the VS Code window and start a new chat. If **GitHub Copilot modernization** is enabled for the workspace, or the Upgrade server has no model access, follow Step 0 of the playbook.
</details>

## Bonus

Up to 5 pts for identifying any other finding in the Arc assessment report and writing its own triage, beyond the trace-flag one this challenge requires.

## Learn more

- [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation)
- [Azure SQL Managed Instance feature differences](https://learn.microsoft.com/azure/azure-sql/managed-instance/transact-sql-tsql-differences-sql-server)
