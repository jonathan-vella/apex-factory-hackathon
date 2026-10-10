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

C5's deployed SQL Managed Instance, with its directory read access granted (the platform lead's Graph grant in C2: ask your coach to confirm it before you start, or `CREATE USER` fails in task 4). C6's modernized, packaged app (image tag `c6`), not yet pointed at App Service.

Start the link first thing on Day 2, before you finish C6, so it's already seeded when C7 starts: creating the link takes up to 10 minutes. If your coach calls the cutover off at go/no-go, plan another 20 to 30 minutes to reseed, validate again and agree a second window.

## Where to run

| Tasks | Where |
| --- | --- |
| 1, 2 (link, replica check) | The Azure portal (Azure Arc > SQL Server instances), in your browser. Run the replica spot-check queries in SSMS on `vm-dev01`. |
| 3 (stop the writers) | `vm-app01` (the legacy IIS and SQL Server VM), through Bastion. Plus a check on `vm-dev01`. |
| 4, 5 (secret, user, App Service) | `vm-dev01`, in PowerShell and SSMS. It's inside the private network, so it reaches the managed instance and Key Vault. |
| 6 (trace flags) | `vm-app01`, through Bastion. |
| 7 (runbook) | The team repo: on `vm-dev01` (clone it as in [Copy your evidence to the team repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-the-team-repo), and save into `evidence/c07/member-<n>/`), or on your own computer. |

Connect to a VM through Bastion in the portal: `rg-datacenter` > the VM > **Connect** > **Bastion**, user `labadmin`. Get the password in your dev container, from `factory/`:

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
(Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json).adminPassword
```

Never stop or deallocate `vm-dev01`: it's your workstation for the whole event.

Pacing for the 120 minutes: tasks 1 and 2 about 20, task 3 about 25, tasks 4 and 5 about 40, task 6 about 10 and task 7 about 15. The rest is slack.

On `vm-dev01`, in PowerShell 7, after `az login --use-device-code`, set up the names that tasks 2, 4 and 5 use:

```powershell
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$suffix = $rg -replace '^rg-university-', ''
$mi = az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query fullyQualifiedDomainName --output tsv
$mi
```

`$mi` is the managed instance's standard host name, never an IP address or a `privatelink` name.

## Your tasks

1. In the Arc portal, start the MI link migration against your SQL Managed Instance. Open **Azure Arc** > **SQL Server instances** > the instance on `vm-app01`, then **Migration** > **Database migration**. If **Select target** isn't done, choose your archetype's managed instance (**Yes, I have already created a target**). Then **Migrate data** > **Migrate using real-time replication (online)**, tick `ContosoUniversity`, **Next: Settings**, name the link and leave the generated availability group name, **Next: Review + create**, check the warnings and select **Start data migration**. Follow it in **Monitor migrations**: wait until the status is **Ready for cutover**.
2. Validate the read-only replica: row counts, and a few spot-check queries, against the source. In SSMS on `vm-dev01`, connect to `$mi` with **Microsoft Entra MFA** (the account that deployed the archetype), and to the source at `10.10.<n>.4` with SQL authentication as `contosoapp` (the password is `sqlAppPassword` in the same `datacenter.json` file as the Bastion password). If something looks wrong, abort and reseed — don't cut over on a replica you haven't checked.
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
      "Sessions: $($table.Rows.Count)"
      ```

      An empty table and `Sessions: 0` is what you want. A row means a client is still connected: use `host_name` and `program_name` to find it (an SSMS window on `vm-dev01` is the usual one), close it, and run the check again.
   4. **Watch the lag reach zero.** In the Arc portal, open the **Monitor and cutover** pane (**Database migration** > **Monitor migrations**). With no writers, the status of `ContosoUniversity` stays **Ready for cutover** and the **Lag** column shows two dashes, which means no lag, within a minute or two. If lag doesn't clear, or a writer keeps appearing, **abort the cutover**: restart the site and pool (`Start-WebAppPool -Name ContosoUniversity; Start-Website -Name ContosoUniversity`), and ask your coach.
   5. **Cut over at no lag.** Select `ContosoUniversity` > **Complete cutover** (Microsoft Learn calls the button **Cutover**). Tick the box that confirms you've stopped all incoming traffic to the source, and leave the **forced failover** box clear: a planned failover waits for the lag to reach zero, and forcing it risks data loss if lag isn't actually zero. The portal removes the link when the cutover completes: it offers no option to keep it.

   After a completed cutover the managed instance is the live database. Leave the legacy site on `vm-app01` stopped: restarting it would write to a source that's no longer authoritative.
4. After cutover, on `vm-dev01`, write the Key Vault secret and create the database user for the web app's managed identity.

   1. **Write the secret `ConnectionStrings--DefaultConnection`.** It uses Microsoft Entra authentication and has no password. The account that deployed the archetype has the rights to write it:

      ```powershell
      az keyvault secret set --vault-name "kv-university-$suffix" --name 'ConnectionStrings--DefaultConnection' --value "Server=$mi;Database=ContosoUniversity;Authentication=Active Directory Default;Encrypt=True;" --output none
      az keyvault secret show --vault-name "kv-university-$suffix" --name 'ConnectionStrings--DefaultConnection' --query id --output tsv
      ```

      The second command prints the secret's ID: it exists. Never put the connection string in an app setting.
   2. **Create the database user.** In SSMS, connect to `$mi` with **Microsoft Entra MFA** as the account that deployed the archetype, open a new query on the `ContosoUniversity` database and run it. The user's name is the web app's identity, `id-university-<suffix>`:

      ```sql
      CREATE USER [id-university-<suffix>] FROM EXTERNAL PROVIDER;
      ALTER ROLE db_datareader ADD MEMBER [id-university-<suffix>];
      ALTER ROLE db_datawriter ADD MEMBER [id-university-<suffix>];
      ALTER ROLE db_ddladmin ADD MEMBER [id-university-<suffix>];
      ```

5. Point the web app at your C6 image and restart it, then check it:

   ```powershell
   az webapp config container set --resource-group $rg --name "app-university-$suffix" --container-image-name "cruniversity$suffix.azurecr.io/contoso-university:c6" --container-registry-url "https://cruniversity$suffix.azurecr.io" --output none
   az webapp config show --resource-group $rg --name "app-university-$suffix" --query acrUseManagedIdentityCreds
   az webapp restart --resource-group $rg --name "app-university-$suffix"
   ```

   The second command must print `true`: the archetype set the image pull with the identity. The app takes a few minutes to start; follow it with `az webapp log tail --resource-group $rg --name "app-university-$suffix"`. Then confirm the five pages load, an upload lands in Blob, a notification round-trips, and telemetry reaches Application Insights. The playbook's step 5 (`.github/modernization/playbook.md` in your clone) has the same commands and the usual startup errors.
6. Follow up on C3's trace-flag decision: remove `-T1800` and `-T9567` from the source now that the link is gone. On `vm-app01`, through Bastion:

   1. Open **SQL Server Configuration Manager** (`SQLServerManager16.msc`), go to **SQL Server Services**, right-click the SQL Server service (`SQL Server (MSSQLSERVER)`) and open **Properties** > the **Startup Parameters** tab.
   2. In **Existing parameters**, select `-T1800` and choose **Remove**, then the same for `-T9567`. Choose **Apply**.
   3. Restart the SQL Server service, not the VM: right-click `SQL Server (MSSQLSERVER)` > **Restart**.
   4. In an Administrator PowerShell on `vm-app01`, check that the flags are gone. The list must not include `1800` or `9567`:

      ```powershell
      $conn = New-Object System.Data.SqlClient.SqlConnection 'Server=localhost;Database=master;Integrated Security=True;TrustServerCertificate=True'
      $conn.Open()
      $cmd = $conn.CreateCommand()
      $cmd.CommandText = 'DBCC TRACESTATUS(-1) WITH NO_INFOMSGS'
      $table = New-Object System.Data.DataTable
      $table.Load($cmd.ExecuteReader())
      $conn.Close()
      $table | Format-Table
      "Flags: $($table.Rows.Count)"
      ```

7. Write the cutover and rollback runbook from what you actually did, using the [template](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/cutover-rollback-runbook.md), and save it in `evidence/c07/member-<n>/` in the team repo.

## Evidence

- The Arc portal's migration status: link created, seeded, replica validated, cutover complete. The portal removes the link when it completes the cutover, so a completed cutover on the **Monitor and cutover** pane is the evidence that the link is gone.
- The maintenance-window output from `vm-app01`: site and pool `Stopped`, `Sessions: 0`, and the lag at no lag (two dashes) in the Monitor and cutover pane just before you completed the cutover.
- `https://app-university-<suffix>.azurewebsites.net/` loading, with the five pages showing the migrated data.
- The contained database user created, and the `CREATE USER` statement used (no `WITH SID`, no `TYPE = E` — SQL MI doesn't support them).
- The source's trace flags removed (the empty `DBCC TRACESTATUS` output from task 6), and the cutover/rollback runbook committed to the team repo.

## Why the cutover isn't scripted

Cut over through the Arc portal's **Monitor and cutover** pane, not with a CLI command. `az sql mi link failover --failover-type Planned` run from the managed instance's side fails, because the managed instance is the secondary at that point. A planned failover you script yourself runs on SQL Server (`ALTER AVAILABILITY GROUP [<DAG>] FAILOVER`, SQL Server 2022 CU13 or later), and the kit doesn't need it.

## Hints

<details>
<summary>The abort leaves something behind</summary>

In the Arc portal, **Monitor and cutover** > select the database > **Cancel migration** removes the link without a failover. An aborted link leaves a writable copy of the database on the MI, and the source is untouched (restart the legacy site if you stopped it). Delete the copy before starting a new seed, or the reseed fails. On `vm-dev01`:

```powershell
az sql midb delete --resource-group $rg --managed-instance "sqlmi-university-$suffix" --name ContosoUniversity --yes
```

Then start the link again from task 1.
</details>

<details>
<summary>`CREATE USER` fails</summary>

Before cutover, the replica is read-only — the user creation step only works after cutover completes. If it still fails afterward with a permissions error on the server's Entra identity, ask your coach: the MI's primary identity needs Microsoft Graph read access, set up once per team in C2.
</details>

<details>
<summary>The app won't start against App Service</summary>

Check the Key Vault secret exists and has the right name (`ConnectionStrings--DefaultConnection`, with the double dash), and that the database user was created with the identity's exact name.
</details>

## Bonus

Up to 5 pts for a clean reseed-after-abort you can show evidence for (not needed if your first seed and validation go cleanly).

## Learn more

- [Migration to Azure SQL Managed Instance with SQL Server enabled by Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/migrate-to-azure-sql-managed-instance)
- [Migrate with the Managed Instance link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-migrate)
- [Managed Instance link feature overview](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-feature-overview)
- [Migration guide for SQL Server to Azure SQL Managed Instance](https://learn.microsoft.com/azure/azure-sql/migration-guides/managed-instance/sql-server-to-managed-instance-guide)
