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

## Your tasks

1. Run `Start-Workload.ps1 -Server <your MI host> -Authentication ActiveDirectoryInteractive` to generate representative load (your identity, not the VM's managed identity — the VM has no MI data access).
2. Open Query Store (SSMS or the MSSQL extension) and find the worst queries by duration and execution count.
3. Diagnose and fix all five planted issues: a missing index, a non-sargable search predicate, an implicit `sql_variant` conversion, a scalar function forcing a serial plan, and the database compatibility level. Use Copilot in your tool of choice to help diagnose each plan, not just to write the fix.
4. Re-run the workload and capture Query Store's before/after numbers for each fix.
5. Follow [`coach/c9-db-optimization.md`](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/coach/c9-db-optimization.md) only if you get stuck — try the diagnosis yourself first.

## Evidence

- Before and after Query Store screenshots or exported reports for each of the five fixes.
- The five fix scripts you ran, committed.
- A one-line summary of what each fix changed and by how much.

## Hints

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
