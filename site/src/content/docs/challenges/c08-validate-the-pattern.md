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

## Where to run

| Tasks | Where |
| --- | --- |
| 1 (pages), 2, 3 (browser flows) | A browser, on any computer. Use `vm-dev01` if your own network can't reach the web app. The row counts in task 1 use SSMS on `vm-dev01`. |
| 4, 5 (load and security checks) | The dev container of your own repo, from `factory/`. |
| 6 (record) | The team repo, in `evidence/c08/member-<n>/`. |

In the dev container, open `pwsh` and set up the values the checks use:

```bash
pwsh
cd factory
```

```powershell
$s = Get-Content .local/settings.json | ConvertFrom-Json
az account set --subscription $s.subscriptionId
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$app = az webapp list --resource-group $rg --query "[0].defaultHostName" --output tsv
$rg; $app
```

The last line prints your archetype's resource group and the web app's host name. If either is empty, C5 didn't finish.

## Your tasks

1. **Smoke checks.** Open `https://<your web app host name>/` in a browser, then each of **Students**, **Courses**, **Instructors** and **Departments** from the menu. Every page must load with no error page, and the four list pages must show rows. Then confirm the data is the migrated data: on `vm-dev01`, open SSMS and run this query against the source (`10.10.<n>.4`, SQL authentication as `contosoapp`) and against your SQL Managed Instance (Microsoft Entra authentication). The counts must match:

   ```sql
   SELECT
     (SELECT COUNT(*) FROM Person WHERE Discriminator = 'Student') AS Students,
     (SELECT COUNT(*) FROM Person WHERE Discriminator = 'Instructor') AS Instructors,
     (SELECT COUNT(*) FROM Course) AS Courses,
     (SELECT COUNT(*) FROM Department) AS Departments,
     (SELECT COUNT(*) FROM Enrollment) AS Enrollments;
   ```

2. **Upload round-trip.** On **Courses > Edit** for any course, choose a small PNG as the teaching material and save. The image must show on the course's page. Then check it landed in Blob: in the portal open your storage account > **Containers** > `teaching-materials`, and see the new blob. Replace it with another image, then delete it, and confirm the blob changes and then goes. Last, try to upload a text file (switch the file dialog from "Image files" to "All files") and a file larger than the app's limit (10 MB in the original app); both must be rejected with a message. The storage account has public access disabled, so a working upload proves the app reaches it privately.
3. **Notification round-trip.** Open the browser's developer tools (`F12`) > **Network**, filter for `GetNotifications`, and leave it open. The page asks `/Notifications/GetNotifications` every 5 seconds. Edit a student (**Students > Edit**, change the first name, save). Within 5 seconds a toast must appear on screen, and the next `GetNotifications` request in the Network panel must show status `200` and a response with `success` set to `true` and a `count` of 1 or more. Then edit the student back. Don't open the `/Notifications/GetNotifications` address in another tab yourself: each call takes the queued messages, so the page would never show the toast. Service Bus has public access disabled, so a working toast proves the app reaches it privately.
4. **Load check.** A light burst of concurrent page loads against the live app. In the dev container:

   ```powershell
   1..20 | ForEach-Object -Parallel {
       (Invoke-WebRequest "https://$using:app/Courses" -SkipHttpErrorCheck -TimeoutSec 60).StatusCode
   } -ThrottleLimit 10 | Group-Object | Select-Object Name, Count
   ```

   Every response must be `200`. It isn't C9's performance work, so keep it light.
5. **Security check.** In the dev container, from `factory/`, run the read-only checker against your archetype's resource group. It never changes anything:

   ```powershell
   ./scripts/Test-Acceptance.ps1 -SubscriptionId $s.subscriptionId -ResourceGroup $rg -OutFile .local/acceptance.json
   ```

   It reports PASS, FAIL or UNKNOWN for: the five pages and the HTTP-to-HTTPS redirect; the web app's HTTPS-only and minimum TLS 1.2; public network access off and an approved private endpoint for Storage, Service Bus, Key Vault and Container Registry; and SQL Managed Instance's public data endpoint off. It must end with `ACCEPT`. Fix every FAIL, and explain every UNKNOWN with the portal view that settles it. It doesn't replace tasks 1 to 3, and it doesn't prove the data is right. As a second view, check **Azure Policy > Compliance** (filter on your resource group) and **Microsoft Defender for Cloud > Recommendations** for findings on the same resources. Treat them as corroboration only: they can lag the live settings by many minutes.
6. **Record every result** against the acceptance pack: pass, fail, or not applicable, with the evidence for each (screenshots, the count query results, the Network panel's response, `acceptance.json`). Save it in `evidence/c08/member-<n>/` in the team repo.

## Evidence

- A filled-in [acceptance and handover](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md) document: every check, its result and its evidence.
- Telemetry (requests, dependencies) from this session's checks visible in Application Insights: open the resource > **Investigate** > **Transaction search**, set the time range to the last 30 minutes, and screenshot the requests from your checks.
- `Test-Acceptance.ps1`'s output (or `acceptance.json`) ending in `ACCEPT`, which shows public network access off for every backend.

## Hints

<details>
<summary>What counts as "enough" load for the load check?</summary>

A handful of concurrent requests — ten to twenty page loads in a short burst is enough to show the app doesn't error under light concurrency. This isn't a performance benchmark; that's C9's job on the database.
</details>

<details>
<summary>How do I confirm public network access is off without a portal tour of every resource?</summary>

Run `Test-Acceptance.ps1` (task 5). To check one resource by hand, `az resource show --ids <resource id> --query properties.publicNetworkAccess` works for most of these resources; SQL MI uses `az sql mi show --query publicDataEndpointEnabled`.
</details>

<details>
<summary>The checker reports UNKNOWN for a private endpoint</summary>

It only looks in your archetype's resource group. If the private endpoint lives elsewhere, open the backend in the portal > **Networking** > **Private endpoint connections**, and screenshot an **Approved** connection instead.
</details>

<details>
<summary>The toast never appears</summary>

Check the Network panel first. A `GetNotifications` response with `success: false` means the app couldn't reach Service Bus: check the app's `ServiceBus` settings and its identity's roles, and that the private endpoint is approved. If the response is fine but empty, someone or something else consumed the message: edit the student again.
</details>

## Lifeline

Ask your coach if a specific acceptance check keeps failing for a reason you can't diagnose after one pass through the hints above. Using the lifeline caps C8 at partial credit.

## Bonus

Up to 5 pts for finding and documenting a real gap the acceptance pack doesn't already cover (for example, a missing diagnostic setting).

## Learn more

- [Monitor Azure App Service](https://learn.microsoft.com/azure/app-service/monitor-app-service)
- [Private endpoints for Azure Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints)
