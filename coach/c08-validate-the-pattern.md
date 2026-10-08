# C8 answer key: Validate the pattern

> [!WARNING]
> Coach material. This page has the answers to C8. Attendees run the acceptance pack themselves against the live, migrated app.

C8 is a fixed checklist, so grading is mostly about completeness and evidence quality, not judgment calls.

## Expected evidence

- Smoke checks: all five pages (home, Students, Courses, Instructors, Departments) load with migrated data.
- Upload round-trip: an image uploaded on **Courses > Edit** shows on the course and lands in `teaching-materials`; replace and delete both work; a non-image and an over-size file are both rejected with a clear error, not a 500.
- Notification round-trip: a toast within 5 seconds of a student edit, and `/Notifications/GetNotifications` returning success.
- A light load check (10–20 concurrent page loads) with no errors.
- Security check: public network access disabled on SQL MI, Blob, Service Bus, Key Vault and ACR; web app HTTPS-only with TLS 1.2 minimum.
- Application Insights showing requests and dependencies from this session's checks.

## Model answer

Commands useful for the security check:

```powershell
az sql mi show --name <mi-name> --resource-group <rg> --query publicDataEndpointEnabled
az storage account show --name <storage-name> --query publicNetworkAccess
az servicebus namespace show --name <sb-name> --resource-group <rg> --query publicNetworkAccess
az keyvault show --name <kv-name> --query properties.publicNetworkAccess
az acr show --name <acr-name> --query publicNetworkAccess
az webapp show --name <app-name> --resource-group <rg> --query "{httpsOnly:httpsOnly, minTlsVersion:siteConfig.minTlsVersion}"
```

All of the above should report disabled/`Disabled`/`false` for public access, and `httpsOnly: true`, `minTlsVersion: '1.2'` for the web app.

## Common mistakes

- Running the load check against `vm-dev01`'s local copy instead of the live App Service URL — the acceptance pack is specifically about production health, not the dev loop.
- Treating the load check as a performance benchmark and spending disproportionate time on it — it's a light smoke test; C9 is where performance work actually happens, and on the database, not the app tier.
- Skipping the rejection cases (non-image, over-size file) in the upload round-trip — a working happy path doesn't prove the validation logic exists.
- Checking public network access on four of five backends and forgetting ACR — it's easy to overlook since it isn't part of a data round-trip test.

## Partial credit

- All data-path checks (smoke, upload, notification) pass but the security check is incomplete: partial credit, finish the security check before moving to C9 — it's quick.
- Telemetry not visible in Application Insights yet (ingestion lag): accept with a note to re-check in a few minutes; don't block on it.

## Bonus

A real, documented gap the acceptance pack doesn't cover (for example, missing diagnostic settings on a backend) is worth up to 5 bonus points — prefer specific, actionable gaps over generic "could be more thorough" comments.

## Reset

Not applicable — C8 only reads the live app's state; nothing to reset.
