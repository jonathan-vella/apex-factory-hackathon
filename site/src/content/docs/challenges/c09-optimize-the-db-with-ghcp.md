---
title: "C9: Optimize the DB with GHCP"
description: Find and fix five planted performance issues with Query Store evidence.
---

## Goal

Use the MSSQL extension's or SSMS's Copilot to find and fix five planted performance issues on the migrated database, with Query Store numbers to prove the fix worked.

## Scope and time box

Member. **60 min**.

## Points

**10 pts** (member).

## Inputs

C7's app, live against SQL MI. The perf kit's planted workload and data (200k students, 2M enrollments) are already on the database from the datacenter build.

## Where to run

Everything runs on `vm-dev01`, through Bastion (see [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01)), in PowerShell 7 and SSMS on the VM, in your kit clone at `C:\src\factory`. Use your own identity (not the VM's managed identity: it has no data access), so the workload signs you in with a browser prompt. Never stop the VM during C9.

Set up once per PowerShell window:

```powershell
cd C:\src\factory
az login --use-device-code
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$mi = az sql mi list --resource-group $rg --query "[0].fullyQualifiedDomainName" --output tsv
$mi
```

`$mi` is your SQL Managed Instance's host name. If it's empty, copy it from the portal instead: the managed instance's **Overview** > **Host**. Use the standard host name, not an IP address or a `privatelink` name.

## Your tasks

1. **Generate load.** Use the same duration and concurrency for every run in this challenge, so the numbers are comparable. Five minutes keeps five fix-and-re-run cycles inside the time box. Note the start time in UTC, then start the run:

   ```powershell
   Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ss'
   ./db/perf-kit/Start-Workload.ps1 -Server $mi -Authentication ActiveDirectoryInteractive -DurationMinutes 5 -Concurrency 8
   ```

   Sign in as yourself in the browser prompt. Don't run `Reset-PerfKit.ps1` at any point in C9: it clears Query Store and puts the problems back. Don't use the app during a run, so the numbers are the workload's.
2. **Find the worst queries in Query Store.** Wait a minute after the run so Query Store flushes to disk. In SSMS, connect to `$mi` (authentication **Microsoft Entra MFA**, your account), then in Object Explorer open **Databases > ContosoUniversity > Query Store > Top Resource Consuming Queries**. Use the **Configure** button to set the metric and the time range:
   - Metric **Duration (ms)**, statistic **Total**: the queries that cost the most time overall.
   - Metric **Execution Count**: the queries that run most often.
   - Time range: **Custom**, covering your run.

   Click a bar to see its plans in the lower pane and its query text. Make a short list of the worst offenders: query ID, what it does, and why you think it's slow. (**Query Store > Tracked Queries** shows one query over time.) Don't use **Force Plan**: it hides the problem rather than fixing it.
3. **Diagnose and fix all five planted issues:** a missing index, a non-sargable search predicate, an implicit `sql_variant` conversion, a scalar function forcing a serial plan, and the database compatibility level. Use Copilot in your tool of choice to help diagnose each plan, not just to write the fix. Fix one issue, then do task 4, before you move to the next, so each fix has its own before and after.
4. **Capture before and after numbers for each fix.** Take the **baseline** (before any fix) and then one measurement after each fix, each time from a fresh run of task 1's command (same duration and concurrency). For each measurement, capture the **Top Resource Consuming Queries** report as a screenshot, and run the snapshot script `C:\src\factory\db\perf-kit\Get-QueryStoreSnapshot.sql` in SSMS against `ContosoUniversity`. Before each run, set its `@Label` (for example `baseline`, `after-P1`) and its UTC window: from the five-minute mark at or before the run's start (use the time task 1 printed) to the five-minute mark at or after its end. Its output gives, per query and plan, executions, average duration and CPU in milliseconds and average logical reads, weighted by execution count. Save each result grid (copy with headers into a CSV or screenshot it) with its label and window.
5. Follow [`coach/c9-db-optimization.md`](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/coach/c9-db-optimization.md) only if you get stuck — try the diagnosis yourself first.

## Evidence

- Before and after Query Store screenshots or exported reports for each of the five fixes.
- The snapshot script's output for the baseline and after each fix, labelled with its window.
- The five fix scripts you ran, committed.
- A one-line summary of what each fix changed and by how much.

## Hints

<details>
<summary>The snapshot script returns no rows</summary>

Check the second result: `intervals_in_window` must be above 0. Your window must be in UTC and cover whole five-minute intervals around the run, and the run must have finished a minute or more ago so Query Store has flushed (or uncomment the `sp_query_store_flush_db` line and run it once). Also check the first result: `query_store_state` must be `READ_WRITE`.
</details>

<details>
<summary>I can't connect with my own identity</summary>

Confirm you've been added as an Entra login on the MI (done during the archetype deployment and C7's cutover) and that you're signed in with `az login` as the identity you expect.
</details>

<details>
<summary>The workload doesn't reproduce a slow plan</summary>

Compatibility level matters here — if it's already at 160, scalar UDF inlining and batch mode can mask P3 and P4. Check the level first (P5) before chasing the others.
</details>

## Lifeline

Ask your coach if you can't diagnose a specific plan after genuinely trying. The coach key documents all five issues and fixes in full, with exact numbers — using it caps C9 at partial credit, so try first.

## Bonus

None for C9 — it's already a tight, well-scoped challenge.

## Learn more

- [Query Store overview](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store)
- [Scalar UDF inlining](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining)
