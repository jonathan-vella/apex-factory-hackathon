---
title: "C9: Optimize the DB with GitHub Copilot"
description: Find and fix five planted performance issues with Query Store evidence.
---

## Background

A migrated database can still be slow. The perf kit planted five performance issues in it. C9 is where you use GitHub Copilot to diagnose each plan and fix it, and prove with Query Store numbers that the fix worked.

**Business context.** Marcus's office puts the heaviest load on the database during enrollment weeks. He needs the slow searches fixed before the next one.

**Business outcome.** Reliable at enrollment peaks. The five slow queries are found, fixed and measured, so the team can say how much faster each one got.

**Objective.** Be able to find the worst queries in Query Store, fix the cause with Copilot's help, and show the before and after.

**Time and scope.** Day 2, **14:00**, **60 min**, **Member**.

## Challenge

**Starting point.** C7's migrated database on SQL MI. The perf kit's planted issues and data (200k students, 2M enrollments) are already in it from the datacenter build. If your cutover isn't complete, work against the source database instead: see the first hint.

**Fixed by the kit.** The five planted issues, numbered P1 to P5 in this order:

- **P1:** a missing index.
- **P2:** a non-sargable search predicate (one the engine can't answer with an index seek, because the column is wrapped or the pattern starts with `%`).
- **P3:** an implicit `sql_variant` conversion (the parameter's type forces SQL Server to convert every row's value before comparing).
- **P4:** a scalar function forcing a serial plan (a function called once per row that stops the query from running in parallel).
- **P5:** the database compatibility level.

**You decide.** How to fix each one, and what the before/after numbers show.

:::note[Where to work]

Everything runs on <span class="sl-badge note">vm-dev01 · Bastion</span> in your single clone (`C:\src\<your-repo>` on `main`):

- <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt;\factory (pwsh)</span> — Run `./db/perf-kit/Start-Workload.ps1` twice: once for `baseline` and once `after` applying all five fixes (Requirements 1 and 4).
- <span class="sl-badge note">vm-dev01 · SSMS</span> — Read **Query Store** reports, execute your five `.sql` fix scripts, and compare `baseline` vs `after` against `ContosoUniversity` on `$mi` (Requirements 2, 3 and 4). Sign in with the Microsoft Entra account you used for `azd` in C5.
- <span class="sl-badge note">vm-dev01 · VS Code (@mssql)</span> — Connect the **MSSQL extension** to `ContosoUniversity` on `$mi` and use `@mssql` in Copilot Chat (or [Diagnose a slow plan](../../prompts/vscode/08-diagnose-a-slow-plan/)) to diagnose P1–P5 (Requirement 3).
- <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt; (main)</span> — Save your five `.sql` fix scripts and Query Store comparison in `C:\src\<your-repo>\factory\evidence\c09\` on `main`. Never stop the VM during C9.

:::

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

<details>
<summary>Set up once per PowerShell window on vm-dev01</summary>

```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
cd C:\src\<your-repo>\factory
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId
$n = $s.memberIndex
$suffix = $s.suffix
$rg = "rg-university-$suffix"
$mi = az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query fullyQualifiedDomainName --output tsv
$mi
$ev = "C:\src\<your-repo>\factory\evidence\c09"
New-Item -ItemType Directory -Force $ev | Out-Null
```

</details>

### How the hour works

You run the 5-minute workload **twice**: once for `baseline` and once `after` applying all five fixes (`P1`–`P5`). Because the planted issues hit distinct queries, one `after` run cleanly measures the improvement across all five fixes without needing intermediate checkpoints.

| Minutes | Step |
| --- | --- |
| 0–8 | Set up, then run the 5-minute `baseline` workload (Requirement 1) |
| 8–15 | Inspect **Top Resource Consuming Queries** in Query Store and capture `baseline` (Requirements 2 and 4) |
| 15–45 | Diagnose and apply all five fixes (`p1-*.sql` to `p5-*.sql`) with Copilot (Requirement 3) |
| 45–55 | Run the 5-minute `after` workload and capture the `after` Query Store comparison (Requirement 4) |
| 55–60 | Commit the five `.sql` fix scripts and before/after comparison on `main` (Requirement 5) |

## Requirements

1. **Run the `baseline` workload.** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt;\factory (pwsh)</span> Use the same duration and concurrency for both runs (`baseline` and `after`) so the numbers are comparable:

   ```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
   ./db/perf-kit/Start-Workload.ps1 -Server $mi -Authentication ActiveDirectoryInteractive -DurationMinutes 5 -Concurrency 8
   ```

   Sign in as yourself in the browser prompt that opens on the VM and approve MFA. Note the `until HH:mm UTC` time it prints at the start and the `Finished at HH:mm UTC` line at the end. Don't run `Reset-PerfKit.ps1` at any point in C9 unless you need to start over from scratch.

2. **Find the worst queries in Query Store.** <span class="sl-badge note">vm-dev01 · SSMS</span> In SSMS, connect to `$mi` with **Microsoft Entra MFA** using the account you used for `azd`. Open **Databases > ContosoUniversity > Query Store > Top Resource Consuming Queries** and use **Configure** to inspect:
   - Metric **Duration (ms)**, statistic **Total** (or **Avg**), and **CPU Time (ms)**.
   - Metric **Execution Count**.
   - Time range: **Custom**, covering your `baseline` run in **UTC**.

   Select each top bar to inspect its execution plan and query text. Don't use **Force Plan**: it pins a plan rather than fixing the underlying issue.

3. **Diagnose and fix all five planted issues (`P1` to `P5`).** <span class="sl-badge note">vm-dev01 · VS Code (@mssql)</span> <span class="sl-badge note">vm-dev01 · SSMS</span> Use GitHub Copilot in **VS Code** to diagnose each plan and write the fix (`p1-<name>.sql` to `p5-<name>.sql` in `factory/evidence/c09/`):
   - Change each object in place (`ALTER` the same procedure, view or function, with the same name and parameter names), because the workload calls `dbo.usp_SearchStudents`, `dbo.usp_GetStudentEnrollments` and `dbo.vw_EnrollmentStatistics` by name.
   - Apply all five fixes against `ContosoUniversity` on `$mi` in SSMS.

4. **Run the `after` workload and compare `baseline` vs `after`.** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt;\factory (pwsh)</span> <span class="sl-badge note">vm-dev01 · SSMS</span> Wait at least 5 minutes after the `baseline` run finished so the two runs don't share a Query Store interval, then repeat the exact workload command:

   ```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
   ./db/perf-kit/Start-Workload.ps1 -Server $mi -Authentication ActiveDirectoryInteractive -DurationMinutes 5 -Concurrency 8
   ```

   Wait a minute for Query Store to flush, then capture your `baseline` vs `after` comparison from **Top Resource Consuming Queries** (or by running `factory/db/perf-kit/Get-QueryStoreSnapshot.sql` in SSMS for the `baseline` and `after` UTC windows).

5. **Commit your five `.sql` scripts and before/after summary on `main`.** <span class="sl-badge note">vm-dev01 · C:\src\\&lt;your-repo&gt; (pwsh)</span> Save your five `.sql` fix scripts (`p1-*.sql` through `p5-*.sql`) and a brief before/after comparison in `factory/evidence/c09/`, then commit and push on `main`:

   ```powershell title="vm-dev01 — C:\src\<your-repo> (pwsh)"
   cd C:\src\<your-repo>
   git pull --rebase
   git add factory/evidence/c09
   git commit -m "docs: C9 query tuning fixes and comparison"
   git push
   ```

## Success criteria

To complete this challenge, review with your coach in `factory/evidence/c09/` on `main`:

- [ ] All five `.sql` fix scripts (`p1-*.sql` to `p5-*.sql`) committed in `factory/evidence/c09/` on `main`.
- [ ] Query Store `baseline` vs `after` comparison showing the duration/CPU and logical-read improvements across the tuned queries.
- [ ] Outcome check: tell Marcus in one line which search improved the most and by how much, and record the headline CPU/duration improvement in your team's C10 handover table.

<details>
<summary>My cutover isn't complete, or the managed instance is stopped</summary>

If C7 is unfinished, the source has the same planted issues. Run the workload against the source with `-MemberIndex $n`:

```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
./db/perf-kit/Start-Workload.ps1 -MemberIndex $n -DurationMinutes 5 -Concurrency 8
```

Check MI state with `az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query state -o tsv`. If `Stopped`, select **Start** immediately and allow **about 20 minutes**.

</details>

<details>
<summary>The snapshot script returns no rows</summary>

Check the second result: `intervals_in_window` must be above 0, and the third result shows which five-minute intervals in your window have executions. Your window must be in UTC and cover whole five-minute intervals around the run, and the run must have finished a minute or more ago so Query Store has flushed (or remove the `--` in front of the `EXEC sys.sp_query_store_flush_db;` line and run it once).

</details>

<details>
<summary>If you need to start over</summary>

Only start over if an object or the data is broken (for example you dropped the view), because it deletes your baseline:

```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
./db/perf-kit/Reset-PerfKit.ps1 -Server $mi -Authentication ActiveDirectoryInteractive
```

**Warning:** the reset puts the five planted issues back, drops every index added since, and clears Query Store.

</details>

## References

- [Query Store overview](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store)
- [Scalar UDF inlining](https://learn.microsoft.com/sql/relational-databases/user-defined-functions/scalar-udf-inlining)
