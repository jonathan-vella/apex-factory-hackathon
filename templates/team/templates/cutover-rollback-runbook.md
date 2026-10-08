# Cutover and rollback runbook

<!--
Fill this in from what you actually did in C7, not from a plan written in advance. If you had to roll back or abort, record that too — it's as valuable as a clean run.
-->

## Pre-cutover state

<!-- Link seeded? Replica validated? What you checked before deciding to proceed. -->

## Go/no-go decision

<!-- What you confirmed before cutting over: replication lag, source writes stopped, replica validation passed. -->

## Cutover steps taken

<!-- The actual steps you ran, in order, including the Arc portal pane and whether you ticked or left unticked the forced-failover checkbox, and why. -->

## Post-cutover validation

<!-- What you checked immediately after cutover: app connectivity, data presence, contained user creation. -->

## Rollback path (if needed)

<!-- If you had to abort or roll back: what you did, and what state you had to clean up before retrying (e.g. deleting a partially seeded database on the MI). -->

## Follow-up actions

<!-- Anything still open after cutover — e.g. removing trace flags from the source, pointing the web app at the modernized image. -->
