---
title: "C8: Validate the pattern"
description: Run the acceptance pack against the live, migrated app.
---

## Background

A demo click-through proves little. C8 proves the modernized app is healthy in production with a fixed, repeatable acceptance pack: pages, data, uploads, notifications, load and security settings, each with evidence.

**Business context.** Tomás, the security lead, wants proof, not a demo. C8 runs a fixed acceptance pack against the live app so he can see for himself that it is healthy and private.

**Business outcome.** Secure by default. The live app passes a repeatable check, and every data service refuses public access.

**Objective.** Be able to validate a migrated workload with a repeatable pack and record each result with evidence.

**Time and points.** Member, **45 min**, **10 pts** (member).

## Challenge

**Starting point.** C7's app, live on App Service against SQL MI.

**Fixed by the kit.** The checks on this page, and `Test-Acceptance.ps1`, which is read-only and never changes anything.

**You decide.** Whether each check passes, fails or doesn't apply, and what evidence shows it. A FAIL means a setting is wrong; these settings come from the archetype's infrastructure code, so ask your coach before you change a resource by hand.

**Where to work.** The acceptance pack is your filled-in `acceptance-handover.md` together with the evidence files beside it.

| Requirements | Where |
| --- | --- |
| 1 (pages), 3 (browser flows) | A browser, on any computer. Use `vm-dev01` if the web app's page times out from your own computer. |
| 1 (row counts), 2 (blob listing) | `vm-dev01`, through Bastion (see [Switching to vm-dev01](../../guides/ghcp-upgrade/#switching-to-vm-dev01)): SSMS and PowerShell there. The databases and storage are private-only. |
| 4, 5 (load and security checks) | The dev container of your own repo, from `factory/`. |
| 6 (record) | Both. Evidence made on `vm-dev01` goes in `C:\src\<your-repo>\factory\evidence\c08\` (the plain clone of your own repo) on `main`; run `git pull --rebase` first. Evidence made in the dev container goes in `factory/evidence/c08/` on `main`; run `git pull` first. |

If a check fails and you want help diagnosing it, there's a prompt for that in the [prompt library](../../prompts/vscode/06-acceptance-pack/). The checks themselves are on this page.

For technical blockers, check [Troubleshooting](../../reference/troubleshooting/) before asking your coach.

<details>
<summary>Values from the dev container</summary>

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
$suffix = $rg -replace '^rg-university-', ''
$rg; $app
"Member index <n>: $($s.memberIndex)   Suffix <suffix>: $suffix"
```

The output is your archetype's resource group, the web app's host name, your member index (`<n>`) and your suffix (`<suffix>`). If the resource group or host name is empty, C5 didn't finish. If `az` says "Please run 'az login'", run `az login --use-device-code` and start again.

Requirement 1 also needs the source database's password. It's in the dev container too, so print it here and type it on the VM yourself (the VM has no `.local` folder):

```powershell
(Get-Content ".local/$($s.subscriptionId)/datacenter.json" | ConvertFrom-Json).sqlAppPassword
```

</details>

<details>
<summary>Values on vm-dev01</summary>

On the VM, in PowerShell, set the same values once per window. Replace `<n>` with your member index:

```powershell
az login --use-device-code
az account show --query name --output tsv   # your workload subscription
$n = <n>
$rg = az group list --query "[?starts_with(name,'rg-university-')].name | [0]" --output tsv
$suffix = $rg -replace '^rg-university-', ''
$mi = az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query fullyQualifiedDomainName --output tsv
$mi
```

`$mi` is your SQL Managed Instance's host name. If the subscription name is wrong, run `az account set --subscription <name>` and repeat.

The first time you connect SSMS to the source, tick **Trust server certificate** in the Connect dialog: the source has a self-signed certificate, and without it the connection fails with "certificate chain was issued by an authority that is not trusted". The managed instance doesn't need it.

</details>

## Requirements

1. **Smoke checks.** Open `https://<your web app host name>/` in a browser, then each of **Students**, **Courses**, **Instructors** and **Departments** from the menu. Every page must load with no error page, and the four list pages must show rows. Then confirm the data is the migrated data: on `vm-dev01`, open SSMS and run the query below twice. First connect to the source: **Server name** `10.10.<n>.4`, **Authentication** **SQL Server Authentication**, **Login** `contosoapp`, **Password** the `sqlAppPassword` you printed in the dev container, and tick **Trust server certificate**. Then connect to your SQL Managed Instance: paste `$mi` into **Server name**, set **Authentication** to **Microsoft Entra MFA**, and sign in with the account that deployed the archetype. Select the `ContosoUniversity` database in both (the database list in SSMS's toolbar). The counts must match, and the source stays running after cutover, so both queries work. Screenshot both results:

   ```sql
   SELECT
     (SELECT COUNT(*) FROM Person WHERE Discriminator = 'Student') AS Students,
     (SELECT COUNT(*) FROM Person WHERE Discriminator = 'Instructor') AS Instructors,
     (SELECT COUNT(*) FROM Course) AS Courses,
     (SELECT COUNT(*) FROM Department) AS Departments,
     (SELECT COUNT(*) FROM Enrollment) AS Enrollments;
   ```

2. **Upload round-trip.** Use a throwaway course so you never touch the seeded data: on **Courses > Create New**, enter a course ID that isn't used (`9901`), a title, credits and a department, choose a small PNG (any PNG under 5 MB, a screenshot works) as the teaching material, and save. The image must show on the course's page (**Details**). Then check it landed in Blob. The storage account is private-only, so the portal's blob browser won't work from your own computer: on `vm-dev01`, in PowerShell, with the values set above, run `az storage blob list --account-name "stuniversity$suffix" --container-name teaching-materials --auth-mode login --output table` and see the new blob. Open **Courses > Edit** on the throwaway course, choose a different image and save, and list again: the blob must have changed. The app has no separate "delete image" control, so to remove the image, delete the course: **Courses > Delete** on the throwaway course only, then list once more and confirm its blob is gone. Never delete a seeded course: it changes the counts requirement 1 compared and the data C9's workload reads.

   Last, on **Courses > Create New**, try to upload a text file (a `.txt` file; switch the file dialog from "Image files" to "All files") and then a file larger than 5 MB (the app's limit); both must be rejected with a message, and no course is created. The app checks the file name's extension and the size, not the content, so a 6 MB dummy file named `.png` does for the size test. If you don't have a big image, create one in PowerShell on the computer you browse from: `[IO.File]::WriteAllBytes("$HOME\big.png", [byte[]]::new(6MB))`. If the message names the file type instead of the size, use a real photo over 5 MB. The storage account has public access disabled, so a working upload proves the app reaches it privately.

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

   It reports PASS, FAIL or UNKNOWN for: the five pages and the HTTP-to-HTTPS redirect; the web app's HTTPS-only and minimum TLS 1.2; public network access off and an approved private endpoint for Storage, Service Bus, Key Vault and Container Registry; and SQL Managed Instance's public data endpoint off. The script ends with `ACCEPT` only when there is no FAIL and no UNKNOWN; any FAIL or UNKNOWN keeps the verdict at `NOT ACCEPTED` and the exit code at 1. A FAIL is a setting that is wrong: ask your coach before you change a resource by hand, and don't leave it unrecorded. An UNKNOWN is a check the script couldn't decide: settle each one in the portal (see the hints for the view) and screenshot it, so every UNKNOWN has a portal screenshot that explains it, and record the row and its screenshot in the pack beside the verdict. The result should end with `ACCEPT` once every UNKNOWN is resolved or explained. It doesn't replace requirements 1 to 3, and it doesn't prove the data is right. If you have time, check **Azure Policy > Compliance** (filter on your resource group) and **Microsoft Defender for Cloud > Recommendations** for findings on the same resources as a second view; they can lag the live settings by many minutes, so treat them as corroboration only, and skip them if you're short of time.

6. **Record every result.** First capture the telemetry: in the portal open `appi-university-<suffix>` > **Investigate** > **Transaction search**, set the time range to the last 30 minutes, and screenshot the requests and dependencies from your checks. Then record every result against the acceptance pack: pass, fail, or not applicable, with the evidence for each (screenshots, the count query results, the Network panel's response, `acceptance.json`).

   1. On `vm-dev01`, save the SSMS count screenshots and the blob listing in `C:\src\<your-repo>\factory\evidence\c08\`. Run `git pull --rebase` there, commit (a conventional message, for example `docs: C8 vm evidence`) and `git push`, as in [Copy your evidence to your repo](../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo).
   2. In the dev container, in your own repo, run `git pull`, then copy `factory/templates/attendee/acceptance-handover.md` to `factory/evidence/c08/` and fill it in. Copy `factory/.local/acceptance.json` and your browser screenshots there too.
   3. Commit (for example `docs: C8 acceptance pack`) and push `main`.

## Success criteria

To complete this challenge, show your coach in `factory/evidence/c08/` of your own repo:

- [ ] A filled-in acceptance and handover document, copied from `factory/templates/attendee/acceptance-handover.md` (the [template on GitHub](https://github.com/jonathan-vella/apex-factory-hackathon/blob/main/templates/attendee/acceptance-handover.md)): every check, its result and its evidence.
- [ ] Telemetry (requests, dependencies) from this session's checks visible in Application Insights: the screenshot from requirement 6.
- [ ] `Test-Acceptance.ps1`'s output (`acceptance.json`), which should end in `ACCEPT` and shows public network access off for every backend. If a check stayed UNKNOWN, the portal screenshot that explains it, noted in the pack.
- [ ] Outcome check (unscored guidance): show Tomás the one result that proves no data service accepts public traffic.

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

The managed instance may be stopped. Check on `vm-dev01`: `az sql mi show --resource-group $rg --name "sqlmi-university-$suffix" --query state --output tsv` prints `Ready` when it runs. If it prints `Stopped`, open the managed instance in the portal and select **Start** on **Overview** (it takes several minutes), or ask your coach. The facilitator can set a schedule for it (by default it runs weekdays 07:30 to 18:30, W. Europe time, once the MI link is removed).

</details>

<details>
<summary>I'm running out of the 45 minutes</summary>

Plan about 10 minutes each for requirements 1 to 3, 5 for requirement 4, 5 for the checker and 5 to write the pack. Skip the Policy and Defender views first, then run the checker (requirement 5) while you do the browser flows.

</details>

<details>
<summary>The checker reports UNKNOWN</summary>

An UNKNOWN means the script couldn't read the setting. Settle it in the portal and screenshot it:

- **Private endpoint:** it only looks in your archetype's resource group. If the private endpoint lives elsewhere, open the backend > **Networking** > **Private endpoint connections**, and screenshot an **Approved** connection instead.
- **Public network access:** open the backend > **Networking** and screenshot the public access setting (disabled).
- **HTTPS only or TLS version:** open the web app > **Configuration** > **General settings** and screenshot **HTTPS Only** and the minimum TLS version.
- **Page checks:** open the page in a browser and screenshot it.

</details>

<details>
<summary>The toast never appears</summary>

Check the Network panel first. A `GetNotifications` response with `success: false` means the app couldn't reach Service Bus: check the app's `ServiceBus` settings and its identity's roles, and that the private endpoint is approved. If the response is fine but empty, someone or something else consumed the message: edit the student again.

</details>

<details>
<summary>If you need to start over</summary>

C8's checks are read-only (the throwaway course is the only change: delete it if the test stopped halfway), so there is nothing to reset. To redo C8, run the checks again and overwrite your files in `factory/evidence/c08/`. If you see `NOT ACCEPTED`, fix the cause (ask your coach) and run `Test-Acceptance.ps1` again; it changes nothing.

</details>

**Bonus.** Up to 5 pts for finding and documenting a real gap the acceptance pack doesn't already cover (for example, a missing diagnostic setting).

## References

- [Monitor Azure App Service](https://learn.microsoft.com/azure/app-service/monitor-app-service)
- [Private endpoints for Azure Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints)
