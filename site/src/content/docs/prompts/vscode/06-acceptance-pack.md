---
title: "VS Code: acceptance pack"
description: C8's fixed, repeatable validation of the live, migrated app.
sidebar:
  order: 7
---

C8's acceptance pack, condensed to a checklist. Run this against the live app after C7's cutover — it isn't a
demo click-through, it's a fixed set of checks with recorded evidence.

## Set up the values once

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$app = az webapp list --resource-group $rg --query "[0].defaultHostName" --output tsv
$rg; $app
```

## Checklist

1. **Smoke checks.** `https://$app/` and each of Students, Courses, Instructors, Departments load with no
   error page and show rows. Row counts against the source and the managed instance match (see C8's query).
2. **Upload round-trip.** Upload, replace, then delete a small PNG on a course's teaching material. Confirm
   each step in Blob with `az storage blob list --account-name stuniversity<suffix> --container-name teaching-materials --auth-mode login`.
   A non-image and a >5MB file are rejected.
3. **Notification round-trip.** With the browser's Network panel open and filtered on `GetNotifications`, edit
   a student. A toast appears within 5 seconds and the next poll returns `success: true`.
4. **Load check.** A light burst — the command is in [C8](../../../../challenges/c08-validate-the-pattern/).
   Every response is `200`.
5. **Security check.** Run the read-only `Test-Acceptance.ps1` script from C8 against the resource group. It
   must end `ACCEPT`.
6. **Record every result** — pass, fail, or not applicable, with evidence — using the
   [acceptance and handover template](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md).

## If you want the agent to help interpret a failure

```text
This acceptance pack check failed: <paste the exact symptom or Test-Acceptance.ps1 output>. Diagnose the likely cause (app configuration, network/private endpoint, or identity/role) without changing anything, and tell me what to check next.
```

Full task text, hints and bonus are in [C8](../../../../challenges/c08-validate-the-pattern/).
