---
title: "C8: Validate the pattern"
description: Run the acceptance pack against the live, migrated app.
---

## Goal

Prove the modernized app is actually healthy in production, with a fixed, repeatable acceptance pack — not a demo click-through.

## Scope and time box

Member. **45 min**.

## Points

**10 pts** (member).

## Inputs

C7's app, live on App Service against SQL MI.

## Your tasks

1. Run the smoke checks: the five pages (home, Students, Courses, Instructors, Departments) load and show migrated data.
2. Run the upload round-trip over a private endpoint: upload a teaching-material image on **Courses > Edit**, confirm it shows on the course and lands in `teaching-materials`, then replace and delete it. Confirm a non-image and an over-size file are rejected.
3. Run the notification round-trip over a private endpoint: edit a student, confirm a toast appears within 5 seconds, and that `/Notifications/GetNotifications` returns success.
4. Run a basic load check: a handful of concurrent page loads against the live app, enough to prove it doesn't fall over under light traffic (this isn't C9's performance work — keep it light).
5. Run a security check: confirm every backend (SQL MI, Blob, Service Bus, Key Vault, ACR) has public network access disabled, and that the web app is HTTPS-only with TLS 1.2 minimum.
6. Record every result against the acceptance pack — pass, fail, or not applicable, with the evidence for each.

## Evidence

- A filled-in [acceptance and handover](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md) document: every check, its result and its evidence.
- Telemetry (requests, dependencies) from this session's checks visible in Application Insights.
- Public network access confirmed off for every backend, with the command or portal view used.

## Hints

<details>
<summary>What counts as "enough" load for the load check?</summary>

A handful of concurrent requests — ten to twenty page loads in a short burst is enough to show the app doesn't error under light concurrency. This isn't a performance benchmark; that's C9's job on the database.
</details>

<details>
<summary>How do I confirm public network access is off without a portal tour of every resource?</summary>

`az resource show --ids <resource id> --query properties.publicNetworkAccess` works for most of these resources; SQL MI uses `az sql mi show --query publicDataEndpointEnabled`.
</details>

## Lifeline

Ask your coach if a specific acceptance check keeps failing for a reason you can't diagnose after one pass through the hints above. Using the lifeline caps C8 at partial credit.

## Bonus

Up to 5 pts for finding and documenting a real gap the acceptance pack doesn't already cover (for example, a missing diagnostic setting).

## Learn more

- [Monitor Azure App Service](https://learn.microsoft.com/azure/app-service/monitor-app-service)
- [Private endpoints for Azure Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints)
