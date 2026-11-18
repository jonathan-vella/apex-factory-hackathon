# Cutover and rollback runbook

<!--
Fill this in from what you actually did in C7. Keep it concise.
-->

## Pre-cutover checklist

- [ ] Link seeded and replica validation passed
- [ ] Source writers stopped (site and pool `ContosoUniversity` on `vm-app01`, any local app on `vm-dev01`)
- [ ] No active user sessions on source database
- [ ] Replication lag reads `--` (caught up)

## Cutover summary

- Cutover mode used (planned vs forced failover) and why:
- Post-cutover checks (`READ_WRITE` on SQL MI, contained user created, App Service HTTP 200):
- Startup trace flags `-T1800` and `-T9567` removed on `vm-app01` (`Prepare-MiLinkSource.ps1 -RemoveTraceFlags`):

## Rollback and customer recovery notes

<!-- Rollback after cutover is not exercised at this event. Note any pre-cutover abort/reseed you performed, and state the post-cutover customer recovery procedure (restore from backup or planned failback with data reconciliation and an accountable owner; never restart the stale source after MI accepts writes). -->
