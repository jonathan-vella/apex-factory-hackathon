# .NET Version Upgrade — ContosoUniversity to .NET 10

## Preferences
- **Flow Mode**: Guided
- **Target Framework**: .NET 10 (net10.0)
- **Scope**: app/ContosoUniversity/ContosoUniversity.csproj

## Source Control
- **Source Branch**: spike/b06-upgrade-compare-v2
- **Working Branch**: spike/b06-upgrade-compare-v2
- **Commit Strategy**: Manual
- **Branch Sync**: Manual

## Upgrade Options

### Strategy
- Upgrade Strategy: All-at-Once

### Project Structure
- Project Approach: In-place rewrite

### Compatibility
- Unsupported Packages: Resolve Inline (2 incompatible packages)
- Unsupported API Handling: Fix Inline
- System.Web Adapters: Direct Migration to ASP.NET Core APIs

### Modernization
- Assembly Binding Redirects: Remove Binding Redirects
- Nullable Reference Types: Leave Disabled

### Reliability
- Test Coverage: Skip

## Strategy
**Selected**: All-at-Once (with the owner-mandated seven-task chain)
**Rationale**: Single .NET Framework 4.8 MVC project, no project references, 3,392 LOC. Prerequisites, SDK-style conversion and the TFM upgrade are merged into Task 1 (the 1-2 project adaptation rule); Tasks 2-7 are owner-mandated Azure migration and CVE tasks, each on the upgraded net10.0 app.

### Execution Constraints
- Strict sequence 01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07; never start a task until its predecessor is complete and validated.
- Task 1 is one atomic pass: SDK-style + net10.0 + package updates, then build and fix all compile errors in a single bounded pass.
- Every task ends with: build of app/ContosoUniversity with 0 errors and 0 warnings, tests if any exist, and a local `dotnet run` where Home, Students, Courses, Instructors, and Departments pages load.
- Where current source already satisfies part of a task, verify and record the implementation step as a no-op in progress-details.md; never skip the task.
- Owner decisions override generic skill guidance: no `migrating-webapi-odata` skill or compatibility gate; preserve the notification JSON routes, HTTP methods and shape.

## User Preferences

### Execution Style
- Assessment and planning only in this run; do not call start_task or execute any task until the owner explicitly approves.
- Guided: pause at the assessment gate for approval, then plan, then stop at the plan gate.
- Do no work outside the seven planned tasks; record extra findings as recommendations only.
- Validation is limited to app/ContosoUniversity: build, run and test only that project. Do not run the repository's PowerShell or npm checks.
- Every task's validation: successful build AND local `dotnet run` where Home, Students, Courses, Instructors, and Departments pages load.
- Local validation uses the `ConnectionStrings:DefaultConnection` user secret. Never fall back to LocalDB.
- Local validation runs on vm-dev01 inside the spike VNet: private DNS resolves backend standard host names to private endpoints; DefaultAzureCredential uses the owner's Azure CLI sign-in. Blob, Service Bus, Key Vault checks are expected to run.

### Technical Preferences
- Do not use the `azure-migrate` scenario or `start_app_mod_migration_session`; no artifacts under `.github/modernize`.
- No Microsoft Entra ID user sign-in. Windows Authentication / Integrated Security settings are local hosting evidence only.
- No Web API / OData surface: notification JSON endpoints are consumed only by `notifications.js`. Preserve routes, HTTP methods, JSON shape. Do not use the `migrating-webapi-odata` skill or its compatibility gate.
- An interim in-process notification queue is acceptable until Task 4; do not move Service Bus into Task 1.
- Container image via .NET SDK container publishing (`dotnet publish /t:PublishContainer`), base `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, app port set in project file. No Dockerfile, no Docker requirement.
- Azure targets (all pre-existing): App Service for Linux (containers), Azure SQL Managed Instance (only DB target; never Azure SQL Database), Blob Storage (only file target; no Azure Files/mounts), Service Bus, Key Vault, Application Insights via `Azure.Monitor.OpenTelemetry.AspNetCore` + `UseAzureMonitor()`.
- Microsoft Entra auth only on Azure; `DefaultAzureCredential` for all SDK clients; no hard-coded credential types, client/tenant/object IDs, endpoints, or secrets. No shared keys, SAS, or connection strings for Storage/Service Bus; no App Insights local auth.
- SQL auth (contosoapp login via user secrets) allowed only in `Development` against the unchanged on-premises source DB; outside Development the app refuses to start if `DefaultConnection` has a user name or password. Never auto-convert SQL auth to managed identity.
- Key Vault mandatory outside Development (`KeyVault:VaultUri`); secret `ConnectionStrings--DefaultConnection` holds the SQL MI Entra connection string.
- Configuration keys: `Storage:BlobServiceUri`, `Storage:ContainerName`, `ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName`, `KeyVault:VaultUri`, `ConnectionStrings:DefaultConnection`, `APPLICATIONINSIGHTS_CONNECTION_STRING` (or `ApplicationInsights:ConnectionString`).
- Network: all backends private; use standard host names (no `privatelink` names, IPs, or SQL MI public endpoint port 3342); no firewall rules.

## Decisions
- No provisioning, IaC, role assignment, private endpoint/DNS config, registry creation, image push, deployment, database/storage/Service Bus/Key Vault/secret creation.
- Commit Strategy stays Manual (owner choice) even though All-at-Once normally recommends Single Commit at End.
- Branch Sync recorded as Manual per the pre-init confirmation form result (brief said off); Manual never syncs automatically.
- No changes to on-premises SQL Server, its database, logins, or the legacy app deployment.
- Required seven-task chain: T1 .NET 10/ASP.NET Core MVC -> T2 SQL MI -> T3 Blob -> T4 Service Bus -> T5 Key Vault -> T6 OpenTelemetry/Azure Monitor -> T7 CVE audit. Where source already satisfies part of a task, plan verification and record implementation as a no-op.
