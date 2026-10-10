# C7 answer key: Migrate and go live

> [!WARNING]
> Coach material. This page has the answers to C7. Attendees run the MI link migration and go-live themselves, following the Arc portal flow.

The cutover mechanism is the one detail worth double-checking: the validated path is the Arc portal's pane, not a CLI command issued from the managed instance.

## Before the team starts

- **Graph grant.** The platform lead and a Privileged Role Administrator ran `Grant-SqlMiDirectoryRead.ps1` in C2 on Day 1. On Day 2 at 08:30 confirm it: `./scripts/Grant-SqlMiDirectoryRead.ps1 -SharedSubscriptionId $s.sharedSubscriptionId -WhatIf` prints that the permissions are already granted. If it wasn't done, the contained user in task 4 fails with "Server identity does not have Azure Active Directory Readers permission". That is the most likely stuck point for a whole team; get the Privileged Role Administrator to run the script, then retry.
- **Both VMs running.** `vm-app01` must be up (it holds the source), and `vm-dev01` stays running all event.
- **Link started at 08:30.** The members start the link as C7 task 1, so seeding overlaps the end of C6. The time counts toward C7's 120 minutes.

## Maintenance window

At go/no-go agree a short window with each member (the page says so in task 3) and check it before they cut over:

1. Nothing on `vm-dev01` writes to the source (modernized app stopped, no `Reset-PerfKit.ps1`).
2. On `vm-app01`, the site and the `ContosoUniversity` pool show `Stopped` and the session count is 0.
3. The **Lag** column in the Arc portal shows two dashes.

Only then do they select **Complete cutover**. A write after the last lag reading is lost, because the source stays writable.

## Day 2 curveball

The [curveball](../facilitator/curveballs.md) fails the replica go/no-go for **one member per team**, picked by the coach, so the rest of the team keeps its pace. Don't corrupt the source database. That member records the failed check, marks no-go, cancels the migration, deletes the MI copy, writes the reseed plan (cap 15 minutes) and restarts the link. They use the new seeding wait for the runbook and finish C7, C8 and C9 after their cutover; rows that need a completed cutover (live pages, contained user) score only once they finish it.

## Expected evidence

- Arc portal migration status: link created, seeded (status **Ready for cutover**), replica validated, cutover complete. The portal removes the link on cutover.
- The maintenance-window output from `vm-app01`: site and pool `Stopped`, `Sessions: 0`, and the lag at no lag (two dashes) just before the cutover.
- The live app at `https://app-university-<suffix>.azurewebsites.net/` showing the migrated data on all five pages.
- The contained database user created with a plain `CREATE USER [<identity-name>] FROM EXTERNAL PROVIDER;` (no `WITH SID`, no `TYPE = E` — both are SQL MI-unsupported syntax from on-premises habits) and granted `db_datareader`, `db_datawriter`, `db_ddladmin`.
- The source's trace flags (`-T1800`, `-T9567`) removed after cutover (empty `DBCC TRACESTATUS` output).
- The cutover and rollback runbook, filled in from what actually happened.

## Model answer

1. Arc portal > SQL Server on `vm-app01` > **Migration** > **Database migration** > **Migrate data** > **Migrate using real-time replication (online)**; wait for seeding to finish and the status to show **Ready for cutover**.
2. Validate: row counts per table match source vs. replica; spot-check a few `Students`/`Courses`/`Enrollment` rows.
3. Go/no-go: stop the app's writes to the source (the source stays technically writable, so this is a procedural stop, not a technical one). Confirm the **Lag** column shows two dashes. Cut over via **Monitor and cutover > Complete cutover** (Learn calls it **Cutover**), ticking the box that confirms traffic is stopped and leaving forced failover unticked (it's for when lag isn't truly zero — ticking it with lag 0 adds risk for no benefit).
4. After cutover: write the Key Vault secret `ConnectionStrings--DefaultConnection` with a normal managed instance connection string using `Authentication=Active Directory Default`, no user name or password. Create the contained user and grant roles.
5. Point the web app's container config at the C6 image; restart; confirm the five pages, an upload round-trip, a notification round-trip, and Application Insights telemetry.
6. Remove `-T1800 -T9567` from the source SQL Server's startup parameters (SQL Server Configuration Manager > the SQL Server service > Properties > **Startup Parameters**) and restart the SQL Server service (not the VM) to apply.
7. Fill in the cutover/rollback runbook template with the actual sequence, including anything that needed a retry.

## Common mistakes

- Ticking "forced failover" by habit — this is only for when you can't confirm zero lag. With a validated, zero-lag replica, it adds risk without a benefit.
- Running `az sql mi link failover --failover-type Planned` from the CLI, expecting it to behave like the portal's cutover — this fails with `DistributedAvailabilityGroupFailoverInvalidInstanceRole`, since the MI is the secondary. The equivalent CLI-adjacent path, if ever needed outside the portal, is `ALTER AVAILABILITY GROUP [<DAG>] FAILOVER` run against SQL Server itself (2022 CU13+) — not from the MI side, and not needed for this kit's validated flow at all.
- Creating the contained user before cutover completes — it fails, because the replica is read-only until then. This is expected; retry after cutover, not a sign of a broken link.
- Using `CREATE USER ... WITH SID = ...` or `TYPE = E` syntax carried over from on-premises Windows-auth habits — SQL MI's contained user syntax is simpler; the extra clauses cause an error.
- Forgetting to remove the trace flags from the source after cutover — small, but it's a deferred-work register item from C3/C4 that needs closing here.

## Partial credit

- Migration and go-live complete, trace-flag removal forgotten: partial credit, have the member close it out before C8.
- Cutover complete but the runbook written generically instead of from what actually happened (no mention of lag check, no mention of the forced-failover decision): partial credit, ask for a rewrite with specifics.

## Bonus

A real, unplanned abort-and-reseed, with the cleanup of the leftover writable copy documented, is worth up to 5 bonus points. The curveball's staged abort earns no bonus: it's part of the event. Don't manufacture a fault for anyone just to claim the bonus.

## Reset

If the link needs to be redone: in the Arc portal, **Monitor and cutover** > select the database > **Cancel migration**, then delete the partially migrated database on the MI (an aborted or failed link leaves a writable copy behind) with `az sql midb delete --resource-group <rg> --managed-instance <mi-name> --name ContosoUniversity --yes`, and restart the link migration from the Arc portal. Budget 20 to 30 minutes for a reseed, validation and a second window.
