# B06 run protocol v2: GHCP golden path on `vm-dev01`

The steps the owner follows on `vm-dev01` for each run of the [B06 spike](../../backlog/B06-spike-ghcp.md). They assume you haven't used GitHub Copilot modernization before. Version 2 is the refined sequence for run 2, rewritten from everything run 1 found (see the [report](README.md#findings) and [Changes from v1](#changes-from-v1)). You don't fill in the results sheets: the executor fills in [run1.md](run1.md) and [run2.md](run2.md) from your commits, chat exports and versions file after you push.

| Run | Branch | Start from commit | Protocol version |
|---|---|---|---|
| 1 | `spike/b06-run1` | `da4e5f606983332001c94ce69b48634f9c1864b3` | v1 (changed into v2 during the run) |
| Comparison | `spike/b06-upgrade-compare` | `da4e5f606983332001c94ce69b48634f9c1864b3` | [Comparison section](#comparison-github-copilot-upgrade-after-run-1-before-run-2) |
| 11a rerun, Copilot harness (stage 2 only, kept as evidence) | `spike/b06-upgrade-compare-v2` | `da4e5f606983332001c94ce69b48634f9c1864b3` | [11a rerun section](#11a-rerun-github-copilot-upgrade-in-vs-code) |
| 11a rerun, Local harness (full run) | `spike/b06-upgrade-compare-v3` | `da4e5f606983332001c94ce69b48634f9c1864b3` | [11a rerun section](#11a-rerun-github-copilot-upgrade-in-vs-code) |
| Comparison in the Copilot app | `spike/b06-upgrade-app-v2` (attempt 2; attempt 1 on `spike/b06-upgrade-app` was abandoned) | `da4e5f606983332001c94ce69b48634f9c1864b3` | [Copilot app section](#comparison-github-copilot-upgrade-in-the-copilot-app-after-the-vs-code-comparison-before-run-2) |
| 2 | `spike/b06-run2` | `e850869e438556c1234dd672f12aa133a2bed644` | v2 |

Order: the VS Code comparison, then the Copilot app comparison, then run 2.

At the event, App Service, the container registry, SQL Managed Instance and the datacenter are already deployed for each attendee. The plan and every step assume existing resources whose endpoints come from configuration; nothing here provisions anything.

Placeholders: `n` is your member index (`1` in the build subscriptions) and `<suffix>` is the suffix in `.local/settings.json`. The spike resources are in `rg-spike-b06` and are private-only, so every Azure data-plane call works only from `vm-dev01`.

| Setting | Value |
|---|---|
| Source database | `10.10.n.4`, database `ContosoUniversity`, SQL login `contosoapp`, password `FactoryLab-2026-Pw` (datacenter lab password) |
| Blob | `https://stuni<suffix>b06.blob.core.windows.net`, container `teaching-materials` |
| Service Bus | `sbns-uni-<suffix>-b06.servicebus.windows.net`, queue `notifications` |
| Key Vault | `https://kv-uni-<suffix>-b06.vault.azure.net/` |
| Container registry | `cruni<suffix>b06.azurecr.io`, repository `contoso-university`, tag `run2` |

Use these configuration keys, so the runs and the archetype (B09) use the same names:

| Key | Local value on `vm-dev01` |
|---|---|
| `ConnectionStrings:DefaultConnection` | SQL authentication to `10.10.n.4`, in user secrets or Key Vault only |
| `Storage:BlobServiceUri` | `https://stuni<suffix>b06.blob.core.windows.net` |
| `Storage:ContainerName` | `teaching-materials` |
| `ServiceBus:FullyQualifiedNamespace` | `sbns-uni-<suffix>-b06.servicebus.windows.net` |
| `ServiceBus:QueueName` | `notifications` |
| `KeyVault:VaultUri` | `https://kv-uni-<suffix>-b06.vault.azure.net/` |

## The sequence at a glance

1. **Set up:** device code sign-in, git identity, `AZURE_TOKEN_CREDENTIALS`, the run branch.
2. **Assess (C3):** a **custom assessment** targeting App Service for Linux (containers). Don't use **Create Plan**.
3. **Plan:** a new chat, `modernize` with GPT-6 Sol at Medium, `/create-modernization-plan` with the kit's seven tasks and rules from [prompts/run2-modernize-plan.md](prompts/run2-modernize-plan.md). A wrong plan is deleted and generated again, never corrected.
4. **Execute (C6):** one task per new chat, `modernize` with GPT-6 Luna at maximum, with a **direct prompt** per task. After each task: bring the work onto the run branch, run the app, check, commit and push.
5. **Gaps:** the seven tasks cover them; check that nothing is left.
6. **Package:** SDK container publishing to the private registry.

## Rules for every step

- **Check the agent and model before every chat.** Each dashboard button and chat uses whatever is selected in the Chat panel's pickers, at the bottom of the chat input box. Each step says what to select.
- **How the run is recorded.** You record by committing; the executor turns it into the results sheet:
  - **Times** come from the commit timestamps. A step starts at the previous commit, so commit before a break and say so in the body.
  - **Prompts and models:** for every chat, run **Chat: Export Chat…** from the Command Palette (Ctrl+Shift+P) before the commit, and save it as `docs\spikes\B06-ghcp-golden-path\chats\run2-step<step>.json`, for example `run2-step4-task003.json`. If the JSON export fails, copy the chat and save it as `.txt`. A step run only from the dashboard has no chat: say so in the commit body. Don't paste passwords or tokens into a chat: the executor checks the exports for secrets.
  - **Interventions:** one line each in the commit body, for example `git commit -m "run2: step 4 task 004 Service Bus" -m "Fixed by hand: receive wait time was TimeSpan.Zero"`. Say there which agent, model and prompt you used, and anything that went wrong.
  - **Build and run:** say in the commit body whether `dotnet build` passed and whether the app ran. Premium requests: add them if VS Code shows them.
- **Run the app after every task, before you commit.** `dotnet run` and open a page. The agents' validations build but never start the app: in run 1, the Service Bus receive path always failed and the OpenTelemetry task crashed at startup, and both passed the agent's validation.
- **Keep the agent in the app.** End every prompt you type with `Scope: app/ContosoUniversity only; never edit files outside it.` Before each commit, check `git status --short` for changes outside `app/` and `.github/modernize/`, and revert them (`git restore <path>`). In run 1, a repo-wide completeness check edited the kit's `docs/prd.md`.
- **Bring each task's work onto the run branch.** Where the agent leaves its work varies: in run 1 it committed on a new `appmod/*` branch, committed on the run branch, or didn't commit at all. After every task:

  ```powershell
  git status --short --branch
  ```

  - **On an `appmod/*` branch:** `git switch spike/b06-run2`, then `git merge --ff-only <appmod-branch>`.
  - **Uncommitted changes:** `git add -A`, then commit on `spike/b06-run2` with the step name.
  - **Already committed on `spike/b06-run2`, clean tree:** nothing to do.
  - Then, in every case, `git push`.

  Never leave a task uncommitted when the next one starts: in run 1, the next task's branch switch stashed the .NET 10 upgrade.
- **Approve tool calls with care.** Approve builds, restores and file edits. Don't approve anything that creates, changes or deletes Azure resources: they already exist.
- **Never paste a password into a committed file.** Connection strings with a password go into user secrets or Key Vault. If Copilot writes one into `appsettings*.json`, move it and note it as an intervention.
- **Keys don't work.** Storage shared keys and Service Bus SAS are turned off. Key- or connection-string-based Blob or Service Bus code fails at runtime: ask for `DefaultAzureCredential`.
- **Time boxes:** C3 is 1 hour and C6 is 3 hours at the event. Don't stop at the time box, but note when you pass it.
- **If Notepad opens after every Copilot tool call,** that's the C# Dev Kit 3.40.204 bug ([microsoft/vscode-dotnettools#3568](https://github.com/microsoft/vscode-dotnettools/issues/3568)). Close Notepad, then rename `track-skill-invocation.ps1` wherever it appears under `%USERPROFILE%\.vscode\extensions` and `%APPDATA%\Code\agentPlugins` (for example to `track-skill-invocation.ps1.disabled`) and restart VS Code. Don't change the `.ps1` file association. Note it in the next commit body.

## Step 1: Set up

1. Connect to `vm-dev01` through Bastion as `labadmin`.
2. Open PowerShell 7 and sign in with device code flows. Each command prints a one-time code: open the page it names on your own device, where passkeys and password managers work, and enter the code there.

   ```powershell
   gh auth login --web                 # enter the code at https://github.com/login/device
   az login --use-device-code          # enter the code at https://microsoft.com/devicelogin
   ```

   Some tenants block device code flow with Conditional Access. If sign-in is refused, note it in the step 1 commit body and use `az login` (browser) inside the Bastion session instead.

   Give git your GitHub identity, with the no-reply email, and let `git push` use the gh sign-in. A fresh VM user has no git identity, so the first commit fails without this:

   ```powershell
   $u = gh api user | ConvertFrom-Json
   git config --global user.name ($u.name ?? $u.login)
   git config --global user.email "$($u.id)+$($u.login)@users.noreply.github.com"
   gh auth setup-git
   ```

   In the Azure CLI subscription picker, pick your own workload subscription, the one that holds `rg-datacenter`, and check it: `az account show --query name -o tsv`. If it's wrong, run `az account set --subscription '<your workload subscription name>'`.
3. Make `DefaultAzureCredential` use your Azure CLI sign-in. `vm-dev01` has a system-assigned managed identity with no data roles, and `DefaultAzureCredential` tries it before the Azure CLI, so without this the app gets 403 on Blob, Service Bus and Key Vault. Set it for your user, then restart VS Code and any terminals:

   ```powershell
   [Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')
   ```

   It's set only on `vm-dev01`, never in Azure, so the deployed app still uses its managed identity. See [Credential chains in the Azure Identity library for .NET](https://learn.microsoft.com/dotnet/azure/sdk/authentication/credential-chains).
4. Get the repo into `C:\src\apex-factory-hackathon` and create the run branch:

   ```powershell
   if (-not (Test-Path C:\src\apex-factory-hackathon)) { git clone https://github.com/jonathan-vella/apex-factory-hackathon.git C:\src\apex-factory-hackathon }
   Set-Location C:\src\apex-factory-hackathon
   git status --short
   ```

   `git status --short` must print nothing. **If it prints anything, stop and tell the executor**: don't commit, stash or delete anything. Then:

   ```powershell
   git fetch origin
   git switch -c spike/b06-run2 e850869e438556c1234dd672f12aa133a2bed644
   git diff --stat e850869e438556c1234dd672f12aa133a2bed644 origin/main -- app/ContosoUniversity
   ```

   Use the run 2 commit from the table above. The last command must print nothing: `app/ContosoUniversity` is unchanged from `main`. If `app\ContosoUniversity\.github\modernize\` exists from an earlier assessment (git ignores it), move it out: `Move-Item app\ContosoUniversity\.github\modernize C:\src\b06-earlier-assessment-run2`.
5. Open the folder in VS Code (`code C:\src\apex-factory-hackathon`), sign in to GitHub with the account that has the Copilot seat, and check that Copilot Chat opens. Both GitHub Copilot modernization (`vscjava.migrate-java-to-azure`) and, after the comparison run, GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) are installed and enabled. The C# Dev Kit status bar shows **Projects: 1 error** for the legacy project until the upgrade: that's expected.
6. Write the versions file:

   ```powershell
   $v = 'docs\spikes\B06-ghcp-golden-path\run2-versions.txt'
   'code --version:' | Set-Content $v
   code --version | Add-Content $v
   'extensions:' | Add-Content $v
   code --list-extensions --show-versions | Select-String -Pattern 'copilot|csdevkit|migrate-java-to-azure|upgrade-agent' | ForEach-Object Line | Add-Content $v
   'dotnet --version:' | Add-Content $v
   dotnet --version | Add-Content $v
   ```

7. Check that the spike services resolve privately (each prints a `10.10.n.128/27` address):

   ```powershell
   'stuni<suffix>b06.blob.core.windows.net','sbns-uni-<suffix>-b06.servicebus.windows.net','cruni<suffix>b06.azurecr.io','kv-uni-<suffix>-b06.vault.azure.net' | ForEach-Object { Resolve-DnsName $_ -Type A | Where-Object IPAddress | Select-Object -Last 1 Name, IPAddress }
   ```

8. Set the local configuration now, so every task can run against the real services:

   ```powershell
   Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
   dotnet user-secrets init
   dotnet user-secrets set 'ConnectionStrings:DefaultConnection' 'Server=10.10.n.4;Database=ContosoUniversity;User Id=contosoapp;Password=FactoryLab-2026-Pw;TrustServerCertificate=True;MultipleActiveResultSets=True'
   dotnet user-secrets set 'Storage:BlobServiceUri' 'https://stuni<suffix>b06.blob.core.windows.net'
   dotnet user-secrets set 'Storage:ContainerName' 'teaching-materials'
   dotnet user-secrets set 'ServiceBus:FullyQualifiedNamespace' 'sbns-uni-<suffix>-b06.servicebus.windows.net'
   dotnet user-secrets set 'ServiceBus:QueueName' 'notifications'
   Set-Location C:\src\apex-factory-hackathon
   ```

   User secrets live outside the repo, so nothing here is committed. `dotnet user-secrets init` changes the legacy project file; if it fails on the legacy project, run it after task 001 instead.
9. Commit: `git add -A`, `git commit -m "run2: step 1 set up"`, with any problem as one line in the body.

## Step 2: C3 assess

1. Open the **GitHub Copilot modernization** view in the Activity Bar and run a **custom assessment**, not the default **Start Assessment**. Set the target to **Azure App Service for Linux (containers)** and leave every other option at its default, as run 1 did (note any you change in the commit body). If it asks which project, pick `app/ContosoUniversity`. The assessment uses the extension's default model; you can't pick one.
2. In the report, check that the target is **Azure App Service (Linux)**. If it shows **Azure App Service (Windows)**, switch it and note it.
3. Read the report: note the issues for local files, MSMQ, the database, the plaintext connection string and `System.Web`. It flags **Windows authentication detected** as mandatory, but the app has no user sign-in: the finding comes only from `IISExpressWindowsAuthentication` and `Integrated Security=True` in the old LocalDB connection string. Rule 2 of the plan removes it.
4. **Don't select Create Plan.** It plans only the service migrations, keeps both storage and both database alternatives, adds an Entra ID task, and a finished plan can't be corrected afterwards.
5. Save the report: copy the files from `app\ContosoUniversity\.github\modernize\assessment\reports\report-<timestamp>\` to `docs\spikes\B06-ghcp-golden-path\assessment\run2\`, plus `...\assessment\engines\dotnet-appcat\result\report.json` as `appcat-report.json`, then `git add docs/spikes/B06-ghcp-golden-path/assessment`.
6. Commit: `run2: step 2 assessment`.

## Step 3: Plan

> [!WARNING]
> **BEFORE you send the planning prompt:** start a **new chat**, and check that the agent is **`modernize`** and the model is **GPT-6 Sol** with reasoning **Medium**. The pickers are at the bottom of the chat input box.

1. ⚠️ **BEFORE you send:** new chat, agent **`modernize`**, model **GPT-6 Sol** at **Medium**.
2. Open [prompts/run2-modernize-plan.md](prompts/run2-modernize-plan.md), copy its whole content and send it. It starts with `/create-modernization-plan`, so it runs the extension's planning skill with the kit's seven tasks and rules as its input: .NET 10 first (with SDK container publishing), SQL Managed Instance, Blob, Service Bus, Key Vault, OpenTelemetry, then CVE fixes; Entra authentication only on Azure, SQL authentication only in Development against the unchanged source; Key Vault mandatory outside Development; private backends; and a 9-row compliance table. Run 1 used an older, shorter prompt with six tasks and seven rules (OpenTelemetry was a separate gap then).

   It writes `.github\modernize\<plan-folder>\plan.md` and `.metadata\tasks.json` at the repo root. If it asks which Azure resources to use for integration tests, answer: configuration keys supplied at execution time, no identifiers.
3. **Check the plan.** All 9 rows of the table must be met. In `tasks.json`: exactly seven tasks, the .NET 10 upgrade first and each task depending on the one before; one target per workload (Blob, SQL Managed Instance); no Entra ID sign-in task. If anything is wrong, don't correct it in the chat: delete the plan's folder, start a new chat and send the prompt again.
4. Export the chat and commit the plan: `run2: step 3 plan`, noting in the body the agent, model and reasoning effort the chat showed and how many times you generated the plan.

## Step 4: Execute (C6)

> [!WARNING]
> **BEFORE each task:** start a **new chat** (never the planning chat or the previous task's chat), and check that the agent is **`modernize`** and the model is **GPT-6 Luna** with reasoning **maximum**.

Run the seven tasks in `tasks.json` in order, **one task per new chat**, with a direct prompt. Don't use **Execute the plan** or `Execute task 00N of the plan`: in run 1 that route's delegation blocked three of six tasks (sub-agent depth, stale trackers, a lost scenario, a phantom "another agent"), while the direct prompt worked every time. For each task:

1. ⚠️ **BEFORE you send:** new chat, agent **`modernize`**, model **GPT-6 Luna** at **maximum**.
2. Send this, with the task's ID, and paste the task's `description` and `requirements` from `tasks.json` after it:

   ```text
   Implement task <task-id> of the modernization plan in .github/modernize/<plan-folder> directly on spike/b06-run2. Work directly: don't delegate, don't initialize a scenario and don't re-plan. Scope: app/ContosoUniversity only; never edit files outside it. After the change, build the app and fix every error. The task's description and requirements from tasks.json:
   ```

   Approve builds and file edits. If it still stops (a stale tracker, "no modernization scenario is active", or "already being handled by another agent"), nothing was changed: reload the window (**Developer: Reload Window**) and send the same prompt in a new chat with the **default Agent** and GPT-6 Luna at maximum instead.
3. Bring the work onto `spike/b06-run2` (see **Rules for every step**), then `dotnet run` and do the task's check below. Every task's check includes the five pages loading against `10.10.n.4`.
4. Export the chat, commit and push: `run2: step 4 task <nnn> <name>`, with the agent, model and any intervention in the body.

| Task | Check after it | Known hot spot from run 1 |
|---|---|---|
| 001 .NET 10 upgrade | `dotnet build app/ContosoUniversity` passes; the home, Students, Courses, Instructors and Departments pages work against `10.10.n.4`; `Global.asax` and `App_Start` are gone, `NotificationService` comes from dependency injection, and the `Site.css` name matches every reference; the project file has the container properties and there's no `Dockerfile` | MSMQ is replaced by a temporary in-process queue until task 004: notifications don't survive a restart yet |
| 002 SQL Managed Instance | Students still read and write against `10.10.n.4` with SQL authentication in Development | — |
| 003 Blob | An upload on **Courses** > **Edit** lands in the container: `az storage blob list --account-name stuni<suffix>b06 --container-name teaching-materials --auth-mode login -o table` | The agent may not commit: use the branch routine |
| 004 Service Bus | Create or edit a student. Send: `az servicebus queue show -g rg-spike-b06 --namespace-name sbns-uni-<suffix>-b06 -n notifications --query countDetails.activeMessageCount` goes up. Receive: `/Notifications/GetNotifications` returns `"success":true`, and toasts appear top right (the **Notifications** page is only information) | Run 1's receive path called `ReceiveMessagesAsync` with `TimeSpan.Zero` and always failed, and the controller hid it. If receive fails, send: `ReceiveMessagesAsync needs a positive maxWaitTime: use TimeSpan.FromSeconds(2), and log exceptions in NotificationsController with ILogger instead of Debug.WriteLine. Scope: app/ContosoUniversity only; never edit files outside it.` |
| 005 Key Vault | Three checks (commands below): the app reads its connection string from Key Vault with the user secret removed; outside Development without `KeyVault:VaultUri`, it refuses to start; outside Development with a SQL-authentication `DefaultConnection`, it refuses to start | — |
| 006 OpenTelemetry | With no connection string, the app starts and runs normally. With `APPLICATIONINSIGHTS_CONNECTION_STRING` set, requests, SQL and HTTP dependencies and logs from a local run appear in `appi-uni-<suffix>-b06` within a few minutes (commands below). `git grep -n -E "Trace\.\|Debug\.Write" -- app/ContosoUniversity` prints nothing | Run 1's predefined OpenTelemetry task registered Azure Monitor unconditionally, so the app crashed without a connection string, and it edited `docs/prd.md`. A `fail: … TaskCanceledException` (499) when you navigate away during a notification poll is expected |
| 007 CVE fixes | `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` finds nothing, or every finding is fixed | Run 1 had nothing to fix; the extension's NuGet safe-version planner crashed (tool bug): ignore it if the list is clean |

Task 005's checks. The last two run outside Development on purpose, and each must fail at startup with a clear message:

```powershell
az keyvault secret set --vault-name kv-uni-<suffix>-b06 --name 'ConnectionStrings--DefaultConnection' --value 'Server=10.10.n.4;Database=ContosoUniversity;User Id=contosoapp;Password=FactoryLab-2026-Pw;TrustServerCertificate=True;MultipleActiveResultSets=True'
Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
dotnet user-secrets set 'KeyVault:VaultUri' 'https://kv-uni-<suffix>-b06.vault.azure.net/'
dotnet user-secrets remove 'ConnectionStrings:DefaultConnection'
dotnet run                                   # Development: pages work, connection string from Key Vault

$env:ASPNETCORE_ENVIRONMENT = 'Production'; $env:KeyVault__VaultUri = ''
dotnet run --no-launch-profile               # must refuse to start: no KeyVault:VaultUri outside Development

$env:KeyVault__VaultUri = 'https://kv-uni-<suffix>-b06.vault.azure.net/'
dotnet run --no-launch-profile               # must refuse to start: the Key Vault connection string has a SQL login and password
Remove-Item Env:ASPNETCORE_ENVIRONMENT, Env:KeyVault__VaultUri
```

User secrets load only in Development, so the Production runs read `KeyVault:VaultUri` from the environment variable. Put the failure messages in the commit body. **If the agent loads Key Vault only outside Development** (as the Upgrade agent did in the comparison), the first run can't show a Key Vault read. Then the third run is the proof: with `KeyVault__VaultUri` set in Production, the app must read `ConnectionStrings--DefaultConnection` from Key Vault and then refuse its SQL login. Say in the commit body which design the agent chose.

Task 006's check. `appi-uni-<suffix>-b06` has local authentication off, so ingestion uses your Azure CLI sign-in through `DefaultAzureCredential` and the Monitoring Metrics Publisher role:

```powershell
az extension add -n application-insights --only-show-errors    # install it first: an auto-install mid-command garbled the value in the comparison
$cs = az monitor app-insights component show -g rg-spike-b06 -a appi-uni-<suffix>-b06 --query connectionString -o tsv --only-show-errors
if ($cs -notmatch '^InstrumentationKey=') { throw 'Bad connection string: it must start with InstrumentationKey=' }
Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
dotnet user-secrets set 'APPLICATIONINSIGHTS_CONNECTION_STRING' $cs
dotnet run                                   # open the five pages, edit a student, then wait 3-5 minutes
az monitor app-insights query -g rg-spike-b06 -a appi-uni-<suffix>-b06 --analytics-query "union requests, dependencies, traces | where timestamp > ago(30m) | summarize count() by itemType" --query "tables[0].rows" -o tsv    # -o table prints nothing for this result shape
```

All three item types must show. You can also look in the portal: **Application Insights** > **Transaction search**. A connection string that's set but invalid crashes the app at startup ("Required keyword 'InstrumentationKey' is missing in connection string"), because the Azure Monitor distro checks it when the host starts. The app only has to start with **no** value, so check the value before you set it. The connection string isn't a secret, but it stays in user secrets, not in a committed file.

## Step 5: Gaps

Run 2's plan covers the old gaps in its tasks: `Global.asax`, bundling, dependency injection and the `Site.css` case in task 001, and OpenTelemetry in task 006. Check that nothing is left, and note the result in the commit body:

1. `Global.asax` and `App_Start` are gone; `NotificationService` comes from dependency injection in `Program.cs`; the `Site.css` file name matches every reference.
2. `git grep -n -i -E "System\.Web|System\.Messaging|MSMQ|MessageQueue|Trace\.|Debug\.Write" -- app/ContosoUniversity` prints nothing.
3. If something is left, ask for it in a new chat with `modernize` and GPT-6 Luna at maximum, ending the prompt with the scope line. Commit and push: `run2: step 5 gaps`, or say "none left" in the task 007 commit body.

## Step 6: Package

Build the image with .NET SDK container publishing (no Docker) and push it to the private registry over its private endpoint:

```powershell
Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
$token = az acr login --name cruni<suffix>b06 --expose-token | ConvertFrom-Json
$env:DOTNET_CONTAINER_REGISTRY_UNAME = $token.username
$env:DOTNET_CONTAINER_REGISTRY_PWORD = $token.accessToken
dotnet publish -c Release /t:PublishContainer -p:ContainerRegistry=cruni<suffix>b06.azurecr.io -p:ContainerRepository=contoso-university -p:ContainerImageTag=run2
Remove-Item Env:DOTNET_CONTAINER_REGISTRY_UNAME, Env:DOTNET_CONTAINER_REGISTRY_PWORD
az acr repository show-tags --name cruni<suffix>b06 --repository contoso-university -o table
```

If the project needs container properties (for example `ContainerBaseImage` or `ContainerPort`), commit them. Commit: `run2: step 6 package`, with the `show-tags` output in the body.

## Step 7: Finish the run

1. Check that `chats\` has an export for every chat, and that `run2-versions.txt` is committed.
2. Push: `git push -u origin spike/b06-run2`.
3. Tell the executor the run is pushed, with the results of the 🧑 checks: the five pages, the upload, the notification round trip, Key Vault and both refusals to start, telemetry in Application Insights, startup without it, and the image tag. The executor fills in `run2.md`, runs the build, reference, registry and secrets checks, and writes the report.

## Comparison: GitHub Copilot upgrade (after run 1, before run 2)

**(v2, owner-approved)** A full end-to-end run with the separate **GitHub Copilot upgrade** extension (`ms-dotnettools.upgrade-agent`, the **Upgrade** agent, `@upgrade`) instead of the `modernize` agent: assess, plan, upgrade to .NET 10, then migrate to SQL Managed Instance, Blob, Service Bus and Key Vault. That's the same scope as run 1's steps 2–4, with the same kit rules and configuration keys. Fill in [compare-upgrade.md](compare-upgrade.md) stage by stage. The Upgrade agent may not cover the Azure migrations at all: that's a result to record, not a failure.

### C.1 Set up

1. Install the extension on `vm-dev01` by hand (nothing in the kit installs it), record its version, and reload the window:

   ```powershell
   code --install-extension ms-dotnettools.upgrade-agent
   code --list-extensions --show-versions | Select-String 'upgrade-agent|migrate-java-to-azure'
   ```

2. **Disable GitHub Copilot modernization for this run (owner decision), so the Upgrade agent is tested strictly on its own:** **Extensions** > **GitHub Copilot modernization** > **Disable (Workspace)**, then reload. The Upgrade agent's `azure-migrate` scenario delegates Azure assessment and planning to the App Modernization session. Where it can't do a stage without modernize (the first attempt reported "the prescribed App Modernization session tool was unavailable"), record that as a result in `compare-upgrade.md`, not a failure, and go on to the next stage. Re-enable modernize after the run.
3. Create the comparison branch from run 1's start commit:

   ```powershell
   Set-Location C:\src\apex-factory-hackathon
   git status --short                   # must print nothing
   git fetch origin
   git switch -c spike/b06-upgrade-compare da4e5f606983332001c94ce69b48634f9c1864b3
   git clean -ndx -- app .github         # dry run: lists leftover untracked and ignored files
   ```

   **Make the tree pure legacy.** `git switch` keeps untracked and ignored files, so run 1's leftovers (for example `.github\modernize\`, `.github\skills\`, `bin` and `obj`) survive it. In the first attempt they made the Upgrade agent edit run 1's plan and load run 1's skill. Check the dry-run list: nothing in it is needed, because user secrets live outside the repo. Then delete them and commit:

   ```powershell
   git clean -fdx -- app .github
   git status --short --ignored -- app .github    # must print nothing
   git commit --allow-empty -m "compare: stage 1 set up"
   ```

### C.2 Assess and plan

**(v2, the owner's method)** Use the Upgrade agent's stateful, dashboard-compatible `dotnet-version-upgrade` scenario, in the **Copilot** harness. Left to itself, the Upgrade agent picks the `azure-migrate` scenario, which hands assessment and planning to GitHub Copilot modernization's App Modernization session, and that fails with modernize disabled. The prompt forces `dotnet-version-upgrade` under `.github/upgrades/dotnet-version-upgrade/`, which the Upgrade dashboard can open.

> [!WARNING]
> **BEFORE you send:** in the Chat panel, set the harness (**Session Target**) to **Copilot**, not **Local**. Start a **new chat**, and check that the agent picker shows **Upgrade** and the model picker shows **GPT-6 Sol** with reasoning **Medium**, as for run 1's planning. The chat uses whatever is selected. The pickers sit at the bottom of the chat input box.

1. ⚠️ **BEFORE you send:** harness **Copilot**, new chat, agent **Upgrade**, model **GPT-6 Sol** at **Medium**.
2. Copy the whole prompt [prompts/compare-upgrade-plan.md](prompts/compare-upgrade-plan.md) and send it. The comparison branch starts from run 1's commit, which doesn't have the file, so fetch it straight from origin, never from a local copy (in the second attempt a stale copy sent the old six-task prompt):

   ```powershell
   git fetch origin
   $prompt = git show origin/jonathan-vella-b06-ghcp-spike:docs/spikes/B06-ghcp-golden-path/prompts/compare-upgrade-plan.md | Out-String
   if ($prompt -notmatch 'exactly these seven') { throw 'Stale prompt: it must contain "exactly these seven"' }
   $prompt | Set-Clipboard
   ```

   Then paste it into the chat. It asks for:
   - the owning scenario `dotnet-version-upgrade`, never `azure-migrate`, no `start_app_mod_migration_session`, and nothing under `.github/modernize`;
   - Guided flow, assessment and planning only;
   - exactly seven tasks in a strict chain, the same tasks and rules as run 2's plan: SDK container publishing in task 1 (no Dockerfile), Entra authentication only on Azure, Key Vault mandatory outside Development, private backends, OpenTelemetry as task 6, and task 7 kept as a verified no-op if there are no CVEs;
   - the artifacts `assessment.md`, `plan.md` and `scenario-instructions.md`;
   - a 9-row compliance table, with blocked validations kept apart from impossible tasks;
   - a stop before `start_task`.
3. Check the answer: the artifacts are under `.github\upgrades\` (in the second attempt, `.github\upgrades\scenarios\dotnet-version-upgrade\`), there's nothing new under `.github\modernize\`, all 9 table rows are met, and the plan opens in the Upgrade dashboard. Record in `compare-upgrade.md` what it covers, anything it lists as blocked or impossible, and whether it changed any file outside `.github\upgrades\`.
4. Export the chat, then commit and push: `compare: stage 2 assess and plan`.

### C.3 Upgrade and migrate

> [!WARNING]
> **BEFORE you run a task: switch the harness (Session Target) to LOCAL.** Planning works in the Copilot harness, but task execution doesn't: there, `start_task` fails with "plan.md exists but could not be parsed into tasks… internal LLM client unavailable". The Upgrade MCP server's plan parser needs a model through MCP sampling, which VS Code provides only in the **Local** harness. Once, give it access: **MCP: List Servers** > **Upgrade** > **Configure Model Access**. Then start a **new chat**, and check that the agent picker shows **Upgrade** and the model picker shows **GPT-6 Luna** with reasoning **maximum**, as for run 1's execution.

For each of the plan's seven tasks in order (.NET 10 upgrade, SQL Managed Instance, Blob, Service Bus, Key Vault, OpenTelemetry, CVE fixes):

1. ⚠️ **BEFORE you send:** harness **Local** (not Copilot), new chat, agent **Upgrade**, model **GPT-6 Luna** at **maximum**.
2. Ask it to do that stage of its plan, for example `Do the .NET 10 upgrade task of your plan, and nothing else.` If it says a stage is out of its scope, don't force it: record that and go on to the next stage.
3. Build, run the app, then do that task's check from the step 4 check table (the five pages, Students, a Blob upload, Service Bus send **and** receive, Key Vault with both refusals to start, telemetry in Application Insights, and the CVE list).
4. Check `git status --short --branch`, commit and push: `compare: stage 3.N <stage>`. Put interventions in the commit body, one line each, and export the chat.

After the last stage, re-enable GitHub Copilot modernization if you disabled it, and tell the executor the branch is pushed. For run 2, note in `compare-upgrade.md` whether the `modernize` agent behaves differently with the upgrade extension installed.

## 11a rerun: GitHub Copilot upgrade in VS Code

**(Owner request, 2026-10-01.)** Rerun the VS Code comparison from scratch to retest finding 51: does `start_task` work in the **Copilot** harness once the Upgrade MCP server has model access? The finished comparison ([compare-upgrade.md](compare-upgrade.md)) stays as it is. Fill in [compare-upgrade-v2.md](compare-upgrade-v2.md) stage by stage.

**v2 and v3 (owner decision, 2026-10-01).** v2, on `spike/b06-upgrade-compare-v2`, ran stage 2 in the **Copilot** harness (`b49ce4b`: tool-based assessment and a compliant plan, 0 interventions) and is kept as evidence; `start_task` wasn't tried there. **v3 restarts from scratch in the Local harness** on `spike/b06-upgrade-compare-v3` from `da4e5f6`, with the same prompt, addendum and models. For v3, follow R.1–R.3 with these changes:

- Use `spike/b06-upgrade-compare-v3` wherever R.1–R.3 say `spike/b06-upgrade-compare-v2`.
- Set the harness (**Session Target**) to **Local** for stage 2 **and** every task, instead of Copilot. The fallback in R.3 step 2 doesn't apply.
- Name the chat exports `chats\compare-v3-stage2.txt` and `chats\compare-v3-task0N.txt`.

> [!NOTE]
> **Run this after issue #28** (Bastion Standard with the native RDP client). That redeploy drops your Bastion session, so don't start the rerun before it's done. The spike resources keep running for the rerun, at about $1.05/hour.

### R.1 Set up

1. Check that GitHub Copilot modernization is still **Disabled (Workspace)**, as in C.1 step 2, and record the extension versions. 11a reported Upgrade agent 1.1.596; the Copilot app's plugin is now 1.1.612:

   ```powershell
   code --list-extensions --show-versions | Select-String 'upgrade-agent|migrate-java-to-azure'
   ```

2. Create the branch and make the tree pure legacy, as in C.1:

   ```powershell
   Set-Location C:\src\apex-factory-hackathon
   git status --short                   # must print nothing
   git fetch origin
   git switch -c spike/b06-upgrade-compare-v2 da4e5f606983332001c94ce69b48634f9c1864b3
   git clean -ndx -- app .github         # dry run
   git clean -fdx -- app .github
   git status --short --ignored -- app .github    # must print nothing
   git commit --allow-empty -m "app: stage 1 set up" -m "upgrade-agent <version>; modernization disabled (Workspace)"
   git push -u origin spike/b06-upgrade-compare-v2
   ```

3. **The variable under test, before stage 2:** **MCP: List Servers** > **Upgrade** > **Configure Model Access**, and allow **Claude Opus 5.5** and **GPT-6 Luna**. In 11a this was done only after `start_task` had failed in the Copilot harness. If `chat.mcp.serverSampling` already allows `GitHub Copilot upgrade: Upgrade` (`allowedDuringChat: true`), left from 11a, record that and change nothing.

### R.2 Assess and plan

> [!WARNING]
> **BEFORE you send:** harness (**Session Target**) **Copilot**, a new chat, agent **Upgrade**, model **Claude Opus 5.5** at **Medium** (owner decision, 2026-10-01; 11a planned with GPT-6 Sol).

1. Fetch the same prompt and addendum as the Copilot app comparison straight from origin, and paste them as one message, the prompt first:

   ```powershell
   git fetch origin
   [Console]::OutputEncoding = [Text.Encoding]::UTF8
   $base = 'origin/jonathan-vella-b06-ghcp-spike:docs/spikes/B06-ghcp-golden-path/prompts'
   $prompt = git show "$base/compare-upgrade-plan.md" | Out-String
   $addendum = git show "$base/compare-upgrade-app-addendum.md" | Out-String
   if ($prompt -notmatch 'exactly these seven') { throw 'Stale prompt: it must contain "exactly these seven"' }
   if ($addendum -notmatch 'Owner decisions for this run') { throw 'Missing addendum' }
   if ($prompt -match 'ΓÇ') { throw 'Mis-encoded prompt' }
   ($prompt.TrimEnd() + "`n`n" + $addendum) | Set-Clipboard
   ```

2. Check the plan as in C.2.3 and A.2.5: the artifacts under `.github\upgrades\scenarios\dotnet-version-upgrade\`, including `assessment.json` and `dependencies-health.json`; the dashboard's **Assessment** tab populated; nothing under `.github\modernize\`; exactly seven tasks in a strict chain; all 9 rows met; no application files changed; no `#skill:migrating-webapi-odata`.
3. Export the chat as `chats\compare-v2-stage2.txt`, commit and push: `app: stage 2 assess and plan`.

### R.3 Tasks 1–7

> [!WARNING]
> **BEFORE each task:** stay in the **Copilot** harness. New chat, agent **Upgrade**, model **GPT-6 Luna** at **maximum**.

For each of the plan's seven tasks in order:

1. ⚠️ **BEFORE you send:** harness **Copilot**, new chat, agent **Upgrade**, model **GPT-6 Luna** at **maximum**.
2. Start the task with `start_task` (or from the dashboard's **Execution** tab). **Only if it fails with "internal LLM client unavailable"**, copy the exact error text into the commit body, switch the harness to **Local**, and run the task there; that confirms finding 51. Record which harness each task ran in.
3. Build, run the app, and do that task's check, as in C.3.3.
4. Check `git status --short --branch`, then commit and push to `spike/b06-upgrade-compare-v2`: `app: stage 3.N <stage>`. Put the harness and the interventions in the commit body, one line each, and export the chat as `chats\compare-v2-task0N.txt`.

After the last task, tell the executor the branch is pushed. Leave GitHub Copilot modernization disabled until run 2 needs it.

## Comparison: GitHub Copilot upgrade in the Copilot app (after the VS Code comparison, before run 2)

**(Owner-approved, 2026-09-29, requirement 11b.)** Repeat the full Upgrade agent comparison in the **GitHub Copilot app** instead of VS Code, with the Upgrade agent from the [microsoft/upgrade-agent-plugins](https://github.com/microsoft/upgrade-agent-plugins) marketplace (plugin `upgrade-agent`, marketplace version 1.1.596, checked 2026-09-29, the same version the VS Code comparison reported; attempt 2 runs 1.1.612 after a clean reinstall), the same kit rules, configuration keys and live checks. Install only `upgrade-agent@upgrade-agent-plugins`: no modernization plugin. Fill in [compare-upgrade-app.md](compare-upgrade-app.md) stage by stage, and write down what's different about the app as you go (see its **Questions** section).

**Attempt 2 (owner decision, 2026-09-30).** Attempt 1, on `spike/b06-upgrade-app`, was abandoned during task 01 (see `compare-upgrade-app.md`). Attempt 2 runs from scratch on **`spike/b06-upgrade-app-v2`**, with two owner-approved changes:

- **Models:** **Claude Opus 5.5** to assess and plan, **Claude Sonnet 5.5** to execute. The VS Code comparison used GPT-6 Sol and GPT-6 Luna, so the two comparisons aren't like for like on models.
- **Prompt:** the refined [prompts/compare-upgrade-plan.md](prompts/compare-upgrade-plan.md) verbatim, followed by the owner-decisions addendum [prompts/compare-upgrade-app-addendum.md](prompts/compare-upgrade-app-addendum.md), which answers attempt 1's blockers up front: no OData skill, the interim queue until task 4, no work outside the seven tasks, validation only in the app, no LocalDB, and backend checks expected to run inside the VNet. *(Owner-directed, 2026-10-01.)* The prompt itself now requires the Upgrade workflow tools and the dedicated .NET assessor, pauses at the assessment gate, and answers the pre-initialization confirmation (`net10.0`, Guided, current branch, Manual commits, branch sync off).

### A.1 Set up

1. The GitHub Copilot app and the `upgrade-agent` plugin are already installed from attempt 1. If you install them again, use the README's deep link, [Add this marketplace in the GitHub Copilot app](https://github.com/copilot/app/launch?entry_point=upgrade_agent_plugins_readme&open=ghapp%3A%2F%2Fplugins%2Fmarketplace%2Fadd%3Fsource%3Dmicrosoft%2Fupgrade-agent-plugins), then **Install** on `upgrade-agent`, or in a session `/plugin marketplace add microsoft/upgrade-agent-plugins` then `/plugin install upgrade-agent@upgrade-agent-plugins`. App versions before 1.0.3 need a restart after the install. **Record the app and plugin versions** in the stage 1 commit body and `compare-upgrade-app.md` (attempt 1 didn't). For attempt 2 the owner reinstalled the app and the plugin from clean, which gave plugin **1.1.612**, not the 1.1.596 the VS Code comparison used, so the Upgrade agent's version now differs between the two comparisons.
2. Close attempt 1's session in the app. Its worktree, with about 50,000 uncommitted changes, stays as it is: don't commit or push from it.
3. Create the attempt 2 branch from run 1's start commit and make the tree pure legacy, as in C.1:

   ```powershell
   Set-Location C:\src\apex-factory-hackathon
   git status --short                   # must print nothing
   git fetch origin
   git switch -c spike/b06-upgrade-app-v2 da4e5f606983332001c94ce69b48634f9c1864b3
   git clean -ndx -- app .github         # dry run
   git clean -fdx -- app .github
   git status --short --ignored -- app .github    # must print nothing
   git commit --allow-empty -m "app: stage 1 set up" -m "Copilot app <version>; upgrade-agent <version>"
   git push -u origin spike/b06-upgrade-app-v2
   ```

   Done for attempt 2. Its first stage 2 was void (finding 65) and was removed in `37a22b6`; redo stage 2 from there.

4. In the Copilot app, start a new session on the project. **The app's default is a worktree session**: it creates its own checkout and branch under `C:\Users\<user>\.copilot\repos\copilot-worktrees\apex-factory-hackathon\<session-branch>`, not in `C:\src`, and the chat footer shows the path and branch. That's what an attendee gets, so use it. Check the worktree's base (`git -C <worktree-path> log --oneline -1` must be `da4e5f6` or `spike/b06-upgrade-app-v2`), and push its work to `spike/b06-upgrade-app-v2` after each stage: `git -C <worktree-path> push origin HEAD:spike/b06-upgrade-app-v2`. If the app offers a **branch** session on the existing clone, that works too; note which you used.
5. **Set the user secrets for the worktree's project before any check** (step 1.8, with `--project <worktree-path>\app\ContosoUniversity`). The project's `UserSecretsId` can differ from the one in `C:\src`, and without the SQL secret the app falls back to LocalDB.
6. 🔎 VERIFY how the Copilot app exports a conversation. If there's no export, select all in the conversation, copy it and save it as `docs\spikes\B06-ghcp-golden-path\chats\app-v2-stage<N>.txt`. Record which way you used.
7. **Preflight before stage 2: the .NET analysis tools.** The plugin's .NET analysis tools, including `generate_dotnet_upgrade_assessment`, come from a separate extension server (`Microsoft.GitHubCopilot.Upgrade.DotNet.Mcp`). In attempt 2's void first stage 2 they never appeared, for an unknown reason (finding 65). Pick **Upgrade** in the agent picker and start a new session, but don't send the prompt yet. Then run this in PowerShell:

   ```powershell
   Get-ChildItem "$env:USERPROFILE\.nuget\packages" -Directory | Where-Object Name -like 'microsoft.githubcopilot.upgrade*' | ForEach-Object { $_.Name + ' ' + ((Get-ChildItem $_.FullName -Name) -join ',') }
   ```

   It must list both `microsoft.githubcopilot.upgrade.mcp` and `microsoft.githubcopilot.upgrade.dotnet.mcp`, each with its versions. If either is missing, don't send the prompt: tell the executor. Both being listed doesn't prove the tools load: the proof is that the dedicated assessor produces `assessment.json` (A.2 step 5). If it doesn't, or the agent says the tool is unavailable, stop and tell the executor.

### A.2 Assess and plan

> [!WARNING]
> **BEFORE you send:** start a **new session**, pick **Upgrade** in the agent picker, and pick **Claude Opus 5.5**. Keep this session for the whole run, including the tasks.

1. ⚠️ **BEFORE you send:** new session, agent **Upgrade**, model **Claude Opus 5.5**.
2. Fetch the prompt and the addendum straight from origin, check them, and paste them as one message, the prompt first:

   ```powershell
   git fetch origin
   [Console]::OutputEncoding = [Text.Encoding]::UTF8
   $base = 'origin/jonathan-vella-b06-ghcp-spike:docs/spikes/B06-ghcp-golden-path/prompts'
   $prompt = git show "$base/compare-upgrade-plan.md" | Out-String
   $addendum = git show "$base/compare-upgrade-app-addendum.md" | Out-String
   if ($prompt -notmatch 'exactly these seven') { throw 'Stale prompt: it must contain "exactly these seven"' }
   if ($addendum -notmatch 'Owner decisions for this run') { throw 'Missing addendum' }
   if ($prompt -match 'ΓÇ') { throw 'Mis-encoded prompt' }
   ($prompt.TrimEnd() + "`n`n" + $addendum) | Set-Clipboard
   ```

3. The prompt answers the pre-initialization confirmation: target framework `net10.0`, Guided, the current branch (no new working branch), **commit strategy Manual** and **branch sync off**. Check the app shows those settings, and record what it showed. Attempt 1 defaulted to After Each Task with Auto (Merge).
4. The dashboard renders inside the app (Overview, Assessment, Plan, Execution and Activity tabs). In Guided mode the app pauses at the **assessment** gate and again at the **plan** gate; approve each to continue. Attempt 2's void first stage 2 ran straight through the assessment gate, so the prompt now asks for that pause.
5. Check the plan as in C.2.3: the artifacts under `.github\upgrades\scenarios\dotnet-version-upgrade\`, including `assessment.json` and `dependencies-health.json` next to `assessment.md`; the dashboard's **Assessment** tab populated; the properties in `scenario.json` include `UpgradeTargetFramework` `net10.0`; nothing under `.github\modernize\`, exactly seven tasks in a strict chain, all 9 table rows met, no application files changed, and **no `#skill:migrating-webapi-odata`**. If the skill is there anyway, ask the agent to remove it before you approve the plan.
6. Save the conversation, commit in the worktree and push to `spike/b06-upgrade-app-v2`: `app: stage 2 assess and plan`.

### A.3 Tasks 1–7

Stay in the **same session** from assessment through execution, and switch only the model picker. The Copilot app has no Copilot/Local harness split, so VS Code's rule that execution needs the Local harness (C.3) doesn't apply here.

> [!WARNING]
> **BEFORE each task:** in the same session, check that the agent is still **Upgrade**, and switch the model picker to **Claude Sonnet 5.5**.

For each of the plan's seven tasks in order:

1. ⚠️ **BEFORE you run it:** same session, agent **Upgrade**, model **Claude Sonnet 5.5**.
2. Start the task (`start_task`, or approve it in the dashboard's **Execution** tab), and reply `continue` when it asks. If a task blocks, record the message and start a new session with the same agent and model. If the agent drifts from the addendum anyway, remind it with one line:
   - OData gate: `The only consumer of the notification JSON endpoints is the app's own notifications.js. Don't use migrating-webapi-odata; preserve the routes, methods and JSON shape.`
   - Durable queue: `Keep the interim in-process queue until task 4, which replaces it with Service Bus.`
   - Extra work: `Do no work outside this task. Record the finding as a recommendation only.`
   - Repo checks: `Scope all validation to app/ContosoUniversity. Don't run the repository's PowerShell or npm checks.`

   Each reminder counts as an intervention.
3. Build, run the app, then do that task's check from the step 4 check table, as in C.3.3.
4. Check the worktree with `git -C <worktree-path> status --short --branch`, and count the changed files (`git -C <worktree-path> status --short | Measure-Object`): hundreds is normal, tens of thousands means build or restore output (`bin`, `obj`, `.vs`, packages) isn't ignored. Don't commit that: fix `.gitignore` first. Commit in the worktree with the message `app: stage 3.N <stage>` and the interventions in the body, one line each, then push: `git -C <worktree-path> push origin HEAD:spike/b06-upgrade-app-v2`. Save the conversation.

After the last task, tell the executor the branch is pushed.

## Optional: step 2 with Copilot CLI

After step 2, repeat the assessment with Copilot CLI on a throwaway branch, and note the differences (time, findings, tasks, premium requests) in the commit message body when you copy its report in:

```powershell
git switch -c spike/b06-run2-cli-scratch
copilot --version
copilot
```

In Copilot CLI, install the modernization plugin once:

```text
/plugin marketplace add microsoft/github-copilot-modernization
/plugin install github-copilot-modernization@github-copilot-modernization
```

Then start it with the modernize agent from `app/ContosoUniversity` (`copilot --agent=github-copilot-modernization:modernize`) and prompt `assess my application`. Stop when it asks **Proceed to planning?**. Copy its report into `docs/spikes/B06-ghcp-golden-path/assessment/run2-cli/` on the run branch, then delete the scratch branch.

## Changes from v1

Run 1 started from v1 and changed it during the run; v2 is the result. Details and evidence are in the [report's findings](README.md#findings).

| Area | v2 | Why (run 1 findings) |
|---|---|---|
| Sign-in | Device code flows on your own device; git identity with the no-reply email and `gh auth setup-git`; pick your own subscription | Bastion sign-in, no git identity, one subscription per attendee (2, 3) |
| Credentials | `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` on `vm-dev01` only | The VM's managed identity has no data roles (1) |
| Configuration | All user secrets set in step 1 | Tasks could be checked against the real services straight away |
| Recording | Commit timestamps, chat exports (`.json` or `.txt`), interventions in commit bodies; the executor fills in the sheet | Owner decision; the JSON export failed once (24) |
| Assessment | Custom assessment, target App Service for Linux (containers) | The default targets App Service (Windows) (5, 15) |
| Plan | No **Create Plan**; `/create-modernization-plan` with the seven kit rules in a new chat; a wrong plan is regenerated, never corrected | **Create Plan** missed the upgrade, kept both alternatives and added Entra ID; a finished plan can't be revised (6, 7, 20–27) |
| Prompt files and skills | Not used | The Copilot harness doesn't load prompt files; workspace skills didn't show (10–17) |
| Execution | One task per new chat with a direct "implement task, work directly, don't delegate" prompt; default Agent as the fallback | The plan-execution delegation blocked three of six tasks (28, 32, 37–40) |
| Branches | Bring each task's work onto the run branch and push before the next task | `appmod/*` branches, uncommitted work stashed by the next task (29, 31, 33, 35) |
| Checks | Run the app after every task; a check table per task, including Service Bus receive | The agent's validation never starts the app (36, 43) |
| Scope | Every prompt ends with the scope line; revert changes outside the app | A repo-wide check edited `docs/prd.md` (44) |
| Gaps | Only OpenTelemetry is left; predefined task, then make Azure Monitor optional | Tasks 001–005 did the other gaps (42, 43) |
| Comparison | Full end-to-end run with GitHub Copilot upgrade before run 2 | Owner-approved (requirement 11a; findings 19, 30) |
| Comparison C.1 | Run `git clean -fdx -- app .github` after `git switch` (dry run first) so the tree is pure legacy; GitHub Copilot modernization stays disabled (owner decision), and a stage the Upgrade agent can't do without it is recorded as a result | The first comparison attempt's stage 2 (`a6c358d`) edited run 1's plan folder and loaded run 1's `modernize-plan` skill from leftover files; with modernize disabled, the Upgrade agent's `azure-migrate` scenario couldn't delegate |
| Comparison C.2 | The owner's prompt file `prompts/compare-upgrade-plan.md` in the **Copilot** harness forces the stateful `dotnet-version-upgrade` scenario (the seven-task chain and kit rules since the refinement, dashboard artifacts under `.github/upgrades/`) | The default routing picked `azure-migrate`, which needs GitHub Copilot modernization's session tool. Forcing `dotnet-version-upgrade` makes the Upgrade dashboard work, and only in the Copilot harness |
| 3, 4, 5 | The plan prompt is the file `prompts/run2-modernize-plan.md`: seven tasks (OpenTelemetry becomes task 006, CVE fixes task 007) and nine rules, from the owner's target state. New checks: telemetry in Application Insights after task 006; refusal to start outside Development without `KeyVault:VaultUri` or with a SQL login, after task 005. Step 5 only checks that nothing is left | Owner decisions after run 1: Entra authentication only on Azure, Key Vault mandatory outside Development, private backends, simple OpenTelemetry visible in Application Insights, SDK container publishing only |
| Run 2 start | Run 2 starts from `e850869` instead of `7c2855b` | The refined prompts under `prompts/` have to be on the run branch |
| Comparison C.2 | Fetch the prompt with `git show origin/<branch>:…/compare-upgrade-plan.md` and check it contains "exactly these seven" before pasting | The second attempt (`1ae9076`) sent a stale local copy of the old six-task prompt |
| Comparison C.3 | Run the Upgrade agent's tasks in the **Local** harness, after **MCP: List Servers** > **Upgrade** > **Configure Model Access** | `start_task` failed in the Copilot harness with "internal LLM client unavailable": the plan parser needs MCP sampling, which only the Local harness provides |
| Copilot app comparison | **Owner-approved** (requirement 11b): after the VS Code comparison, repeat it in the GitHub Copilot app with the `upgrade-agent` plugin, on `spike/b06-upgrade-app` from `da4e5f6` | Only the host changes, to see whether the app is a better home for the Upgrade agent than VS Code |
| 4 task 005 | If Key Vault loads only outside Development, prove the Key Vault read with Production plus `KeyVault__VaultUri`, expecting the refusal of the SQL login | The comparison's Upgrade agent loaded Key Vault only outside Development, so a Development run never reads it (`9f70212`) |
| 4 task 006 | Install the `application-insights` CLI extension first, and check that the connection string starts with `InstrumentationKey=` before setting the user secret | In the comparison, the extension auto-installed mid-command, the secret got a garbled value, and the app crashed at startup on the invalid connection string |
| 4 task 006 | Read the Application Insights query with `--query "tables[0].rows" -o tsv` | `az monitor app-insights query … -o table` printed nothing for this result shape in the comparison |
| Copilot app A.1, A.2 | The app's default session is a worktree under `.copilot\repos\copilot-worktrees\`; find it in the chat footer and push its work to `spike/b06-upgrade-app`. The dashboard renders in the app, and Guided mode pauses at the assessment gate | The first Copilot app session was a worktree, not a branch session on `C:\src`; the owner continued in it as the attendee default |
| Copilot app A.3 | One session from assessment through execution; switch only the model picker (GPT-6 Sol Medium to plan, GPT-6 Luna maximum for each task); commit in the worktree and push to `spike/b06-upgrade-app` | The Copilot app has no Copilot/Local harness split, so the VS Code rule that execution needs Local doesn't apply |
| Copilot app A.2, A.3 | Remove `#skill:migrating-webapi-odata` from task 01 before approving the plan; if its gate still stops a task, answer it with the notification-endpoint reply. Keep validation inside `app/ContosoUniversity` | The Copilot app's task 01 was blocked by the OData skill's compatibility gate (unknown consumers of the notification JSON endpoints, no API contract tests), which the VS Code run had removed from the plan. The agent also ran the kit's PowerShell preflight and `npm test`, which aren't part of the app |
| Copilot app A.3 | Set user secrets for the worktree's project before the checks; keep the interim notification queue until task 04; check the app's automatic commits and merges, and the changed-file count, before pushing | Task 01's page checks fell back to LocalDB without the SQL secret; the workflow asked to pull Service Bus into task 01; the app's scenario uses After Each Task commits with Auto (Merge) sync; the run showed more than 50,000 changed files before any commit |
| Copilot app comparison | **Owner decision:** restart from scratch as attempt 2 on `spike/b06-upgrade-app-v2`, with Claude Opus 5.5 to plan and Claude Sonnet 5.5 to execute (not like for like with the VS Code comparison's GPT-6 models), and the prompt followed by `prompts/compare-upgrade-app-addendum.md` | Attempt 1 was stopped by the OData gate, the default After Each Task and Auto (Merge) settings, an unplanned task split, a LocalDB fallback, out-of-scope checks and about 50,000 unpushed file changes |
| Copilot app comparison, attempt 2 stage 2 | **Owner-directed:** the prompt requires the Upgrade workflow tools and the dedicated .NET assessor, pauses at the assessment gate, answers the pre-initialization confirmation and is pure ASCII; a NuGet-cache preflight (A.1 step 7), UTF-8 and mis-encoding checks on the clipboard block, and `assessment.json` plus a populated dashboard required in A.2 step 5 | Finding 65: the void first stage 2 ran without the .NET analysis tools (cause unknown) |
| 11a rerun | **Owner request:** rerun the VS Code comparison on `spike/b06-upgrade-compare-v2` with **Configure Model Access** set before stage 2, and `start_task` in the **Copilot** harness; Local only if it fails with `internal LLM client unavailable` | Retests finding 51 |
| 11a rerun v3 | **Owner decision:** keep v2's Copilot-harness stage 2 (`b49ce4b`) as evidence and run the full rerun in the **Local** harness on `spike/b06-upgrade-compare-v3` | v2 showed planning works in the Copilot harness with model access allowed |
