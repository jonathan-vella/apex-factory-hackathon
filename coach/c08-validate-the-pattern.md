# C8 answer key: Validate the pattern (coach)

> [!WARNING]
> Coach material. This page has the answers to C8. Attendees run the acceptance pack themselves against the live, migrated app.

C8 is a fixed checklist, so grading is mostly about completeness and evidence quality, not judgment calls.

## Expected evidence

**Timing cues:** by 20 minutes, the smoke and acceptance checks should have results. Use the rest of the 45-minute box for failed checks and the recorded decision, not an unsupported acceptance.

- Smoke checks: all five pages (home, Students, Courses, Instructors, Departments) load with migrated data, and the row counts on the source and on the managed instance match.
- Upload round-trip: an image uploaded on **Courses > Edit** shows on the course and lands in `teaching-materials` (checked with `az storage blob list` on `vm-dev01`: the storage account is private-only); replacing the image on **Courses > Edit** changes the blob, and deleting the throwaway course (**Courses > Delete**) removes its blob (the app has no separate delete-image control, and a seeded course is never deleted); a non-image and a file over 5 MB are both rejected with a clear error, not a 500.
- Notification round-trip: a toast within 5 seconds of a student edit, and `/Notifications/GetNotifications` returning success.
- A light load check (10–20 concurrent page loads) with no errors.
- Security check: `acceptance.json` showing **Verdict ACCEPT**, with no FAIL or UNKNOWN: the five pages and HTTPS redirect, HTTPS-only/TLS 1.2 minimum, backend public access off and approved private endpoints, plus SQL MI's public data endpoint off.
- Application Insights **Investigate > Search (formerly Transaction search)** (last hour or a custom range from C8's start) showing requests and dependencies from this session's checks.
- A filled-in acceptance and handover document with the member index.

## Model answer

The member runs the read-only checker from the dev container, in `factory/`:

```powershell
./scripts/Test-Acceptance.ps1 -SubscriptionId $s.subscriptionId -ResourceGroup $rg -OutFile .local/acceptance.json
```

A clean run has no FAIL and no UNKNOWN. Portal evidence can explain an UNKNOWN but **does not change NOT ACCEPTED**: resolve the scope/read problem and rerun the checker. No passing rerun means no ACCEPT. If C7 is unfinished, the member finishes cutover before browser/data checks; ARM security checks can be prepared meanwhile. The checker does not replace browser flows or row-count comparisons.

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

## Business outcome check

The outcome is secure by default. Ask the member to show the single result that proves public network access is off for every backend: the checker output or a portal screenshot. This supports the scoring row on public network access being off. It earns no points of its own.

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
