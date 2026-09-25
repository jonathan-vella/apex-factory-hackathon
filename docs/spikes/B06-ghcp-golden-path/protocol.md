# B06 run protocol v2: GHCP golden path on `vm-dev01`

The steps the owner follows on `vm-dev01` for each run of the [B06 spike](../../backlog/B06-spike-ghcp.md). They assume you haven't used GitHub Copilot modernization before. Version 2 is the refined sequence for run 2, rewritten from everything run 1 found (see the [report](README.md#findings) and [Changes from v1](#changes-from-v1)). You don't fill in the results sheets: the executor fills in [run1.md](run1.md) and [run2.md](run2.md) from your commits, chat exports and versions file after you push.

| Run | Branch | Start from commit | Protocol version |
|---|---|---|---|
| 1 | `spike/b06-run1` | `da4e5f606983332001c94ce69b48634f9c1864b3` | v1 (changed into v2 during the run) |
| Comparison | `spike/b06-upgrade-compare` | `da4e5f606983332001c94ce69b48634f9c1864b3` | [Comparison section](#comparison-github-copilot-upgrade-after-run-1-before-run-2) |
| 2 | `spike/b06-run2` | `7c2855bd3e99c48e94b7b01817a0ca84eae43fa4` | v2 |

Order: the comparison run first, then run 2.

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
3. **Plan:** a new chat, `modernize` with GPT-6 Sol at Medium, `/create-modernization-plan` with the seven kit rules. A wrong plan is deleted and generated again, never corrected.
4. **Execute (C6):** one task per new chat, `modernize` with GPT-6 Luna at maximum, with a **direct prompt** per task. After each task: bring the work onto the run branch, run the app, check, commit and push.
5. **Gaps:** only OpenTelemetry is left after the plan; use the predefined task, then make Azure Monitor optional.
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
   git switch -c spike/b06-run2 7c2855bd3e99c48e94b7b01817a0ca84eae43fa4
   git diff --stat 7c2855bd3e99c48e94b7b01817a0ca84eae43fa4 origin/main -- app/ContosoUniversity
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

1. Open the **GitHub Copilot modernization** view in the Activity Bar and run a **custom assessment**, not the default **Start Assessment**. Set the target to **Azure App Service for Linux (containers)** and leave the other options at their defaults (run 1 didn't record them; note any you change in the commit body). If it asks which project, pick `app/ContosoUniversity`. The assessment uses the extension's default model; you can't pick one.
2. In the report, check that the target is **Azure App Service (Linux)**. If it shows **Azure App Service (Windows)**, switch it and note it.
3. Read the report: note the issues for local files, MSMQ, the database, the plaintext connection string and `System.Web`. It flags **Windows authentication detected** as mandatory, but the app has no user sign-in: the finding comes only from `IISExpressWindowsAuthentication` and `Integrated Security=True` in the old LocalDB connection string. Rule 2 of the plan removes it.
4. **Don't select Create Plan.** It plans only the service migrations, keeps both storage and both database alternatives, adds an Entra ID task, and a finished plan can't be corrected afterwards.
5. Save the report: copy the files from `app\ContosoUniversity\.github\modernize\assessment\reports\report-<timestamp>\` to `docs\spikes\B06-ghcp-golden-path\assessment\run2\`, plus `...\assessment\engines\dotnet-appcat\result\report.json` as `appcat-report.json`, then `git add docs/spikes/B06-ghcp-golden-path/assessment`.
6. Commit: `run2: step 2 assessment`.

## Step 3: Plan

> [!WARNING]
> **BEFORE you send the planning prompt:** start a **new chat**, and check that the agent is **`modernize`** and the model is **GPT-6 Sol** with reasoning **Medium**. The pickers are at the bottom of the chat input box.

1. ⚠️ **BEFORE you send:** new chat, agent **`modernize`**, model **GPT-6 Sol** at **Medium**.
2. Paste this and send it. It runs the extension's planning skill with the kit rules as its input:

   ```text
   /create-modernization-plan Create the modernization plan for app/ContosoUniversity from the latest assessment report in .github/modernize/assessment/reports, following these rules exactly:
   1. First task: upgrade app/ContosoUniversity to .NET 10 and ASP.NET Core MVC (SDK-style project, PackageReference, Web.config settings to appsettings.json, keep controllers, views and the EF Core model). Every other task depends on it and runs on .NET 10.
   2. No Microsoft Entra ID user sign-in task. The app has no sign-in; Windows authentication findings come only from IIS Express settings and the LocalDB Integrated Security connection string. Remove it.
   3. One target per workload: Azure Blob Storage (not Azure Files, no storage mounts) and Azure SQL Managed Instance (not Azure SQL Database). Remove the other alternatives.
   4. Database: keep local SQL authentication working. When ConnectionStrings:DefaultConnection uses SQL authentication (the on-premises server and contosoapp login, from user secrets) use it as is; use managed identity only when it says Authentication=Active Directory Default.
   5. Order: .NET 10 upgrade, SQL Managed Instance, Blob and file handling, Service Bus, Key Vault, CVE fixes.
   6. DefaultAzureCredential everywhere. Storage shared keys and Service Bus SAS are disabled: no keys, SAS tokens or connection strings. Endpoints come from configuration at execution time: Storage:BlobServiceUri, Storage:ContainerName, ServiceBus:FullyQualifiedNamespace, ServiceBus:QueueName, KeyVault:VaultUri.
   7. Hosting: Azure App Service for Linux (containers). All Azure resources already exist; don't provision or deploy anything.
   Then show a table with one row per rule (1-7) and how the plan meets it, and wait for my review.
   ```

   It writes `.github\modernize\<plan-folder>\plan.md` and `.metadata\tasks.json` at the repo root. If it asks which Azure resources to use for integration tests, answer: configuration keys supplied at execution time, no identifiers.
3. **Check the plan.** All 7 rows of the table must be met. In `tasks.json`: the .NET 10 upgrade is the first task and every other task depends on it; one target per workload (Blob, SQL Managed Instance); no Entra ID sign-in task. If anything is wrong, don't correct it in the chat: delete the plan's folder, start a new chat and send the prompt again. Run 1 met every rule first time.
4. Export the chat and commit the plan: `run2: step 3 plan`, noting in the body the agent, model and reasoning effort the chat showed and how many times you generated the plan.

## Step 4: Execute (C6)

> [!WARNING]
> **BEFORE each task:** start a **new chat** (never the planning chat or the previous task's chat), and check that the agent is **`modernize`** and the model is **GPT-6 Luna** with reasoning **maximum**.

Run the tasks in `tasks.json` in order, **one task per new chat**, with a direct prompt. Don't use **Execute the plan** or `Execute task 00N of the plan`: in run 1 that route's delegation blocked three of six tasks (sub-agent depth, stale trackers, a lost scenario, a phantom "another agent"), while the direct prompt worked every time. For each task:

1. ⚠️ **BEFORE you send:** new chat, agent **`modernize`**, model **GPT-6 Luna** at **maximum**.
2. Send this, with the task's ID, and paste the task's `description` and `requirements` from `tasks.json` after it:

   ```text
   Implement task <task-id> of the modernization plan in .github/modernize/<plan-folder> directly on spike/b06-run2. Work directly: don't delegate, don't initialize a scenario and don't re-plan. Scope: app/ContosoUniversity only; never edit files outside it. After the change, build the app and fix every error. The task's description and requirements from tasks.json:
   ```

   Approve builds and file edits. If it still stops (a stale tracker, "no modernization scenario is active", or "already being handled by another agent"), nothing was changed: reload the window (**Developer: Reload Window**) and send the same prompt in a new chat with the **default Agent** and GPT-6 Luna at maximum instead.
3. Bring the work onto `spike/b06-run2` (see **Rules for every step**), then `dotnet run` and do the task's check below.
4. Export the chat, commit and push: `run2: step 4 task <nnn> <name>`, with the agent, model and any intervention in the body.

| Task | Check after it | Known hot spot from run 1 |
|---|---|---|
| 001 .NET 10 upgrade | `dotnet build app/ContosoUniversity` passes; the home, Students, Courses, Instructors and Departments pages work against `10.10.n.4` | MSMQ is replaced by a temporary in-process queue until task 004: notifications don't survive a restart yet |
| 002 SQL Managed Instance | Students still read and write against `10.10.n.4` with SQL authentication | — |
| 003 Blob | An upload on **Courses** > **Edit** lands in the container: `az storage blob list --account-name stuni<suffix>b06 --container-name teaching-materials --auth-mode login -o table` | The agent may not commit: use the branch routine |
| 004 Service Bus | Create or edit a student. Send: `az servicebus queue show -g rg-spike-b06 --namespace-name sbns-uni-<suffix>-b06 -n notifications --query countDetails.activeMessageCount` goes up. Receive: `/Notifications/GetNotifications` returns `"success":true`, and toasts appear top right (the **Notifications** page is only information) | Run 1's receive path called `ReceiveMessagesAsync` with `TimeSpan.Zero` and always failed, and the controller hid it. If receive fails, send: `ReceiveMessagesAsync needs a positive maxWaitTime: use TimeSpan.FromSeconds(2), and log exceptions in NotificationsController with ILogger instead of Debug.WriteLine. Scope: app/ContosoUniversity only; never edit files outside it.` |
| 005 Key Vault | Store the connection string in Key Vault, point the app at it and remove the user secret, then the pages still work (commands below) | — |
| 006 CVE fixes | `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` finds nothing | Run 1 had nothing to fix; the extension's NuGet safe-version planner crashed (tool bug): ignore it if the list is clean |

Task 005's check:

```powershell
az keyvault secret set --vault-name kv-uni-<suffix>-b06 --name 'ConnectionStrings--DefaultConnection' --value 'Server=10.10.n.4;Database=ContosoUniversity;User Id=contosoapp;Password=FactoryLab-2026-Pw;TrustServerCertificate=True;MultipleActiveResultSets=True'
Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
dotnet user-secrets set 'KeyVault:VaultUri' 'https://kv-uni-<suffix>-b06.vault.azure.net/'
dotnet user-secrets remove 'ConnectionStrings:DefaultConnection'
dotnet run
```

## Step 5: Gaps

After the plan's tasks, run 1 had only one gap left. Check the others, then do OpenTelemetry.

1. Check, and note in the commit body: `Global.asax` and `App_Start` are gone; `NotificationService` comes from dependency injection in `Program.cs`; the `Site.css` file name matches every reference; `git grep -n -i -E "System\.Web|System\.Messaging|MSMQ|MessageQueue" -- app/ContosoUniversity` prints nothing. If one isn't done, ask for it in a new chat with `modernize` and GPT-6 Luna at maximum, ending the prompt with the scope line.
2. **Trace to OpenTelemetry.** ⚠️ **BEFORE you click:** agent **`modernize`**, model **GPT-6 Luna** at **maximum**. Run the predefined task **Tasks** > **.NET** > **Logging or Observability Tasks** > **Migrate Logging or Observability to OpenTelemetry on Azure**. It replaces the `Trace` and `Debug` calls with `ILogger` and adds Azure Monitor OpenTelemetry.
3. Revert any change it makes outside `app/` (run 1: `docs/prd.md`), bring the work onto the run branch, and run the app **without** `APPLICATIONINSIGHTS_CONNECTION_STRING`. In run 1 it crashed at startup ("A connection string was not found"), because the task registers Azure Monitor unconditionally. If it crashes, send in a new chat:

   ```text
   Register Azure Monitor only when APPLICATIONINSIGHTS_CONNECTION_STRING or ApplicationInsights:ConnectionString is set; otherwise use the OpenTelemetry console exporters. Scope: app/ContosoUniversity only; never edit files outside it.
   ```

   A `fail: … TaskCanceledException` (499) in the log when you navigate away during a notification poll is expected, not an error.
4. Export the chat, commit and push: `run2: step 5 gaps`.

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
3. Tell the executor the run is pushed, with the results of the 🧑 checks: the five pages, the upload, the notification round trip, Key Vault, startup without Application Insights and the image tag. The executor fills in `run2.md`, runs the build, reference, registry and secrets checks, and writes the report.

## Comparison: GitHub Copilot upgrade (after run 1, before run 2)

**(v2, owner-approved)** A full end-to-end run with the separate **GitHub Copilot upgrade** extension (`ms-dotnettools.upgrade-agent`, the **Upgrade** agent, `@upgrade`) instead of the `modernize` agent: assess, plan, upgrade to .NET 10, then migrate to SQL Managed Instance, Blob, Service Bus and Key Vault. That's the same scope as run 1's steps 2–4, with the same kit rules and configuration keys. Fill in [compare-upgrade.md](compare-upgrade.md) stage by stage. The Upgrade agent may not cover the Azure migrations at all: that's a result to record, not a failure.

### C.1 Set up

1. Install the extension on `vm-dev01` by hand (nothing in the kit installs it), record its version, and reload the window:

   ```powershell
   code --install-extension ms-dotnettools.upgrade-agent
   code --list-extensions --show-versions | Select-String 'upgrade-agent|migrate-java-to-azure'
   ```

2. **Default, for a clean comparison:** disable GitHub Copilot modernization for this run: **Extensions** > **GitHub Copilot modernization** > **Disable (Workspace)**, then reload. Re-enable it after the run. You may keep both enabled if you prefer; record which you chose in `compare-upgrade.md`.
3. Create the comparison branch from run 1's start commit:

   ```powershell
   Set-Location C:\src\apex-factory-hackathon
   git status --short                   # must print nothing
   git fetch origin
   git switch -c spike/b06-upgrade-compare da4e5f606983332001c94ce69b48634f9c1864b3
   git commit --allow-empty -m "compare: stage 1 set up"
   ```

### C.2 Assess and plan

> [!WARNING]
> **BEFORE you send:** start a **new chat**, and check that the agent picker shows **Upgrade** and the model picker shows **GPT-6 Sol** with reasoning **Medium**, as for run 1's planning. The chat uses whatever is selected. The pickers sit at the bottom of the chat input box.

1. ⚠️ **BEFORE you send:** new chat, agent **Upgrade**, model **GPT-6 Sol** at **Medium**.
2. Send the assessment and planning prompt. It uses the same seven kit rules as run 1's planning prompt (step 3.2 of this protocol):

   ```text
   Assess app/ContosoUniversity and create an upgrade and migration plan, following these rules exactly:
   1. First task: upgrade app/ContosoUniversity to .NET 10 and ASP.NET Core MVC (SDK-style project, PackageReference, Web.config settings to appsettings.json, keep controllers, views and the EF Core model). Every other task depends on it and runs on .NET 10.
   2. No Microsoft Entra ID user sign-in task. The app has no sign-in; Windows authentication findings come only from IIS Express settings and the LocalDB Integrated Security connection string. Remove it.
   3. One target per workload: Azure Blob Storage (not Azure Files, no storage mounts) and Azure SQL Managed Instance (not Azure SQL Database). Remove the other alternatives.
   4. Database: keep local SQL authentication working. When ConnectionStrings:DefaultConnection uses SQL authentication (the on-premises server and contosoapp login, from user secrets) use it as is; use managed identity only when it says Authentication=Active Directory Default.
   5. Order: .NET 10 upgrade, SQL Managed Instance, Blob and file handling, Service Bus, Key Vault, CVE fixes.
   6. DefaultAzureCredential everywhere. Storage shared keys and Service Bus SAS are disabled: no keys, SAS tokens or connection strings. Endpoints come from configuration at execution time: Storage:BlobServiceUri, Storage:ContainerName, ServiceBus:FullyQualifiedNamespace, ServiceBus:QueueName, KeyVault:VaultUri.
   7. Hosting: Azure App Service for Linux (containers). All Azure resources already exist; don't provision or deploy anything.
   Then show a table with one row per rule (1-7) and how the plan meets it, and say which tasks you can't do. Wait for my review.
   ```

3. Record which rules and tasks it covers, and where it writes its assessment and plan. Export the chat, then commit and push: `compare: stage 2 assess and plan`.

### C.3 Upgrade and migrate

> [!WARNING]
> **BEFORE you send:** start a **new chat**, and check that the agent picker shows **Upgrade** and the model picker shows **GPT-6 Luna** with reasoning **maximum**, as for run 1's execution.

For each stage in order, .NET 10 upgrade, SQL Managed Instance, Blob, Service Bus, Key Vault:

1. ⚠️ **BEFORE you send:** new chat, agent **Upgrade**, model **GPT-6 Luna** at **maximum**.
2. Ask it to do that stage of its plan, for example `Do the .NET 10 upgrade task of your plan, and nothing else.` If it says a stage is out of its scope, don't force it: record that and go on to the next stage.
3. Build, then do the same check as run 1 for that stage: the step 4 check table (pages against `10.10.n.4` after the upgrade, Students, a Blob upload, Service Bus send **and** receive with `/Notifications/GetNotifications`, and Key Vault).
4. Check `git status --short --branch`, commit and push: `compare: stage 3.N <stage>`. Put interventions in the commit body, one line each, and export the chat.

After the last stage, re-enable GitHub Copilot modernization if you disabled it, and tell the executor the branch is pushed. For run 2, note in `compare-upgrade.md` whether the `modernize` agent behaves differently with the upgrade extension installed.

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
