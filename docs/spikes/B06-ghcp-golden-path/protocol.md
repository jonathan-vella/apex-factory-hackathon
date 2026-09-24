# B06 run protocol: GHCP golden path on `vm-dev01`

The steps the owner follows on `vm-dev01` for each run of the [B06 spike](../../backlog/B06-spike-ghcp.md). They assume you haven't used GitHub Copilot modernization before. Fill in the results sheet as you go: [run1.md](run1.md) for run 1, [run2.md](run2.md) for run 2.

| Run | Branch | Start from commit | Protocol version |
|---|---|---|---|
| 1 | `spike/b06-run1` | `da4e5f606983332001c94ce69b48634f9c1864b3` | v1 |
| 2 | `spike/b06-run2` | set between runs | v2 |

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

- **Record as you go.** Before a step, write the start time in the results sheet. After it, write the end time, the model and agent you used, the prompts (paste them), what Copilot changed, anything you fixed by hand, whether `dotnet build` passes and whether the app runs, and the premium requests used if VS Code shows them.
- **Commit after each step,** with a message that names the step, for example `git commit -am "run1: step 3 upgrade to .NET 10"`. Include new files: `git add -A` first.
- **Models:** no model is pinned. Follow the kit's guidance and record the exact model name and the date:
  - assessment: a balanced model (Sonnet- or Terra-class);
  - planning: the most capable model (Opus- or Sol-class);
  - plan execution: an efficient model at maximum reasoning effort (Luna-class).

  The modernization agent picks its own default model; switch it with the model picker in the chat input box.
- **Approve tool calls with care.** Copilot asks before it runs commands or uses MCP tools. Read what it wants to run. Approve builds, restores and file edits. Don't approve anything that creates, changes or deletes Azure resources: they already exist.
- **Never paste a password into a committed file.** Connection strings with a password go into user secrets (`dotnet user-secrets`) or Key Vault. If Copilot writes one into `appsettings*.json`, move it and note it as an intervention.
- **Keys don't work.** Storage shared keys and Service Bus SAS are turned off. If Copilot generates key- or connection-string-based code for Blob or Service Bus, it fails at runtime: note it as a hot spot and ask for `DefaultAzureCredential`.
- **Time boxes:** C3 is 1 hour and C6 is 3 hours at the event. Don't stop a step at the time box, but note when you pass it. If you can't reach a building .NET 10 app within a working day, stop and tell the executor.
- **If Notepad opens after every Copilot tool call,** that's the C# Dev Kit 3.40.204 bug ([microsoft/vscode-dotnettools#3568](https://github.com/microsoft/vscode-dotnettools/issues/3568)). Close Notepad, then rename `track-skill-invocation.ps1` wherever it appears under `%USERPROFILE%\.vscode\extensions` and `%APPDATA%\Code\agentPlugins` (for example to `track-skill-invocation.ps1.disabled`) and restart VS Code. Don't change the `.ps1` file association. Note it in the results sheet if it happened.

## Step 1: Set up

1. Connect to `vm-dev01` through Bastion as `labadmin`.
2. Open PowerShell 7 and sign in:

   ```powershell
   gh auth login --web
   az login
   az account set --subscription '<workload-subscription-id>'
   ```

3. Use the existing clone in `C:\src\apex-factory-hackathon` (clone it there only if it's missing). Check that it's clean, fetch, and create the run branch from the commit in the table above:

   ```powershell
   if (-not (Test-Path C:\src\apex-factory-hackathon)) { git clone https://github.com/jonathan-vella/apex-factory-hackathon.git C:\src\apex-factory-hackathon }
   Set-Location C:\src\apex-factory-hackathon
   git status --short
   ```

   `git status --short` must print nothing. **If it prints anything, stop and tell the executor**: don't commit, stash or delete anything. Otherwise:

   ```powershell
   git fetch origin
   git switch -c spike/b06-run1 da4e5f606983332001c94ce69b48634f9c1864b3
   git diff --stat da4e5f606983332001c94ce69b48634f9c1864b3 origin/main -- app/ContosoUniversity
   ```

   The last command must print nothing: `app/ContosoUniversity` is unchanged from `main`. For run 2, use `spike/b06-run2` and the run 2 commit.

4. **Run 1 only: save the earlier manual assessment.** The assessment you ran by hand on 2026-09-24 left its output in `C:\src\apex-factory-hackathon\app\ContosoUniversity\.github\modernize\`, which git ignores. Copy its report into the spike folder, then move the whole folder out of the repo so run 1's assessment starts clean:

   ```powershell
   $manual = 'C:\src\apex-factory-hackathon\app\ContosoUniversity\.github\modernize'
   $target = 'C:\src\apex-factory-hackathon\docs\spikes\B06-ghcp-golden-path\assessment\manual-2026-09-24'
   New-Item -ItemType Directory -Force $target | Out-Null
   Copy-Item "$manual\assessment\reports\report-20260924145927\*" $target -Recurse
   Copy-Item "$manual\assessment\engines\dotnet-appcat\result\report.json" (Join-Path $target 'appcat-report.json')
   Move-Item $manual 'C:\src\b06-manual-assessment'
   git add docs/spikes/B06-ghcp-golden-path/assessment
   git commit -m "run1: step 1 save the manual assessment"
   ```

   The target folder then holds `report.json`, `solution.json` and `appcat-report.json`.

5. Open the folder in VS Code: `code C:\src\apex-factory-hackathon`. Sign in to GitHub in VS Code (**Accounts** menu, bottom left) with the account that has the Copilot seat. Check that Copilot Chat opens in **Agent** mode.
6. Check the extensions under **Extensions** (Ctrl+Shift+X):
   - **GitHub Copilot modernization** (`vscjava.migrate-java-to-azure`) is installed. It's the only modernization extension the kit uses. It adds the **GitHub Copilot modernization** view to the Activity Bar and the `modernize` agent to Copilot Chat, which covers the assessment, the .NET upgrade and the migration tasks.
   - Record its version, and the VS Code, Copilot Chat and C# Dev Kit versions, in the results sheet.
7. Check that the spike services resolve privately (each prints a `10.10.n.128/27` address):

   ```powershell
   'stuni<suffix>b06.blob.core.windows.net','sbns-uni-<suffix>-b06.servicebus.windows.net','cruni<suffix>b06.azurecr.io','kv-uni-<suffix>-b06.vault.azure.net' | ForEach-Object { Resolve-DnsName $_ -Type A | Where-Object IPAddress | Select-Object -Last 1 Name, IPAddress }
   ```

## Step 2: C3 assess

Model: balanced (Sonnet- or Terra-class).

1. Keep the repo root open in VS Code. Pick the balanced model in the Copilot Chat model picker.
2. Open the **GitHub Copilot modernization** view in the Activity Bar. In **QUICKSTART**, select **Start Assessment**, then **Run Assessment** on the **Assessment reports** page. If it asks which project, pick `app/ContosoUniversity`.
3. Wait for the report. Read it: note the issues it finds for local files, MSMQ, the database, the plaintext connection string and `System.Web`, and the migration tasks it recommends.
4. Save the report into the spike folder. The modernization extension writes it to `C:\src\apex-factory-hackathon\app\ContosoUniversity\.github\modernize\assessment\reports\report-<timestamp>\`, which git ignores. Copy the new report folder's files to `docs\spikes\B06-ghcp-golden-path\assessment\run1\` (run 2: `run2\`), plus `...\.github\modernize\assessment\engines\dotnet-appcat\result\report.json` as `appcat-report.json`. If the report page offers an export (HTML or Markdown), save that there too. `git add docs/spikes/B06-ghcp-golden-path/assessment` so the ignored source folder doesn't matter.
5. Commit: `run1: step 2 assessment`.

## Step 3: C6 upgrade to .NET 10

Model: planning with the most capable model (Opus- or Sol-class); execution with an efficient model at maximum reasoning effort (Luna-class).

1. In Copilot Chat, pick the `modernize` agent in the agent picker, and the planning model.
2. Prompt:

   ```text
   Upgrade app/ContosoUniversity to .NET 10 and ASP.NET Core MVC. Convert the project to SDK-style,
   replace packages.config with PackageReference, move Web.config settings to appsettings.json,
   and keep the existing controllers, views and EF Core model. Don't add Azure services yet.
   Plan first and wait for my review before you change code.
   ```

3. Review the assessment and plan files it writes. Edit them if something is wrong, and note what you changed.
4. Switch to the execution model, then reply `continue` (or the button it offers) until it finishes. Keep the changes it proposes when they build.
5. Check: `dotnet build app/ContosoUniversity` passes on the .NET 10 SDK. Point the app at the source database for a first run:

   ```powershell
   Set-Location C:\src\apex-factory-hackathon\app\ContosoUniversity
   dotnet user-secrets init
   dotnet user-secrets set 'ConnectionStrings:DefaultConnection' 'Server=10.10.n.4;Database=ContosoUniversity;User Id=contosoapp;Password=FactoryLab-2026-Pw;TrustServerCertificate=True;MultipleActiveResultSets=True'
   dotnet run
   ```

   Open the URL it prints and try the home, Students, Courses, Instructors and Departments pages. MSMQ may still be in the code at this point; note what works.
6. Commit: `run1: step 3 upgrade to .NET 10`.

## Step 4: C6 predefined tasks

Do the four tasks in this order. For each one, start it from the **TASKS - .NET** section of the **GitHub Copilot modernization** view, or from the assessment report's **Run Task** button, or in Copilot Chat with the `modernize` agent and a `migrate from <source> to <target>` prompt. Record which way you used. Add the prompt below to the chat when the task asks for input, or send it as the first message. Review the `plan.md` and `progress.md` it writes before you reply `continue`. After each task: build, run, commit.

Before 4.2, sign in with the Azure CLI (`az login`) in the same terminal VS Code uses, so `DefaultAzureCredential` finds your account locally.

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

1. Fill in the totals in the results sheet.
2. Push the run branch: `git push -u origin spike/b06-run1`.
3. Tell the executor the run is pushed. The executor runs the build, reference, registry and secrets checks, and adds your results to the report.

## Optional: step 2 with Copilot CLI

After step 2, repeat the assessment with Copilot CLI on a throwaway branch, and note the differences (time, findings, tasks, premium requests) in the results sheet:

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
