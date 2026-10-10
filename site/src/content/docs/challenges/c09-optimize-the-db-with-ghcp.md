---
title: "C9: Optimize the DB with GHCP"
description: Find and fix five planted performance issues with Query Store evidence.
---

## Goal

Use GitHub Copilot to find and fix five planted performance issues on the migrated database, with Query Store numbers to prove the fixes worked.

## Scope and time box

Member. **60 min**.

## Points

**10 pts** (member).

## Inputs

C7's migrated database on SQL MI. The perf kit's planted issues and data (200k students, 2M enrollments) are already in it from the datacenter build. If your cutover isn't complete, work against the source database instead: see the first hint.

## Where to run

Everything runs on `vm-dev01`, through Bastion (see [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01)), in PowerShell 7 and SSMS on the VM, in your kit clone at `C:\src\factory`. Use your own identity, not the VM's managed identity: it has no data access. Sign in with the account that deployed the archetype in C5: it's the managed instance's Microsoft Entra admin, so it can change the database. The workload signs you in with a browser prompt. Never stop the VM during C9.

Set up once per PowerShell window:

```powershell
cd C:\src\factory
az login --use-device-code
az account show --query name --output tsv   # your workload subscription
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$mi = az sql mi list --resource-group $rg --query "[0].fullyQualifiedDomainName" --output tsv
$mi
```

`$mi` is your SQL Managed Instance's host name. If it's empty, copy it from the portal instead: the managed instance's **Overview** > **Host**. Use the standard host name, not an IP address or a `privatelink` name.

Clone the team repo on the VM once, as in [Copy your evidence to the team repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-the-team-repo), and create your folder `C:\src\team-repo\evidence\c09\member-<n>\`. You'll save the fix scripts and the numbers there as you go.

## How the hour works

Six separate re-runs don't fit in 60 minutes, so you measure at three points: a baseline and two checkpoints. Each run is 5 minutes. The planted issues hit different queries, so one run after a group of fixes still gives each fix its own before and after.

| Minutes | Step |
| --- | --- |
| 0–5 | Set up, then start the baseline run (task 1) |
| 5–12 | Read Query Store while the run finishes, then capture the baseline (tasks 2 and 4) |
| 12–30 | Diagnose and fix checkpoint 1 with Copilot (task 3) |
| 30–40 | Run, then capture checkpoint 1 |
| 40–45 | Fix checkpoint 2 |
| 45–55 | Run, then capture checkpoint 2 |
| 55–60 | Write the summary and push the evidence (task 5) |

Start each run at least five minutes after the previous one finished, so two runs never share a Query Store interval. If you're behind at minute 35, finish the fixes and do one more run for all of them: say in your summary which comparisons you couldn't separate.

## Your tasks

1. **Run the baseline.** Use the same duration and concurrency for every run in this challenge, so the numbers are comparable:

   ```powershell
   ./db/perf-kit/Start-Workload.ps1 -Server $mi -Authentication ActiveDirectoryInteractive -DurationMinutes 5 -Concurrency 8
   ```

   Sign in as yourself in the browser prompt. Note the `until HH:mm UTC` time it prints at the start (the run started 5 minutes earlier) and the `Finished at HH:mm UTC` line at the end. Before the fixes, one query can take a couple of minutes on SQL MI, so the run can finish a minute or two after its set time: use `Finished at` for your window. Don't run `Reset-PerfKit.ps1` at any point in C9: it clears Query Store and puts the problems back. Don't use the app, and don't run other queries on the tables, during a run, so the numbers are the workload's.
2. **Find the worst queries in Query Store.** Query Store flushes to disk every minute, so you can start looking while the baseline runs. In SSMS, connect to `$mi` (authentication **Microsoft Entra MFA**, your account), then in Object Explorer open **Databases > ContosoUniversity > Query Store > Top Resource Consuming Queries**. Use the **Configure** button to set the metric and the time range:
   - Metric **Duration (ms)**, statistic **Total**: the queries that cost the most time overall.
   - Metric **Execution Count**: the queries that run most often.
   - Time range: **Custom**, covering your run.

   Click a bar to see its plans in the lower pane and its query text. Make a short list of the worst offenders: query ID, what it does, and why you think it's slow. (**Query Store > Tracked Queries** shows one query over time.) Don't use **Force Plan**: it hides the problem rather than fixing it.
3. **Diagnose and fix all five planted issues.** They're numbered P1 to P5 in this order:
   - **P1:** a missing index.
   - **P2:** a non-sargable search predicate.
   - **P3:** an implicit `sql_variant` conversion.
   - **P4:** a scalar function forcing a serial plan.
   - **P5:** the database compatibility level.

   Use GitHub Copilot to diagnose each plan, not just to write the fix: in VS Code, which has the SQL Server extension, paste the query text and the plan's warnings or its XML into Copilot Chat (SSMS's own Copilot works too, if your SSMS has it). Apply the fixes in two checkpoints:
   - **Checkpoint 1:** P5, P1, P2 and P3.
   - **Checkpoint 2:** P4, last: raising the compatibility level can change how P4's view runs, so measuring P4 afterwards shows whether the rewrite still matters.

   Save each fix as its own script (`p1-<name>.sql` to `p5-<name>.sql`) in your `evidence\c09\member-<n>\` folder, and run it in SSMS against `ContosoUniversity`.
4. **Capture the numbers after each run.** The baseline run is task 1. After each fix checkpoint, repeat task 1's command, unchanged. After every run, wait a minute for Query Store to flush, then:
   - Capture the **Top Resource Consuming Queries** report as a screenshot, with the run's time range.
   - Open the snapshot script `C:\src\factory\db\perf-kit\Get-QueryStoreSnapshot.sql` in SSMS, connected to `ContosoUniversity`, and set `@Label` (`baseline`, `after-checkpoint-1`, `after-checkpoint-2`) and the UTC window `@FromUtc` and `@ToUtc`: from the five-minute mark at or before the run's start to the five-minute mark at or after `Finished at`. A run from 09:03 to 09:08 gets 09:00 to 09:10, written `'2026-10-14T09:00:00+00:00'`.
   - Run it. Its output gives, per query and plan, executions, average duration and CPU in milliseconds and average logical reads, weighted by execution count. Save each result grid (copy with headers into a CSV, or screenshot it) in your `evidence\c09\member-<n>\` folder, named with its label.
5. **Summarize and push.** Write one line per fix: what it changed, and how much the query's average duration (and reads) moved between the baseline and the checkpoint that contains it. Say so when a fix shows no change of its own, and why. Then commit and push the folder to the team repo (`git add`, `git commit`, `git pull --rebase`, `git push`, as in the guide).

## Evidence

- Query Store screenshots or exported reports for the baseline and both checkpoints, together covering the before and after of all five fixes.
- The snapshot script's output for the baseline and each checkpoint, labelled with its window.
- The five fix scripts you ran, committed to the team repo in `evidence/c09/member-<n>/`.
- A one-line summary of what each fix changed and by how much.

## Hints

<details>
<summary>My cutover isn't complete, or the managed instance is stopped</summary>

If C7 isn't finished, run C9 against the source SQL Server, which has the same planted issues. Run the workload with `./db/perf-kit/Start-Workload.ps1 -MemberIndex <n> -DurationMinutes 5 -Concurrency 8`, and connect SSMS to `10.10.<n>.4` with SQL authentication as `contosoapp`. The password is `sqlAppPassword` in the same `datacenter.json` file as the Bastion password (see C7).

The managed instance starts and stops on a schedule the facilitator sets (by default weekdays 07:30 to 18:30, W. Europe time). If it's stopped, tell your coach.
</details>

<details>
<summary>The snapshot script returns no rows</summary>

Check the second result: `intervals_in_window` must be above 0, and the third result shows which five-minute intervals in your window have executions. Your window must be in UTC and cover whole five-minute intervals around the run, and the run must have finished a minute or more ago so Query Store has flushed (or uncomment the `sp_query_store_flush_db` line and run it once). Also check the first result: `query_store_state` must be `READ_WRITE`.
</details>

<details>
<summary>I can't connect with my own identity</summary>

Sign in as the account that ran the archetype deployment in C5: it's the managed instance's Microsoft Entra admin. A different account, or the wrong subscription after `az login`, is the usual cause. Check with `az account show`.
</details>

<details>
<summary>The workload doesn't reproduce a slow plan</summary>

Check the compatibility level first: `SELECT name, compatibility_level FROM sys.databases;`. If it's already 160, scalar UDF inlining can mask P4, and P5 has nothing to fix: say so in your summary.
</details>

## Bonus

None for C9 — it's already a tight, well-scoped challenge.

## Learn more

- [Query Store overview](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store)
- [Scalar UDF inlining](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining)
