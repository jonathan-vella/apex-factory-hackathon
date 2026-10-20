---
title: "C7: Migrate and go live"
description: Prepare the source, seed the link, validate the replica, cut over, and bring the app up on App Service.
---

## Goal

Move the database to SQL Managed Instance with no data loss, then put the modernized app live on App Service against it.

The MI link is a database mirror from `vm-app01` to your managed instance. It keeps a read-only copy in sync until you cut over, and then the managed instance takes over as the live database.

## Scope and time box

Member. **120 min**.

## Points

**20 pts** (member).

## Inputs

- C5's deployed SQL Managed Instance, with its directory read access granted: the Microsoft Graph read grant made in C2 by a Privileged Role Administrator. Ask your coach to confirm it before you start, or `CREATE USER` fails in task 5.
- C6's modernized, packaged app (image tag `c6`), not yet pointed at App Service.
- `vm-app01` running, with its Azure Arc entry **Connected**. C3 had you start it; run `az vm start` for it if it's stopped. The portal shows the instance only while the machine is connected.

Start the link at 08:30 on Day 2 (the agenda's "Reconnect and start the MI link"), before you finish C6, so it's already seeded when you reach task 3: tasks 1 and 2 take about 20 minutes, and creating the link takes up to 10 more. Those 10 minutes of waiting overlap C6 and don't count toward C7's 120. If your coach calls the cutover off at go/no-go, plan another 20 to 30 minutes to reseed, validate again and agree a second window. Go/no-go is the check, with your coach, that the lag is clear and the replica is validated before you stop the writers.

## What the kit already did for you

The datacenter deployment turned on availability groups on `vm-app01`'s SQL Server, set the startup trace flags `-T1800` and `-T9567`, made `NT AUTHORITY\SYSTEM` a sysadmin and onboarded the instance to Azure Arc (C0). C2's vending opened the network path between `vm-app01` and your managed instance's subnet. Task 1 does the rest of what the link needs on the source: a Windows Firewall rule for port 5022, a database master key, the Azure root certificates and a full backup.

## Where to run

| Tasks | Where |
| --- | --- |
| 1 (prepare the source) | `vm-app01` (the legacy IIS and SQL Server VM), through Bastion, in Windows PowerShell as an administrator. |
| 2, 3 (link, replica check) | The Azure portal (Azure Arc > SQL Server instances), in your browser. Run the replica spot-check queries in SSMS on `vm-dev01`. |
| 4 (stop the writers, cut over) | `vm-app01` through Bastion, plus a check on `vm-dev01`. |
| 5, 6 (secret, user, App Service) | `vm-dev01`, in PowerShell and SSMS. It's inside the private network, so it reaches the managed instance and Key Vault. |
| 7 (trace flags) | `vm-app01`, through Bastion. |
| 8 (runbook) | Your own repo: on `vm-dev01` in `C:\src\<your-repo>` (the plain clone of your own repo), or in the dev container. See Evidence for where the file goes. |

Connect to a VM through Bastion in the portal: `rg-datacenter` > the VM > **Connect** > **Bastion**, user `labadmin`. To paste into a Bastion session, use Ctrl+V and allow the browser's clipboard prompt if it asks. To open an Administrator PowerShell on `vm-app01`, select **Start**, type `powershell`, right-click **Windows PowerShell** and choose **Run as administrator**.

`<n>` is your member index, the `memberIndex` value in your settings. In your dev container, from `factory/`, this prints the passwords you need and the exact command for task 1 with your `<n>` filled in:

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
$dc = Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json
"labadmin password (Bastion):  $($dc.adminPassword)"
"contosoapp password (source): $($dc.sqlAppPassword)"
"Source SQL Server address:    10.10.$($s.memberIndex).4"
"Task 1 command:               C:\LabTools\Prepare-MiLinkSource.ps1 -MiSubnetPrefix 10.20.$($s.memberIndex).128/26"
```

These are lab-only passwords: keep them out of your screenshots and evidence. For member 3, the source is `10.10.3.4` and the subnet is `10.20.3.128/26`.

Never stop or shut down `vm-dev01`: it's your workstation for the whole event.

Pacing for the 120 minutes: tasks 1 to 3 about 25, task 4 about 25, tasks 5 and 6 about 40, task 7 about 10 and task 8 about 15. The rest is slack.

On `vm-dev01`, in PowerShell 7, after `az login --use-device-code`, set up the names that tasks 3, 5 and 6 use:

```powershell
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$suffix = $rg -replace '^rg-university-', ''
$mi = az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query fullyQualifiedDomainName --output tsv
$mi
```

`$mi` prints the managed instance's standard host name, for example `sqlmi-university-ab12cd.<something>.database.windows.net`. It's never an IP address or a `privatelink` name. Copy it: SSMS needs the host name itself, not the variable `$mi`.

## Your tasks

1. **Prepare the source.** Run the kit's `Prepare-MiLinkSource.ps1` on `vm-app01`. It must run inside a Bastion session, because VM run commands stop working once the VM is Arc-enabled. Safe to run again: it changes nothing that already exists.

   1. Connect to `vm-app01` through Bastion and open an Administrator Windows PowerShell (Where to run).
   2. Download the script and run it with the command from the dev container, which has your `<n>` in it. If your event runs from a copy of the kit, your coach gives you that copy's URL instead of the one below.

      ```powershell
      New-Item -ItemType Directory -Force C:\LabTools | Out-Null
      Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/infra/datacenter/scripts/Prepare-MiLinkSource.ps1' -OutFile C:\LabTools\Prepare-MiLinkSource.ps1 -UseBasicParsing
      C:\LabTools\Prepare-MiLinkSource.ps1 -MiSubnetPrefix 10.20.<n>.128/26
      ```

   The script prints one line per step with the time, and logs the same lines to `C:\LabTools\logs\Prepare-MiLinkSource.log`. You should see, in order: the firewall rule for TCP 5022; an `Instance:` line with availability groups `1`, trace flags on `2 of 2` and SYSTEM sysadmin `1`; the database master key created (or "exists"); the two root certificates `DigiCertPKI` and `MicrosoftPKI` imported (or "exist"); `ContosoUniversity` in the full recovery model; the full backup with checksum; and last, `The source is ready for MI link.`

   Done when the last line is `The source is ready for MI link.` If it stops with an `ERROR:` line, see **If link creation fails** in the hints.
2. **Start the link.** In the Azure portal, start the MI link migration against your SQL Managed Instance.

   1. Open **Azure Arc** > **SQL Server instances** and select the instance whose host machine is `vm-app01`. In the menu, under **Migration**, select **Database migration**. The pane has four tiles: **Assess source instance**, **Select target**, **Migrate data** and **Monitor and cutover**.
   2. **Select target**: on the **Create or select target** pane, choose **Yes, I have already created a target**. Pick your workload subscription, the resource group `rg-university-<suffix>` and the managed instance `sqlmi-university-<suffix>`, then select the target.
   3. **Migrate data** > **Migrate using real-time replication (online)**. (**Migrate using log shipping (online)** is a different method that the kit doesn't use.)
   4. Tick `ContosoUniversity` and select **Next: Settings**. Name the link and leave the generated availability group name. **Test connection** can pass even when creation would fail, so don't treat it as proof.
   5. Select **Next: Review + create**. Read each warning. A warning that leaves **Start data migration** available doesn't block you; one that blocks it, or that mentions the network, certificates or backups, means stop and see **If link creation fails**.
   6. Select **Start data migration** and note the time. Follow it in **Monitor migrations** (the **Monitor and cutover** pane): creating the link takes up to 10 minutes, then it seeds the database.

   Done when the status of `ContosoUniversity` is **Ready for cutover**. The **Lag** column shows two dashes, which Microsoft Learn describes as no lag.
3. **Validate the read-only replica.** The replica must hold the same data as the source before you trust it. In SSMS on `vm-dev01`, open two connections:

   - **Source:** server name `10.10.<n>.4`; **Authentication** SQL Server Authentication; **Login** `contosoapp` with the `contosoapp` password from the dev container. Select **Options** > **Connection Properties** and tick **Trust server certificate**, because the source's certificate is self-signed.
   - **Replica:** server name the host name that `$mi` printed (paste it); **Authentication** **Microsoft Entra MFA**; **User name** the account that deployed the archetype in C5.

   On each connection, open a new query on the `ContosoUniversity` database and run these, with no writers on the source (stop anything you started in C6):

   ```sql
   -- 1. Row counts of every table
   SELECT s.name + N'.' + t.name AS TableName, SUM(p.rows) AS [RowCount]
   FROM sys.tables AS t
   JOIN sys.schemas AS s ON s.schema_id = t.schema_id
   JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
   GROUP BY s.name, t.name
   ORDER BY TableName;

   -- 2. A content checksum of two tables
   SELECT COUNT(*) AS Total, CHECKSUM_AGG(BINARY_CHECKSUM(*)) AS Fingerprint FROM dbo.Department;
   SELECT COUNT(*) AS Total, CHECKSUM_AGG(BINARY_CHECKSUM(*)) AS Fingerprint FROM dbo.Course;

   -- 3. Compatibility level, read or write, and the performance kit's objects
   SELECT name, compatibility_level, CAST(DATABASEPROPERTYEX(name, 'Updateability') AS nvarchar(20)) AS Updateability FROM sys.databases WHERE name = DB_NAME();
   SELECT name FROM sys.objects WHERE name IN (N'usp_SearchStudents', N'usp_GetStudentEnrollments', N'vw_EnrollmentStatistics') ORDER BY name;
   ```

   The two connections must give the same answer for every query, except `Updateability`: `READ_WRITE` on the source and `READ_ONLY` on the replica. The compatibility level is `110` on both, and the last query lists three objects on both. If a count differs, wait a minute (the replica catches up) and run it again. If it still differs, or something else looks wrong, abort and reseed: don't cut over on a replica you haven't checked.

   Done when the row counts, both fingerprints, the compatibility level and the three objects match on both connections.
4. **Stop every writer to the source, then cut over.** The source stays writable even after cutover, so any write after your final lag reading is lost. Tell your coach you're about to stop the writers and wait for their go-ahead. Then do these steps in order.

   **Don't script the cutover.** Use the **Monitor and cutover** pane, not a command: `az sql mi link failover` run from the managed instance's side fails, because the managed instance is the secondary at that point, and failing over by hand on SQL Server skips the portal's checks. [The guide](../../guides/arc-mi-link/#why-the-cutover-isnt-scripted) has the detail; don't run those commands.

   1. **Stop anything on `vm-dev01` that writes to the source.** Close the SSMS windows connected to `10.10.<n>.4`. Close the modernized app if you left it running from C6 (stop `dotnet run`, or the debug session, and close its terminal), and don't run `Reset-PerfKit.ps1`. `Start-Workload.ps1` only reads, but stop it too. Don't stop the VM itself.
   2. **Stop the legacy app on `vm-app01`.** Connect through Bastion (above), open an Administrator Windows PowerShell, and stop the site and its application pool (IIS runs the site, and the pool is what keeps database connections open). Leave SQL Server running: the link needs it.

      ```powershell
      Import-Module WebAdministration
      Stop-Website -Name ContosoUniversity
      Stop-WebAppPool -Name ContosoUniversity
      (Get-Website -Name ContosoUniversity).State
      (Get-WebAppPoolState -Name ContosoUniversity).Value
      ```

      Both lines must print `Stopped`. From `vm-dev01`, `http://10.10.<n>.4/` must no longer load.
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
   4. **Watch the lag reach zero.** In the Azure portal, open the **Monitor and cutover** pane (**Database migration** > **Monitor migrations**). With no writers, the status of `ContosoUniversity` stays **Ready for cutover** and the **Lag** column shows two dashes, which means no lag, within a minute or two. If lag doesn't clear, or a writer keeps appearing, **abort the cutover**: restart the site and pool (`Start-WebAppPool -Name ContosoUniversity; Start-Website -Name ContosoUniversity`), and ask your coach.
   5. **Cut over at no lag.** Select `ContosoUniversity`, then **Cutover** (Microsoft Learn's name; some portal builds label the button **Complete cutover**, and it's the same action). Tick the box that confirms you've stopped all incoming traffic to the source, and leave the **forced failover** box clear: a planned failover waits for the lag to reach zero, and forcing it with lag above zero can lose writes. The portal removes the link when the cutover completes: it offers no option to keep it.
   6. **Wait for it to finish.** It takes about 2 minutes. On **Monitor and cutover**, the migration for `ContosoUniversity` shows as completed and the link is gone. Then, in SSMS on the replica connection from task 3, run `SELECT DATABASEPROPERTYEX('ContosoUniversity', 'Updateability');`. It must return `READ_WRITE` (it said `READ_ONLY` in task 3).

   Done when the migration shows completed and the managed instance's database returns `READ_WRITE`. The managed instance is now the live database. Leave the legacy site on `vm-app01` stopped: restarting it would write to a source that's no longer authoritative.
5. **Write the secret and create the database user.** On `vm-dev01`, do both for the web app's managed identity. The Key Vault stores the connection string, and the web app reads it at startup through its identity `id-university-<suffix>`.

   1. **Write the secret `ConnectionStrings--DefaultConnection`.** It uses Microsoft Entra authentication and has no password. The account that deployed the archetype has the rights to write it:

      ```powershell
      az keyvault secret set --vault-name "kv-university-$suffix" --name 'ConnectionStrings--DefaultConnection' --value "Server=$mi;Database=ContosoUniversity;Authentication=Active Directory Default;Encrypt=True;" --output none
      az keyvault secret show --vault-name "kv-university-$suffix" --name 'ConnectionStrings--DefaultConnection' --query id --output tsv
      ```

      The second command prints the secret's ID: it exists. Never put the connection string in an app setting.
   2. **Create the database user.** In SSMS, connect to the managed instance as in task 3 (host name, **Microsoft Entra MFA**, the account that deployed the archetype), open a new query on the `ContosoUniversity` database and run it. The user's name is the web app's identity: replace `<suffix>` with your suffix, for example `[id-university-ab12cd]`.

      ```sql
      CREATE USER [id-university-<suffix>] FROM EXTERNAL PROVIDER;
      ALTER ROLE db_datareader ADD MEMBER [id-university-<suffix>];
      ALTER ROLE db_datawriter ADD MEMBER [id-university-<suffix>];
      ALTER ROLE db_ddladmin ADD MEMBER [id-university-<suffix>];
      ```

   Done when `az keyvault secret show` prints an ID and SSMS reports the four statements completed successfully.
6. **Point the web app at your image** and restart it, then check it. The web app pulls the image from your private registry with its managed identity:

   ```powershell
   az webapp config container set --resource-group $rg --name "app-university-$suffix" --container-image-name "cruniversity$suffix.azurecr.io/contoso-university:c6" --container-registry-url "https://cruniversity$suffix.azurecr.io" --output none
   az webapp config show --resource-group $rg --name "app-university-$suffix" --query acrUseManagedIdentityCreds
   az webapp restart --resource-group $rg --name "app-university-$suffix"
   ```

   The second command must print `true`: the archetype set the image pull with the identity. The app takes a few minutes to start; follow it with `az webapp log tail --resource-group $rg --name "app-university-$suffix"`. If the tail prints nothing, turn on container logging first: `az webapp log config --resource-group $rg --name "app-university-$suffix" --docker-container-logging filesystem`. Playbook Step 5 (`.github/modernization/playbook.md` in your clone) has the same commands and the usual startup errors.

   Done when `https://app-university-$suffix.azurewebsites.net/` (with your suffix) loads the five pages, the home page, Students, Courses, Instructors and Departments, showing the migrated data. Then confirm an upload lands in Blob, a notification round-trips, and telemetry reaches Application Insights.
7. **Follow up on C3's trace-flag decision:** remove `-T1800` and `-T9567` from the source now that the link is gone. On `vm-app01`, through Bastion:

   1. Open **SQL Server Configuration Manager**: press Win+R, type `SQLServerManager16.msc` and press Enter. Go to **SQL Server Services**, right-click the SQL Server service (`SQL Server (MSSQLSERVER)`) and open **Properties** > the **Startup Parameters** tab.
   2. In **Existing parameters**, select `-T1800` and choose **Remove**, then the same for `-T9567`. Choose **Apply**.
   3. Restart the SQL Server service, not the VM: right-click `SQL Server (MSSQLSERVER)` > **Restart**.
   4. In an Administrator Windows PowerShell on `vm-app01`, check that the flags are gone. The list must not include `1800` or `9567`; no rows (`Flags: 0`) is the expected result:

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

   5. Mark your trace-flag row in `deferred-work-register.md` (the register you built in C4) as done.

   Done when the `DBCC TRACESTATUS` list has no `1800` or `9567`.
8. **Write the cutover and rollback runbook** from what you actually did, using the [template](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/cutover-rollback-runbook.md), and save it as `cutover-rollback-runbook.md` in `factory/evidence/c07/` of your own repo. Write the six short sections from what you did, not from a plan. Done when all six sections hold your own notes and output.

## Evidence

Save screenshots and output as files in `factory/evidence/c07/` of your own repo, on `main`, and redact tenant, subscription and object IDs first (and never include a password). In the dev container, run `git pull` first. On `vm-dev01`, use `C:\src\<your-repo>\factory\evidence\c07\` (the plain clone of your own repo) and run `git pull --rebase` first. Commit with a conventional message (for example `docs: C7 evidence`) and run `git push`.

- The output of task 1 ending in `The source is ready for MI link.`
- The Azure portal's migration status: link created, seeded (**Ready for cutover**), and cutover completed. The portal removes the link when it completes the cutover, so a completed cutover on the **Monitor and cutover** pane is the evidence that the link is gone.
- The replica comparison from task 3: the query results from both connections, side by side.
- The maintenance-window output from `vm-app01`: site and pool `Stopped`, `Sessions: 0`, and the lag at no lag (two dashes) in the **Monitor and cutover** pane just before you cut over. The `READ_WRITE` result after the cutover.
- `https://app-university-<suffix>.azurewebsites.net/` loading, with the five pages showing the migrated data.
- The contained database user created, and the `CREATE USER` statement used (no `WITH SID`, no `TYPE = E`: SQL MI doesn't support them).
- The source's trace flags removed (the empty `DBCC TRACESTATUS` output from task 7), your trace-flag row marked done in the register, and the cutover and rollback runbook committed to your own repo.

## Hints

<details>
<summary>If link creation fails</summary>

Work through these in order:

1. Task 1 must have finished with `The source is ready for MI link.` Read `C:\LabTools\logs\Prepare-MiLinkSource.log` on `vm-app01`. An `ERROR:` line that says the instance is not ready means a datacenter setting is missing: tell your coach.
2. The prefix you passed must be your own `10.20.<n>.128/26`. A wrong prefix opens port 5022 to the wrong subnet and the link can't connect. Run the script again with the right one: it fixes the firewall rule.
3. `vm-app01` must be running with its Arc entry **Connected**, and the SQL Server service must be running.
4. **Test connection** can pass while creation still fails, so read the error the portal shows on **Monitor migrations** and send it to your coach. Don't change firewall, network or certificate settings by hand.
5. To retry, select **Cancel migration**, delete the leftover copy on the managed instance (the next hint), and start again from task 2. Task 1 doesn't need repeating.

</details>

<details>
<summary>The abort leaves something behind</summary>

In the Azure portal, **Monitor and cutover** > select the database > **Cancel migration** removes the link without a failover. An aborted link leaves a writable copy of the database on the MI, and the source is untouched (restart the legacy site if you stopped it). Delete the copy before starting a new seed, or the reseed fails. This deletes the copy on the managed instance only; the database on `vm-app01` isn't affected. On `vm-dev01`:

```powershell
az sql midb delete --resource-group $rg --managed-instance "sqlmi-university-$suffix" --name ContosoUniversity --yes
```

Then start the link again from task 2.
</details>

<details>
<summary>CREATE USER fails</summary>

Before cutover, the replica is read-only, so the user creation step only works after cutover completes (task 4, step 6). If it still fails afterward with a permissions error on the server's Entra identity, ask your coach: the MI's primary identity needs Microsoft Graph read access, set up once per team in C2.
</details>

<details>
<summary>The app won't start against App Service</summary>

Check the Key Vault secret exists and has the right name (`ConnectionStrings--DefaultConnection`, with the double dash), and that the database user was created with the identity's exact name.
</details>

## If you need to start over

Before the cutover, cancel and reseed: **Cancel migration** in the portal, delete the copy on the managed instance (see the hint "The abort leaves something behind"), then start again from task 2. After the cutover there's no link to remove: the managed instance is the live database, so ask your coach before you change anything. If the web app won't start after go-live, check the Key Vault secret and the database user first, then ask your coach.

## Bonus

Up to 5 pts for a clean reseed after a real, unplanned abort that you can show evidence for (not needed if your first seed and validation go cleanly). An abort a coach stages is part of the event and earns no bonus.

## Learn more

- [Migration to Azure SQL Managed Instance with SQL Server enabled by Azure Arc](https://learn.microsoft.com/sql/sql-server/azure-arc/migrate-to-azure-sql-managed-instance)
- [Prepare environment for a Managed Instance link migration](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-sql-mi-prepare-link)
- [Migrate with the Managed Instance link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-migrate)
- [Managed Instance link feature overview](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-feature-overview)
- [Migration guide for SQL Server to Azure SQL Managed Instance](https://learn.microsoft.com/azure/azure-sql/migration-guides/managed-instance/sql-server-to-managed-instance-guide)
