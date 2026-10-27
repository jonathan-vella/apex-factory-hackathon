---
title: Azure Arc and the MI link
description: Onboarding, assessment, source preparation, seeding, go/no-go and cutover.
sidebar:
  order: 3
---

This guide covers the mechanics of the Arc-based SQL Managed Instance link migration. [C7](../../challenges/c07-migrate-and-go-live/) is the what, the maintenance-window steps and the acceptance bar; [C3](../../challenges/c03-assess-the-source/) covers assessment triage.

The MI link is a database mirror from `vm-app01` to your SQL Managed Instance. It keeps a read-only copy in sync until you cut over, and then the managed instance becomes the live database.

## Onboarding

`vm-app01`'s SQL Server instance is onboarded to Azure Arc by the `member` stage during [C0](../../challenges/c00-ready-to-hack/), unattended, with no manual portal steps. This is the kit's only onboarding path. If it fails, don't run the stage again: follow the Arc onboarding hint in C0 and tell your coach.

## Assessment

Once onboarded, the Arc resource can run a migration assessment against the SQL Server instance. It reports readiness findings, including a trace-flag warning for `1800` and `9567`. Trace flags are SQL Server startup options, and the kit sets these two on purpose so the link works, so the warning is expected. [C3](../../challenges/c03-assess-the-source/) explains how to triage it.

## Preparing the source

Before you start the link, SQL Server on `vm-app01` needs a few things that the Arc wizard doesn't set up (see Microsoft Learn's [Prepare environment for a Managed Instance link migration](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-sql-mi-prepare-link)): a Windows Firewall rule for TCP 5022 from the managed instance's subnet, a database master key in `master`, the Azure root certificate authorities imported as issuers for `*.database.windows.net`, and the database in the full recovery model with a full backup. The datacenter deployment already turned on availability groups and the two trace flags.

The kit's `infra/datacenter/scripts/Prepare-MiLinkSource.ps1` does the rest. You run it yourself in [C7 task 1](../../challenges/c07-migrate-and-go-live/#your-tasks), in an Administrator Windows PowerShell in a Bastion session on `vm-app01`: VM run commands stop working once the VM is Arc-enabled, so it can't run remotely. It takes your managed instance's subnet, `10.20.<n>.128/26`, and is safe to run again.

## Seeding the link

In the Azure portal, open **Azure Arc** > **SQL Server instances**, select the instance on `vm-app01`, then **Migration** > **Database migration** > **Migrate data**, and choose **Migrate using real-time replication (online)**. That's the managed instance link: it seeds the database into your deployed SQL Managed Instance, then keeps it in sync as a real-time replica. (**Migrate using log shipping (online)** is a different method, the Log Replay Service, which the kit doesn't use.) Creating the link takes up to 10 minutes. Seeding then depends on database size; the perf kit's data (200k students, 2M enrollments, around 120 MB) seeds quickly. [C7 task 2](../../challenges/c07-migrate-and-go-live/#your-tasks) has every click.

## Validating the replica

The replica is read-only while the link is active. Compare the row counts, checksums and a few objects against the source before you trust it enough to cut over: [C7 task 3](../../challenges/c07-migrate-and-go-live/#your-tasks) has the queries and what must match. If something looks wrong, abort the link (**Monitor and cutover** > select the database > **Cancel migration**) and reseed rather than cutting over on an unverified replica. [C7's hint](../../challenges/c07-migrate-and-go-live/#hints) shows how to delete the copy the abort leaves behind.

## Go/no-go and cutover

Stop every writer to the source first: the source stays writable even after cutover completes, so sequencing matters. [C7 task 4](../../challenges/c07-migrate-and-go-live/#your-tasks) has the maintenance-window steps in order: stop the writers on `vm-dev01`, stop the site and pool on `vm-app01`, check for open sessions, and watch the lag.

Once there's no lag, open the **Monitor and cutover** pane in the Azure portal (**Database migration** > **Monitor migrations**). In the **Lag** column, two dashes mean no lag. Select the database, then **Cutover** (some portal builds label the button **Complete cutover**; it's the same action). The **Cutover** pane has two checkboxes: one to confirm you've stopped incoming traffic, and an optional forced failover. Leave forced failover clear when the lag is zero. It's meant for emergency cutovers where some data loss is accepted, which shouldn't be your case if you've waited for the lag to clear.

After cutover, the link is removed and the managed instance becomes the sole copy of the database.

### Why the cutover isn't scripted

Cut over through the portal's **Monitor and cutover** pane, not with a command, and don't run the commands below. `az sql mi link failover --failover-type Planned` run from the managed instance's side fails, because the managed instance is the secondary at that point. A planned failover you script yourself runs on SQL Server (`ALTER AVAILABILITY GROUP [<DAG>] FAILOVER`, SQL Server 2022 CU13 or later), where `<DAG>` is the distributed availability group's name. It skips the portal's checks, and the kit doesn't need it.

## After cutover

Create the database user for the web app's managed identity, `id-university-<suffix>`. It's a contained user, which lives in the database itself and needs no server login. Run it in SSMS on `vm-dev01`, connected to the managed instance with **Microsoft Entra MFA** as the account that deployed the archetype, on the `ContosoUniversity` database ([C7 task 5](../../challenges/c07-migrate-and-go-live/#your-tasks) has the steps): `CREATE USER [id-university-<suffix>] FROM EXTERNAL PROVIDER`, then add it to `db_datareader`, `db_datawriter` and `db_ddladmin`. Don't use `WITH SID` or `TYPE = E`, which SQL MI doesn't support. This only works once the replica is writable, which is after cutover, not before.

It also needs the Microsoft Graph read grant for `id-sqlmi-directory` that a Privileged Role Administrator made for your team at T-7 (checked in [C2](../../challenges/c02-secure-ai-ready-foundation/)). Without it, the statement fails with "Server identity does not have Azure Active Directory Readers permission": ask your coach to confirm the grant. The playbook's Step 5 has the full sequence, including the Key Vault secret.

Remove the `1800` and `9567` trace flags from the source now that the link no longer needs them ([C7 task 7](../../challenges/c07-migrate-and-go-live/#your-tasks)). This closes out the deferred item from C3's trace-flag finding.

## If the abort path is needed

Aborting a link leaves a writable copy of the database on the managed instance. Delete it before reseeding, or the next seed attempt fails. The command is in [C7's hint "The abort leaves something behind"](../../challenges/c07-migrate-and-go-live/#hints); it deletes only the copy on the managed instance, never the database on `vm-app01`.
