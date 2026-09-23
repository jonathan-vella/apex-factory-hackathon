# B05: Build the DB perf kit

| Field | Value |
|---|---|
| Milestone | P1 Skeleton and datacenter |
| Type | Both |
| Depends on | B04 |
| Unblocks | B07 |
| Effort | 1 day |
| Cost | The datacenter from B04 keeps running: about $1.30/hour. Nothing new is deployed |
| Teardown | **Keep** `rg-datacenter` for B06 and B07 |
| PRD | §5 C9; §6 DB optimization |

## Outcome

- The `ContosoUniversity` database in every datacenter comes seeded with realistic volume (about 200,000 students and 2 million enrollments) and five planted performance issues. The datacenter deployment does this automatically.
- A workload generator on the dev VM produces steady load that makes the issues show up in Query Store, against the source SQL Server before migration and against SQL MI after it.
- A reset script puts the issues back, so C9 can run standalone or be re-run.
- `coach/c9-db-optimization.md` is the answer key, with before and after numbers measured in the workload subscription.

## Before you start

1. B04 is closed and `scripts/Test-Datacenter.ps1` passes against the workload subscription. If the VMs are deallocated, start them first.
2. `.local/settings.json` has `subscriptionId` and `memberIndex`.

## Requirements

### Volume

1. Seed data is generated in SQL Server with set-based T-SQL: no row-by-row loops, and no data files in the repo. It's deterministic: the same script gives the same rows every time.
2. Target volumes, on top of the app's own seed data:

   | Table | Rows |
   |---|---|
   | Students (`Person`, discriminator Student) | about 200,000 |
   | Instructors (`Person`, discriminator Instructor) | about 2,000 |
   | Departments | about 40 |
   | Courses | about 4,000 |
   | CourseAssignment | about 8,000 |
   | OfficeAssignment | one per instructor |
   | Enrollment | about 2,000,000, with realistic grade distribution and some null grades |

   Names and dates look plausible (for example, names combined from first-name and last-name lists), so the app's pages and search results look real.
3. The seeded database is a few GB and seeds in under 10 minutes on `vm-app01`.
4. The app still works against the seeded database: home, Students (with search and paging), Courses, Instructors and Departments pages all return 200 within 30 seconds each. Slow is expected; errors aren't.

### Planted issues

5. Exactly these five issues, each in database objects or settings, so they survive the app's modernization:

   | ID | Issue | Planted as |
   |---|---|---|
   | P1 | Missing index on a foreign key | No non-clustered index on `Enrollment.StudentID`, which student detail and statistics queries filter on |
   | P2 | Non-sargable search | Stored procedure `dbo.usp_SearchStudents` that searches first and last names with `LIKE '%' + @term + '%'` |
   | P3 | Implicit conversion | Stored procedure `dbo.usp_GetStudentEnrollments` whose parameter type doesn't match the column type, causing a conversion on the column and a scan |
   | P4 | Scalar UDF in a view | View `dbo.vw_EnrollmentStatistics` that calls a scalar function per row to compute a grade value, blocking parallelism |
   | P5 | Outdated compatibility level | Database compatibility level `110` (SQL Server 2012) instead of `160` |

6. Don't break the app: EF Core's own queries must keep working at compatibility level 110, and the app must not depend on the new objects.
7. Query Store is on for `ContosoUniversity` in read-write mode, capturing all queries, with settings suited to a 2-day event (short interval, enough storage). 🔎 VERIFY the options on [Monitor performance by using the Query Store](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store).
8. `P5` must survive MI link: 🔎 VERIFY on [MI link overview](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-feature-overview) that a database replicated by the link keeps its compatibility level. If it doesn't, stop and ask.

### Workload

9. `db/perf-kit/Start-Workload.ps1`, PowerShell 7 on `vm-dev01`, needing only the `SqlServer` module (install it for the current user if missing). Parameters: `Server` (default `10.10.n.4` from `MemberIndex`), `MemberIndex`, `Authentication` (`SqlPassword` for the source, using `contosoapp` and the password from the datacenter secrets file; `ActiveDirectoryDefault` for MI after cutover), `DurationMinutes` (default 15) and `Concurrency` (default 8).
10. The workload mixes calls to the three planted objects with the app-like queries (student search, student details with enrollments, instructor page with course assignments, enrollment statistics), with realistic random parameters. Every planted issue appears in the Query Store top resource consumers after one default run.
11. It prints a summary at the end: calls per query type, average and 95th percentile duration.

### Install and reset

12. SQL scripts live in `db/perf-kit/sql/`, numbered in run order, each idempotent: volume, planted objects, compatibility level, Query Store.
13. The datacenter deployment runs them on `vm-app01` after the app's warm-up (B04 requirement 11.9), through one more run command. Change B04's Bicep and in-VM scripts for this, keeping B04's requirements intact, and update `infra/datacenter/README.md`. If the total deploy time goes over 60 minutes, say so in the PR follow-ups.
14. `db/perf-kit/sql/` also has a reset script that removes any fixes (drops added indexes, restores the planted objects and compatibility level) and clears Query Store. `db/perf-kit/Reset-PerfKit.ps1` (PowerShell 7) runs it from the dev VM against the source or MI, with the same authentication options as the workload.
15. `scripts/Test-Datacenter.ps1` gets extra checks: enrollment and student counts within 5% of the targets, the three objects exist, compatibility level is 110 and Query Store is read-write.

### Answer key

16. `coach/c9-db-optimization.md` has, per issue: the symptom the attendee sees, how to find it with Query Store and the execution plan, a GitHub Copilot prompt that leads to it (MSSQL extension in VS Code or Copilot in SSMS), the fix, and the before and after numbers from the workload subscription.
17. It ends with the expected order of work for a 1-hour C9 and notes for coaches on partial credit.
18. `db/perf-kit/README.md` explains the kit to kit builders: what's planted, how it's installed, how to run the workload and reset, and a warning that `coach/` holds the answers.

### Validate for real

19. Redeploy into the existing datacenter with `scripts/Deploy-Datacenter.ps1 -ScriptsRef <this branch>`. The run converges on the existing VMs and installs the perf kit. Record how long the seeding took.
20. Run `scripts/Test-Datacenter.ps1`: every check passes.
21. On `vm-dev01`, run the workload for 15 minutes. Capture the Query Store top queries (duration and CPU) as the "before" numbers.
22. Apply the five fixes from the answer key, run the workload again, and capture the "after" numbers. Each issue shows a clear improvement. Put both tables in the answer key.
23. Run the reset script, and check with the Test-Datacenter checks that the issues are back.
24. Keep `rg-datacenter` running for B06.

## Deliverables

- `db/perf-kit/sql/*.sql`, `db/perf-kit/Start-Workload.ps1`, `db/perf-kit/Reset-PerfKit.ps1`, `db/perf-kit/README.md`.
- `coach/c9-db-optimization.md`.
- Changes to `infra/datacenter/` (Bicep, in-VM script, README) and `scripts/Test-Datacenter.ps1`.
- `versions.md` row for the `SqlServer` PowerShell module.

## Verify

```powershell
Invoke-ScriptAnalyzer -Path db/perf-kit, scripts -Recurse
az bicep lint --file infra/datacenter/main.bicep
$s = Get-Content .local/settings.json | ConvertFrom-Json
./scripts/Test-Datacenter.ps1 -SubscriptionId $s.subscriptionId -MemberIndex $s.memberIndex; $LASTEXITCODE
npm run check
```

- Static checks are clean, and Test-Datacenter passes after the reset.
- The PR body has the seeding time, the before and after tables and the cost so far.

## Done when

- [ ] A fresh or re-run datacenter deployment comes with the seeded database and the five planted issues.
- [ ] The workload makes all five issues visible in Query Store.
- [ ] Fixes give measurable improvements, and the reset puts the issues back.
- [ ] The answer key has real before and after numbers.
- [ ] `rg-datacenter` is still deployed, for B06.

## Commit message

```text
feat: add the DB perf kit
```

## Stop and ask if

- Seeding takes more than 20 minutes.
- An app page errors, or needs more than 30 seconds, on the seeded database.
- A planted issue doesn't show up in Query Store after one workload run.
- MI link doesn't keep the compatibility level.

## Notes and traps

- **EF Core schema:** the app creates the tables with `EnsureCreated()`, so read the actual table and column names and types from the database, not from assumptions. `Person` uses a discriminator column for Student and Instructor.
- **Identity columns:** insert seed rows so that the app's own seed data stays intact and new rows don't clash with it.
- **Log growth:** seeding millions of rows in one transaction bloats the log. Batch the inserts, and keep the recovery model at full: MI link needs full recovery and a full backup (B07).
- **Compatibility level 110** disables newer optimizer features, such as scalar UDF inlining and batch mode on rowstore, which makes P4 worse. That's intended: fixing P5 partly helps P4, and the answer key should say so.
- **MI is Entra-only** (PRD §6), so after cutover the workload can't use SQL authentication. That's why it supports `ActiveDirectoryDefault`.
- **Run commands** still work here because Arc onboarding comes later, in B07.
