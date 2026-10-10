# Modernization playbook

Last updated 2026-10-10. Built from the golden path the kit validated end to end. The tools and models change often: if this date is more than a few weeks old, check with your coach before you start.

The playbook takes Contoso University in `app/ContosoUniversity` from ASP.NET MVC 5 on .NET Framework 4.8 to .NET 10 and ASP.NET Core MVC, with uploads on Blob, notifications on Service Bus, secrets in Key Vault and telemetry in Application Insights. Then it packages the app as an image in your private registry and runs it on App Service against SQL Managed Instance. Everything runs on `vm-dev01`.

| Part | Use |
|---|---|
| Host | VS Code on `vm-dev01` |
| Extension | GitHub Copilot upgrade (`ms-dotnettools.upgrade-agent`) |
| Agent and scenario | **Upgrade**, scenario `dotnet-version-upgrade` (the prompt forces it) |
| Harness | **Local** for the whole run. In the Copilot harness, tasks don't start |
| Prompt | [plan-prompt.txt](plan-prompt.txt), sent once, at the start |
| Execution | One task per new chat, then that task's check, then a commit and push |
| Package | .NET SDK container publishing, no Dockerfile and no Docker |

## Models

Models change faster than this playbook. Choose by class, not by name:

| Phase | Class | Validated on 2026-10-02 |
|---|---|---|
| Assessment | Balanced (Sonnet- or Terra-class) | Claude Opus 5.5 at Medium ran the assessment and the plan in one chat |
| Planning | Most capable (Opus- or Sol-class), Medium reasoning | Claude Opus 5.5 at Medium |
| Execution | Balanced at Medium reasoning; an efficient model at maximum reasoning (Luna-class) is worth exploring | Claude Sonnet 5.5 at Medium ran 7 of 7 tasks with no intervention. GPT-6 Luna at maximum also ran 7 of 7, with one `continue` |

The prompt pauses at the assessment gate, so you can switch from a balanced model to the most capable one before you approve planning. The chat uses whatever the agent and model pickers show when you send, so check both before every message that starts work.

## Rules for the whole run

- **Scope.** Only `app/ContosoUniversity` and `.github/upgrades/` change. Before every commit, `git status --short -- . ':!app' ':!.github/upgrades'` must print nothing. If it prints anything, restore it with `git restore` before you commit.
- **Run the app after every task.** The agent's own validation can pass without the app ever starting. Build, `dotnet run`, open the pages, then commit.
- **Commit and push after every task**, before the next one starts, on your `vm-dev01-work` branch: `git add -A`, `git commit -m "app: task 0N <name>"`, `git push`. The push goes to your own repo (the `member` remote), not the public kit. Check `git branch -vv` before you commit, and don't run `git pull`: the [guide](https://factory.apexops.pro/guides/ghcp-upgrade/#save-your-work-and-keep-the-branches-straight) lists the branch rules. The scenario uses manual commits, so the agent doesn't commit for you.
- **Local runs** need `ASPNETCORE_ENVIRONMENT=Development`. `dotnet run` sets it from the launch profile; `dotnet run --no-launch-profile` starts in Production, which refuses the on-premises SQL login.
- **Names.** `<suffix>` is your archetype suffix and `<n>` your member number. The archetype's resources are in `rg-university-<suffix>`: `stuniversity<suffix>`, `sbns-university-<suffix>`, `kv-university-<suffix>`, `cruniversity<suffix>`, `appi-university-<suffix>`, `sqlmi-university-<suffix>`, `id-university-<suffix>` and `app-university-<suffix>`.
- **Stuck?** After two attempts at a step, ask your coach.

## Step 0: Set up

**Goal:** a signed-in VM, a clean legacy tree and the Upgrade agent ready in the Local harness.

1. Connect to `vm-dev01` through Bastion. Open PowerShell 7 and sign in with device code flows. Each command prints a code: enter it on your own device, where passkeys and password managers work.

   ```powershell
   gh auth login --web                 # enter the code at https://github.com/login/device
   az login --use-device-code          # enter the code at https://microsoft.com/devicelogin
   az account show --query name -o tsv # your workload subscription, the one with rg-datacenter
   ```

   Some tenants block device code flow. Then use `az login` in the Bastion session.

2. Give git your GitHub identity. A fresh VM user has none, and the first commit fails without it:

   ```powershell
   $u = gh api user | ConvertFrom-Json
   git config --global user.name ($u.name ?? $u.login)
   git config --global user.email "$($u.id)+$($u.login)@users.noreply.github.com"
   gh auth setup-git
   ```

3. Make `DefaultAzureCredential` use your Azure CLI sign-in. Your own identity holds the data roles, and without this the app gets 403 from Blob, Service Bus and Key Vault. Then restart VS Code and every terminal:

   ```powershell
   [Environment]::SetEnvironmentVariable('AZURE_TOKEN_CREDENTIALS', 'AzureCliCredential', 'User')
   ```

   Set it only on `vm-dev01`. On App Service the app uses its managed identity.

4. Use the kit clone and your work branch, then make the tree pure legacy. The deployment cloned the kit to `C:\src\factory`; the [GHCP upgrade guide](https://factory.apexops.pro/guides/ghcp-upgrade/#switching-to-vm-dev01) (steps 4 and 5) connects it to your own repo as the `member` remote and creates your work branch `vm-dev01-work`. Do those steps first. Leftover plans, skills and build output from an earlier attempt steer the agent:

   ```powershell
   Set-Location C:\src\factory
   git branch -vv                       # must show * vm-dev01-work tracking member/vm-dev01-work
   git clean -ndx -- app .github        # dry run: read the list
   git clean -fdx -- app .github
   git status --short --ignored -- app .github   # must print nothing
   ```

5. Open the clone's root in VS Code (`code C:\src\factory`), so the agent finds `.github/skills/` and `.github/modernization/`. Check that **GitHub Copilot upgrade** is installed and enabled. If **GitHub Copilot modernization** is installed, disable it for the workspace (**Extensions** > **GitHub Copilot modernization** > **Disable (Workspace)**).
6. In the Chat panel, set the harness (**Session Target**) to **Local**. Give the Upgrade server model access once: **MCP: List Servers** > **Upgrade** > **Configure Model Access**, and allow the models you'll use.

**Check:** `az account show` names your workload subscription, `git status --short` prints nothing, and the agent picker lists **Upgrade**.

## Step 1: Assess and plan (C3)

**Goal:** a tool-based assessment and a seven-task plan that follows the kit's rules, with no application file changed.

1. ⚠️ **Before you send:** harness **Local**, a new chat, agent **Upgrade**, a balanced model for the assessment (see [Models](#models)).
2. Copy the prompt with UTF-8 intact, then paste it into the chat and send it:

   ```powershell
   [Console]::OutputEncoding = [Text.Encoding]::UTF8
   Get-Content -Raw -Encoding utf8 .github\modernization\plan-prompt.txt | Set-Clipboard
   ```

3. Answer the pre-initialization confirmation as the prompt says: target `net10.0`, **Guided**, stay on the current branch, commit strategy **Manual**, branch sync off.
4. At the assessment gate, check that `.github/upgrades/scenarios/dotnet-version-upgrade/` has `assessment.md`, `assessment.json` and `dependencies-health.json`, and that the Upgrade dashboard's **Assessment** tab shows data. Switch to the most capable model, then approve planning.
5. Check the plan gate:
   - `plan.md`, `scenario-instructions.md` and `scenario.json` exist;
   - exactly seven tasks, in a strict chain: .NET 10, SQL Managed Instance, Blob, Service Bus, Key Vault, OpenTelemetry, CVE audit;
   - all 9 rows of the rules table are met;
   - no task mentions `#skill:migrating-webapi-odata`;
   - `git status --short -- app` prints nothing.

   If a check fails, tell the agent which one, in the same chat. The Upgrade agent can revise its own plan.
6. Commit and push: `app: assess and plan`. This commit is your baseline: if you ever have to restart the seven tasks, `git reset --hard` to it (it discards uncommitted work, and your next push needs `git push --force-with-lease`), then check the tree is clean again with Step 0's last command.

**Hot spots**

| Symptom | Fix |
|---|---|
| The agent picks the `azure-migrate` scenario or asks for GitHub Copilot modernization | The prompt wasn't sent whole. Start a new chat and paste it again |
| The prompt arrives with garbled characters | Copy it with the UTF-8 block above |
| "The Upgrade workflow tools aren't available", or no `assessment.json` | The extension's tools didn't load. Reload the window (**Developer: Reload Window**) and start a new chat. Don't accept a hand-written assessment |
| The plan includes Entra ID user sign-in, Azure SQL Database or Azure Files | Point the agent at the rules table and ask it to revise the plan |

## Step 2: Run the tasks (C6)

**Goal:** the seven tasks done, each checked by running the app.

For each task, in order:

1. ⚠️ **Before you send:** harness **Local**, a **new chat**, agent **Upgrade**, the execution model (see [Models](#models)).
2. Start the task. Use **Start** on the task in the Upgrade dashboard's **Execution** tab, or send:

   ```text
   Start task <task-id> with start_task. Scope: app/ContosoUniversity and .github/upgrades only; never edit files outside them.
   ```

   The task IDs are in `.github/upgrades/scenarios/dotnet-version-upgrade/tasks.md`, for example `01-aspnetcore-net10`.
3. Approve builds and file edits. If the agent stops halfway, reply `continue`.
4. Build and run the app, then do the task's check below.
5. Commit and push: `app: task 0N <name>`.

### Local configuration

Task 01 gives the project a new `UserSecretsId`, so set your user secrets **after** task 01, and again whenever the `UserSecretsId` changes:

```powershell
Set-Location C:\src\factory\app\ContosoUniversity
dotnet user-secrets set 'ConnectionStrings:DefaultConnection' 'Server=10.10.<n>.4;Database=ContosoUniversity;User Id=contosoapp;Password=FactoryLab-2026-Pw;TrustServerCertificate=True;MultipleActiveResultSets=True'
dotnet user-secrets set 'Storage:BlobServiceUri' 'https://stuniversity<suffix>.blob.core.windows.net'
dotnet user-secrets set 'Storage:ContainerName' 'teaching-materials'
dotnet user-secrets set 'ServiceBus:FullyQualifiedNamespace' 'sbns-university-<suffix>.servicebus.windows.net'
dotnet user-secrets set 'ServiceBus:QueueName' 'notifications'
```

User secrets live outside the repo, so nothing here is committed. The SQL login is the datacenter's documented lab login, and it works only against the source database on `vm-app01`.

### Task checks

| Task | Check after it | Hot spots |
|---|---|---|
| 01 .NET 10 and ASP.NET Core MVC | `dotnet build` passes. The home, Students, Courses, Instructors and Departments pages load against `10.10.<n>.4`. `Global.asax` and `App_Start` are gone, the project file has the container properties (`ContainerBaseImage`, `ContainerRepository` `contoso-university`, port 8080) and there's no `Dockerfile`. `/Notifications/GetNotifications` returns `{"success":true,...}` with PascalCase properties | The pages fail or fall back to LocalDB: the user secrets aren't set for the new `UserSecretsId`. Notifications are in memory until task 04: that's expected |
| 02 SQL Managed Instance | Students still read and write in Development. Production refuses a SQL login: `$env:ASPNETCORE_ENVIRONMENT='Production'; dotnet run --no-launch-profile` stops with a message about the user name or password. Remove the variable afterwards | Production runs need the setting from the environment, because user secrets load only in Development |
| 03 Blob | On **Courses** > **Edit**, upload an image. It shows on the course and lands in the container: `az storage blob list --account-name stuniversity<suffix> -c teaching-materials --auth-mode login -o table`. Replace it and delete it. A non-image and a file over 5 MB are rejected. The page never links to a `blob.core.windows.net` URL | 403: `AZURE_TOKEN_CREDENTIALS` isn't set in this terminal. Restart the terminal |
| 04 Service Bus | Create or edit a student. A toast appears at the top right within 5 seconds, and `/Notifications/GetNotifications` returns `"success":true`. The **Notifications** page is only information | A receive path that always fails and is hidden by the controller. If receive fails, ask the agent to use a positive wait time and to log exceptions with `ILogger` |
| 05 Key Vault | A: Development without `KeyVault:VaultUri` runs. B: Production without it refuses to start. C: Production with `KeyVault__VaultUri` set opens the vault, then stops because the vault has no `ConnectionStrings--DefaultConnection` yet (C7 writes it). A 403 or a name resolution error instead means the vault wasn't reached (commands below) | Key Vault answers 403: `AZURE_TOKEN_CREDENTIALS` isn't set in this terminal, or you lack a Key Vault data role. The archetype gives its deployer **Key Vault Secrets Officer** |
| 06 OpenTelemetry | With no connection string the app starts normally. With one (below), requests, SQL dependencies and traces from a local run show in Application Insights within 5 minutes. The `Trace` and `Debug` search below prints nothing | A connection string that's set but invalid crashes the app at startup. Service Bus never shows as a dependency: prove messaging with task 04's check. A `TaskCanceledException` (499) when you leave a page during a notification poll is harmless |
| 07 CVE audit | `dotnet list app/ContosoUniversity package --vulnerable --include-transitive` finds nothing. A no-op task is a valid result | — |

Task 06's search for leftover `Trace` and `Debug` calls:

```powershell
git grep -n -E "Trace\.|Debug\.Write" -- app/ContosoUniversity
```

Task 05's checks. The Production runs read `KeyVault:VaultUri` from the environment, because user secrets load only in Development:

```powershell
Set-Location C:\src\factory\app\ContosoUniversity
dotnet run                                       # A: Development, no vault: pages work
$env:ASPNETCORE_ENVIRONMENT = 'Production'
dotnet run --no-launch-profile                   # B: refuses to start, KeyVault:VaultUri is missing
$env:KeyVault__VaultUri = 'https://kv-university-<suffix>.vault.azure.net/'
dotnet run --no-launch-profile                   # C: opens the vault, then refuses to start: no DefaultConnection yet
Remove-Item Env:ASPNETCORE_ENVIRONMENT, Env:KeyVault__VaultUri
```

Task 06's check. Application Insights has local authentication off, so your own sign-in needs **Monitoring Metrics Publisher** on it. Grant it once; you're Owner of your workload subscription. This grant is the one Azure change C6 asks of you besides the image push: you run it yourself, the agent doesn't:

```powershell
$appi = az monitor app-insights component show -g rg-university-<suffix> -a appi-university-<suffix> --query id -o tsv --only-show-errors
az role assignment create --assignee (az ad signed-in-user show --query id -o tsv) --role 'Monitoring Metrics Publisher' --scope $appi --output none
az extension add -n application-insights --only-show-errors   # install first: an install mid-command garbles the value
$cs = az monitor app-insights component show -g rg-university-<suffix> -a appi-university-<suffix> --query connectionString -o tsv --only-show-errors
if ($cs -notmatch '^InstrumentationKey=') { throw 'Bad connection string' }
dotnet user-secrets set 'APPLICATIONINSIGHTS_CONNECTION_STRING' $cs
dotnet run                                       # open the five pages, edit a student, wait 3-5 minutes
az monitor app-insights query -g rg-university-<suffix> -a appi-university-<suffix> --analytics-query "union requests, dependencies, traces | where timestamp > ago(30m) | summarize count() by itemType" --query "tables[0].rows" -o tsv
```

**Hot spots for every task**

| Symptom | Fix |
|---|---|
| `start_task` fails with "internal LLM client unavailable" or "plan.md could not be parsed" | You're in the Copilot harness. Switch to **Local** and start a new chat |
| The agent edits files outside `app/` and `.github/upgrades/` | Restore them with `git restore <path>` before you commit |
| The agent offers extra work (Aspire, ARM64, reports) | Decline: it's out of scope |

## Step 3: Close the gaps

**Goal:** nothing from the legacy stack is left.

The tasks cover these gaps, but check them. Each skill in `.github/skills/` checks one gap and says how to fix what's left:

| Check | Skill if it fails |
|---|---|
| `Global.asax`, `App_Start` and `Web.config` are gone; `Program.cs` maps the default route and serves `wwwroot` | `aspnet-startup-migration` |
| Controllers get the notification service through their constructor; the first search below prints nothing | `notification-service-di` |
| The second search below prints nothing | `trace-to-opentelemetry` for `Trace` and `Debug`; `aspnet-startup-migration` for `System.Web` |

```powershell
git grep -n "new NotificationService" -- app
git grep -n -i -E "System\.Web|System\.Messaging|MessageQueue|Trace\.|Debug\.Write" -- app/ContosoUniversity
```

To use a skill, ask in a new chat with agent **Upgrade** or **Agent**: `Use the <skill> skill. Scope: app/ContosoUniversity only.` Then run the app, commit and push: `app: gaps`.

## Step 4: Package (C6)

**Goal:** the image in your private registry, built without Docker. The `sdk-container-publish` skill has the details. The push writes to Azure, so you run these commands in your own terminal; the agent explains and checks, it doesn't run them.

```powershell
Set-Location C:\src\factory\app\ContosoUniversity
$token = az acr login --name cruniversity<suffix> --expose-token --only-show-errors | ConvertFrom-Json
$env:DOTNET_CONTAINER_REGISTRY_UNAME = $token.username
$env:DOTNET_CONTAINER_REGISTRY_PWORD = $token.accessToken
dotnet publish -c Release /t:PublishContainer -p:ContainerRegistry=cruniversity<suffix>.azurecr.io -p:ContainerImageTag=c6
Remove-Item Env:DOTNET_CONTAINER_REGISTRY_UNAME, Env:DOTNET_CONTAINER_REGISTRY_PWORD
az acr repository show-tags --name cruniversity<suffix> --repository contoso-university -o table
```

**Check:** `show-tags` lists `c6`. The registry has no public access, so the push works only from `vm-dev01`.

**Hot spots:** an `unauthorized` push means the token expired (it lasts about 3 hours): run the block again. A push that times out means the registry name didn't resolve to its private endpoint: `Resolve-DnsName cruniversity<suffix>.azurecr.io` must return a `10.20.<n>.` address.

## Step 5: App Service configuration (C6) and go-live (C7)

**Goal:** in C6, the web app's identity, Key Vault and OpenTelemetry settings checked against your app. In C7, after the database migration, the web app runs your image against SQL Managed Instance with its managed identity. The `app-service-configuration` skill has the details.

> [!IMPORTANT]
> Don't point the web app at your image in C6. The modernized app reads its database at startup, so on App Service it exits until C7 has migrated the database, written the Key Vault secret and created its database user. That's expected: the app first runs on App Service at the end of C7.

C6 only checks: use the `list` and `show` commands. The commands under C7 change Azure, so you run them yourself in C7, after the cutover; the agent never runs them.

### C6: check the configuration

1. The archetype already set the app settings: `Storage__BlobServiceUri`, `Storage__ContainerName`, `ServiceBus__FullyQualifiedNamespace`, `ServiceBus__QueueName`, `KeyVault__VaultUri`, `APPLICATIONINSIGHTS_CONNECTION_STRING` and `AZURE_CLIENT_ID`. App settings use `__` where the code reads `:`. Check them against the keys your app reads:

   ```powershell
   az webapp config appsettings list -g rg-university-<suffix> -n app-university-<suffix> --query "[].name" -o tsv
   ```

2. The web app uses the user-assigned identity `id-university-<suffix>`, which has the data roles, AcrPull and Key Vault Secrets User. The database connection isn't an app setting: it's the Key Vault secret `ConnectionStrings--DefaultConnection`, which C7 writes.

**Check:** every key the app reads has a setting, and your image is in the registry (step 4).

### C7: go live after cutover

After the MI link cutover, the database on the Managed Instance is writable:

1. Write the connection secret. It uses Microsoft Entra authentication and has no password:

   ```powershell
   $mi = az sql mi show -g rg-university-<suffix> -n sqlmi-university-<suffix> --query fullyQualifiedDomainName -o tsv
   az keyvault secret set --vault-name kv-university-<suffix> --name 'ConnectionStrings--DefaultConnection' --value "Server=$mi;Database=ContosoUniversity;Authentication=Active Directory Default;Encrypt=True;" --output none
   ```

2. Create the database user for the web app's identity. Connect to `ContosoUniversity` on your Managed Instance from SSMS on `vm-dev01` with **Microsoft Entra MFA**, as the archetype's deployer, and run:

   ```sql
   CREATE USER [id-university-<suffix>] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_datareader ADD MEMBER [id-university-<suffix>];
   ALTER ROLE db_datawriter ADD MEMBER [id-university-<suffix>];
   ALTER ROLE db_ddladmin ADD MEMBER [id-university-<suffix>];
   ```

   It fails before cutover, because the replica is read-only. Don't use `WITH SID` or `TYPE = E`: SQL Managed Instance doesn't support them.

3. Point the web app at your image and restart it. The archetype already set the pull identity, so the image comes from the private registry with the managed identity:

   ```powershell
   az webapp config container set -g rg-university-<suffix> -n app-university-<suffix> --container-image-name cruniversity<suffix>.azurecr.io/contoso-university:c6 --container-registry-url https://cruniversity<suffix>.azurecr.io --output none
   az webapp config show -g rg-university-<suffix> -n app-university-<suffix> --query acrUseManagedIdentityCreds   # true: the archetype set the pull identity
   az webapp restart -g rg-university-<suffix> -n app-university-<suffix>
   ```

**Check:** `https://app-university-<suffix>.azurewebsites.net/` loads within a few minutes. The five pages show the migrated data, an upload lands in Blob, a student edit shows a toast, and requests reach Application Insights. Read the log stream with `az webapp log tail -g rg-university-<suffix> -n app-university-<suffix>`.

**Hot spots**

| Symptom | Fix |
|---|---|
| The container never starts, with `ACRTokenRetrievalFailure` in the log | The registry must accept ARM-audience tokens: `az acr config authentication-as-arm show -r cruniversity<suffix>` must print `enabled`. The archetype sets it; ask your coach if it doesn't |
| The app stops at startup with "KeyVault:VaultUri is not configured" or "DefaultConnection is not configured" | An app setting is missing or uses `:`, or the Key Vault secret wasn't written (C7 step 1) |
| `CREATE USER` fails with "Server identity does not have Azure Active Directory Readers permission" | The Managed Instance's primary identity must be the team's `id-sqlmi-directory`. Ask your coach |
| Pages fail with "Login failed for user '<token-identified principal>'" | The database user doesn't exist yet, or its name isn't the identity's name |

## With Copilot CLI instead of VS Code

The same sequence runs in GitHub Copilot CLI, with the same plugin as the GitHub Copilot app. The kit validated VS Code only, so use the CLI if you prefer a terminal and can fall back to VS Code.

1. Install the plugin once, in a Copilot CLI session:

   ```text
   /plugin marketplace add microsoft/upgrade-agent-plugins
   /plugin install upgrade-agent@upgrade-agent-plugins
   ```

   Then check that `/agent` lists `upgrade-agent:upgrade`.

2. Start it from the repo root on `vm-dev01`, in a clean tree (step 0): `copilot --agent upgrade-agent:upgrade`. Pick the model with `/model`.
3. Paste [plan-prompt.txt](plan-prompt.txt), as in step 1. Then run one task per session, as in step 2, with the same checks, commits and pushes.

Where it differs from VS Code:

- There's no harness to choose and no Local or Copilot split, and you don't configure model access.
- There's no dashboard. Read the plan and progress in `.github/upgrades/scenarios/dotnet-version-upgrade/` (`plan.md`, `tasks.md`).
- If the agent says the Upgrade workflow tools (`get_state`, `initialize_scenario`) aren't available, the prompt stops it on purpose. The GitHub Copilot app had the same problem in the kit's tests. Switch to VS Code.
