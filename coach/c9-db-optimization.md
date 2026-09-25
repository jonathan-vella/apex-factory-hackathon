# C9 answer key: Optimize the DB with GHCP

> [!WARNING]
> Coach material. This page has the answers to C9. Attendees work it out with GitHub Copilot, Query Store and the execution plans.

The DB perf kit ([`db/perf-kit`](../db/perf-kit/README.md)) plants five issues in `ContosoUniversity`. They live in database objects and settings, so they're there on the source SQL Server and, after cutover, on SQL MI. Attendees run the workload, find the issues in Query Store, fix them with GitHub Copilot's help (the MSSQL extension in VS Code, or Copilot in SSMS 22), and show Query Store before and after.

The numbers on this page were measured in the workload subscription on 2026-09-25: `vm-app01` on `Standard_D8as_v6` with SQL Server 2022 Developer, and one default workload run (15 minutes, 8 connections) from `vm-dev01` before the fixes and one after. Expect other numbers on other sizes and on SQL MI, but the same order of magnitude and the same ranking.

## Set up

1. Put the issues back and clear Query Store: `./db/perf-kit/Reset-PerfKit.ps1 -MemberIndex <n>`. See the [perf kit README](../db/perf-kit/README.md#reset).
2. Run the workload: `./db/perf-kit/Start-Workload.ps1 -MemberIndex <n>`. On MI after cutover, add `-Server '<sql-mi-host-name>' -Authentication ActiveDirectoryDefault`.
3. In SSMS, open **ContosoUniversity > Query Store > Top Resource Consuming Queries**. Look at **Duration** and then **CPU Time**, with the **Total** statistic, over the last hour.

## Before

Query Store after the "before" run, top queries by total duration. Calls are over 15 minutes, and CPU rank is the query's place by total CPU time.

| Query | Issue | Calls | Avg duration (ms) | Total duration (s) | Avg CPU (ms) | CPU rank | Avg logical reads | Max DOP |
|---|---|---|---|---|---|---|---|---|
| `vw_EnrollmentStatistics` for one department | P4, P5 | 371 | 17,533 | 6,505 | 11,565 | 1 | 7,539 | 1 |
| `usp_SearchStudents` | P2 | 477 | 411 | 196 | 268 | 4 | 6,311 | 1 |
| App student search (count) | App's own `Contains` | 490 | 367 | 180 | 250 | 5 | 1,882 | 1 |
| `usp_GetStudentEnrollments` | P3, P1 | 462 | 270 | 125 | 483 | 2 | 7,637 | 2 |
| App student search (page) | App's own `Contains` | 490 | 172 | 84 | 302 | 3 | 1,979 | 2 |
| App student details | P1 | 655 | 81 | 53 | 131 | 6 | 7,635 | 2 |
| App instructor page | None | 307 | 168 | 52 | 111 | 8 | 1,956 | 1 |
| App enrollment statistics | P1 | 513 | 75 | 38 | 131 | 7 | 7,637 | 2 |

The workload's own summary for the same run, client side, so it includes the network and reading the rows:

| Query | Calls | Avg ms | P95 ms |
|---|---|---|---|
| P2 `dbo.usp_SearchStudents` | 477 | 413 | 720 |
| P3 `dbo.usp_GetStudentEnrollments` | 462 | 272 | 376 |
| P4 `dbo.vw_EnrollmentStatistics` | 371 | 17,536 | 25,931 |
| App: student search | 490 | 542 | 865 |
| App: student details | 655 | 83 | 116 |
| App: enrollment statistics | 513 | 77 | 108 |
| App: instructor page | 307 | 186 | 303 |

What the plans in Query Store showed for the "before" run:

| Query | Evidence in the plan |
|---|---|
| `vw_EnrollmentStatistics` | Serial plan, `NonParallelPlanReason="TSQLUserDefinedFunctionsNotParallelizable"`; scan of `Enrollment`; compiled at compatibility level 110 |
| `usp_GetStudentEnrollments` | `CONVERT_IMPLICIT(sql_variant, ...StudentID...)` on the column, and a scan of `Enrollment` |
| App student details and enrollment statistics | Scan of `Enrollment`, and a missing index suggestion on `Enrollment (StudentID)` |
| `usp_SearchStudents` | Scan of `Person`: the leading `%` rules out a seek |

## The issues

### P1: missing index on `Enrollment.StudentID`

- **Symptom:** a student's details page, and anything else per student, reads about 7,600 pages, the whole `Enrollment` table, to return about 10 rows. It gets slower as enrollments grow.
- **Find it:** the app's student details and enrollment statistics queries in Query Store. Their plans scan `PK_Enrollment` and carry a green **Missing Index** suggestion on `Enrollment (StudentID)`. `sys.dm_db_missing_index_details` says the same.
- **Copilot prompt:** "Here's the execution plan of the student details query in ContosoUniversity. Why does it scan the Enrollment table, and which index would fix it? Check the existing indexes on dbo.Enrollment first."
- **Fix:**

  ```sql
  CREATE INDEX IX_Enrollment_StudentID ON dbo.Enrollment (StudentID) INCLUDE (CourseID, Grade);
  ```

  A plain index on `StudentID` works too. `INCLUDE` saves the key lookups.
- **Note:** SQL Server doesn't index foreign key columns automatically. EF Core adds the index when it creates the table, and the kit drops it: a realistic "someone dropped it" story.

### P2: non-sargable search in `usp_SearchStudents`

- **Symptom:** the search procedure is one of the top queries by duration, and it's slow whatever the search term.
- **Find it:** `usp_SearchStudents` in Query Store. The plan scans `Person`: `LIKE '%' + @Term + '%'` has a leading wildcard, so no index can seek.
- **Copilot prompt:** "dbo.usp_SearchStudents is slow. Explain why LIKE '%' + @Term + '%' can't use an index, and rewrite it so it can, with the indexes it needs. Tell me what changes for the user."
- **Fix:** search on the start of the name, with an index per name column:

  ```sql
  CREATE INDEX IX_Person_LastName ON dbo.Person (LastName, FirstName) INCLUDE (Discriminator, EnrollmentDate);
  CREATE INDEX IX_Person_FirstName ON dbo.Person (FirstName, LastName) INCLUDE (Discriminator, EnrollmentDate);
  ```

  In the procedure, match each name with `LIKE @Term + N'%'` in two queries combined with `UNION`, so each can seek its own index, then page the result.
- **Note:** "starts with" isn't "contains": `mar` no longer finds `Omar`. That's a product decision, and a good attendee says so. A full-text index with a prefix term (`CONTAINS(..., '"mar*"')`) keeps word-prefix matching and is also a full answer. The app's own search (`Contains` in LINQ, `CHARINDEX` in SQL) has the same problem but lives in the app. The new indexes make its scan cheaper, but fixing it properly is a bonus, not part of P2.

### P3: implicit conversion in `usp_GetStudentEnrollments`

- **Symptom:** a procedure that returns about 10 rows reads the whole `Enrollment` table, and ranks second by CPU.
- **Find it:** `usp_GetStudentEnrollments` in Query Store. The plan has a warning on the `SELECT` operator, **Type conversion in expression may affect "SeekPlan"**, and `CONVERT_IMPLICIT(sql_variant, ...)` around `StudentID` in the scan's predicate. The parameter is `sql_variant`, which wins data type precedence, so SQL Server converts the column on every row instead of the parameter once.
- **Copilot prompt:** "Look at dbo.usp_GetStudentEnrollments and its execution plan. Why is there a CONVERT_IMPLICIT on StudentID, and how do I fix it without changing its results?"
- **Fix:** make the parameter match the column, `int`:

  ```sql
  ALTER PROCEDURE dbo.usp_GetStudentEnrollments @StudentID int AS ...
  ```

- **Note:** the P1 index alone doesn't fix P3. With the conversion on the column, SQL Server scans the new index instead of seeking it. Attendees who fix P1 first and see P3 barely move have found the lesson.

### P4: scalar UDF in `vw_EnrollmentStatistics`

- **Symptom:** the statistics view is by far the slowest query: about 17.5 seconds per department, mostly on CPU. It dominates Query Store's totals.
- **Find it:** the view's query in Query Store. The plan is serial, with `NonParallelPlanReason="TSQLUserDefinedFunctionsNotParallelizable"` in its properties, and a Compute Scalar that calls `dbo.ufn_GradePoint` once for every enrollment row.
- **Copilot prompt:** "dbo.vw_EnrollmentStatistics is slow and its plan is serial. What does dbo.ufn_GradePoint cost per row, and how do I rewrite the view without it, keeping the same results?"
- **Fix:** inline the function's logic in the view:

  ```sql
  AVG(CAST(CASE e.Grade WHEN 0 THEN 4.0 WHEN 1 THEN 3.0 WHEN 2 THEN 2.0 WHEN 3 THEN 1.0 WHEN 4 THEN 0.0 END AS decimal(3, 2))) AS AverageGradePoint
  ```

  An inline table-valued function also works. Keep `ufn_GradePoint` if other code uses it.
- **Note:** P5 partly fixes P4. From compatibility level 150, SQL Server inlines scalar UDFs that qualify (`sys.sql_modules.is_inlineable` is `1` for this one), so raising the level alone makes the view much faster (see P5). Rewriting the view is still the right fix: it doesn't depend on the level, or on the function staying inlineable.

### P5: compatibility level 110

- **Symptom:** nothing on its own: it's a setting. Attendees find it in the database properties, in `sys.databases`, in the `compatibility_level` column of `sys.query_store_plan`, or when Copilot asks.
- **Find it:** `SELECT name, compatibility_level FROM sys.databases;` gives `110` (SQL Server 2012) on SQL Server 2022, whose default is `160`. At 110 the optimizer uses the legacy cardinality estimator and turns off scalar UDF inlining, batch mode on rowstore and the other Intelligent Query Processing features.
- **Copilot prompt:** "What's the compatibility level of ContosoUniversity, what does it turn off on SQL Server 2022, and how do I raise it safely with Query Store?"
- **Fix:**

  ```sql
  ALTER DATABASE ContosoUniversity SET COMPATIBILITY_LEVEL = 160;
  ```

  The safe way, which is what to look for: Query Store on first, capture a baseline, raise the level, compare, and force the old plan for any query that regresses.
- **Measured on its own**, with P4 still unfixed: the view for one department averaged 8,706 ms over 20 departments at level 110, and 98 ms at level 160, because the scalar UDF is inlined.
- **Note:** MI link keeps the compatibility level, so the database arrives on SQL MI at 110 and the fix applies there too. Microsoft's migration guide recommends raising it after the migration.

## After

The five fixes applied, Query Store cleared, then one more default workload run. The fixes made the database fast enough that the same 8 connections made 67,079 calls instead of 3,275, so compare averages, not totals. Top queries by total duration:

| Query | Issue | Calls | Avg duration (ms) | Total duration (s) | Avg CPU (ms) | CPU rank | Avg logical reads | Max DOP |
|---|---|---|---|---|---|---|---|---|
| App student search (count) | App's own `Contains` | 10,100 | 303 | 3,058 | 239 | 1 | 1,581 | 1 |
| `vw_EnrollmentStatistics` for one department | P4, P5 | 6,670 | 198 | 1,321 | 156 | 2 | 5,492 | 1 |
| App student search (page) | App's own `Contains` | 10,100 | 119 | 1,197 | 93 | 3 | 458 | 1 |
| App instructor page | None | 6,532 | 147 | 960 | 116 | 4 | 1,956 | 1 |
| `usp_SearchStudents` | P2 | 10,082 | 40 | 399 | 31 | 5 | 5,280 | 1 |
| `usp_GetStudentEnrollments` | P3, P1 | 10,262 | 0.1 | 1.2 | 0.1 | 6 | 23 | 1 |
| App student details | P1 | 13,439 | 0.1 | 1.1 | 0.1 | 7 | 25 | 1 |
| App enrollment statistics | P1 | 9,994 | 0.1 | 0.8 | 0.1 | 8 | 23 | 1 |

The workload's own summary:

| Query | Calls | Avg ms | P95 ms |
|---|---|---|---|
| P2 `dbo.usp_SearchStudents` | 10,082 | 41 | 78 |
| P3 `dbo.usp_GetStudentEnrollments` | 10,262 | 1.4 | 4.2 |
| P4 `dbo.vw_EnrollmentStatistics` | 6,670 | 200 | 354 |
| App: student search | 10,100 | 423 | 909 |
| App: student details | 13,439 | 1.4 | 4.2 |
| App: enrollment statistics | 9,994 | 1.4 | 4.2 |
| App: instructor page | 6,532 | 174 | 284 |

Before and after, per issue (average Query Store duration per call):

| Issue | Query | Before (ms) | After (ms) | Improvement |
|---|---|---|---|---|
| P1 | App student details | 81 | 0.1 | Reads 7,635 → 25 pages per call |
| P1 | App enrollment statistics | 75 | 0.1 | Reads 7,637 → 23 pages per call |
| P2 | `usp_SearchStudents` | 411 | 40 | About 10× |
| P3 | `usp_GetStudentEnrollments` | 270 | 0.1 | Reads 7,637 → 23 pages per call |
| P4 | `vw_EnrollmentStatistics` | 17,533 | 198 | About 90× |
| P5 | `vw_EnrollmentStatistics`, P4 unfixed, measured on its own | 8,706 | 98 | About 90×, from scalar UDF inlining |

After the fixes, the top of Query Store is the app's own search, which C9 doesn't cover: a good point to close on, because the next fix is in the app, not the database.

## A 1-hour C9

Expected order of work:

| Time | Step |
|---|---|
| 0–10 min | Reset if needed, start the workload, and open Query Store while it runs. Record the "before" top queries, as a screenshot or an export |
| 10–15 min | P5: find the compatibility level and plan the change. Raising it at the end, after the baseline, is the right order |
| 15–30 min | P4: the top query. Read the plan, find the scalar UDF, rewrite the view |
| 30–40 min | P1 and P3: the missing index and the conversion. P3 needs its own fix even after the P1 index |
| 40–45 min | P2: the search. Discuss "starts with" against "contains" |
| 45–60 min | Raise the compatibility level, run the workload again and show Query Store before and after |

## Partial credit

- Score what's proven in Query Store, not what's claimed: every fix needs a before and after for the query it targets.
- A fix that changes results without saying so, such as P2's "starts with", gets partial credit. Full credit needs the trade-off stated.
- P4 fixed only by raising the compatibility level gets partial credit for P4 and full credit for P5. Full P4 credit needs the view rewritten, or a clear explanation of why inlining is enough.
- P3 "fixed" by the P1 index alone isn't fixed: the plan still converts the column.
- Every AI change is reviewed and tested before it's applied, for the "trust but verify" badge. A fix pasted from Copilot without looking at the plan doesn't count.
- Running the reset and the workload again to prove the fixes, on the source or on SQL MI after cutover, is worth a bonus.

## Reset

`./db/perf-kit/Reset-PerfKit.ps1 -MemberIndex <n>` puts all five issues back and clears Query Store. On MI after cutover, add `-Server '<sql-mi-host-name>' -Authentication ActiveDirectoryDefault`.
