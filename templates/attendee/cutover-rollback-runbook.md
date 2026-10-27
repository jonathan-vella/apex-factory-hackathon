# Cutover and rollback runbook

<!--
Fill this in from what you actually did in C7, not from a plan written in advance. If you had to roll back or abort, record that too — it's as valuable as a clean run.
-->

## Pre-cutover state

<!-- Link seeded? Replica validated? What you checked before deciding to proceed. -->

## Go/no-go decision

<!-- What you confirmed before cutting over: every writer to the source stopped (site and pool `ContosoUniversity` on vm-app01, any local app on vm-dev01), no remaining database sessions, no replication lag (two dashes in the Lag column), replica validation passed. Paste the command output. -->

## Cutover steps taken

<!-- The actual steps you ran, in order, including the Arc portal pane and whether you ticked or cleared the forced-failover checkbox, and why. -->

## Post-cutover validation

<!-- What you checked immediately after cutover: the database reads READ_WRITE on the managed instance, app connectivity, data presence, contained user creation. -->

## Rollback path (if needed)

<!-- If you had to abort or roll back: what you did, and what state you had to clean up before retrying (e.g. deleting a partially seeded database on the MI). -->

## Follow-up actions

<!-- Anything still open after cutover, such as the web app's first start on App Service or anything you deferred (the trace flags are removed in C7 requirement 7; record them here only if you left them). -->
