# Migrate ContosoUniversity to SQL MI with MI link: the Arc portal way

The steps for C7, written for B11 to turn into the challenge page, and the owner's script for B07 requirement 19. They migrate `ContosoUniversity` online from `vm-app01` to `sqlmi-university-<suffix>-b07` through **SQL Server migration in Azure Arc** with the Managed Instance link: link created, seeded, read-only replica validated, then a planned cutover that removes the link. Times are in the [report](README.md#timings).

Sources, checked 2026-10-02: [Migration to Azure SQL Managed Instance](https://learn.microsoft.com/sql/sql-server/azure-arc/migrate-to-azure-sql-managed-instance) and [Prepare environment for a Managed Instance link migration](https://learn.microsoft.com/sql/sql-server/azure-arc/migration-sql-mi-prepare-link) (SQL Server migration in Azure Arc), and [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation).

## Before you start

These are done by the kit, with Bicep and scripts, not by hand. `n` is the member index.

| Check | How it's done | How to check |
|---|---|---|
| `vm-app01` is Arc-enabled and its SQL Server shows under **Azure Arc** > **SQL Server instances** | [onboarding-portal.md](onboarding-portal.md) | Edition Developer, extension `WindowsAgent.SqlServer` up to date (**Azure Arc** > **Machines** > `vm-app01` > **Extensions**) |
| The MI exists, with `snet-sqlmi` peered to `vnet-datacenter` and the MI link rules in `nsg-sqlmi` and `nsg-servers` | [infra/main.bicep](infra/main.bicep) into `rg-spike-b07` | `az network nsg rule list -g rg-datacenter --nsg-name nsg-servers -o table` lists `AllowMiLinkFromMiSubnetInbound` and `AllowMiLinkToMiSubnetOutbound` |
| SQL Server is prepared: Windows Firewall allows TCP 5022 from `10.20.n.128/26`; a database master key in `master`; the Azure root CAs (DigiCert Global Root G2, Microsoft RSA Root Certificate Authority 2017) imported as issuers for `*.database.windows.net`; `ContosoUniversity` in the full recovery model with a full backup with checksum | [infra/arc-source-prep.bicep](infra/arc-source-prep.bicep) into `rg-datacenter`: an Arc run command that runs [scripts/Prepare-MiLinkSource.ps1](scripts/Prepare-MiLinkSource.ps1) | Its output, or `C:\LabTools\logs\Prepare-MiLinkSource.log` on `vm-app01` |
| The network works **both ways** | [scripts/Test-MiLinkNetwork.ps1](scripts/Test-MiLinkNetwork.ps1) on `vm-app01` (Arc run command) and the page's `NetHelper` SQL Agent job on the MI (run from `vm-dev01` with [scripts/Invoke-MiQuery.ps1](scripts/Invoke-MiQuery.ps1)) | Every probe prints `TcpTestSucceeded True` / `True` |

The availability groups feature, trace flags `-T1800` and `-T9567`, and `NT AUTHORITY\SYSTEM` as a sysadmin (the Arc extension uses it for the link, cutover and cancel) come from the datacenter deployment. The prep script checks them.

You need **SQL Managed Instance Contributor** on the MI, or Contributor on the subscription. The member's Owner role covers it.

## 1. Open the migration pane

1. In the Azure portal, open **Azure Arc** > **SQL Server instances** > `vm-app01`.
2. Under **Migration**, select **Database migration**. The pane has four tiles: **Assess source instance**, **Select target**, **Migrate data** and **Monitor and cutover**.

## 2. Assess and select the target

1. **Assess source instance** > **View report**. If there's no result, use **Run assessment**. Check the **Azure SQL MI** tile's readiness for `ContosoUniversity`.
2. **Select target** > **Yes, I have already created a target**. Pick the workload subscription, `rg-spike-b07` and `sqlmi-university-<suffix>-b07`, then **Select target**.

## 3. Create the link

1. **Migrate data** > **Migrate using real-time replication (online)**.
2. **Select source databases**: tick `ContosoUniversity`, then **Next: Settings**.
3. **Settings**: link name `link-contosouniversity`. Leave the availability group name it generates. Use **Test connection**: it can pass while the link would still fail, which is why the kit tests both directions first.
4. **Review + create**: check the warnings, then **Start data migration**. Note the time.

Creating the link takes up to 10 minutes; the portal grants the extension just-in-time permissions on SQL Server while it does. Seeding then copies the database. Follow it on **Monitor and cutover**: the status turns to **Ready for cutover** when the replica is in sync, and the **Lag** column shows two dashes when there's no lag. Note the time.

## 4. Validate the read-only replica

From `vm-dev01`, connect to the MI's host name with the Entra admin (SSMS: **Microsoft Entra MFA**; `sqlcmd`: `--authentication-method ActiveDirectoryInteractive`). Check, against the source:

- the row counts of every user table (for example `dbo.Person`, with students and instructors in one table, and `dbo.Enrollment`);
- the compatibility level is still `110`;
- the perf kit objects exist: `dbo.usp_SearchStudents`, `dbo.usp_GetStudentEnrollments`, `dbo.vw_EnrollmentStatistics`.

The replica is read-only until cutover, so you can't create users for app identities yet.

## 5. The abort path (Day 2 curveball)

The go/no-go check fails, so the cutover is called off and re-planned:

1. **Monitor and cutover** > select `ContosoUniversity` > **Cancel migration**. This removes the link without a failover; the pane is short and simple.
2. Check the source is untouched: `ContosoUniversity` on `vm-app01` is online and read-write, and the app at `http://10.10.n.4/` still works from `vm-dev01`.
3. The MI keeps its copy of the database, now `ONLINE` and **read-write**, and it no longer receives changes. Keep the app on the source and don't write to the MI copy. Delete it before the new link: `az sql midb delete -g rg-spike-b07 --mi <mi-name> -n ContosoUniversity --yes`.
4. Create the link again (step 3) and let it reseed. Note the times.

## 6. Cut over

1. Wait for **Ready for cutover** and no lag. Stop writes to the source: stop the `ContosoUniversity` site in IIS on `vm-app01`.
2. **Monitor and cutover** > select `ContosoUniversity` > **Complete cutover**. Tick "I confirm that I have stopped all incoming traffic to the source database". Leave "I want to do a forced failover" **unticked**: a planned failover waits for the lag to reach 0 seconds, and a forced one can lose data. Select **Complete cutover**. The portal offers no choice to keep the link; it removes it.
3. Check the MI database is read-write (`SELECT DATABASEPROPERTYEX('ContosoUniversity', 'Updateability')` returns `READ_WRITE`). The source stays read-write too, with no link: keep the app stopped on the source until it points at the MI.
4. Before anything restarts the MI, check that it has taken its first full backup of the database (`msdb.dbo.backupset`, `type = 'D'`). Dropping the link before that backup can leave the database unavailable after a restart.
5. Smoke test from `vm-dev01`: `db/perf-kit/Start-Workload.ps1 -Server <mi-host-name> -Authentication ActiveDirectoryInteractive -DurationMinutes 5` against the MI. Use `ActiveDirectoryInteractive` (a browser sign-in), not `ActiveDirectoryDefault`, which signs in as `vm-dev01`'s managed identity.
6. Once the link is removed and no failback is planned, remove the MI link startup trace flags `-T1800` and `-T9567` from the source (SQL Server Configuration Manager > SQL Server service > **Startup Parameters**, then restart SQL Server). They're why the assessment warns "Trace flags not supported in Azure SQL Managed Instance": source-side only, not needed on the MI, not a blocker.

After cutover the MI can be stopped, which an active link prevents.

## 7. Failback (bonus)

Reverse migration isn't in the Arc portal, and the portal's cutover doesn't offer to keep the link. With the SQL Server 2022 update policy, a new link from the MI back to SQL Server 2022 is possible in SSMS or with T-SQL ([Reverse a migration](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-migrate#reverse-a-migration)), after deleting the source database so the link can seed it. B07 didn't attempt it (owner decision); the kit's rollback is the abort before cutover (step 5).

## Where the portal differed from this page

Recorded during the owner's run on 2026-10-02 and folded into the steps above:

- **Run assessment** finished in under 3 minutes.
- The link resource on the MI is named `DAG_ContosoUniversity`, from the database name, whatever link name you type in the wizard. Creating the link took about 6 minutes from **Start data migration**; seeding 200 MB took under a minute.
- **Cancel migration** was simple, but it leaves the database on the MI, read-write (step 5).
- **Complete cutover** has two checkboxes (traffic stopped, forced failover) and no choice to keep the link. It removes the link and leaves the source read-write (step 6).
