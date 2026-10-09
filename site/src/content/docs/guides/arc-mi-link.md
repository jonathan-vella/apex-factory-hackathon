---
title: Azure Arc and the MI link
description: Onboarding, assessment, seeding, go/no-go and cutover.
---

This guide covers the mechanics of the Arc-based SQL Managed Instance link migration. [C7](../../challenges/c07-migrate-and-go-live/) is the what and the acceptance bar; [C3](../../challenges/c03-assess-the-source/) covers assessment triage.

## Onboarding

`vm-app01`'s SQL Server instance is onboarded to Azure Arc by `scripts/Connect-DatacenterArc.ps1` during C0 — unattended, with no manual portal walkthrough. This is the kit's only onboarding path; there's no alternative flow to fall back to if it fails (check outbound connectivity to Arc's endpoints first).

## Assessment

Once onboarded, the Arc resource can run a migration assessment against the SQL Server instance. It reports readiness findings, including the expected trace-flag warning for `1800` and `9567` — see C3 for how to triage it, rather than repeating that here.

## Seeding the link

From the Arc portal, start a managed instance link migration targeting your deployed SQL Managed Instance. Seeding copies the database and then keeps a continuous log-shipping replica in sync — this can take a while depending on database size; the perf kit's data (200k students, 2M enrollments, around 120 MB) seeds quickly.

## Validating the replica

The replica is read-only while the link is active. Spot-check row counts and a few representative queries against the source before you trust it enough to cut over. If something looks wrong, abort the link and reseed rather than cutting over on an unverified replica.

## Go/no-go and cutover

Stop writes to the source first — the source stays writable even after cutover completes, so sequencing matters. Wait for replication lag to reach zero, then use the Arc portal's **Monitor and cutover > Complete cutover** pane. Two checkboxes appear: confirming you've stopped incoming traffic, and an optional forced failover. Leave forced failover unticked when lag is genuinely zero; it's meant for emergency cutovers where some data loss is accepted, which shouldn't be your case if you've waited for lag to reach zero.

After cutover, the link is removed and the managed instance becomes the sole copy of the database.

## After cutover

Create the contained database user for the web app's managed identity (`CREATE USER [...] FROM EXTERNAL PROVIDER`, with role memberships — not `WITH SID` or `TYPE = E`, which SQL MI doesn't support). This only works once the replica is writable, i.e. after cutover, not before.

Remove the `1800` and `9567` trace flags from the source now that the link no longer needs them — this closes out the deferred item from C3's trace-flag finding.

## If the abort path is needed

Aborting a link leaves a (partial) writable copy of the database on the managed instance. Delete it before reseeding, or the next seed attempt fails.
