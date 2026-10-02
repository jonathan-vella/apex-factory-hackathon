# B07 spike: Arc onboarding and MI link migration

| Field | Value |
|---|---|
| Date | 2026-10-02 to in progress |
| Result | In progress |
| Region | swedencentral |
| Versions | Azure Connected Machine agent `1.68.03532.3282`, Azure extension for SQL Server (`WindowsAgent.SqlServer`) `1.1.3547.472`, SQL Server 2022 Developer `16.0.4255.1`, MI update policy SQL Server 2022 (`databaseFormat: 'SQLServer2022'`). In [versions.md](../../../versions.md) |

## Question

Can `vm-app01` be onboarded to Azure Arc unattended with a kit script, and does `ContosoUniversity` migrate online to SQL Managed Instance through the Arc portal migration with MI link: link created, seeded, read-only replica validated, aborted and re-created, planned cutover, link removed?

## What we did

1. Placed the Arc prep script on `vm-app01` with a datacenter re-run from this branch (`app-07-arc-prep`), and deployed the MI target with [infra/main.bicep](infra/main.bicep).
2. Onboarded `vm-app01` with `scripts/Connect-DatacenterArc.ps1`. Attempt 1 stopped after the prep (finding 4); after an owner-approved delete and rebuild of `vm-app01`, attempt 2 onboarded it unattended in 7.3 minutes. `Test-Datacenter.ps1` passed 44 of 44 before each attempt.
3. Re-applied the MI link rules in `nsg-servers` with [infra/modules/datacenter.bicep](infra/modules/datacenter.bicep), because the rebuild removed them (finding 1), and confirmed them with `az network nsg rule list`.
4. Prepared the source with [infra/arc-source-prep.bicep](infra/arc-source-prep.bicep), an Arc run command running [scripts/Prepare-MiLinkSource.ps1](scripts/Prepare-MiLinkSource.ps1): Windows Firewall rule, database master key, Azure root CAs, full recovery model, full backup with checksum.
5. Tested the network both ways before creating the link: SQL Server to MI with [scripts/Test-MiLinkNetwork.ps1](scripts/Test-MiLinkNetwork.ps1) (Arc run command), MI to SQL Server with the page's `NetHelper` SQL Agent job on the MI, run from `vm-dev01` with [scripts/Invoke-MiQuery.ps1](scripts/Invoke-MiQuery.ps1).
6. Took the source fingerprint with [scripts/fingerprint.sql](scripts/fingerprint.sql) for the replica check.

### Arc-enabled SQL Server

| Property | Value |
|---|---|
| Edition | Developer |
| Licence type set by the extension | `Free` (not billed) |
| Version reported | SQL Server 2022 |
| Extensions on the Arc machine | `WindowsAgent.SqlServer` (automatic), plus `MicrosoftDefenderForSQL` and `MDE.Windows`, which Defender for Cloud added (finding 6) |
| Other instances Arc found | `vm-app01_MSAS16_MSSQLSERVER` (Analysis Services) and `vm-app01_SSIS_2022` (Integration Services), from the SQL marketplace image |

### Network test before the link (requirement 17)

| Direction | Method | Result |
|---|---|---|
| SQL Server → MI, TCP 5022 (MI host name) | `Test-NetConnection` on `vm-app01` (what the page's `TestMILinkConnection` job runs) | `True`, resolves into `snet-sqlmi` |
| SQL Server → MI, HADR port 11002 (MI node) | Same | `True` |
| MI → SQL Server, TCP 5022, to the test endpoint `TEST_ENDPOINT` | The page's `NetHelper` SQL Agent job on the MI | `True` |

The test endpoint and certificate were dropped afterwards, and the `NetHelper` job deleted.

### Source before migration

| Table | Rows |
|---|---|
| `dbo.Course` | 4,007 |
| `dbo.CourseAssignment` | 8,008 |
| `dbo.Department` | 44 |
| `dbo.Enrollment` | 2,000,011 |
| `dbo.Notification` | 0 |
| `dbo.OfficeAssignment` | 2,003 |
| `dbo.Person` | 202,013 |

Compatibility level 110, full recovery model, `dbo.usp_SearchStudents`, `dbo.usp_GetStudentEnrollments` and `dbo.vw_EnrollmentStatistics` present. Data files 200 MB; the compressed full backup is 33 MB and took 1 second.

### Arc SQL migration assessment (requirement 12)

The owner selected **Run assessment** in the portal (**Database migration** > **Assess source instance**) at about 13:05. The API shows the result uploaded at **13:07:56**, so it took under 3 minutes on demand, and it was available 18 minutes after onboarding finished (12:49). Without the button, the first scheduled assessment runs on Sunday at 23:00 server time, and the docs warn a new instance's first one can take days. The owner started the MI link at about 13:09, without waiting to review the result: by the API it had already finished a minute earlier.

Result, saved in [evidence/arc-sql-assessment.json](evidence/arc-sql-assessment.json) (it holds no IDs):

| Target | Readiness | Recommendation |
|---|---|---|
| Azure SQL Managed Instance | **Ready**, 0 blockers; 1 warning: "Trace flags not supported in Azure SQL Managed Instance" for `1800` and `9567`, which MI link itself needs on the source (finding 9) | Next-gen General Purpose, Gen5, 4 vCores; predicted data 200 MB, log 136 MB |
| SQL Server on Azure VM | Ready, 0 blockers | `Standard_D2as_v4`, P2 data and log disks |
| Azure SQL Database | Not ready | Same trace flag warning |

The assessment's default settings price the targets in **West US**, with 3-year reserved instances and Azure Hybrid Benefit, not in the datacenter's region (finding 8).

### Replica check (requirement 21)

From `vm-dev01`, connected to the MI's private host name as the Entra admin (a VM run command with the owner's token), [scripts/fingerprint.sql](scripts/fingerprint.sql) returned the same row counts as the source for all 7 tables, compatibility level `110`, the three perf kit objects, and `READ_ONLY`. The link was `Secondary` on the MI, async, automatic seeding, single database, `LinkSynchronizing` and `HEALTHY`.

### Abort path (requirement 22)

**Cancel migration** removed the distributed availability group on both sides, without a failover. Afterwards:

- **Source untouched:** a fresh fingerprint matched the baseline, `READ_WRITE`, no availability group left on SQL Server, and the app returned HTTP 200 for `/Students` from `vm-dev01`.
- **The MI kept the database, now read-write:** `ContosoUniversity` stayed `ONLINE` on the MI and became `READ_WRITE`, a standalone copy that diverges from the source (finding 10). With owner approval, only that database was deleted (`az sql midb delete`, 13:32:06–13:32:26) before the link was recreated.

### Target MI

Deployed with [infra/main.bicep](infra/main.bicep) into `rg-spike-b07`. A **paid** General Purpose MI, not the free offer (owner decision, 2026-10-02):

| Setting | Value |
|---|---|
| Name | `sqlmi-university-<suffix>-b07` |
| SKU | General Purpose, Standard-series (Gen5), 4 vCores, 64 GB storage |
| Licence | `licenseType: 'BasePrice'`: Azure Hybrid Benefit on, which assumes eligible SQL Server licences with Software Assurance. Turn it off with `az sql mi update -g rg-spike-b07 -n <mi-name> --license-type LicenseIncluded` |
| Update policy | SQL Server 2022 (`databaseFormat: 'SQLServer2022'`), which a failback to SQL Server 2022 needs |
| Authentication | Entra-only, the owner as Entra admin |
| Network | `snet-sqlmi` `10.20.n.128/26` in `vnet-spike-mi` `10.20.n.0/24`, delegated to `Microsoft.Sql/managedInstances`, with `nsg-sqlmi` and `rt-sqlmi`; peered both ways with `vnet-datacenter`. Public endpoint off |
| Zones | No zone, zone redundancy off |
| Time zone | `W. Europe Standard Time` |
| Cost | About $0.68/hour (compute $0.67/hour with AHB, storage $0.14/GB-month, about $9/month for 64 GB), about $16/day. It bills from creation and **can't be stopped while the link is active**; stop it after cutover |

### MI link network rules

Only what MI link needs, from [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation) (checked 2026-10-02). `n` is the member index.

| Where | Direction | Protocol and ports | From | To |
|---|---|---|---|---|
| `nsg-sqlmi` | Inbound | TCP 5022, 11000–11999 | `10.10.n.4` (`vm-app01`) | `10.20.n.128/26` |
| `nsg-sqlmi` | Outbound | TCP 5022 | `10.20.n.128/26` | `10.10.n.4` |
| `nsg-servers` | Inbound | TCP 5022 | `10.20.n.128/26` | `10.10.n.4` |
| `nsg-servers` | Outbound | TCP 5022, 11000–11999 | `10.10.n.4` | `10.20.n.128/26` |
| Windows Firewall on `vm-app01` | Inbound | TCP 5022 | `10.20.n.128/26` | local |

Windows Firewall allows outbound traffic by default, so only the inbound rule is needed on `vm-app01`. The test also needs DNS resolution of the MI's private host name from `vm-app01`, which Azure DNS gave over the peering; through the hub, B08's DNS has to resolve it.

### `licenseType` on the MI (requirement 14)

`licenseType: 'BasePrice'` (Azure Hybrid Benefit) was accepted on the paid General Purpose MI at creation, and the live MI reports `BasePrice`. At list price that's $0.67/hour compute instead of the licence-included rate. Cost Management posts usage a day later, so the billed rate is checked in B09 (follow-up).

### Day 2 schedule

For a database of this size (200 MB), the link isn't the long pole:

| Step | Time in B07 |
|---|---|
| Create the link (portal, to `LinkSynchronizing`) | About 6–7 min |
| Seeding | Under 1 min |
| Abort (cancel), delete the MI copy, recreate and reseed | About 20 min, mostly the 6 minutes of link creation |
| Cutover to complete | About 2 min, then 4 min until the MI's first full backup |

So the link doesn't have to start early on Day 2 to overlap C6: starting it at the beginning of C7 leaves room for the curveball's abort and reseed inside C7. Start it earlier only if the dry run's database is much bigger. The MI itself takes minutes to provision here, but deploy it on Day 1 as planned (PRD §5), because provisioning time varies by region and capacity.

## What-if summaries

Every deployment ran `az deployment ... what-if` first and was checked: only B07-owned resources created or changed, nothing deleted, nothing in `rg-datacenter` changed except what the runbook prescribes, no zones or zone redundancy, no public endpoints.

| Deployment | What-if result | Checked |
|---|---|---|
| `infra/main.bicep` into `rg-spike-b07` (2026-10-02) | 11 creates, nothing modified or deleted. `rg-spike-b07`: `nsg-sqlmi` with the two MI link rules, `rt-sqlmi`, `vnet-spike-mi` with `snet-sqlmi` and its peering, and the MI (GP_Gen5, 4 vCores, 64 GB, `BasePrice`, `SQLServer2022`, zone redundancy off, public endpoint off, Entra-only, no `zones`). `rg-datacenter`: the peering `peer-datacenter-to-spike-mi` and the two MI link rules in `nsg-servers` | ✅ |
| `Deploy-Datacenter.ps1 -ScriptsRef <this branch>` (requirement 3, 2026-10-02) | 1 create (run command `app-07-arc-prep`); every run command modified (new script URL and run ID, which re-runs them); the rest no change or what-if noise: read-only and default properties, secure parameters. Two real side effects, owner-approved: `vm-dev01`'s system-assigned identity is removed (finding 2), and the MI link rules in `nsg-servers` are removed (finding 1). It also lists `vnet-datacenter`'s `virtualNetworkPeerings` as deleted; a test with two throwaway VNets in `rg-spike-b07` showed that a VNet redeploy without the property keeps the peering `Connected`, so that's noise | ✅ owner-approved |
| Delete and rebuild `vm-app01` with `Deploy-Datacenter.ps1` (requirement 10, 2026-10-02) | Creates `vm-app01`, `nic-vm-app01` and the eight `app-*` run commands (the disks come with the VM); no deletes; the rest the same noise as above | ✅ owner-approved |
| [infra/modules/datacenter.bicep](infra/modules/datacenter.bicep) into `rg-datacenter`, to re-apply the MI link rules after the rebuild (2026-10-02) | 2 creates (the `nsg-servers` rules); the peering "modify" only lists read-only properties. The full `main.bicep` wasn't re-run, because its what-if would PUT `nsg-sqlmi` and `rt-sqlmi` without the rules and routes the MI's network intent policy adds | ✅ |
| [infra/arc-source-prep.bicep](infra/arc-source-prep.bicep) into `rg-datacenter` (2026-10-02) | 1 create: the Arc run command `milink-source-prep` on the Arc machine `vm-app01` | ✅ |

## Timings

Times are UTC+2.

| Step | Time | Notes |
|---|---|---|
| MI provisioning (General Purpose, new subnet) | 7 min (11:42–11:49) | |
| Datacenter re-run with `-ScriptsRef` (requirement 3) | 9 min (11:47–11:56) | Places `C:\LabTools\arc\Prepare-ArcOnAzureVm.ps1` |
| Kit script, attempt 1 | Stopped after the prep (12:01–12:03) | Removing `MDE.Windows` took 35 s; staging the task 47 s. The task ran the prep, then failed (finding 4) |
| Delete and rebuild `vm-app01` | 12:26–12:41 | Owner-approved: VM, NIC and both disks deleted in 13 s; `Deploy-Datacenter.ps1` recreated `vm-app01` only in 13 min |
| Kit script, attempt 2 | 7.3 min (12:42–12:49) | Staging 1 min; **Connected** after 3 min; Arc SQL Server instance after 7 min. No VM extension to remove on the fresh VM |
| Source prep (Arc run command, Bicep) | 3 min (12:55–12:58) | Most of it is run command overhead; the script itself took 1 s |
| Two-way network test | 3 min (12:58–13:01) | |
| Arc migration assessment (**Run assessment**) | Under 3 min, uploaded 13:07:56 | 18 min after onboarding finished |
| Link 1: **Start data migration** to link visible on the MI | 13:09 to 13:14:45, about 6 min | The portal uploaded the SQL Server's endpoint certificate to the MI (`serverTrustCertificates/write`, 13:14:07–13:14:24), then created the distributed availability group (13:14:25–13:15:13) |
| Link 1: seeding | Under 1 min: database Online on the MI at 13:15:29 | 200 MB data, compressed seeding (`-T9567`). `LinkSynchronizing`, `HEALTHY`, lag 0 at 13:17 |
| Replica validation from `vm-dev01` | 13:18–13:20 | Identical (see [Replica check](#replica-check-requirement-21)) |
| Abort: **Cancel migration** to link gone | About 13:26 to 13:26:23 | Owner: "super straightforward". The pane's labels, and the status and lag before cancelling, weren't captured |
| Delete the leftover MI database (owner-approved) | 20 s (13:32:06–13:32:26) | |
| Link 2: **Start data migration** to link visible | About 13:40 to 13:45:38, about 6 min | Same flow, no warnings |
| Link 2: reseeding | Under 30 s: `LinkInitialSeeding` 13:45:38, `LinkSynchronizing` 13:46:03 | Replica re-validated, identical |
| Cutover: **Complete cutover** to complete | About 2 min (13:56–13:58); link gone at 13:58:03 | "Forced failover" was ticked; lag 0 and no traffic, no data loss (finding 13) |
| First full backup on the MI after failover | Finished 14:02:25, 4 min after cutover | Safe to restart or stop the MI from then on |

## Findings

1. **A datacenter redeploy wipes NSG rules that later items add.** `nsg-servers` lists its rules inline in B04's Bicep, so `Deploy-Datacenter.ps1` removes the MI link rules this spike adds as child `securityRules`. B07 re-applies them with [infra/main.bicep](infra/main.bicep) after every datacenter redeploy.
2. **A policy above the kit changes the VMs.** `vm-dev01` has a system-assigned managed identity and the Guest Configuration extension `AzurePolicyforWindows`, and `vm-app01` has `MDE.Windows` (Defender for Servers). None of them is in B04's template. The what-if for a datacenter redeploy lists `vm-dev01`'s identity as deleted, but after the re-run it was still `SystemAssigned`, so that's what-if noise (or the policy re-added it at once).
3. **The MI provisioned in 7 minutes** (11:42–11:49): a new General Purpose instance in a new subnet, with `licenseType: 'BasePrice'` accepted. Backup storage redundancy is the default, Geo, because the template doesn't set it.
4. **Kit script attempt 1 failed after the prep, from a bug in the staged task, now fixed.** `Connect-AppArc.ps1` called the prep script with `&` and then checked `$LASTEXITCODE`, which a script that succeeds without `exit` leaves `$null`, so the task stopped before installing the agent. It now runs the prep in its own `powershell.exe`. With the guest agent already off, run commands can't reach the VM any more, so the only ways forward from a half-done onboarding are Bastion or a rebuild: `vm-app01` was deleted and rebuilt (owner-approved), and the fixed script ran again.
5. **The MI is reachable from `vm-dev01` with an Entra token.** A VM run command on `vm-dev01` ([scripts/Invoke-MiQuery.ps1](scripts/Invoke-MiQuery.ps1)) connected to the MI's private host name over the peering as the Entra admin, with the caller's token for `https://database.windows.net/` as a protected parameter, and read the MI's HADR port (`11002`, inside 11000–11999).
6. **Defender for Cloud follows `vm-app01` into Arc.** On the Arc machine it added `MicrosoftDefenderForSQL` and `MDE.Windows` within minutes, and it also re-added `MDE.Windows` to the Azure VM, where it stays in `Creating` because the guest agent is off. It's the subscription's Defender plan, outside the kit; attendee subscriptions on Foundational CSPM only (PRD §6) won't see it.
7. **Run commands on an Arc machine work as IaC.** `Microsoft.HybridCompute/machines/runCommands` (API `2025-01-13`) deploys from Bicep with `loadTextContent` and parameters, like a VM run command, so the MI link prep after onboarding needs no Bastion session. Each one takes 1–3 minutes of overhead.
8. **The Arc migration assessment prices targets in West US by default.** Its settings (`targetLocation: West US`, 3-year RI, AHB on) aren't the member's region, so its monthly cost (MI compute about $490 list, $220 with 3-year RI) isn't the swedencentral price. Attendees change it under **Assessment settings**. ARM has no action to start an assessment (only `getMigrationReadinessReport`, which rejected an empty body), so **Run assessment** stays a portal click.
9. **The assessment's only warning is self-inflicted: "Trace flags not supported in Azure SQL Managed Instance"** (owner, 2026-10-02), for trace flags `1800` and `9567`. B04 sets them on the source for MI link ([Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation): `1800` for disks with different sector sizes, `9567` to compress automatic seeding). They're source-side only, aren't needed on the MI and don't block the migration. Remove them from the source after the link is removed ([migration.md](migration.md#6-cut-over), step 6). B11's C3 has attendees triage it.
10. **Cancelling the migration leaves a read-write copy on the MI.** After **Cancel migration**, `ContosoUniversity` stays on the MI, `ONLINE` and `READ_WRITE`, and no longer receives changes. For the Day 2 curveball this means: the app must stay pointed at the source, nobody should write to the MI copy, and the copy has to be deleted (`az sql midb delete`) before the link is recreated.
11. **Certificates are handled for you.** Before creating the link, the portal uploaded SQL Server's endpoint certificate to the MI as a server trust certificate, and the extension created the source's endpoint certificate `Cert_vm-app01_endpoint` (valid one year) and the mirroring endpoint on 5022. The only manual certificate step is importing the Azure root CAs on the source so it trusts the MI's certificate, which the kit's source prep does.
12. **The portal's cutover has no "keep the link" choice.** **Monitor and cutover** (toolbar: **Complete cutover**, **Cancel migration**, **Delete migration**, **View logs**, **Refresh**) opens a **Complete cutover** pane that fails `ContosoUniversity` over to the MI "once the lag becomes 0 seconds". It has two checkboxes: "I confirm that I have stopped all incoming traffic to the source database" and "I want to do a forced failover" (with "If lag is more than 0, a forced failover may lead to data loss"). The SQL Server 2022 option to keep the link for a reverse migration, which the docs describe, isn't offered (owner's screenshot, 13:55).
13. **The cutover ran as a forced failover, and nothing was lost.** The owner ticked "I want to do a forced failover". With lag 0 and no traffic, row counts, maximum identities and `CHECKSUM_AGG(BINARY_CHECKSUM(*))` matched on all 7 tables afterwards. The portal then removed the link: on the MI, `ContosoUniversity` is `ONLINE`, `READ_WRITE` and primary, with no availability group. Attendees should leave forced failover unticked and cut over only at lag 0.
14. **After cutover the source stays writable.** On `vm-app01`, `ContosoUniversity` is still `ONLINE` and `READ_WRITE`, with no availability group: two writable copies. Until the app moves to the MI, writes to the source are lost to the migration, so the cutover runbook has to stop the app (and the source database, or set it read-only) first.

## Decisions

- **Paid MI, not the free offer** (owner, 2026-10-02). A regular General Purpose MI with Azure Hybrid Benefit replaces the SQL MI free offer in B07. Changes [B07](../../backlog/B07-spike-arc-mi-link.md) (Cost, Outcome, Before you start, requirements 13, 14, 24 and 25, Stop and ask if, Notes and traps); the PRD, roadmap, B09, B10 and the backlog README change in a separate PR.
- **Arc onboarding is automated only** (owner, 2026-10-02): lab provisioning, policy deployment and teardowns use IaC and the kit's scripts, never manual steps or agents. `scripts/Connect-DatacenterArc.ps1` is the only onboarding path, and [onboarding-portal.md](onboarding-portal.md) is its attendee page. Changes B07's Outcome, requirements 4, 5, 10 and 26, and Done when. The DB migration (assessment, MI link) stays the Arc portal path the runbook prescribes.
- **Failback not attempted** (owner, 2026-10-02, requirement 24, a bonus). The Arc portal has no reverse migration. A failback needs a new link from the MI to SQL Server 2022, set up in SSMS or with T-SQL and `az sql mi link`, and deleting the source database first, so it can seed. The kit's rollback is the abort before cutover, which worked (requirement 22). The MI's SQL Server 2022 update policy is what a failback would need.

## Evidence

- [evidence/arc-sql-assessment.json](evidence/arc-sql-assessment.json): the Arc SQL migration assessment, from the Arc SQL Server instance's `migration.assessment` property (no IDs).
- [evidence/replica-and-cutover-checks.md](evidence/replica-and-cutover-checks.md): the source baseline, the replica checks, the state after the abort and the post-cutover comparison.
- The run command outputs quoted in this report, with host names and IPs replaced by placeholders. The owner's screenshot of the cutover pane isn't committed, because it shows IDs.

## Follow-ups

- **B08: MI link through the hub.** Move the rules in [MI link network rules](#mi-link-network-rules) to the hub firewall: from `10.10.n.4` to the MI subnet `10.20.n.128/26` on TCP 5022 and 11000–11999, and from the MI subnet to `10.10.n.4` on TCP 5022. Keep the NSG rules, and the Windows Firewall rule on `vm-app01`. Make sure `vm-app01` resolves the MI's private host name through the hub's DNS. Re-run the two-way test ([scripts/Test-MiLinkNetwork.ps1](scripts/Test-MiLinkNetwork.ps1) and the `NetHelper` job), because a one-way test can pass while the link fails.
- **B09: MI settings validated here.** General Purpose, Gen5, 4 vCores, 64 GB; `licenseType: 'BasePrice'` accepted (check the billed rate in Cost Management); `databaseFormat: 'SQLServer2022'`; Entra-only with the deployer as admin; public endpoint off; zone redundancy off; time zone `W. Europe Standard Time`; API `Microsoft.Sql/managedInstances@2025-01-01`. Provisioning took 7 minutes. Leave the MI's NSG and route table rules and routes out of the Bicep: the MI's network intent policy adds them, and a re-deploy that lists them inline fights it. App identities' database users can only be created after cutover (the replica is read-only).
- **B08 and B11: NSG rules added after the datacenter** (finding 1). Move `nsg-servers`' rules to child `securityRules` in B04, or add the MI link rules to B04, so a datacenter redeploy keeps them. B08 moves the MI link rules to the hub firewall anyway.
- **B04 or B11: the policy-added identity and extensions** (finding 2). Declare a system-assigned identity on the datacenter VMs in B04, or document that a policy outside the kit may add it and the Guest Configuration and MDE extensions.
- **B09: MI backup redundancy** (finding 3). Decide `requestedBackupStorageRedundancy` (the kit's storage convention is LRS; the default is Geo).
- **B11 (C7): the abort leaves a writable copy on the MI** (finding 10). The attendee page must say to delete the MI copy (or at least never use it) before retrying the link, and never to point the app at it.
- **B11 (C3): the trace flag warning** (finding 9). Attendees triage "Trace flags not supported in Azure SQL Managed Instance" as expected and remove `-T1800` and `-T9567` from the source after cutover (owner added it to B11's C3).
- **B11 (C0) and B12: the assessment's region** (finding 8). Tell attendees to set **Assessment settings** to their region before reading the cost estimate.
- **B11 (C7): the cutover pane** (findings 12–14). Leave "I want to do a forced failover" unticked unless the portal requires it, and cut over only at lag 0. Stop the app and writes to the source first, because the source stays writable after cutover. There's no "keep the link" option in the portal.
- **B11 (C0 and C7): content.** C0 is [onboarding-portal.md](onboarding-portal.md) (the one script, checks, troubleshooting); C7 is [migration.md](migration.md), with the kit's prep (source prep Bicep, two-way test) before the portal steps, and the Day 2 timings above for the time box.
