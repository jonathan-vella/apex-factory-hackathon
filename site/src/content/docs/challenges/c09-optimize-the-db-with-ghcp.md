---
title: "C9: Optimize the DB with GHCP"
description: Find and fix five planted performance issues with Query Store evidence.
---

## Background

A migrated database can still be slow. The perf kit planted five performance issues in it. C9 is where you use GitHub Copilot to diagnose each plan and fix it, and prove with Query Store numbers that the fix worked.

**Business context.** Marcus's office puts the heaviest load on the database during enrollment weeks. He needs the slow searches fixed before the next one.

**Business outcome.** Reliable at enrollment peaks. The five slow queries are found, fixed and measured, so the team can say how much faster each one got.

**Objective.** Be able to find the worst queries in Query Store, fix the cause with Copilot's help, and show the before and after.

**Time and points.** Day 2, **14:00**, **60 min**, **Member**, **10 pts** (member).

## Challenge

**Starting point.** C7's migrated database on SQL MI. The perf kit's planted issues and data (200k students, 2M enrollments) are already in it from the datacenter build. If your cutover isn't complete, work against the source database instead: see the first hint.

**Fixed by the kit.** The five planted issues, numbered P1 to P5 in this order:

- **P1:** a missing index.
- **P2:** a non-sargable search predicate (one the engine can't answer with an index seek, because the column is wrapped or the pattern starts with `%`).
- **P3:** an implicit `sql_variant` conversion (the parameter's type forces SQL Server to convert every row's value before comparing).
- **P4:** a scalar function forcing a serial plan (a function called once per row that stops the query from running in parallel).
- **P5:** the database compatibility level.

**You decide.** How to fix each one, and what the numbers show.

**Where to work.** Everything runs on `vm-dev01`, through Bastion (see [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01)), in PowerShell 7 and SSMS on the VM. Run the scripts from the kit clone at `C:\src\factory`, but save C9 evidence only in your own repo's clone, `C:\src\<your-repo>\factory\evidence\c09\`, on `main` (run `git pull --rebase` there first). C9 evidence isn't collected from `vm-dev01-work`; that branch holds the kit's app work. Use your own identity: it's the one with access to the managed instance. Sign in with the account you used for `azd` in C5: it's the managed instance's Microsoft Entra admin, so it can change the database. Never stop the VM during C9.

**Query Store** is SQL Server's built-in record of every query's duration, reads and plans. You'll read it in SSMS, which shows it in reports.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

Use [Diagnose a slow plan](../../prompts/vscode/08-diagnose-a-slow-plan/) for a neutral, evidence-led Copilot prompt. It does not contain the fixes.

In VS Code, connect the **MSSQL extension** to **ContosoUniversity** on your managed instance using your Microsoft Entra identity. Start database-aware Copilot prompts with **`@mssql`** so they use that connection; verify the selected database before running any proposed SQL.

<details>
<summary>Set up once per PowerShell window</summary>

Replace `<your-repo>` and `<n>` (your member index; the dev container prints it with `$s.memberIndex`, from `factory/.local/settings.json`):

```powershell
cd C:\src\factory
az login --use-device-code
az account show --query name --output tsv   # your workload subscription; if it's wrong: az account set --subscription <name>
$n = <n>
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$suffix = $rg -replace '^rg-university-', ''
$mi = az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query fullyQualifiedDomainName --output tsv
$mi
$ev = 'C:\src\<your-repo>\factory\evidence\c09'
New-Item -ItemType Directory -Force $ev | Out-Null
```

`$mi` is your SQL Managed Instance's host name. If it's empty, copy it from the portal instead: the managed instance's **Overview** > **Host**. Use the standard host name, not an IP address or a `privatelink` name. `$ev` is your evidence folder: the fix scripts and the numbers go there as you go. Save it in your plain clone at `C:\src\<your-repo>` (set up as in [set up `vm-dev01`](../../deploy/member-steps/#33-set-up-vm-dev01)), and run `git pull --rebase` there first, as in [Copy your evidence to your repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo).

</details>

### How the hour works

Six separate re-runs don't fit in 60 minutes, so you measure at three points: a baseline and two checkpoints. Each run is 5 minutes. The planted issues hit different queries, so one run after a group of fixes still gives each fix its own before and after.

| Minutes | Step |
| --- | --- |
| 0–5 | Set up, then start the baseline run (requirement 1) |
| 5–12 | Read Query Store while the run finishes, then capture the baseline (requirements 2 and 4) |
| 12–30 | Diagnose and fix checkpoint 1 with Copilot (requirement 3) |
| 30–40 | Run, then capture checkpoint 1. While the run goes, diagnose P4 |
| 40–45 | Apply the P4 fix (checkpoint 2) |
| 45–55 | Run, then capture checkpoint 2 |
| 55–60 | Write the summary and push the evidence (requirement 5) |

Start each run at least five minutes after the previous one finished, so two runs never share a Query Store interval. If you're behind at minute 35, finish the fixes and do one more run for all of them: say in your summary which comparisons you couldn't separate.

## Requirements

1. **Run the baseline.** Use the same duration and concurrency for every run in this challenge, so the numbers are comparable:

   ```powershell
   ./db/perf-kit/Start-Workload.ps1 -Server $mi -Authentication ActiveDirectoryInteractive -DurationMinutes 5 -Concurrency 8
   ```

   Sign in as yourself in the browser prompt that opens on the VM: use the same account and approve MFA. Note the `until HH:mm UTC` time it prints at the start (the run started 5 minutes earlier) and the `Finished at HH:mm UTC` line at the end. Before the fixes, one query can take a couple of minutes on SQL MI, so the run can finish a minute or two after its set time: use `Finished at` for your window. Don't run `Reset-PerfKit.ps1` at any point in C9, unless you decide to start over (see the end of this page): it clears Query Store and puts the problems back. Don't use the app, and don't run other queries on the tables, during a run, so the numbers are the workload's.

2. **Find the worst queries in Query Store.** Query Store flushes to disk every minute, so you can start looking while the baseline runs. In SSMS, in the Connect dialog paste `$mi` (the host name you printed) into **Server name**, set **Authentication** to **Microsoft Entra MFA**, and select **Connect**, signing in with the account you used for `azd`. Then in Object Explorer open **Databases > ContosoUniversity > Query Store > Top Resource Consuming Queries**. Use the **Configure** button to set the metric and the time range:
   - Metric **Duration (ms)**, statistic **Total**: the queries that cost the most time overall.
   - Metric **Execution Count**: the queries that run most often.
   - Time range: **Custom**, covering your run, with the time zone set to **UTC**: the run prints UTC times, and the VM's clock may not be UTC.

   Click a bar to see its plans in the lower pane and its query text. Make a short list of the worst offenders: query ID, what it does, and why you think it's slow. (**Query Store > Tracked Queries** shows one query over time.) Don't use **Force Plan**: it pins the slow plan, which hides the problem rather than fixing it.

3. **Diagnose and fix all five planted issues** (P1 to P5 above). Use GitHub Copilot in **VS Code** to diagnose each plan, not just write the fix: paste the query text and plan warnings or XML into Copilot Chat. The kit's SSMS install has no **AI Assistance** workload; do not spend the time box looking for its Copilot button. In SSMS, right-click the plan > **Show Execution Plan XML**; warnings show as a yellow triangle. Apply the fixes in two checkpoints:
   - **Checkpoint 1:** P5, P1, P2 and P3.
   - **Checkpoint 2:** P4, last: raising the compatibility level can change how P4's view runs, so measuring P4 afterward shows whether the rewrite still matters.

   Change each object in place (`ALTER` the same procedure, view or function, with the same name and parameter names): the workload calls `dbo.usp_SearchStudents`, `dbo.usp_GetStudentEnrollments` and `dbo.vw_EnrollmentStatistics` by name, so a copy such as `usp_SearchStudents_v2` leaves the "after" run unchanged. Each fix is done when the same input returns the same rows as before, or when you state in your summary what changed in behavior (P2 can't keep `LIKE '%term%'` results identical if you change it to a prefix search). Save each fix as its own script (`p1-<name>.sql` to `p5-<name>.sql`) in `$ev`, and run it in SSMS against `ContosoUniversity`.

4. **Capture the numbers after each run.** The baseline run is requirement 1. After each fix checkpoint, repeat requirement 1's command, unchanged. After every run, wait a minute for Query Store to flush, then:
   - Capture the **Top Resource Consuming Queries** report as a screenshot, with the run's time range.
   - Open the snapshot script `C:\src\factory\db\perf-kit\Get-QueryStoreSnapshot.sql` in SSMS, connected to `ContosoUniversity`, and edit the three `DECLARE` lines at the top: `@Label` (`baseline`, `after-checkpoint-1`, `after-checkpoint-2`) and the UTC window `@FromUtc` and `@ToUtc`: from the five-minute mark at or before the run's start to the five-minute mark at or after `Finished at`. A run from 09:03 to 09:08 gets 09:00 to 09:10, written `'2026-10-14T09:00:00+00:00'`. Today's UTC date is `Get-Date -AsUTC -Format yyyy-MM-dd` in PowerShell.
   - Run it. It returns four result grids. Its last grid gives, per query and plan, executions, average duration and CPU in milliseconds and average logical reads, weighted by execution count. Save grid 1 (the label and window) and grid 4 (the per-query numbers): right-click the grid > **Save Results As...** > CSV, into `$ev`, named with its label. Grid 3 should show executions only in your run's intervals: if not, your window includes other activity.

5. **Summarize and push.** Write one line per fix: what it changed, and how much the query's average duration (and reads) moved between the baseline and the checkpoint that contains it. Say so when a fix shows no change of its own, and why. Then in `C:\src\<your-repo>`, run `git pull --rebase`, commit the folder with a conventional message (for example `docs: C9 query tuning evidence`) and push `main`, as in the guide.

## Success criteria

To complete this challenge, show your coach in `factory/evidence/c09/` of your own repo:

- [ ] Query Store screenshots or exported reports for the baseline and both checkpoints, together covering the before and after of all five fixes.
- [ ] The snapshot script's output (grids 1 and 4) for the baseline and each checkpoint, labeled with its window.
- [ ] The five fix scripts you ran, committed to your own repo.
- [ ] A one-line summary of what each fix changed and by how much.
- [ ] Outcome check (unscored guidance): tell Marcus in one line which search got fastest to answer and by how much, using your Query Store numbers.

<details>
<summary>My cutover isn't complete, or the managed instance is stopped</summary>

If C7 is unfinished, the source has the same planted issues. The workload already knows the documented default lab password, so for a standard deployment run:

```powershell
./db/perf-kit/Start-Workload.ps1 -MemberIndex $n -DurationMinutes 5 -Concurrency 8
```

Only a deployment with a custom `-SqlAppPassword` needs `-SqlPassword`: retrieve it privately from the dev container's `.local/<subscription-id>/datacenter.json`, then on the VM set `$pw = Read-Host -AsSecureString 'Custom contosoapp password'` and add `-SqlPassword $pw`. Never put it in evidence.

In SSMS, connect to `10.10.<n>.4` with **SQL Server Authentication** as `contosoapp`, and tick **Trust server certificate** in the Connect dialog: the source has a self-signed certificate. The managed instance doesn't need that.

Check MI state with `az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query state -o tsv`. If `Stopped`, select **Start** immediately and allow **about 20 minutes**; use the wait for plan review and non-database preparation. `Ready` means it runs. Ask your coach about the schedule (normally weekdays 07:30–18:30 W. Europe time after link removal).

</details>

<details>
<summary>The snapshot script returns no rows</summary>

Check the second result: `intervals_in_window` must be above 0, and the third result shows which five-minute intervals in your window have executions. Your window must be in UTC and cover whole five-minute intervals around the run, and the run must have finished a minute or more ago so Query Store has flushed (or remove the `--` in front of the `EXEC sys.sp_query_store_flush_db;` line and run it once). Also check the first result: `query_store_state` must be `READ_WRITE`.

</details>

<details>
<summary>I can't connect with my own identity</summary>

Sign in as the account you used for `azd` in C5: it's the managed instance's Microsoft Entra admin. A different account, or the wrong subscription after `az login`, is the usual cause. Check with `az account show`; if the name is wrong, run `az account set --subscription <name>`.

</details>

<details>
<summary>The workload doesn't reproduce a slow plan</summary>

Check the compatibility level first: `SELECT name, compatibility_level FROM sys.databases;`. If it's already 160, scalar UDF inlining can mask P4, and P5 has nothing to fix: say so in your summary.

</details>

<details>
<summary>If you need to start over</summary>

Only start over if an object or the data is broken (for example you dropped the view), because it deletes your baseline. Save your evidence in `$ev` first. Then, on `vm-dev01` in `C:\src\factory`, run the reset against the managed instance (for the standard source deployment use `-MemberIndex $n` instead; only a custom password needs the first hint's secure prompt and `-SqlPassword`):

```powershell
./db/perf-kit/Reset-PerfKit.ps1 -Server $mi -Authentication ActiveDirectoryInteractive
```

**Warning:** the reset puts the five planted issues back, drops every index added since, and clears Query Store, which deletes your baseline. Never run it between a baseline and its re-runs. It doesn't touch the data. While the MI link is running, the replica on the managed instance is read-only: reset the source instead, and the link replicates it.

Then run the baseline again (requirement 1) and repeat the checkpoints.

</details>

**Bonus.** No bonus for C9.

## References

- [Query Store overview](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store)
- [Scalar UDF inlining](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining)
