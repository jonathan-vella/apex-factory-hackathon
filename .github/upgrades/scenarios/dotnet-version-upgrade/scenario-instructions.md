# .NET Version Upgrade

## Preferences
- **Flow Mode**: Guided
- **Target Framework**: .NET 10 (net10.0)
- **Scope**: app/ContosoUniversity only (ContosoUniversity.sln / ContosoUniversity.csproj)

## Source Control
- **Source Branch**: spike/b06-upgrade-compare-v3
- **Working Branch**: spike/b06-upgrade-compare-v3 (stay on current branch, no new branch)
- **Commit Strategy**: Manual
- **Branch Sync**: Disabled

## User Preferences

### Execution Style
- This run: assessment and planning only. Pause at the assessment gate for approval, then plan, then stop at the plan gate. Do not call start_task or execute any task.
- Do not modify application source files. Do not change, provision, or deploy Azure resources. Do not change the on-premises environment (SQL Server on the app VM, its database, its logins, the legacy app deployment).
- Do not use the `azure-migrate` scenario, do not invoke `start_app_mod_migration_session`, do not create artifacts under `.github/modernize`.
- Assessment must run through the dedicated .NET assessor (`generate_dotnet_upgrade_assessment` writes assessment.md, assessment.json, dependencies-health.json). Never hand-write assessment.md. If that tool is unavailable, stop and tell the user (no generic Assessor fallback).
- Do no work outside the seven tasks. Record extra findings as recommendations only; do not add, split or implement tasks for them.
- Validation is limited to app/ContosoUniversity: build, run and test only that project. Do not run the repository's PowerShell or npm checks.
- Local validation uses the `ConnectionStrings:DefaultConnection` .NET user secret. Never fall back to LocalDB.
- Local validation runs on vm-dev01 inside the spike VNet: private DNS resolves every backend's standard host name to its private endpoint; DefaultAzureCredential uses the owner's Azure CLI sign-in. Blob, Service Bus and Key Vault checks are expected to run, not be blocked.
- Do not manually create tasks.md.

### Technical Preferences

#### Plan structure (exactly seven top-level tasks, in this order)
1. Upgrade to .NET 10 and ASP.NET Core MVC (no dependencies)
2. Migrate the database workload to Azure SQL Managed Instance (depends on 1)
3. Migrate mutable file handling to Azure Blob Storage (depends on 2)
4. Migrate messaging to Azure Service Bus (depends on 3)
5. Integrate Azure Key Vault (depends on 4)
6. Migrate logging and tracing to OpenTelemetry with Azure Monitor (depends on 5)
7. Audit and remediate dependency CVEs (depends on 6)

- Chain: Task 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7. All tasks after Task 1 operate on the upgraded .NET 10 app.
- Preserve task order and dependencies even when current source already satisfies part of a task; plan verification and record the implementation step as a no-op.
- Every task's validation: successful build AND local `dotnet run` where home, Students, Courses, Instructors and Departments pages load.

#### Task 1 – .NET 10 / ASP.NET Core MVC
- net10.0, SDK-style `Microsoft.NET.Sdk.Web`, PackageReference instead of packages.config.
- Migrate applicable Web.config settings to appsettings.json / environment-specific config / ASP.NET Core configuration.
- Nothing lost from Global.asax, RouteConfig, FilterConfig, BundleConfig: default route, global filters, CSS/JS served as static files.
- DI registration for services incl. the database context and the notification service.
- Consistent static file names and references (Linux case-sensitivity).
- Preserve controllers, Razor views, user-visible behavior, EF Core entity model/relationships/mappings.
- SDK container publishing (`dotnet publish /t:PublishContainer`) with container properties in the csproj: base image `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, the app's listening port. No Dockerfile, Docker not required.
- Build, test and local-run validation.
- No Microsoft Entra ID user sign-in. IIS Express Windows Auth and LocalDB Integrated Security are local hosting/database evidence only, not identity requirements. Stale docs/view text mentioning Windows Authentication may be corrected within Task 1, but never produce an identity migration task.
- Notification JSON endpoints are consumed only by the app's own notifications.js: preserve routes, HTTP methods and JSON shape. No Web API / OData surface; do not use the `migrating-webapi-odata` skill or its compatibility gate.
- An interim in-process notification queue is acceptable until Task 4. Do not move Service Bus into Task 1.

#### Task 2 – Azure SQL Managed Instance
- SQL MI is the only Azure database target. Never propose Azure SQL Database.
- Keep reading `ConnectionStrings:DefaultConnection`.
- On Azure: `Authentication=Active Directory Default`, no user name/password, MI private VNet-local host name; never the public data endpoint (port 3342).
- Exception: in `Development` only, a SQL-auth DefaultConnection for the on-prem SQL Server using the existing `contosoapp` login (from .NET user secrets) is passed to EF Core unchanged.
- Outside `Development`, the app must refuse to start if DefaultConnection contains a user name or password.
- Never auto-convert a SQL-auth connection string to managed identity.
- No user names, passwords, connection strings or secrets in source control or planning artifacts.
- Preserve EF Core model and behavior.
- If the local SQL-auth secret is unavailable during assessment, record runtime validation as blocked until supplied; keep the requirement.

#### Task 3 – Azure Blob Storage
- Only target for mutable application files. No Azure Files, storage mounts, shared keys, SAS tokens, or storage connection strings.
- DefaultAzureCredential; config `Storage:BlobServiceUri`, `Storage:ContainerName`.
- Only mutable app-managed files (teaching-material upload, replacement, retrieval, deletion). Keep ordinary CSS/JS/images/bundled assets in the app.
- Serve stored images through the app; never link browsers to blob URLs (no public access).
- Preserve validation, supported file types, size limits, naming, replacement cleanup, deletion behavior, controllers, views.

#### Task 4 – Azure Service Bus
- Only messaging target; replace MSMQ / System.Messaging preserving notification semantics (notify on create/edit/delete; read notifications back).
- SAS disabled: no shared access keys, SAS tokens, or Service Bus connection strings. DefaultAzureCredential.
- Config `ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName`.
- Validation must prove both send and receive.
- Do not create/configure/provision/deploy the Service Bus resource.

#### Task 5 – Azure Key Vault
- Existing Key Vault as ASP.NET Core configuration source via DefaultAzureCredential, `KeyVault:VaultUri`.
- Outside `Development`, refuse to start if `KeyVault:VaultUri` is missing.
- On Azure, secret `ConnectionStrings--DefaultConnection` holds the SQL MI connection string (Entra auth, no password). App Service settings hold only `KeyVault:VaultUri` and non-secret endpoints.
- In `Development`, `KeyVault:VaultUri` optional; user secrets allowed for the on-prem SQL login only. Do not replace or reinterpret a SQL-auth DefaultConnection in Development.
- No Entra user sign-in. Do not provision Key Vault, create secrets/identities, assign roles, or deploy.

#### Task 6 – OpenTelemetry / Azure Monitor
- Replace System.Diagnostics.Trace/Debug with ILogger<T>.
- Add `Azure.Monitor.OpenTelemetry.AspNetCore` with a single `UseAzureMonitor()` call; no individual instrumentation packages or custom exporters.
- Register only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value; set credential to DefaultAzureCredential (App Insights local auth disabled).
- With no connection string, register nothing extra; app must start and run normally with built-in console logging.
- Validation: with a connection string, requests, SQL and HTTP dependencies, and logs from a local run appear in Application Insights within a few minutes.

#### Task 7 – CVE audit and remediation
- Run last. Fresh audit of direct and transitive NuGet dependencies.
- Per vulnerability: upgrade to minimum compatible patched version; document major-version changes and breaking-change risks; build final net10.0 app; run all available tests.
- If none found, keep Task 7 as a verified no-op. Never invent CVE findings.

#### Azure authentication rules
- DefaultAzureCredential for all Azure SDK clients (managed identity on Azure, Azure CLI locally). No hard-coded credential types, client IDs, tenant IDs, object IDs.
- Prohibited: SQL logins/user names/passwords on Azure; Storage shared keys/SAS/connection strings; Service Bus shared keys/SAS/connection strings; App Insights instrumentation-key-only auth; hard-coded endpoints; hard-coded secrets.
- From configuration at execution time: `Storage:BlobServiceUri`, `Storage:ContainerName`, `ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName`, `KeyVault:VaultUri`, `ConnectionStrings:DefaultConnection`, `APPLICATIONINSIGHTS_CONNECTION_STRING`.

#### Network rules
- SQL MI, Blob Storage, Service Bus, Key Vault and the container registry have public network access disabled; reached only via private endpoints / VNet.
- Use each service's standard host name from configuration (private DNS resolves it). Never use `privatelink` host names, IP addresses, or the SQL MI public data endpoint. No IP firewall rules or anything needing public backend access.
- Only public endpoints: the App Service web front end and Application Insights ingestion.

#### Hosting and infrastructure boundaries
- Target: existing Azure App Service for Linux (containers). All Azure resources already exist.
- No tasks for provisioning, IaC, role assignment, private endpoint/DNS config, registry creation, image push, deployment, database/storage/Service Bus/Key Vault creation, or secret creation.
- Container packaging and local container validation may be planned; never deploy.

## Decisions
- Pre-initialization confirmed: net10.0, Guided, stay on spike/b06-upgrade-compare-v3, Manual commits, branch sync disabled.
- Assessment approved by user (2026-10-02). Proceed to planning; stop at the plan gate.
- Upgrade options confirmed as-is by user (2026-10-02). Commit strategy stays Manual (user choice; All-at-Once would otherwise suggest a single commit at end).

## Upgrade Options

### Strategy
- Upgrade Strategy: All-at-Once

### Project Structure
- Project Approach (Web Projects): In-place rewrite

### Compatibility
- Unsupported Packages: Resolve Inline
- Unsupported API Handling: Fix Inline
- System.Web Adapters: Direct Migration to ASP.NET Core APIs

### Modernization
- Assembly Binding Redirects: Remove Binding Redirects
- Nullable Reference Types: Leave Disabled

### Reliability
- Test Coverage: Skip

## Strategy
**Selected**: All-at-Once
**Rationale**: Single .NET Framework 4.8 web project (no project references), ~3.4k LOC; framework rules force All-at-Once for a single project. User-mandated seven-task chain layers Azure modernization on top of the core upgrade (Task 1).

### Execution Constraints
- Task 1 is the single atomic in-place rewrite: SDK-style conversion, packages.config to PackageReference, net10.0 retarget, System.Web to ASP.NET Core, binding-redirect removal and code fixes happen together; build-and-fix in one bounded pass.
- Strict chain 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07; a task starts only after the previous one builds and its local-run validation passes or is explicitly recorded as BLOCKED with the unblocking condition.
- Every task validates with `dotnet build` of app/ContosoUniversity plus local `dotnet run` (home, Students, Courses, Instructors, Departments load) and its task-specific checks. Do not run the repo's PowerShell or npm checks.
- Unsupported packages/APIs are resolved inline (no stubs, no deferred subtasks). No System.Web adapters; no `migrating-webapi-odata` skill or compatibility gate (notification JSON endpoints are internal to notifications.js — preserve routes, methods, property names).
- Nullable stays disabled; no test-baseline generation (no test project exists).

### Local Validation Status
- No `UserSecretsId` in the legacy csproj, so the `ConnectionStrings:DefaultConnection` user secret cannot exist yet for this project. Runtime validation against the on-prem database is BLOCKED until Task 1 adds `UserSecretsId` and the owner sets the secret. Never fall back to LocalDB.
