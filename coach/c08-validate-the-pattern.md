# C8 answer key: Validate the pattern

> [!WARNING]
> Coach material. This page has the answers to C8. Attendees run the acceptance pack themselves against the live, migrated app.

C8 is a fixed checklist, so grading is mostly about completeness and evidence quality, not judgment calls.

## Expected evidence

- Smoke checks: all five pages (home, Students, Courses, Instructors, Departments) load with migrated data, and the row counts on the source and on the managed instance match.
- Upload round-trip: an image uploaded on **Courses > Edit** shows on the course and lands in `teaching-materials` (checked with `az storage blob list` on `vm-dev01`: the storage account is private-only); replace and delete both work; a non-image and a file over 5 MB are both rejected with a clear error, not a 500.
- Notification round-trip: a toast within 5 seconds of a student edit, and `/Notifications/GetNotifications` returning success.
- A light load check (10–20 concurrent page loads) with no errors.
- Security check: `scripts/Test-Acceptance.ps1` output (or `acceptance.json`) ending in `ACCEPT`: the five pages and the HTTP-to-HTTPS redirect, web app HTTPS-only with TLS 1.2 minimum, and public network access off with an approved private endpoint on Storage, Service Bus, Key Vault and ACR, plus SQL MI's public data endpoint off.
- Application Insights **Transaction search** (last 30 minutes) showing requests and dependencies from this session's checks.
- A filled-in acceptance and handover document with the member index.

## Model answer

The member runs the read-only checker from the dev container, in `factory/`:

```powershell
./scripts/Test-Acceptance.ps1 -SubscriptionId $s.subscriptionId -ResourceGroup $rg -OutFile .local/acceptance.json
```

A clean run has no FAIL and no UNKNOWN, and ends with `ACCEPT`. A FAIL names the setting to change. An UNKNOWN means the check couldn't decide, for example a resource in another resource group or an account that can't read it: the member explains it with the portal view that settles it (the resource's **Networking** > **Private endpoint connections**, with an **Approved** connection). The checker doesn't replace the browser flows or the row-count comparison.

To check one setting by hand:

```powershell
az sql mi show --resource-group $rg --name <mi-name> --query publicDataEndpointEnabled
az storage account show --resource-group $rg --name <storage-name> --query publicNetworkAccess
az servicebus namespace show --resource-group $rg --name <sb-name> --query publicNetworkAccess
az keyvault show --resource-group $rg --name <kv-name> --query properties.publicNetworkAccess
az acr show --resource-group $rg --name <acr-name> --query publicNetworkAccess
az webapp show --resource-group $rg --name <app-name> --query httpsOnly
az webapp config show --resource-group $rg --name <app-name> --query minTlsVersion
```

All of the above should report disabled/`Disabled`/`false` for public access, `true` for `httpsOnly` and `1.2` for the minimum TLS version. The checker's own commands are `az webapp show` for `httpsOnly` and `az webapp config show` for the TLS version.

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
