---
title: "C3: Assess the source"
description: Triage the GitHub Copilot upgrade and Azure Arc migration assessments, finding by finding.
---

## Background

Assessment tools produce long lists. A migration only goes well if a person reads each finding and decides what it means. C3 is where you turn raw output from the Upgrade agent and from Azure Arc into a reviewed list: blocker, accepted risk, or fix.

**Business context.** Priya, the head of IT operations, has patched this VM by hand for years and has never had a list of what a move would break. C3 gives her that list before anyone changes code.

**Business outcome.** Safe, repeatable change. Risks are known before work starts. Every finding is triaged, and the one the kit set on purpose (the trace flags) has a removal decision.

**Objective.** Be able to triage migration assessment findings and tell an expected, self-inflicted finding from a real blocker.

**Time and scope.** Day 1, **10:30**, **60 min** (pacing), **Member**. If the Upgrade agent runs are slow, do the Arc review (requirement 2) while they run. Your VM is already set up ([set up `vm-dev01`](../../deploy/member-steps/#33-set-up-vm-dev01)), so none of the 60 minutes goes on setup.

## Challenge

**Starting point.** The first Arc migration assessment from [Step 3: Datacenter and workstation](../../deploy/member-steps/#32-run-the-first-arc-sql-assessment-and-check-hybrid-benefit), and your single clone (`C:\src\<your-repo>` on `main`) on `vm-dev01`. Both datacenter VMs must be running (`az vm list -g rg-datacenter -d -o table`).

**Fixed by the kit.** Your subscription was vended at T-1, so `vm-dev01` already uses the hub's DNS. The kit set the trace flags `1800` and `9567` on the source on purpose.

**You decide.** How you triage each finding, and what the trace-flag finding means for the target state.

**Terms.** The **harness** is where the Upgrade agent runs (**Local** means on `vm-dev01`). A **scenario** is the agent's workflow (`dotnet-version-upgrade`). A **gate** is a point where the agent stops so you can review before it continues (the playbook's Step 1 shows each one). The **dashboard** is an optional visual view of the Upgrade session, not a required embedded VS Code tab. [Learn's dashboard reference](https://learn.microsoft.com/dotnet/core/porting/github-copilot-upgrade/dashboard) describes a side panel in the Copilot app and browser access in other clients. If it is unavailable in your VS Code session, review the files named below.

:::note[Where to work]

- <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt; (VS Code &amp; pwsh)</span> — **Upgrade agent assessment and plan (Requirement 1) and triage table (Requirements 3 to 6)** on `main` in `C:\src\<your-repo>`. Because `.github/upgrades/` sits in your single clone on `main`, `assessment.md` and `plan.md` stay in place alongside `factory/evidence/c03/triage.md` (pre-created by `Import-Kit.ps1`).
- <span class="sl-badge tip">Azure portal</span> — **Arc assessment (Requirement 2)** in your browser.
- **Paste-ready prompts (optional help):** [Assess and plan](../../prompts/vscode/01-assess-and-plan/) for Requirement 1 and [Triage assessment findings](../../prompts/vscode/07-triage-assessment-findings/) for Requirements 3 to 6.

:::

## Requirements

1. **Assess and plan (about 25 min).** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt; (VS Code)</span> Run the GitHub Copilot Upgrade agent against `app/ContosoUniversity` (harness **Local**, agent **Upgrade**, scenario `dotnet-version-upgrade`), by sending the whole of `.github/modernization/plan-prompt.txt` as the playbook's Step 1 says. Review the assessment at the assessment gate first. Then approve planning and check the plan gate (`plan.md` with seven tasks). Don't start task execution: that's C6. Done when `.github/upgrades/scenarios/dotnet-version-upgrade/assessment.md` and `plan.md` exist and `git status --short -- app` prints nothing.

2. **Review the Arc assessment.** <span class="sl-badge tip">Azure portal</span> In **Azure Arc** > **SQL Server instances**, open the instance on `vm-app01`, then **Migration** > **Assessments**. Select **Run assessment** if needed, open its readiness details and select **Azure SQL Managed Instance** as the target to review. This is the [current documented path](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-assessment); older portal versions use **Database migration** > **Assess source instance** > **View report**. Done when both reports are open side by side and you have listed every finding.

3. **Triage the findings in `factory/evidence/c03/triage.md`** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt;</span> from both assessments: classify each finding (`must-fix` / `defer` / `ignore` or blocker / accepted risk / fix) and state its impact on the target state.

4. **Verify the trace-flag finding.** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt;</span> The Arc assessment reports **"Trace flags not supported in Azure SQL Managed Instance"** (warning) for flags `1800` and `9567`. Check why the kit set them in **Enable startup trace flags** of the MI link preparation article under References, and confirm your `triage.md` row explains why they are needed during MI link seeding and when they are removed (after C7 cutover, with `Prepare-MiLinkSource.ps1 -RemoveTraceFlags`).

5. **Commit in place on `main`.** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt; (pwsh)</span> Commit `.github/upgrades/` and `factory/evidence/c03/triage.md` directly on `main` in `C:\src\<your-repo>` (no file copying between folders needed):

   ```powershell title="vm-dev01 — C:\src\<your-repo> (pwsh)"
   cd C:\src\<your-repo>
   git pull --rebase
   git add .github/upgrades factory/evidence/c03/triage.md
   git commit -m "docs: C3 assessment, plan and triage"
   git push
   ```

## Success criteria

To complete this challenge, check your work in `C:\src\<your-repo>` on `main`:

- [ ] `.github/upgrades/scenarios/dotnet-version-upgrade/assessment.md`, `assessment.json`, and `plan.md` committed in place on `main`, with no task started yet and nothing in `app/` changed.
- [ ] `factory/evidence/c03/triage.md` committed on `main`, covering the DB and app findings and calling out why trace flags `1800` and `9567` stay until C7 cutover completes.
- [ ] Outcome check: your triage table lets Priya see in one place which findings are handled in C6/C7 and which are deferred.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

<details>
<summary>How do I tell a self-inflicted finding from a real blocker?</summary>

Ask: does this finding describe something the kit deliberately set up on the source (like the trace flags), or does it describe application behavior that SQL MI genuinely can't support? The first kind has a known cause and a known removal step. The second kind needs a target-state decision in C4.

</details>

<details>
<summary>The Upgrade agent won't produce an assessment</summary>

Check the harness is **Local** (not the Copilot harness) and the agent picker shows **Upgrade**. If the tools report unavailable, reload the VS Code window and start a new chat. If **GitHub Copilot modernization** is enabled for the workspace, or the Upgrade server has no model access, follow step 8 of [Step 3.3](../../deploy/member-steps/#33-set-up-vm-dev01).

</details>

<details>
<summary>The Upgrade dashboard doesn't open</summary>

The validated baseline is GitHub Copilot upgrade extension **1.1.612** on VS Code **1.139.0**, as recorded in `versions.md`. Documentation reviewed **2026-10-31**, not a new runtime test; the owner retests current versions before the dry run. If no dashboard opens, ask Copilot to show `plan.md` and `tasks.md`; review `assessment.md` and `assessment.json` for the assessment.

</details>

<details>
<summary>If you need to start over</summary>

Re-run either assessment: they only read the source, so there is no state to reset. To redo the Upgrade agent's assess and plan from scratch, remove its leftovers first with `git clean -fdx -- app .github/upgrades`, then start a new chat. Correct `triage.md` in place rather than starting a new file.

</details>

## References

- [GitHub Copilot upgrade](https://learn.microsoft.com/dotnet/core/porting/github-copilot-upgrade/)
- [Assess migration readiness with SQL Server enabled by Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-assessment)

- [Azure Arc and the MI link guide](../../guides/arc-mi-link/#assessment)

- [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation)
- [Azure SQL Managed Instance feature differences](https://learn.microsoft.com/azure/azure-sql/managed-instance/transact-sql-tsql-differences-sql-server)

Next: [C4: Choose target states](../c04-choose-target-states/).
