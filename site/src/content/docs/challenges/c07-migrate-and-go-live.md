---
title: "C7: Migrate and go live"
description: Seed the link, validate the replica, cut over, and bring the app up on App Service.
---

## Goal

Move the database to SQL Managed Instance with no data loss, then put the modernized app live on App Service against it.

## Scope and time box

Member. **120 min**.

## Points

**20 pts** (member).

## Inputs

C5's deployed SQL Managed Instance. C6's modernized, packaged app, not yet pointed at App Service.

## Your tasks

1. In the Arc portal, start the MI link migration against your SQL Managed Instance: seed, then wait for the replica to show as healthy.
2. Validate the read-only replica: row counts, and a few spot-check queries, against the source. If something looks wrong, abort and reseed — don't cut over on a replica you haven't checked.
3. At the go/no-go point, stop the application's writes to the source first (the source stays writable even after cutover, so this order matters). Cut over at lag 0, with **forced failover left unticked** — it isn't needed when there's no lag and no traffic, and ticking it risks data loss if lag isn't actually zero.
4. After cutover, write the Key Vault secret `ConnectionStrings--DefaultConnection` (Microsoft Entra authentication, no password) and create the contained database user for the web app's managed identity, with `db_datareader`, `db_datawriter` and `db_ddladmin`.
5. Point the web app at your C6 image and restart it. Confirm the five pages load, an upload lands in Blob, a notification round-trips, and telemetry reaches Application Insights.
6. Follow up on C3's trace-flag decision: remove `-T1800` and `-T9567` from the source now that the link is gone.
7. Write the cutover and rollback runbook from what you actually did, using the [template](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/cutover-rollback-runbook.md).

## Evidence

- The Arc portal's migration status: link created, seeded, replica validated, cutover complete, link removed.
- `https://app-university-<suffix>.azurewebsites.net/` loading, with the five pages showing the migrated data.
- The contained database user created, and the `CREATE USER` statement used (no `WITH SID`, no `TYPE = E` — SQL MI doesn't support them).
- The source's trace flags removed, and the cutover/rollback runbook committed.

## Evidence note: how the cutover actually ran

The kit's validated path cuts over through the Arc portal's **Monitor and cutover > Complete cutover** pane, not through a CLI command run from the managed instance's own side. If you try to script a planned failover yourself instead of using the portal, the applicable command runs **on SQL Server itself** (`ALTER AVAILABILITY GROUP [<DAG>] FAILOVER`, SQL Server 2022 CU13 or later) — `az sql mi link failover --failover-type Planned` run from the MI side fails, because the MI is the secondary at that point.

## Hints

<details>
<summary>The abort leaves something behind</summary>

An aborted link leaves a writable copy of the database on the MI. Delete it before starting a new seed, or the reseed fails.
</details>

<details>
<summary>`CREATE USER` fails</summary>

Before cutover, the replica is read-only — the user creation step only works after cutover completes. If it still fails afterward with a permissions error on the server's Entra identity, ask your coach: the MI's primary identity needs Microsoft Graph read access, set up once per team in C2.
</details>

<details>
<summary>The app won't start against App Service</summary>

Check the Key Vault secret exists and has the right name (`ConnectionStrings--DefaultConnection`, with the double dash), and that the database user was created with the identity's exact name.
</details>

## Lifeline

Ask your coach if the link won't seed, or cutover doesn't complete, after one retry. Your coach can advance you to the C7 end state if needed. Using it caps C7 at partial credit.

## Bonus

Up to 5 pts for a clean reseed-after-abort you can show evidence for (not needed if your first seed and validation go cleanly).

## Learn more

- [Managed instance link - overview and prerequisites](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-overview)
- [Migration guide for SQL Server to Azure SQL Managed Instance](https://learn.microsoft.com/azure/azure-sql/migration-guides/managed-instance/sql-server-to-managed-instance-guide)
