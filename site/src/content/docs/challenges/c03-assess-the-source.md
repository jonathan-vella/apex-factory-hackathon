---
title: "C3: Assess the source"
description: Triage the GitHub Copilot upgrade and Azure Arc migration assessments, finding by finding.
---

## Background

Assessment tools produce long lists. A migration only goes well if a person reads each finding and decides what it means. C3 is where you turn raw output from the Upgrade agent and from Azure Arc into a reviewed list: blocker, accepted risk, or fix.

**Business context.** Priya, the head of IT operations, has patched this VM by hand for years and has never had a list of what a move would break. C3 gives her that list before anyone changes code.

**Business outcome.** Safe, repeatable change. Risks are known before work starts. Every finding is triaged, and the one the kit set on purpose (the trace flags) has a removal decision.

**Objective.** Be able to triage migration assessment findings and tell an expected, self-inflicted finding from a real blocker.

**Time and points.** Day 1, **10:30**, **60 min** (pacing), **Member**, **15 pts** (member). If the Upgrade agent runs are slow, do the Arc review (requirement 2) while they run. Your VM is already set up ([set up `vm-dev01`](../../deploy/member-steps/#33-set-up-vm-dev01)), so none of the 60 minutes goes on setup.

## Challenge

**Starting point.** The first Arc migration assessment from [Step 3: Datacenter and workstation](../../deploy/member-steps/#32-run-the-first-arc-sql-assessment-and-check-hybrid-benefit), and a ready `vm-dev01` ([set up `vm-dev01`](../../deploy/member-steps/#33-set-up-vm-dev01)). Both datacenter VMs must be running: in your dev container (with `$s` loaded from `factory/.local/settings.json`), `az vm list -g rg-datacenter -d -o table` shows their power state, and `az vm start -g rg-datacenter -n vm-app01 --subscription $s.subscriptionId`, then the same with `-n vm-dev01`, starts them if you stopped them.

**Fixed by the kit.** Your subscription was vended at T-1, so `vm-dev01` already uses the hub's DNS. The kit set the trace flags `1800` and `9567` on the source on purpose.

**You decide.** How you triage each finding, and what the trace-flag finding means for the target state.

**Terms.** The **harness** is where the Upgrade agent runs (**Local** means on `vm-dev01`). A **scenario** is the agent's workflow (`dotnet-version-upgrade`). A **gate** is a point where the agent stops so you can review before it continues (the playbook's Step 1 shows each one). The **dashboard** is the Upgrade view in VS Code, with an **Assessment** tab.

**Validated baseline:** GitHub Copilot upgrade extension **1.1.612** on VS Code **1.139.0**, as recorded in `versions.md`. Documentation reviewed **2026-10-30**, not a new runtime test. If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`; review `assessment.md` and `assessment.json` for the assessment. The owner retests current versions before the dry run.

**Where to work.**

- **Upgrade agent assessment and plan (requirement 1):** on `vm-dev01`, in VS Code opened on `C:\src\factory`, on your `vm-dev01-work` branch. If you're not connected, follow steps 1 and 2 of [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01), open PowerShell 7 and run `code C:\src\factory`. Don't use the dev container: the Local harness has to run next to the app. The prompt and the gates are in Step 1 of the playbook, `C:\src\factory\.github\modernization\playbook.md` on the VM.
- **Arc assessment (requirement 2):** the Azure portal, on your own computer (not in the VM).
- **Triage record (requirements 3 to 6):** on the VM, in the plain clone of your own repo: `C:\src\<your-repo>\factory\evidence\c03\`. On `vm-dev01`, evidence goes in `C:\src\<your-repo>\factory\evidence\...` on `main`; run `git pull --rebase` first. Copy `assessment.md`, `assessment.json` and `plan.md` there as in [Copy your evidence to your repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo), write `triage.md` in the same folder, then commit and push. In your dev container, run `git pull` before the next evidence commit.
- **Paste-ready prompts (optional help):** [Assess and plan](../../prompts/vscode/01-assess-and-plan/) for requirement 1 and [Triage assessment findings](../../prompts/vscode/07-triage-assessment-findings/) for requirements 3 to 6.

## Requirements

1. **Assess and plan (about 25 min).** Run the GitHub Copilot Upgrade agent against `app/ContosoUniversity` (harness **Local**, agent **Upgrade**, scenario `dotnet-version-upgrade`), by sending the whole of `.github/modernization/plan-prompt.txt` as the playbook's Step 1 says. Review the assessment at the assessment gate first. Then approve planning and check the plan gate (`plan.md` with seven tasks), and commit and push `app: assess and plan` as the playbook's Step 1 says. This is the plan approval for the whole run; don't start task execution: that's C6. Done when `assessment.md` and `plan.md` exist and `git status --short -- app` prints nothing.

The kit clone at `C:\src\factory` on `vm-dev01-work` has no commit hook. Use the playbook's `app:` messages there; use conventional commit types for commits in your own repo.

2. **Review the Arc assessment.** In **Azure Arc** > **SQL Server instances**, open the instance on `vm-app01`, then **Migration** > **Assessments**. Select **Run assessment** if needed, open its readiness details and select **Azure SQL Managed Instance** as the target to review. This is the [current documented path](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-assessment); older portal versions use **Database migration** > **Assess source instance** > **View report**. Done when both reports are open side by side and you have listed every finding.

3. **Triage every finding** from both assessments: blocker, accepted risk, or fix, and what it means for the target state. Done when every finding on your list has a triage and a one-line impact (you write them into the table in requirement 6).

4. **Work through the trace-flag finding by hand,** not just by ticking it. A trace flag is a SQL Server startup switch. The assessment reports **"Trace flags not supported in Azure SQL Managed Instance"** (warning) for flags `1800` and `9567`. Find out why the kit set them in the section **Enable startup trace flags** of the MI link preparation article under References, then decide what to do about the finding. Record your reason, its impact on the target state, and when the flags should be removed. Use this format: "Decision: …; reason and source: …; target impact: …; removal condition: …". Done when your triage row for it holds the reason, the impact and the decision.

5. **Tell expected findings from real blockers.** A self-inflicted, expected finding (like the trace flags) has a known cause and a known removal step. A real blocker would force the workload onto SQL Server on an Azure VM instead of SQL MI, for example a feature SQL MI doesn't support at all that the application uses. Done when your triage table marks which findings are which, with a reason for each blocker.

6. **Write the triage table** to `C:\src\<your-repo>\factory\evidence\c03\triage.md`, with the columns finding, source, triage and impact, then commit and push it. Deferrals from it go into the deferred-work register in C4. Done when `triage.md` is on `main` in your own repo.

## Success criteria

To complete this challenge, show your coach in your own repo:

- [ ] The Upgrade agent's `assessment.md` and `assessment.json`, reviewed in the dashboard if available or directly as files, and its `plan.md`. No task has started.
- [ ] A triage table (`triage.md`): finding, source, triage (blocker / accepted risk / fix), and target-state impact.
- [ ] The trace-flag finding specifically called out with its reason, impact and decision.
- [ ] Nothing in `app/` changed yet.
- [ ] Outcome check (unscored guidance): your triage table lets Priya see in one place which findings block the move and which can wait.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

<details>
<summary>How do I tell a self-inflicted finding from a real blocker?</summary>

Ask: does this finding describe something the kit deliberately set up on the source (like the trace flags), or does it describe application behavior that SQL MI genuinely can't support? The first kind has a known cause and a known removal step. The second kind needs a target-state decision in C4.

</details>

<details>
<summary>The Upgrade agent won't produce an assessment</summary>

Check the harness is **Local** (not the Copilot harness) and the agent picker shows **Upgrade**. If the tools report unavailable, reload the VS Code window and start a new chat. If **GitHub Copilot modernization** is enabled for the workspace, or the Upgrade server has no model access, follow step 9 of [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01).

</details>

<details>
<summary>If you need to start over</summary>

Re-run either assessment: they only read the source, so there is no state to reset. To redo the Upgrade agent's assess and plan from scratch, remove its leftovers first with the `git clean` commands in the guide's [Check your setup](../../guides/ghcp-upgrade/#check-your-setup), then start a new chat. Correct `triage.md` in place rather than starting a new file.

</details>

**Bonus.** Up to 5 pts for taking another Arc assessment finding beyond the base triage classification: explain its cause, cite the source you checked, give your reasoning and target-state impact with the same rigor as the trace-flag row. Merely listing another finding already required by the base work is not bonus evidence.

## References

- [GitHub Copilot upgrade](https://learn.microsoft.com/dotnet/core/porting/github-copilot-upgrade/)
- [Assess migration readiness with SQL Server enabled by Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-assessment)

- [Azure Arc and the MI link guide](../../guides/arc-mi-link/#assessment)

- [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation)
- [Azure SQL Managed Instance feature differences](https://learn.microsoft.com/azure/azure-sql/managed-instance/transact-sql-tsql-differences-sql-server)

Next: [C4: Choose target states](../c04-choose-target-states/).
