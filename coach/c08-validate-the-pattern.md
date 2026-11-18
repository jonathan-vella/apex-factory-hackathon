# C8 answer key: Validate the pattern (coach)

> [!WARNING]
> Coach material. This page has the answers to C8. Attendees run the acceptance pack themselves against the live, migrated app.

C8 is a fixed checklist, so grading is mostly about completeness and evidence quality, not judgment calls.

## Expected evidence

**Timing cues:** by 20 minutes, the smoke and acceptance checks should have results. Use the rest of the 45-minute box for fixing any failed checks.

- `factory/evidence/c08/acceptance.json` committed on `main` in `C:\src\<your-repo>` showing **Verdict ACCEPT**, with no FAIL or UNKNOWN: the five pages and HTTPS redirect, HTTPS-only/TLS 1.2 minimum, backend public access off and approved private endpoints, plus SQL MI's public data endpoint off.
- Live checks verified on `vm-dev01` (and summarized in the team's C10 `handover-and-ai-review.md`):
  - Smoke checks: all five pages (home, Students, Courses, Instructors, Departments) load with migrated data, and the row counts on the source and on the managed instance match.
  - Upload round-trip: throwaway course (`9901`) image upload, replace, delete, and rejection of non-image and >5 MB files.
  - Notification round-trip: a toast within 5 seconds of a student edit, and `/Notifications/GetNotifications` returning success.
  - Load check: 20 concurrent page loads returning HTTP 200.
  - Application Insights **Investigate > Search (formerly Transaction search)** showing requests and dependencies from the session's checks.

## Model answer

The member runs the read-only checker on `vm-dev01`, in `C:\src\<your-repo>\factory`:

```powershell
./scripts/Test-Acceptance.ps1 -SubscriptionId $s.subscriptionId -ResourceGroup $rg -OutFile evidence/c08/acceptance.json
```

A clean run has no FAIL and no UNKNOWN. If C7 is unfinished, the member finishes cutover before browser/data checks; ARM security checks can be prepared meanwhile. The checker does not replace browser flows or row-count comparisons.

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

All of the above should report disabled/`Disabled`/`false` for public access, `true` for `httpsOnly` and `1.2` for the minimum TLS version.

## Business outcome check

The outcome is secure by default. Ask the member to show `acceptance.json` proving public network access is off for every backend.

## Common mistakes

- Running the load check against `vm-dev01`'s local copy instead of the live App Service URL — the acceptance pack is specifically about production health, not the dev loop.
- Treating the load check as a performance benchmark and spending disproportionate time on it — it's a light smoke test; C9 is where performance work actually happens, and on the database, not the app tier.
- Skipping the rejection cases (non-image, over-size file) in the upload round-trip — a working happy path doesn't prove the validation logic exists.
- Checking public network access on four of five backends and forgetting ACR.

## Reset

Not applicable — C8 only reads the live app's state; nothing to reset.
