# B06 run protocol: GHCP golden path on `vm-dev01`

The steps the owner follows on `vm-dev01` for each run of the [B06 spike](../../backlog/B06-spike-ghcp.md). They assume you haven't used GitHub Copilot modernization before. **(v2)** You don't fill in the results sheets: the executor fills in [run1.md](run1.md) and [run2.md](run2.md) from your commits, chat exports and versions file after you push (see **How the run is recorded** below).

| Run | Branch | Start from commit | Protocol version |
|---|---|---|---|
| 1 | `spike/b06-run1` | `da4e5f606983332001c94ce69b48634f9c1864b3` | v1 |
| 2 | `spike/b06-run2` | set between runs | v2 |

Run 1 started from v1. Changes in v2 are marked **(v2)** and listed under [Changes in v2](#changes-in-v2) at the end.

At the event, App Service, the container registry, SQL Managed Instance and the datacenter are already deployed for each attendee. **(v2)** The plan and every step assume existing resources whose endpoints come from configuration; nothing here provisions anything.

Placeholders: `n` is your member index (`1` in the build subscriptions) and `<suffix>` is the suffix in `.local/settings.json`. The spike resources are in `rg-spike-b06` and are private-only, so every Azure data-plane call works only from `vm-dev01`.

| Setting | Value |
|---|---|
| Source database | `10.10.n.4`, database `ContosoUniversity`, SQL login `contosoapp`, password `FactoryLab-2026-Pw` (datacenter lab password) |
| Blob | `https://stuni<suffix>b06.blob.core.windows.net`, container `teaching-materials` |
| Service Bus | `sbns-uni-<suffix>-b06.servicebus.windows.net`, queue `notifications` |
| Key Vault | `https://kv-uni-<suffix>-b06.vault.azure.net/` |
| Container registry | `cruni<suffix>b06.azurecr.io`, repository `contoso-university`, tag `run1` or `run2` |

Use these configuration keys in every step, so both runs and the archetype (B09) use the same names:

| Key | Local value on `vm-dev01` |
|---|---|
| `ConnectionStrings:DefaultConnection` | SQL authentication to `10.10.n.4`, in user secrets or Key Vault only |
| `Storage:BlobServiceUri` | `https://stuni<suffix>b06.blob.core.windows.net` |
| `Storage:ContainerName` | `teaching-materials` |
| `ServiceBus:FullyQualifiedNamespace` | `sbns-uni-<suffix>-b06.servicebus.windows.net` |
| `ServiceBus:QueueName` | `notifications` |
| `KeyVault:VaultUri` | `https://kv-uni-<suffix>-b06.vault.azure.net/` |

## Rules for every step

- **(v2) How the run is recorded.** You record by committing; the executor turns it into the results sheet:
  - **Times** come from the commit timestamps. Commit at the end of every step; a step starts at the previous commit, so don't leave long breaks uncommitted (commit before a break and say so in the body).
  - **Prompts and models:** for every step where you prompted in Copilot Chat, run **Chat: Export Chat…** before the commit from the Command Palette (Ctrl+Shift+P) and save it as `docs\spikes\B06-ghcp-golden-path\chats\run1-step<step>.json`. **(v2)** If the JSON export fails, select all in the chat, copy it and save it as `run1-step<step>.txt` instead, for example `run1-step3.json` or `run1-step4.2.json` (run 2: `run2-…`). One file per chat session; add `-a`, `-b` if a step used more than one. A step run only from the modernization view (for example the assessment dashboard) has no chat to export: say so in the commit body, and the model is recorded as *extension default, not selectable*. Don't paste passwords or tokens into the chat: the executor checks the exports for secrets before they stay committed.
  - **Manual fixes:** one line each in the commit message body, for example `git commit -m "run1: step 4.3 MSMQ to Service Bus" -m "Fixed by hand: ServiceBusClient registered as scoped, changed to singleton"`. Also say there which way you started a predefined task and anything that went wrong.
  - **Versions:** the versions file in step 1.7.
  - **Build and run:** say in the commit body whether `dotnet build` passed and whether the app ran; the executor also runs the build and reference checks after the push. Premium requests: add them to the body if VS Code shows them.
- **Commit after each step,** with a message that names the step, for example `git commit -am "run1: step 3 upgrade to .NET 10"`. Include new files: `git add -A` first.
- **Models:** follow the kit's guidance. **(v2)** For planning and execution, step 3 says which agent, model and reasoning effort to select before each dashboard button. The chat export records the exact model name and the date:
  - assessment: a balanced model (Sonnet- or Terra-class);
  - planning: the most capable model (Opus- or Sol-class);
  - plan execution: an efficient model at maximum reasoning effort (Luna-class).

  The modernization agent picks its own default model; switch it with the model picker in the chat input box.
- **Approve tool calls with care.** Copilot asks before it runs commands or uses MCP tools. Read what it wants to run. Approve builds, restores and file edits. Don't approve anything that creates, changes or deletes Azure resources: they already exist.
- **Never paste a password into a committed file.** Connection strings with a password go into user secrets (`dotnet user-secrets`) or Key Vault. If Copilot writes one into `appsettings*.json`, move it and note it as an intervention.
- **Keys don't work.** Storage shared keys and Service Bus SAS are turned off. If Copilot generates key- or connection-string-based code for Blob or Service Bus, it fails at runtime: note it as a hot spot and ask for `DefaultAzureCredential`.
- **Time boxes:** C3 is 1 hour and C6 is 3 hours at the event. Don't stop a step at the time box, but note when you pass it. If you can't reach a building .NET 10 app within a working day, stop and tell the executor.
- **If Notepad opens after every Copilot tool call,** that's the C# Dev Kit 3.40.204 bug ([microsoft/vscode-dotnettools#3568](https://github.com/microsoft/vscode-dotnettools/issues/3568)). Close Notepad, then rename `track-skill-invocation.ps1` wherever it appears under `%USERPROFILE%\.vscode\extensions` and `%APPDATA%\Code\agentPlugins` (for example to `track-skill-invocation.ps1.disabled`) and restart VS Code. Don't change the `.ps1` file association. Note it in the next commit message body if it happened.

## Step 1: Set up

1. Connect to `vm-dev01` through Bastion as `labadmin`.
2. **(v2)** Open PowerShell 7 and sign in with device code flows. Browser sign-in inside the Bastion session is awkward, and passkeys and password managers aren't available there. Each command prints a one-time code: copy it from the terminal, open the page it names on your own device, enter the code and finish sign-in there.

   ```powershell
   gh auth login --web                 # enter the code at https://github.com/login/device
   az login --use-device-code          # enter the code at https://microsoft.com/devicelogin
   ```

   **(v2)** Right after `gh auth login`, give git your GitHub identity and let `git push` use the gh sign-in. A fresh VM user has no git identity, so without this the first commit fails with `Author identity unknown`. The no-reply email keeps your personal address out of commits:

   ```powershell
   $u = gh api user | ConvertFrom-Json
   git config --global user.name ($u.name ?? $u.login)
   git config --global user.email "$($u.id)+$($u.login)@users.noreply.github.com"
   gh auth setup-git
   ```

   After sign-in, the Azure CLI shows a subscription picker. Pick your own workload subscription, the one that holds `rg-datacenter`. Then check it:

   ```powershell
   az account show --query name -o tsv
   ```

   If you skipped the picker or it shows the wrong subscription, run `az account set --subscription '<your workload subscription name>'` and check again.

   Some tenants block device code flow with Conditional Access. If sign-in is refused, note it in the step 1 commit body and use `az login` (browser) inside the Bastion session instead.

3. **(v2)** Make `DefaultAzureCredential` use your Azure CLI sign-in. `vm-dev01` has a system-assigned managed identity, and `DefaultAzureCredential` tries `ManagedIdentityCredential` before `AzureCliCredential`, so without this the app gets the VM's token, which has no data roles, and fails with 403 on Blob, Service Bus and Key Vault. The data roles are on your user, not the VM. Set it for your user and restart VS Code and any open terminals so they pick it up:

   ```powershell
   [Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')
   ```

   It's set only on `vm-dev01`, never in Azure, so the deployed app still uses its managed identity. See [Credential chains in the Azure Identity library for .NET](https://learn.microsoft.com/dotnet/azure/sdk/authentication/credential-chains).

4. **(v2)** Get the repo into `C:\src\apex-factory-hackathon`, either a fresh clone or an existing one, then create the run branch from the commit in the table above.

   - **No clone yet:** clone it.

     ```powershell
     git clone https://github.com/jonathan-vella/apex-factory-hackathon.git C:\src\apex-factory-hackathon
     Set-Location C:\src\apex-factory-hackathon
     ```

   - **Existing clone:** check that it's clean.

     ```powershell
     Set-Location C:\src\apex-factory-hackathon
     git status --short
     ```

     `git status --short` must print nothing. **If it prints anything, stop and tell the executor**: don't commit, stash or delete anything.

   Then, in both cases:

   ```powershell
   git fetch origin
   git switch -c spike/b06-run1 <run-commit>
   git diff --stat <run-commit> origin/main -- app/ContosoUniversity
   ```

   Replace `<run-commit>` with the commit in the table above. The last command must print nothing: `app/ContosoUniversity` is unchanged from `main`. For run 2, use `spike/b06-run2` and the run 2 commit.

5. **(v2) Only if an earlier assessment is in the clone:** a GitHub Copilot modernization assessment run by hand before the spike leaves its output in `app\ContosoUniversity\.github\modernize\`, which git ignores. If that folder exists, move it out of the repo so the run's assessment starts clean, and note it in the step 1 commit body. With a fresh clone, skip this step.

   ```powershell
   if (Test-Path app\ContosoUniversity\.github\modernize) { Move-Item app\ContosoUniversity\.github\modernize C:\src\b06-earlier-assessment }
   ```

6. Open the folder in VS Code: `code C:\src\apex-factory-hackathon`. Sign in to GitHub in VS Code (**Accounts** menu, bottom left) with the account that has the Copilot seat. Check that Copilot Chat opens in **Agent** mode.
7. Check the extensions under **Extensions** (Ctrl+Shift+X):
   - **GitHub Copilot modernization** (`vscjava.migrate-java-to-azure`) is installed. It's the only modernization extension the kit uses. It adds the **GitHub Copilot modernization** view to the Activity Bar and the `modernize` agent to Copilot Chat, which covers the assessment, the .NET upgrade and the migration tasks.
   - **(v2)** Write the versions file, which the executor uses for the results sheet and `versions.md` (run 2: `run2-versions.txt`):

     ```powershell
     $v = 'docs\spikes\B06-ghcp-golden-path\run1-versions.txt'
     'code --version:' | Set-Content $v
     code --version | Add-Content $v
     'extensions:' | Add-Content $v
     code --list-extensions --show-versions | Select-String -Pattern 'copilot|csdevkit|migrate-java-to-azure' | ForEach-Object Line | Add-Content $v
     'dotnet --version:' | Add-Content $v
     dotnet --version | Add-Content $v
     ```

8. Check that the spike services resolve privately (each prints a `10.10.n.128/27` address):

   ```powershell
   'stuni<suffix>b06.blob.core.windows.net','sbns-uni-<suffix>-b06.servicebus.windows.net','cruni<suffix>b06.azurecr.io','kv-uni-<suffix>-b06.vault.azure.net' | ForEach-Object { Resolve-DnsName $_ -Type A | Where-Object IPAddress | Select-Object -Last 1 Name, IPAddress }
   ```

9. **(v2)** Commit the set-up, so its time marks the start of step 2: `git add -A`, then `git commit -m "run1: step 1 set up"`, with any manual fix or problem (for example, device code refused or Notepad opening) as one line in the message body.

## Step 2: C3 assess

Model: the assessment uses the extension's default model. **(v2)** Step 2 uses the **custom assessment** in the **GitHub Copilot modernization** view. Step 3 doesn't use **Create Plan**: it generates the plan in a new chat with `/create-modernization-plan` and the kit rules as the planning input.

1. Keep the repo root open in VS Code. Before the upgrade, the C# Dev Kit status bar shows **Projects: 1 error** for the legacy .NET Framework project: that's expected, ignore it.
2. **(v2)** Open the **GitHub Copilot modernization** view in the Activity Bar and run a **custom assessment**, not the default **Start Assessment**, with the target set to **Azure App Service for Linux (containers)**. The default assessment targets App Service (Windows), which led run 1 to the wrong plan target. Options to choose (from run 1's step 2 commit):

   - *Pending: copied exactly from the owner's step 2 commit message on `spike/b06-run1`.*

   If it asks which project, pick `app/ContosoUniversity`.
3. **(v2)** In the report, check that the target is **Azure App Service (Linux)** (containers). If it shows **Azure App Service (Windows)**, the custom options didn't apply: switch it to Linux and note it in the commit body.
4. Wait for the report. Read it: note the issues it finds for local files, MSMQ, the database, the plaintext connection string and `System.Web`, and the migration tasks it recommends. It flags **Windows authentication detected** as mandatory, but the app has no user sign-in and no `[Authorize]`. The finding comes only from `IISExpressWindowsAuthentication` in the project file and `Integrated Security=True` in the old LocalDB connection string. **(v2)** Rule 2 of the planning prompt in step 3.2 removes it.
5. Save the report into the spike folder. The modernization extension writes it to `C:\src\apex-factory-hackathon\app\ContosoUniversity\.github\modernize\assessment\reports\report-<timestamp>\`, which git ignores. Copy the new report folder's files to `docs\spikes\B06-ghcp-golden-path\assessment\run1\` (run 2: `run2\`), plus `...\.github\modernize\assessment\engines\dotnet-appcat\result\report.json` as `appcat-report.json`. If the report page offers an export (HTML or Markdown), save that there too. `git add docs/spikes/B06-ghcp-golden-path/assessment` so the ignored source folder doesn't matter.
6. Commit: `run1: step 2 assessment`.

## Step 3: C6 plan and upgrade to .NET 10

**(v2)** Don't use **Create Plan** from the report. A finished plan can't be corrected: when run 1 sent the kit rules as a follow-up, the `modernize` agent replied that the planning coordinator had already completed and that the workflow doesn't allow re-invoking it or editing its outputs. The kit rules have to go in as the **planning input**, so start a new planning chat and send them with `/create-modernization-plan`. **If a plan is wrong, delete its folder under `.github\modernize\` and generate it again; don't try to correct it.**

> [!WARNING]
> **BEFORE you send the planning prompt:** start a **new chat**, and check that the model picker shows **GPT-6 Sol** with reasoning **Medium**, and that the agent is **`modernize`**. The chat uses whatever is selected.
>
> **How to check:** the agent and model pickers sit at the bottom of the chat input box in the Chat panel. Open each one and select the value if it's wrong.

1. ⚠️ **BEFORE you send:** start a **new chat** in the Chat panel. Check the model picker shows **GPT-6 Sol** with reasoning **Medium**, and the agent is **`modernize`**. (The pickers are at the bottom of the chat input box.)
2. **(v2)** Paste this into the new chat and send it. It runs the extension's built-in planning skill with the kit rules as its input:

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

   It writes the plan to `.github\modernize\<name>-<timestamp>\plan.md` and `.metadata\tasks.json` at the repo root. If it asks which Azure resources to use for integration tests, answer: configuration keys supplied at execution time, no identifiers.
3. **(v2) Check the plan.** All 7 rows of the table must be met. Then open `tasks.json` and check:
   - the .NET 10 upgrade is the **first** task, and every other task depends on it;
   - **one** target per workload: Blob (no Azure Files, no storage mount) and SQL Managed Instance (no Azure SQL Database);
   - **no** Microsoft Entra ID sign-in task.

   If anything is wrong, don't correct it in the chat: delete the plan's folder under `.github\modernize\`, start a new chat (step 3.1) and send the prompt again. Export the chat and commit the plan: `run1: step 3 plan` (run 2: `run2: …`, as everywhere). In the commit body, note the agent, model and reasoning effort the chat showed, and how many times you generated the plan.

> [!WARNING]
> **BEFORE you start execution:** open a **new chat** (never the planning chat), and in the Chat panel check that the model picker shows **GPT-6 Luna** with reasoning **maximum**, and that the agent is **`modernize`**. Execution uses whatever is selected.
>
> **How to check:** the agent and model pickers sit at the bottom of the chat input box in the Chat panel.

4. ⚠️ **BEFORE you start:** in the Chat panel, check the model picker shows **GPT-6 Luna** with reasoning **maximum**, and the agent is **`modernize`**. (The pickers are at the bottom of the chat input box.) **(v2) Plan and execute in separate chats, one task per chat.** Execution never runs in the chat that planned it: nested coordinators in one chat use up the sub-agent depth limit. For **each task** in `tasks.json`, in order:

   1. Open a **new chat** with **`modernize`** and **GPT-6 Luna** at **maximum**.
   2. Send `Execute task 00N of the plan in .github/modernize/<plan-folder>.` (for example `Execute task 001 of the plan in .github/modernize/contoso-university-dotnet10-azure.`). Approve builds and file edits; reply `continue` when it asks.
   3. **(v2)** When it reports the task done, check where the work landed, because it varies from task to task: in run 1, task 002 was committed by the tool on a new `appmod/*` branch, task 003 (after a stale-tracker retry) stayed uncommitted on the run branch, and task 004 was committed by the tool directly on the run branch.

      ```powershell
      git status --short --branch
      ```

      - **On an `appmod/*` branch:** `git switch spike/b06-run1`, then `git merge --ff-only <appmod-branch>`.
      - **Uncommitted changes:** `git add -A`, then commit on `spike/b06-run1` with the step name.
      - **Already committed on `spike/b06-run1`, clean tree:** nothing to do.
      - Then, in every case, `git push`.
   4. Do the check for that task (below).
   5. **(v2)** Run **Developer: Reload Window** from the Command Palette, then start the next task in another new chat. If the agent reports a leftover in-progress tracker or invocation tracking item from the previous task, reply: `Mark the stale tracking item complete and run task 00N.`

   The tool also writes per-task notes to `.github\modernize\code-migration\<timestamp>\` (`plan.md`, `progress.md`, `summary.md`): commit them with the task. Note the exact prompt in the commit body. If execution is **BLOCKED** (for example "saw an in-progress execution-phase tracker" or "Maximum sub-agent depth of 4 reached"), nothing was changed: abort, reload the window (**Developer: Reload Window**), and start again in a new chat. Never retry in the same chat.

   > [!WARNING]
   > **Commit and push after EVERY task, before you let the agent start the next one.** The agent's version control tool creates an `appmod/*` branch per task and switches to it (`prepareBranch`). In run 1 that switch stashed task 001's uncommitted .NET 10 upgrade and left the working tree back on .NET Framework 4.8. If it offers to create a branch, decline; if it creates one anyway, merge or fast-forward it back into `spike/b06-runN` before the next task. The run's final result must be on `spike/b06-runN`. Check `git branch --show-current` before every commit. It runs the plan task by task; reply `continue` when it asks. Keep the changes when they build. Do the step 3 check below after the upgrade task, and the step 4 checks after each of the other tasks, committing after each task with the step names below and exporting the chat before each commit.
5. Check, after the upgrade task: `dotnet build app/ContosoUniversity` passes on the .NET 10 SDK. Point the app at the source database for a first run:

   ```powershell
   Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
   dotnet user-secrets init
   dotnet user-secrets set 'ConnectionStrings:DefaultConnection' 'Server=10.10.n.4;Database=ContosoUniversity;User Id=contosoapp;Password=FactoryLab-2026-Pw;TrustServerCertificate=True;MultipleActiveResultSets=True'
   dotnet run
   ```

   Open the URL it prints and try the home, Students, Courses, Instructors and Departments pages. MSMQ may still be in the code at this point; note what works.
6. Commit: `run1: step 3 upgrade to .NET 10`.

## Step 4: C6 predefined tasks

**(v2)** When you execute the checked plan (step 3.4), these four tasks run as part of the reviewed plan, in this order: do each check below after its task, then commit with the name given. The prompts below are the fallback when a task is missing from the plan or fails: start it from the **TASKS - .NET** section of the **GitHub Copilot modernization** view, or from the assessment report's **Run Task** button, or in Copilot Chat with the `modernize` agent and a `migrate from <source> to <target>` prompt. Say in the commit body which way you used. Add the prompt below to the chat when the task asks for input, or send it as the first message. Review the `plan.md` and `progress.md` it writes before you reply `continue`. After each task: build, run, commit.

Before 4.2, check that you're signed in with the Azure CLI (`az account show`) and that `AZURE_TOKEN_CREDENTIALS` is `AzureCliCredential` in the terminal VS Code uses (`$env:AZURE_TOKEN_CREDENTIALS`), so `DefaultAzureCredential` uses your account locally (step 1.3).

### 4.1 Database with managed identity

```text
Migrate the database to Azure SQL Managed Instance with managed identity, but keep the dev VM working:
when ConnectionStrings:DefaultConnection uses SQL authentication (it does locally, to 10.10.n.4 with
the contosoapp login, from user secrets), use it as is. Use managed identity only when the connection
string is configured for it (Authentication=Active Directory Default) on Azure. Don't create Azure
resources, and don't put a password in any committed file.
```

Check: the app still reads and writes Students against `10.10.n.4`. Commit: `run1: step 4.1 database with managed identity`.

### 4.2 Uploads to Blob

```text
Migrate the teaching-material uploads in CoursesController from the local Uploads folder to Azure Blob
Storage. Use BlobServiceClient with DefaultAzureCredential and the endpoint in Storage:BlobServiceUri,
container Storage:ContainerName (teaching-materials). Shared key access is off on the account, so
don't use keys, SAS or connection strings. Show existing images through the app, not with public blob URLs.
```

Set the values locally, then check that an upload on **Courses** > **Edit** lands in the container:

```powershell
dotnet user-secrets set 'Storage:BlobServiceUri' 'https://stuni<suffix>b06.blob.core.windows.net'
dotnet user-secrets set 'Storage:ContainerName' 'teaching-materials'
az storage blob list --account-name stuni<suffix>b06 --container-name teaching-materials --auth-mode login -o table
```

Commit: `run1: step 4.2 uploads to Blob`.

### 4.3 MSMQ to Service Bus

```text
Migrate NotificationService from MSMQ to Azure Service Bus. Use ServiceBusClient with
DefaultAzureCredential and ServiceBus:FullyQualifiedNamespace, queue ServiceBus:QueueName
(notifications). Local (SAS) auth is off, so don't use connection strings. Keep both paths working:
sending a notification when an entity is created, edited or deleted, and reading notifications back
on the Notifications page. Remove every reference to System.Messaging.
```

Set the values, then create or edit a student and check that the notification appears on the **Notifications** page:

```powershell
dotnet user-secrets set 'ServiceBus:FullyQualifiedNamespace' 'sbns-uni-<suffix>-b06.servicebus.windows.net'
dotnet user-secrets set 'ServiceBus:QueueName' 'notifications'
```

Commit: `run1: step 4.3 MSMQ to Service Bus`.

### 4.4 Secrets to Key Vault

```text
Migrate secrets to Azure Key Vault with managed identity. When KeyVault:VaultUri is set, add Key Vault
as a configuration source with DefaultAzureCredential, so the secret ConnectionStrings--DefaultConnection
overrides ConnectionStrings:DefaultConnection. When it isn't set, keep reading configuration and user
secrets as today. Don't put any secret in a committed file.
```

Store the dev connection string in Key Vault and run with the vault instead of the user secret:

```powershell
az keyvault secret set --vault-name kv-uni-<suffix>-b06 --name 'ConnectionStrings--DefaultConnection' --value 'Server=10.10.n.4;Database=ContosoUniversity;User Id=contosoapp;Password=FactoryLab-2026-Pw;TrustServerCertificate=True;MultipleActiveResultSets=True'
dotnet user-secrets set 'KeyVault:VaultUri' 'https://kv-uni-<suffix>-b06.vault.azure.net/'
dotnet user-secrets remove 'ConnectionStrings:DefaultConnection'
dotnet run
```

Commit: `run1: step 4.4 secrets to Key Vault`.

## Step 5: C6 gaps

These have no predefined task in the plan. Use Copilot Chat in **Agent** mode (the default agent) with the execution model, one prompt per gap, and build after each. Commit once at the end, or after each gap if it was large.

1. **Global.asax and bundling:**

   ```text
   Check that nothing from Global.asax, App_Start/RouteConfig, FilterConfig or BundleConfig is lost in
   Program.cs: the default route, global filters and the CSS and JS bundles. Serve the CSS and JS as
   static files from wwwroot with plain link and script tags in _Layout.cshtml, without a bundling
   package. Delete Global.asax and App_Start when nothing uses them.
   ```

2. **`new NotificationService()` to dependency injection:**

   ```text
   BaseController creates NotificationService and SchoolContext itself. Register both in Program.cs
   (AddDbContext for SchoolContext, and NotificationService with the lifetime Service Bus clients need)
   and inject them through constructors in BaseController and every controller that derives from it.
   ```

3. **`Trace` to OpenTelemetry:** first try the predefined **Migrate to OpenTelemetry on Azure** task from the **TASKS - .NET** section, and note whether it covers `System.Diagnostics.Trace`. If it doesn't, use:

   ```text
   Replace System.Diagnostics.Trace and Debug calls with ILogger<T>. Add OpenTelemetry for logs, traces
   and metrics (ASP.NET Core, HttpClient and SqlClient instrumentation). Export to Azure Monitor only
   when APPLICATIONINSIGHTS_CONNECTION_STRING is set, and to the console otherwise.
   ```

4. **`site.css` file-name case:**

   ```text
   The stylesheet is Content/Site.css but the layout and the old bundle reference site.css. Linux file
   names are case-sensitive, so make the file name and every reference the same: wwwroot/css/site.css.
   Check the other static files for the same problem.
   ```

Check: `dotnet build` passes, and `git grep -n -i -E "System\.Web|System\.Messaging|MSMQ|MessageQueue" -- app/ContosoUniversity` prints nothing. Run the app and check every page again. Commit: `run1: step 5 gaps`.

## Step 6: Package

Build the image with .NET SDK container publishing (no Docker) and push it to the private registry over its private endpoint.

```powershell
Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
$token = az acr login --name cruni<suffix>b06 --expose-token | ConvertFrom-Json
$env:DOTNET_CONTAINER_REGISTRY_UNAME = $token.username
$env:DOTNET_CONTAINER_REGISTRY_PWORD = $token.accessToken
dotnet publish -c Release /t:PublishContainer -p:ContainerRegistry=cruni<suffix>b06.azurecr.io -p:ContainerRepository=contoso-university -p:ContainerImageTag=run1
Remove-Item Env:DOTNET_CONTAINER_REGISTRY_UNAME, Env:DOTNET_CONTAINER_REGISTRY_PWORD
az acr repository show-tags --name cruni<suffix>b06 --repository contoso-university -o table
```

If you ask Copilot to containerize the app instead, tell it to use SDK container publishing, not a Dockerfile, and note what it did. If the project needs properties for this (for example `ContainerBaseImage` or `ContainerPort`), commit them. Commit: `run1: step 6 package`.

## Step 7: Finish the run

1. Check that `docs\spikes\B06-ghcp-golden-path\chats\` has an export for every step where you prompted in Copilot Chat, and that the versions file is committed.
2. Push the run branch: `git push -u origin spike/b06-run1`.
3. Tell the executor the run is pushed, with the results of the 🧑 checks: the five pages, the upload landing in the container, and the notification round-trip. The executor fills in the results sheet, runs the build, reference, registry and secrets checks, and adds the results to the report.

## Optional: step 2 with Copilot CLI

After step 2, repeat the assessment with Copilot CLI on a throwaway branch, and note the differences (time, findings, tasks, premium requests) in the commit message body when you copy its report in:

```powershell
git switch -c spike/b06-run1-cli-scratch
copilot --version
copilot
```

In Copilot CLI, install the modernization plugin once:

```text
/plugin marketplace add microsoft/github-copilot-modernization
/plugin install github-copilot-modernization@github-copilot-modernization
```

Then start it with the modernize agent from `app/ContosoUniversity` (`copilot --agent=github-copilot-modernization:modernize`) and prompt `assess my application`. Stop when it asks **Proceed to planning?**. Copy its report into `docs/spikes/B06-ghcp-golden-path/assessment/run1-cli/` on the run branch, then delete the scratch branch.

## Changes in v2

Run 1 findings folded into the protocol for run 2. Run 1 used v1, with these fixes given to the owner at the start of the run.

| Step | Change | Run 1 finding |
|---|---|---|
| 1.2 | Sign in with device code flows: `az login --use-device-code` and `gh auth login --web` with the code entered at `github.com/login/device`, both completed on the attendee's own device | Browser sign-in inside the Bastion session is awkward and has no passkeys or password managers. Some tenants block device code flow with Conditional Access |
| 1.2 | Pick your own workload subscription (the one that holds `rg-datacenter`) in the Azure CLI subscription picker, and check it with `az account show --query name -o tsv`; `az account set --subscription '<your workload subscription name>'` if the picker was skipped. No subscription is hard-coded | Each attendee has their own workload subscription |
| 1.3, 4.2 | Set the user environment variable `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` on `vm-dev01` | `vm-dev01` has a system-assigned managed identity. `DefaultAzureCredential` tries it before `AzureCliCredential`, so the app gets a VM token with no data roles and fails with 403 on Blob, Service Bus and Key Vault. The roles stay on the user (owner decision) |
| 1.4, 1.5 | Step 1 handles a fresh clone and an existing clean clone. An earlier hand-run assessment in the clone is moved aside, not saved into the spike folder | The owner's clone was gone before run 1, so run 1 used a fresh clone and the 2026-09-24 manual assessment was lost |
| Rules, 1.7, 1.9, 7 | Recording is automated: times come from commit timestamps (a step starts at the previous commit, and step 1 now ends with a commit); versions go in `runN-versions.txt`; prompts and models in `chats/runN-step<step>.json` exported with **Chat: Export Chat…**; manual fixes as one line each in the commit body. The executor fills in the results sheet and checks the exports for secrets | Owner decision at the start of run 1, so the owner doesn't fill in the sheet by hand |
| 1.2 | Right after `gh auth login`, set the git identity from `gh api user` with the GitHub no-reply email, and run `gh auth setup-git` | A fresh VM user has no git identity, so the first commit failed with `Author identity unknown` |
| Rules, 2, 7 | The chat export is needed only for steps prompted in Copilot Chat. For a step run only from the modernization view, the commit body says so and the model is *extension default, not selectable* | The owner ran step 2 from the assessment dashboard, with no chat and no model picker |
| 3 | Pick the planning model first, then start the upgrade from the dashboard (**QUICKSTART** > **Upgrade to a newer version of .NET**, target .NET 10) and send the constraints as a chat reply; the `modernize` agent chat prompt is the alternative. Chat export needed; the commit body records the start route and both models | The owner started run 1's upgrade from the dashboard |
| 2.3 | Set the report's target to **Azure App Service (Linux)** before **Create Plan** | The target defaults to **Azure App Service (Windows)**; the kit targets App Service for Linux (PRD §2). The owner re-planned with Linux |
| 2.4 | *(Superseded: rule 2 of the planning input removes it.)* Deselect **Windows authentication** before **Create Plan** if the report allows it; otherwise the step 3.2 correction removes it | The app has no user sign-in or `[Authorize]`; the finding comes only from `IISExpressWindowsAuthentication` in the project file and `Integrated Security=True` in the LocalDB connection string. Run 1's first plan included **Windows AD to Microsoft Entra ID** |
| 2.5, 3.2, 3.3 | *(Superseded by the kit rules row.)* **Create Plan** is followed by a correction reply (upgrade first; remove Entra ID; Blob; Managed Instance with local SQL auth kept; order database, Blob, Service Bus, Key Vault; `DefaultAzureCredential` with no keys; App Service for Linux containers; no provisioning), and the revised plan is reviewed and committed before execution | Run 1's first plan (commit `7904c1b`) was service-migration only: "No … runtime/framework upgrade". Its open questions were Blob or Files and SQL Database or Managed Instance, and its integration verification defaulted to mock mode because no Azure environment was given |
| 2.1 | **Projects: 1 error** in the C# Dev Kit status bar before the upgrade is expected | Seen in run 1 on the legacy .NET Framework project |
| 2.4, 2.5, 3, 4 | *(Superseded by the dashboard row.)* **Owner-approved deviation:** `/modernize-plan` and `/modernize-execute` prompt files in `.github/prompts/` pin the `modernize` agent and the model (planning `GPT-6 Sol (copilot)`, execution `GPT-6 Luna (copilot)`) and carry the full plan prompt. They replace **Create Plan** and the correction reply. Reasoning effort is set in the picker: Sol Medium, Luna maximum | Run 1's **Create Plan** needed a long correction reply, and the model depended on the picker |
| 3 | *(Superseded by the dashboard row.)* No `reasoning-effort:` line in the prompt files; set reasoning effort in the model picker (Sol Medium, Luna maximum) | A `reasoning-effort:` frontmatter line stopped the prompt files from working in VS Code on `vm-dev01` (`spike/b06-run1` commit `4508c6d`) |
| 3.1, 3.3 | *(Superseded by the dashboard row.)* Run the prompt files from the editor with **▶ Run Prompt** or **Chat: Run Prompt**; the slash command is the alternative | Typing `/modernize-plan` in chat didn't work in run 1; **▶ Run Prompt** from the editor did |
| Intro, 3.1, prompt files | *(Superseded by the dashboard row.)* The prompt files say that every Azure resource already exists, that endpoints come from the configuration keys supplied at execution time, and that no subscription, resource group or resource IDs are recorded. Step 3.1 checks the agent and model the chat shows | The run 1 plan asked which resource reference its real-mode integration tests should use; the owner chose configuration keys at execution time. With **Run Prompt**, the chat footer showed `Agent` and `GPT-5.6 Sol`, not the pinned `modernize` and `GPT-6 Sol (copilot)` |
| 3.1, 3.3 | *(Superseded by the dashboard row.)* Use the **Local** harness, not Agent Host, for the prompt files | Agent Host doesn't load prompt files: run 1's first `/modernize-plan` ran there, fell back to `Agent` and `GPT-5.6 Sol`, and failed as a slash command. In Local, `/modernize-plan` works and applies the pinned agent |
| 2.2, 2.3 | Run a **custom assessment** targeting App Service for Linux (containers), in the Local harness, with the options copied from run 1; the report's target is only checked | The default **Start Assessment**, with its App Service (Windows) default, led to the wrong plan target in run 1's false start |
| 3, skills | *(Superseded by the dashboard row.)* **Owner decision:** the prompt files are replaced by the agent skills `.github/skills/modernize-plan` and `modernize-execute` (`disable-model-invocation: true`, same bodies). Skills can't pin an agent or model, so step 3 picks `modernize`, GPT-6 Sol at Medium and GPT-6 Luna at maximum by hand. They work in the Copilot and Local harnesses | The assessment dashboard switches the chat to the Copilot harness, which doesn't load prompt files |
| 2, 3 | *(Its review checklist and correction reply are superseded by the kit rules row.)* **Owner decision:** the dashboard buttons are the primary path: custom assessment, **Create Plan** from the report, then execute. A ⚠️ callout before each button says which agent, model and reasoning effort to select (`modernize`, GPT-6 Sol Medium to plan, GPT-6 Luna maximum to execute), because the button uses whatever is selected. The review checks the plan against a list, and the correction reply is inlined in step 3.3. The skills are removed | The workspace skills didn't show in the Copilot harness's skill list, and the dashboard writes the prompts itself |
| 3.2, 3.4, rules | *(The review checklist and correction reply are superseded by the kit rules row; the Windows authentication callout and .txt exports still apply.)* A second ⚠️ callout, as loud as the model check, to deselect Windows authentication before **Create Plan**. The review checklist adds Blob only (no Files or storage mount), Managed Instance only (no SQL Database), the CVE check last and the hosting target; the correction reply uses run 1's task IDs as examples. Chat exports may be `.txt` if the JSON export fails | Run 1's dashboard plan (commit `e5defe5`) had no upgrade, both storage and both database alternatives chained, task 007 on Azure Files, 005 Entra ID (Windows auth wasn't deselected), no local SQL auth rule, no hosting target and no rule against keys. **Chat: Export Chat** failed, so the chat was saved as text |
| 3.4, 3.5 | *(Superseded by the next row: a finished plan can't be corrected.)* **Owner decision:** always send one fixed kit rules prompt straight after **Create Plan** (no task IDs, 7 rules, ending with a self-check table), then check that all 7 rows are met or send it again. It replaces the conditional review and correction reply | Run 1's dashboard plan missed most of the kit's rules; a fixed prompt with a self-check is simpler to follow than a review checklist |
| 3 | **Owner decision:** no **Create Plan**. After the custom assessment, start a new chat (`modernize`, GPT-6 Sol, Medium) and send `/create-modernization-plan` with the seven kit rules as the planning input, ending with the 1–7 self-check table. Check the table and `tasks.json` (upgrade first, one target per workload, no Entra), then execute. A wrong plan is deleted and regenerated, never corrected. Supersedes the kit rules row | When the kit rules were sent after **Create Plan**, the agent refused: the planning coordinator had completed and the workflow doesn't allow re-invoking it or editing its outputs, and it said to start a new planning session with the rules as input |
| 3.4 | After any abandoned plan or execution attempt, start execution in a new chat with `Execute the modernization plan in .github/modernize/<plan-folder>`, reloading the window if needed | In run 1, "Execute the plan" in the planning chat handed off to `execution-coordinator`, which returned BLOCKED before any task because it saw an in-progress execution-phase tracker. No tracker file was on disk, so it's likely session state from the earlier abandoned attempts |
| 3.4 | Plan and execute in separate chats: execution always starts in a new chat, never retried in the planning chat. Reload the window after any blocked execution. Supersedes the previous row | "Retry from scratch" in the planning chat was blocked too: "Maximum sub-agent depth of 4 reached". `modernize` → `create-modernization-plan` → `execution-coordinator` → retry uses up the depth budget within one chat |
| 3.4 | Commit and push after every task, before the next one starts. Decline branch creation; if the agent creates `appmod/*` branches anyway, merge or fast-forward them back into `spike/b06-runN`. Check the current branch before every commit | When task 002 started, the agent's version control tool ran `prepareBranch` and switched to `appmod/dotnet-migration-azure-sql-database-<timestamp>`. Task 001's uncommitted output was probably stashed ("no restore-stash action"), and the working tree was back at .NET Framework 4.8 |
| 3.4 | One task per chat: new chat (`modernize`, GPT-6 Luna maximum), `Execute task 00N of the plan in <plan folder>`, then `git switch spike/b06-runN`, `git merge --ff-only <appmod branch>`, `git push`. Per-task notes in `.github/modernize/code-migration/<timestamp>/` are committed too | Task 001 was restored from the agent's auto-stash and pushed; task 002 ran in a new chat and the tool committed it on a new `appmod/*` branch (`prepareBranch` and `commitChanges` per task) |
| 3.4 | After each task is fast-forwarded and pushed, reload the window before the next task's new chat. If the agent reports a stale tracker, tell it to mark it complete and run the task | Task 003, in a new chat, stopped on a leftover "in-progress invocation tracking item" from task 002's run; the agent marked it complete and went on when told to |
| 3.4.3 | After each task, check `git status --short --branch`: fast-forward from an `appmod/*` branch, or commit uncommitted changes, then push | The branch and commit behaviour differs by path: task 002 was committed on an `appmod/*` branch, while task 003's retry ran directly on `spike/b06-run1` with no `prepareBranch` and no commit |
