# DB perf kit

The DB perf kit gives the `ContosoUniversity` database realistic volume and five planted performance issues, for C9 (Optimize the DB with GHCP). The datacenter deployment installs it on `vm-app01`, and a workload generator on `vm-dev01` makes the issues show up in Query Store, against the source SQL Server before migration and against SQL MI after it.

> [!WARNING]
> The answers, with the fixes and the before and after numbers, are in [`coach/c9-db-optimization.md`](../../coach/c9-db-optimization.md). Coach material is public, on the honor system: attendees shouldn't read it.

## What's planted

The issues live in database objects and settings, not in the app, so they survive the app's modernization and the migration. The app doesn't use the planted objects, and its own EF Core queries work at compatibility level 110.

| ID | Issue | Planted as |
|---|---|---|
| P1 | Missing index on a foreign key | No non-clustered index on `Enrollment.StudentID`, which student detail and statistics queries filter on. `EnsureCreated()` adds `IX_Enrollment_StudentID`, so the kit drops it |
| P2 | Non-sargable search | `dbo.usp_SearchStudents` searches first and last names with `LIKE '%' + @Term + '%'` |
| P3 | Implicit conversion | `dbo.usp_GetStudentEnrollments` takes `@StudentID` as `sql_variant`, so the `int` column is converted and scanned, even with an index |
| P4 | Scalar UDF in a view | `dbo.vw_EnrollmentStatistics` calls the scalar function `dbo.ufn_GradePoint` once per row, which forces a serial plan |
| P5 | Outdated compatibility level | Compatibility level `110` (SQL Server 2012) instead of `160`. MI link keeps it, so it survives the migration |

Query Store is on, read-write, capturing every query, with 5-minute intervals, a 1-minute flush, 2 GB of storage and a 14-day stale query threshold.

## Volume

On top of the app's own seed data, which stays intact:

| Table | Rows | IDs |
|---|---|---|
| `Person`, students | 200,000 | 100001–300000 |
| `Person`, instructors | 2,000 | 10001–12000 |
| `Department` | 40 | 101–140 |
| `Course` | 4,000 | 5001–9000 |
| `CourseAssignment` | 8,000 | Two instructors per course |
| `OfficeAssignment` | 2,000 | One per new instructor |
| `Enrollment` | 2,000,000 | 8–12 per student. Grades A 20%, B 30%, C 25%, D 12%, F 6%, none yet 7% |

Names come from lists of common first and last names, and dates are plausible intakes and hire dates. The data is generated in SQL Server with set-based T-SQL and is deterministic: the same script gives the same rows every time. New rows the app creates get IDs above the seed.

## How it's installed

The scripts in [`sql/`](sql/) run in order. Each is idempotent.

| Script | What it does |
|---|---|
| `01-volume.sql` | The volume above. Skips rows that exist, so a re-run finishes a partial seed. Inserts enrollments in batches and keeps the recovery model at full, which MI link needs |
| `02-planted-objects.sql` | P1–P4: drops `IX_Enrollment_StudentID` and creates the planted objects, dropping them first, so it also puts back a fixed version |
| `03-compatibility-level.sql` | P5: compatibility level 110 |
| `04-query-store.sql` | The Query Store settings |
| `90-reset.sql` | Not part of the install: the last step of the reset (see below) |

The datacenter deployment runs `01`–`04` on `vm-app01` through the `app-06-perf-kit` run command (`infra/datacenter/scripts/Install-AppPerfKit.ps1`), after the app's warm-up has created and seeded the database. It downloads the scripts from `db/perf-kit/sql` at the deployment's `-ScriptsRef`, and logs to `C:\LabTools\logs\Install-AppPerfKit.log`, with the time each script took. `scripts/Test-Datacenter.ps1` checks the result: student and enrollment counts within 5% of the targets, the three planted objects, compatibility level 110 and Query Store read-write.

## Run the workload

On `vm-dev01`, from a clone of the repo, in PowerShell 7:

```powershell
./db/perf-kit/Start-Workload.ps1 -MemberIndex <n>
```

After cutover, against SQL MI, which is Entra-only:

```powershell
./db/perf-kit/Start-Workload.ps1 -Server '<sql-mi-host-name>' -Authentication ActiveDirectoryDefault
```

| Parameter | Default | Notes |
|---|---|---|
| `Server` | `10.10.n.4` | The source SQL Server, from `MemberIndex`. After cutover, the SQL MI host name |
| `MemberIndex` | `1` | 1–20 |
| `Authentication` | `SqlPassword` | `SqlPassword` connects as `contosoapp`, with the password from `$HOME/.apex-factory/<subscription-id>/datacenter.json` if it's on the machine, or the documented lab password. `ActiveDirectoryDefault` uses the signed-in Entra identity (`az login`, or Visual Studio Code), for SQL MI |
| `DurationMinutes` | `15` | |
| `Concurrency` | `8` | Connections running queries at the same time |

It needs only the `SqlServer` module, and installs it for the current user if it's missing. For the whole run, each connection calls a weighted random mix of the three planted objects and app-like queries shaped like the app's EF Core queries: student search, student details with enrollments, a student's enrollment statistics, and the instructor page with course assignments. Students, departments and search terms are random, read from the database. At the end it prints the calls, errors, and average and 95th percentile duration per query type. One default run makes every planted issue show up in Query Store's **Top Resource Consuming Queries**.

## Reset

To re-run C9, or run it standalone, put the issues back:

```powershell
./db/perf-kit/Reset-PerfKit.ps1 -MemberIndex <n>
./db/perf-kit/Reset-PerfKit.ps1 -Server '<sql-mi-host-name>' -Authentication ActiveDirectoryDefault
```

It takes the same `Server`, `MemberIndex` and `Authentication` parameters as the workload, and runs `02`, `03`, `04` and then `90-reset.sql`, which drops every index added to the app's tables since `EnsureCreated()`, whatever its name, and clears Query Store. It doesn't touch the data. The login needs `db_owner`: `contosoapp` on the source, the MI Entra admin on MI. While MI link is running, the replica on MI is read-only: reset the source instead, and the link replicates it.

## Traps

- **Compatibility level 110** also turns off scalar UDF inlining and batch mode on rowstore, so it makes P4 worse. That's intended: fixing P5 partly helps P4.
- **Run commands stop working after Arc onboarding** (B07), so the deployment's install and `Test-Datacenter.ps1`'s in-VM checks have to happen before it. The workload and the reset don't use run commands.
- **The data is small.** 200,000 students and 2 million enrollments fit in a few hundred MB. The issues come from plan shapes, not size, and a small database seeds MI link quickly.
