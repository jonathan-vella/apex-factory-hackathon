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

## Where to run

| Tasks | Where |
| --- | --- |
| 1, 2 (link, replica check) | The Azure portal (Azure Arc > SQL Server instances), in your browser. Run the replica spot-check queries in SSMS on `vm-dev01`. |
| 3 (stop the writers) | `vm-app01` (the legacy IIS and SQL Server VM), through Bastion. Plus a check on `vm-dev01`. |
| 4, 5 (user, secret, App Service) | `vm-dev01`, in SSMS and PowerShell. It's inside the private network, so it reaches the managed instance and Key Vault. |
| 7 (runbook) | The team repo, on `vm-dev01` (copy the runbook to `evidence/c07/member-<n>/` as in [Copy your evidence to the team repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-the-team-repo)), or on your own computer. |

Connect to a VM through Bastion in the portal: `rg-datacenter` > the VM > **Connect** > **Bastion**, user `labadmin`. Get the password in your dev container, from `factory/`:

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
(Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json).adminPassword
```

Never stop or deallocate `vm-dev01`: it's your workstation for the whole event.

## Your tasks

1. In the Arc portal, start the MI link migration against your SQL Managed Instance: seed, then wait for the replica to show as healthy.
2. Validate the read-only replica: row counts, and a few spot-check queries, against the source. If something looks wrong, abort and reseed — don't cut over on a replica you haven't checked.
3. **Stop every writer to the source, then cut over.** The source stays writable even after cutover, so any write after your final lag reading is lost. Agree a short maintenance window with your coach and your team, then do these steps in order:

   1. **Stop anything on `vm-dev01` that writes to the source.** Close the modernized app if you left it running from C6 (stop `dotnet run`, or the debug session, and close its terminal), and don't run `Reset-PerfKit.ps1`. `Start-Workload.ps1` only reads, but stop it too. Don't stop the VM itself.
   2. **Stop the legacy app on `vm-app01`.** Connect through Bastion (above), open **PowerShell as Administrator**, and stop the site and its application pool (the pool is what keeps database connections open). Leave SQL Server running: the link needs it.

      ```powershell
      Import-Module WebAdministration
      Stop-Website -Name ContosoUniversity
      Stop-WebAppPool -Name ContosoUniversity
      (Get-Website -Name ContosoUniversity).State
      (Get-WebAppPoolState -Name ContosoUniversity).Value
      ```

      Both lines must print `Stopped`. From `vm-dev01`, `http://10.10.<n>.4/` (your member index for `<n>`) must no longer load.
   3. **Check nothing else is connected to the database.** Still on `vm-app01`, in the same PowerShell:

      ```powershell
      $query = "SELECT session_id, login_name, host_name, program_name, status FROM sys.dm_exec_sessions WHERE is_user_process = 1 AND database_id = DB_ID('ContosoUniversity') AND session_id <> @@SPID"
      $conn = New-Object System.Data.SqlClient.SqlConnection 'Server=localhost;Database=master;Integrated Security=True;TrustServerCertificate=True'
      $conn.Open()
      $cmd = $conn.CreateCommand()
      $cmd.CommandText = $query
      $table = New-Object System.Data.DataTable
      $table.Load($cmd.ExecuteReader())
      $conn.Close()
      $table | Format-Table
      ```

      An empty result is what you want. A row means a client is still connected: use `host_name` and `program_name` to find it (an SSMS window on `vm-dev01` is the usual one), close it, and run the check again.
   4. **Watch the lag reach zero.** In the Arc portal, open the link's **Monitor and cutover** pane. With no writers, the replication lag falls to 0 within a minute or two and stays there. If it doesn't reach 0, or a writer keeps appearing, **abort the cutover**: restart the site and pool (`Start-WebAppPool -Name ContosoUniversity; Start-Website -Name ContosoUniversity`), and ask your coach.
   5. **Cut over at lag 0** with **Complete cutover**, and leave **forced failover unchecked** — it isn't needed when there's no lag and no traffic, and ticking it risks data loss if lag isn't actually zero.

   After a completed cutover the managed instance is the live database. Leave the legacy site on `vm-app01` stopped: restarting it would write to a source that's no longer authoritative.
4. After cutover, write the Key Vault secret `ConnectionStrings--DefaultConnection` (Microsoft Entra authentication, no password) and create the contained database user for the web app's managed identity, with `db_datareader`, `db_datawriter` and `db_ddladmin`.
5. Point the web app at your C6 image and restart it. Confirm the five pages load, an upload lands in Blob, a notification round-trips, and telemetry reaches Application Insights.
6. Follow up on C3's trace-flag decision: remove `-T1800` and `-T9567` from the source now that the link is gone.
7. Write the cutover and rollback runbook from what you actually did, using the [template](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/cutover-rollback-runbook.md).

## Evidence

- The Arc portal's migration status: link created, seeded, replica validated, cutover complete, link removed.
- The maintenance-window output from `vm-app01`: site and pool `Stopped`, an empty session list, and the lag at 0 in the Monitor and cutover pane just before you completed the cutover.
- `https://app-university-<suffix>.azurewebsites.net/` loading, with the five pages showing the migrated data.
- The contained database user created, and the `CREATE USER` statement used (no `WITH SID`, no `TYPE = E` — SQL MI doesn't support them).
- The source's trace flags removed, and the cutover/rollback runbook committed to the team repo.

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
