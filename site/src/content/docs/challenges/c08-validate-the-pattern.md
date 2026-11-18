---
title: "C8: Validate the pattern"
description: Run the acceptance pack against the live, migrated app.
---

## Background

A demo click-through proves little. C8 proves the modernized app is healthy in production with a fixed, repeatable acceptance pack: pages, data, uploads, notifications, load and security settings, each with evidence.

**Business context.** Tomás, the security lead, wants proof, not a demo. C8 runs a fixed acceptance pack against the live app so he can see for himself that it is healthy and private.

**Business outcome.** Secure by default. The live app passes a repeatable check, and every data service refuses public access.

**Objective.** Be able to validate a migrated workload with a repeatable pack and record the automated acceptance verdict.

**Time and scope.** Day 2, **13:15**, **45 min**, **Member**.

## Challenge

**Starting point.** C7's app, live on App Service against SQL MI.

If cutover is unfinished, finish C7 before the browser/data checks. Meanwhile you can inspect ARM security settings. The checker's page checks still fail until go-live; this is preparation, not grounds for `ACCEPT`.

**Fixed by the kit.** The checks on this page, and `Test-Acceptance.ps1`, which is read-only and never changes anything.

**You decide.** Whether each check passes, fails or doesn't apply. A FAIL means a setting is wrong; these settings come from the archetype's infrastructure code, so ask your coach before you change a resource by hand.

:::note[Where to work]

Everything in C8 runs on <span class="sl-badge note">vm-dev01 · Bastion</span>:

- <span class="sl-badge tip">Browser on vm-dev01</span> / <span class="sl-badge tip">Azure portal</span> — Open the live web app pages, test uploads and notifications, and check Application Insights search results (Requirements 1, 2, 3 and 6).
- <span class="sl-badge note">vm-dev01 · SSMS</span> — Run the row-count comparison query against the source and SQL MI (Requirement 1).
- <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt;\factory (pwsh)</span> — Run the private Blob listing, the 20-request load burst, and `Test-Acceptance.ps1` writing directly to `factory/evidence/c08/acceptance.json` on `main` (Requirements 2, 4, 5 and 6).

:::

If a check fails and you want help diagnosing it, there's a prompt for that in the [prompt library](../../prompts/vscode/06-acceptance-pack/). The checks themselves are on this page.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

<details>
<summary>Set up values once on vm-dev01</summary>

In PowerShell 7 (`pwsh`) on `vm-dev01`, load your settings from `C:\src\<your-repo>\factory`:

```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
cd C:\src\<your-repo>\factory
$s = Get-Content .local/settings.json | ConvertFrom-Json
$dc = Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json
az account set --subscription $s.subscriptionId
$n = $s.memberIndex
$suffix = $s.suffix
$rg = "rg-university-$suffix"
$app = az webapp list --resource-group $rg --query "[0].defaultHostName" --output tsv
$mi = az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query fullyQualifiedDomainName --output tsv
"Web app: https://$app"
"SQL MI:  $mi"
"contosoapp password: $($dc.sqlAppPassword)"
```

The first time you connect SSMS to the source, tick **Trust server certificate** in the Connect dialog: the source has a self-signed certificate. The managed instance doesn't need it.

</details>

## Requirements

1. **Smoke checks and row counts.** <span class="sl-badge tip">Browser</span> <span class="sl-badge note">vm-dev01 · SSMS</span> Open `https://<your web app host name>/` in a browser, then each of **Students**, **Courses**, **Instructors** and **Departments** from the menu. Every page must load with no error page, and the four list pages must show rows. Then confirm the data is the migrated data: on `vm-dev01`, open SSMS and run the query below on both the source (`10.10.<n>.4`, SQL login `contosoapp`) and your SQL Managed Instance (`$mi`, **Microsoft Entra MFA**). The counts must match:

   ```sql title="vm-dev01 — SSMS (ContosoUniversity on source and SQL MI)"
   SELECT
     (SELECT COUNT(*) FROM Person WHERE Discriminator = 'Student') AS Students,
     (SELECT COUNT(*) FROM Person WHERE Discriminator = 'Instructor') AS Instructors,
     (SELECT COUNT(*) FROM Course) AS Courses,
     (SELECT COUNT(*) FROM Department) AS Departments,
     (SELECT COUNT(*) FROM Enrollment) AS Enrollments;
   ```

2. **Upload round-trip.** <span class="sl-badge tip">Browser</span> <span class="sl-badge note">vm-dev01 · PowerShell 7</span> Use a throwaway course so you never touch the seeded data: on **Courses > Create New**, enter a course ID that isn't used (`9901`), a title, credits and a department, choose a small PNG (under 5 MB) as the teaching material, and save. The image must show on the course's page (**Details**). Then on `vm-dev01`, run `az storage blob list --account-name "stuniversity$suffix" --container-name teaching-materials --auth-mode login --output table` and see the new blob. Open **Courses > Edit** on the throwaway course, choose a different image and save, and list again: the blob must have changed. Delete the throwaway course (**Courses > Delete** on `9901` only), then list once more and confirm its blob is gone. Never delete a seeded course.

   Last, on **Courses > Create New**, try a text file and then an image larger than 5 MB (`[IO.File]::WriteAllBytes("$HOME\big.png", [byte[]]::new(6MB))`); both must be rejected with a message and no course created.

3. **Notification round-trip.** <span class="sl-badge tip">Browser · DevTools</span> Open the browser's developer tools (`F12`) > **Network**, filter for `GetNotifications`, and leave it open. Edit a student (**Students > Edit**, change the first name, save). Within 5 seconds a toast must appear on screen, and the next `GetNotifications` request in the Network panel must show status `200` and a response with `success` set to `true` and a `count` of 1 or more. Then edit the student back.

4. **Load check.** <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt;\factory (pwsh)</span> Run a 20-request burst of concurrent page loads against the live app from `vm-dev01`:

   ```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
   1..20 | ForEach-Object -Parallel {
       (Invoke-WebRequest "https://$using:app/Courses" -SkipHttpErrorCheck -TimeoutSec 60).StatusCode
   } -ThrottleLimit 10 | Group-Object | Select-Object Name, Count
   ```

   Every response must be `200`.

5. **Automated security and acceptance check (`acceptance.json`).** <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt;\factory (pwsh)</span> Run the read-only checker against your archetype's resource group, writing directly to `factory/evidence/c08/acceptance.json`:

   ```powershell title="vm-dev01 — C:\src\<your-repo>\factory (pwsh)"
   ./scripts/Test-Acceptance.ps1 -SubscriptionId $s.subscriptionId -ResourceGroup $rg -OutFile evidence/c08/acceptance.json
   ```

   It reports PASS, FAIL or UNKNOWN for the pages, HTTPS redirect, HTTPS-only/minimum TLS 1.2, backend public-access and approved private-endpoint settings, and SQL MI's public data endpoint. `ACCEPT` requires **no FAIL and no UNKNOWN**; otherwise the verdict is `NOT ACCEPTED` and the exit code is 1.

6. **Verify Application Insights telemetry and commit `acceptance.json`.** <span class="sl-badge tip">Azure portal</span> <span class="sl-badge note">vm-dev01 · C:\src\&lt;your-repo&gt; (pwsh)</span> In the portal open `appi-university-<suffix>` > **Investigate** > **Search (formerly Transaction search)**, set the time range to the **last hour**, and confirm requests and dependencies from your C8 checks appear. Then commit `factory/evidence/c08/acceptance.json` on `main` (live check outcomes are summarized once for the team in C10's `handover-and-ai-review.md`, rather than a per-member 22-row Markdown table):

   ```powershell title="vm-dev01 — C:\src\<your-repo> (pwsh)"
   cd C:\src\<your-repo>
   git pull --rebase
   git add factory/evidence/c08/acceptance.json
   git commit -m "docs: C8 acceptance check result"
   git push
   ```

## Success criteria

To complete this challenge, review with your coach on `vm-dev01`:

- [ ] `factory/evidence/c08/acceptance.json` committed on `main` in `C:\src\<your-repo>` showing **`Verdict: ACCEPT`**, with no FAIL or UNKNOWN, and public network access off for every backend.
- [ ] Live checks verified on `vm-dev01` (matching source/MI row counts, throwaway course upload/replace/delete and >5 MB rejection, notification toast within 5 seconds, 20/20 HTTP 200 load burst, and requests/dependencies visible in Application Insights), ready to record in your team's C10 handover summary.
- [ ] Outcome check: show Tomás the `acceptance.json` result proving no data service accepts public traffic.

<details>
<summary>What counts as "enough" load for the load check?</summary>

A handful of concurrent requests: ten to twenty page loads in a short burst is enough to show the app doesn't error under light concurrency. This isn't a performance benchmark; that's C9's job on the database.

</details>

<details>
<summary>How do I confirm public network access is off without a portal tour of every resource?</summary>

Run `Test-Acceptance.ps1` (requirement 5). To check one resource by hand, `az resource show --ids <resource id> --query properties.publicNetworkAccess` works for most of these resources; for SQL MI, run `az sql mi show --resource-group $rg --name sqlmi-university-<suffix> --query publicDataEndpointEnabled`.

</details>

<details>
<summary>The pages return errors, or the app is slow to answer</summary>

The managed instance may be stopped. Check on `vm-dev01`: `az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query state --output tsv` prints `Ready` when it runs. If stopped, select **Start** on its portal **Overview** immediately and allow **about 20 minutes**.

</details>

<details>
<summary>The toast never appears</summary>

Check the Network panel first. A `GetNotifications` response with `success: false` means the app couldn't reach Service Bus: check the app's `ServiceBus` settings and its identity's roles, and that the private endpoint is approved. If the response is fine but empty, someone or something else consumed the message: edit the student again.

</details>

<details>
<summary>If you need to start over</summary>

C8's checks are read-only (the throwaway course is the only change: delete it if the test stopped halfway), so there is nothing to reset. If you see `NOT ACCEPTED`, fix the cause (ask your coach) and run `Test-Acceptance.ps1` again; it changes nothing.

</details>

## References

- [Monitor Azure App Service](https://learn.microsoft.com/azure/app-service/monitor-app-service)
- [Private endpoints for Azure Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints)
