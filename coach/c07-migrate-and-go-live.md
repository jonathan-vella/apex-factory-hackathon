# C7 answer key: Migrate and go live (coach)

> [!WARNING]
> Coach material. This page has the answers to C7. Attendees run the MI link migration and go-live themselves, following the Arc portal flow.

The cutover mechanism is the one detail worth double-checking: the validated path is the Arc portal's pane, not a CLI command issued from the managed instance.

## Before the team starts

- **Graph grant.** The team lead and a Privileged Role Administrator ran `Grant-SqlMiDirectoryRead.ps1` at Step 2 (T-7). On Day 2 at 08:30 confirm it again. You don't have `$s.sharedSubscriptionId` (it's in the team lead's settings), so the team lead (or the Privileged Role Administrator, signed in as themselves) runs `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -WhatIf` while you watch: it prints that the permissions are already granted. Whoever runs it needs Reader on the shared services subscription (or on `rg-management`) to read the identity. If the grant wasn't done, the contained user in requirement 5 fails with "Server identity does not have Azure Active Directory Readers permission". That is the most likely stuck point for a whole team; get the Privileged Role Administrator to run the script, then retry.
- **Both VMs running.** `vm-app01` must be up (it holds the source), and `vm-dev01` stays running all event.
- **Link started at 08:30.** The members start the link in C7 requirements 1 and 2 (prepare the source, then start the link), so seeding overlaps the end of C6. Requirements 1 and 2 count toward C7's 120 minutes, but the wait of up to 10 minutes while the link is created overlaps C6 and doesn't count.

## Maintenance window

At go/no-go agree a short window with each member (the page says so in requirement 4) and check it before they cut over:

1. Nothing on `vm-dev01` writes to the source (modernized app stopped, no `Reset-PerfKit.ps1`).
2. On `vm-app01`, the site and the `ContosoUniversity` pool show `Stopped` and the session count is 0.
3. The **Lag** column in the Arc portal shows two dashes.

Only then do they select **Cutover** (some portal builds label the button **Complete cutover**; it's the same action). A write after the last lag reading is lost, because the source stays writable.

## Day 2 curveball

The exercise in **Curveballs** in the Coach sidebar fails the replica go/no-go for **one member per team**, picked by the coach, so the rest of the team keeps its pace. Don't corrupt the source database. That member records the failed check, marks no-go, cancels the migration, deletes the MI copy, writes the reseed plan (cap 15 minutes) and restarts the link. They use the new seeding wait for the runbook and finish C7, C8 and C9 after their cutover.

## Expected evidence

**Timing cues:** early link setup counts toward the 120-minute effort; about 100 minutes remain at 10:30. At the midpoint, expect read-only replica checks or an explicit no-go. Reserve the final 20 minutes for go-live checks and the runbook; never cut over to meet the clock.

- Arc portal migration status: link created, seeded (status **Ready for cutover**), replica validated, cutover complete. The portal removes the link on cutover.
- The maintenance-window output from `vm-app01`: site and pool `Stopped`, `Sessions: 0`, and the lag at no lag (two dashes) just before the cutover.
- The live app at `https://app-university-<suffix>.azurewebsites.net/` returning HTTP 200 (full acceptance checks follow in C8).
- The contained database user created with a plain `CREATE USER [<identity-name>] FROM EXTERNAL PROVIDER;` (no `WITH SID`, no `TYPE = E` — both are SQL MI-unsupported syntax from on-premises habits) and granted `db_datareader`, `db_datawriter`, `db_ddladmin`.
- The source's trace flags (`-T1800`, `-T9567`) removed after cutover (`C:\LabTools\Prepare-MiLinkSource.ps1 -RemoveTraceFlags`).
- The concise cutover and rollback runbook (`factory/evidence/c07/cutover-rollback-runbook.md`), filled in from what actually happened. Post-cutover rollback is not exercised: record pre-cutover abort/reseed and name the customer backup-restore or planned-failback procedure with data reconciliation. Never send new MI writes back to the stale source by simply restarting IIS.

## Model answer

The steps use the attendee page's requirement numbers.

1. Requirement 1: on `vm-app01`, through Bastion, run `Prepare-MiLinkSource.ps1 -MiSubnetPrefix ...` until it prints `The source is ready for MI link.`
2. Requirement 2: Arc portal > SQL Server on `vm-app01` > **Migration** > **Database migration** > **Migrate data** > **Migrate using real-time replication (online)**; wait for seeding to finish and the status to show **Ready for cutover**.
3. Requirement 3: validate: row counts per table match source vs. replica; spot-check `Department` and `Course` checksums.
4. Requirement 4: go/no-go: stop the app's writes to the source (the source stays technically writable, so this is a procedural stop, not a technical one). Confirm the **Lag** column shows two dashes. Cut over via **Monitor and cutover > Cutover** (some portal builds label it **Complete cutover**), ticking the box that confirms traffic is stopped and leaving forced failover unticked.
5. Requirement 5: after cutover, write the Key Vault secret `ConnectionStrings--DefaultConnection` with a normal managed instance connection string using `Authentication=Active Directory Default`, no user name or password. Create the contained user and grant roles.
6. Requirement 6: point the web app's container config at the C6 image; restart; confirm `https://app-university-<suffix>.azurewebsites.net/` returns HTTP 200.
7. Requirement 7: run `C:\LabTools\Prepare-MiLinkSource.ps1 -RemoveTraceFlags` on `vm-app01` in Administrator Windows PowerShell, which removes `-T1800` and `-T9567`, restarts `MSSQLSERVER`, and verifies with `DBCC TRACESTATUS(-1)` that both flags are off.
8. Requirement 8: fill in `factory/evidence/c07/cutover-rollback-runbook.md` and commit on `main`.

## Business outcome check

The outcome is safe, repeatable change. Read `cutover-rollback-runbook.md` as Marcus would: it states when the stop starts, how long it lasted and how to recover.

## Common mistakes

- Ticking "forced failover" by habit — this is only for when you can't confirm zero lag. With a validated, zero-lag replica, it adds risk without a benefit.
- Running `az sql mi link failover --failover-type Planned` from the CLI, expecting it to behave like the portal's cutover — this fails with `DistributedAvailabilityGroupFailoverInvalidInstanceRole`, since the MI is the secondary.
- Creating the contained user before cutover completes — it fails, because the replica is read-only until then. This is expected; retry after cutover, not a sign of a broken link.
- Using `CREATE USER ... WITH SID = ...` or `TYPE = E` syntax carried over from on-premises Windows-auth habits — SQL MI's contained user syntax is simpler; the extra clauses cause an error.
- Forgetting to run `Prepare-MiLinkSource.ps1 -RemoveTraceFlags` on the source after cutover.

## Reset

If the link needs to be redone: in the Arc portal, **Monitor and cutover** > select the database > **Cancel migration**, then delete the partially migrated database on the MI (an aborted or failed link leaves a writable copy behind) with `az sql midb delete --resource-group <rg> --managed-instance <mi-name> --name ContosoUniversity --yes`, and restart the link migration from the Arc portal. Budget 20 to 30 minutes for a reseed, validation and a second window.
