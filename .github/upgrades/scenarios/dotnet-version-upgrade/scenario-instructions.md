# .NET Version Upgrade

## Preferences
- **Flow Mode**: Guided
- **Target Framework**: .NET 10 (LTS)

## Source Control
- **Source Branch**: jonathan-vella-stunning-garbanzo
- **Working Branch**: jonathan-vella-stunning-garbanzo
- **Commit Strategy**: Manual
- **Branch Sync**: Disabled

## User Preferences

### Technical Preferences
- Scope: `app/ContosoUniversity` only (.NET Framework 4.8, ASP.NET MVC 5.2.9) → `net10.0`, SDK-style `Microsoft.NET.Sdk.Web`, `PackageReference`, ASP.NET Core MVC.
- Full requirements source (binding): `C:\Users\labadmin\.copilot\attachments\pasted-text-07a95c3b-7499-47ad-ae58-101446abd124.txt` (owner decisions at the end take precedence where more specific).
- Azure target state: Microsoft Entra authentication only, `DefaultAzureCredential` for every Azure SDK client; no hard-coded credential types, client/tenant/object IDs, endpoints or secrets.
- Database: Azure SQL Managed Instance only (never Azure SQL Database). Keep reading `ConnectionStrings:DefaultConnection`. On Azure: `Authentication=Active Directory Default`, no user/password, private VNet-local host name, never public data endpoint 3342. Outside Development, refuse to start if `DefaultConnection` contains a user name or password. Never auto-convert SQL auth to managed identity.
- Development exception: SQL-authenticated `DefaultConnection` (existing `contosoapp` login) supplied via .NET user secrets is passed to EF Core unchanged, against the unchanged on-premises SQL Server.
- Mutable files: Azure Blob Storage only (`Storage:BlobServiceUri`, `Storage:ContainerName`). No Azure Files, storage mounts, shared keys, SAS or storage connection strings. Serve stored images through the app; never link browsers to blob URLs. Keep ordinary static CSS/JS/images in the app.
- Messaging: Azure Service Bus only (`ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName`); no SAS, keys or connection strings. Validation must prove send AND receive.
- Key Vault: mandatory outside Development via `KeyVault:VaultUri` (refuse to start if missing outside Development); holds secret `ConnectionStrings--DefaultConnection`; App Service settings hold only `KeyVault:VaultUri` and non-secret endpoints. Optional in Development.
- Observability: replace `System.Diagnostics.Trace`/`Debug` with `ILogger<T>`; `Azure.Monitor.OpenTelemetry.AspNetCore` with a single `UseAzureMonitor()` registered only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` is set, credential = `DefaultAzureCredential`; no individual instrumentation packages or custom exporters.
- Network: all backends private; use standard host names from configuration; never `privatelink` host names, IP addresses, or the SQL MI public endpoint; no IP firewall rules. Only the web front end and App Insights ingestion are public.
- Containers: .NET SDK container publishing (`dotnet publish /t:PublishContainer`), base image `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, app port in the project file. No Dockerfile; Docker not required.
- Hosting: existing Azure App Service for Linux (containers). All Azure resources already exist.

### Execution Style
- Guided flow. This run: assessment + planning only; do not call `start_task` or execute tasks; do not modify application source.
- Validation limited to `app/ContosoUniversity` (build, run, test that project only). Do not run repo PowerShell or npm checks.
- Local validation uses the `ConnectionStrings:DefaultConnection` user secret; never fall back to LocalDB. If the secret is unavailable, runtime validation is BLOCKED (not dropped).
- Every task's validation: successful build AND local `dotnet run` where home, Students, Courses, Instructors and Departments pages load.
- Never write secrets, user names, passwords or connection-string values into source control or planning artifacts.

## Decisions
- Exactly seven top-level tasks, chain 1→2→3→4→5→6→7 (Task 1 no deps): (1) Upgrade to .NET 10 and ASP.NET Core MVC; (2) Migrate the database workload to Azure SQL Managed Instance; (3) Migrate mutable file handling to Azure Blob Storage; (4) Migrate messaging to Azure Service Bus; (5) Integrate Azure Key Vault; (6) Migrate logging and tracing to OpenTelemetry with Azure Monitor; (7) Audit and remediate dependency CVEs.
- Where current source already satisfies part of a task, plan verification and record the implementation step as a no-op; keep the task.
- No Microsoft Entra ID user sign-in. IIS Express Windows Auth and LocalDB `Integrated Security` are hosting/database evidence only; stale Windows Auth text may be corrected within Task 1.
- No Web API/OData work; do not use the `migrating-webapi-odata` skill or its compatibility gate. Preserve notification JSON endpoint routes, HTTP methods and JSON shape (consumed only by `notifications.js`).
- Interim in-process notification queue is acceptable until Task 4; do not move Service Bus into Task 1.
- No tasks for provisioning, IaC, role assignment, private endpoint/DNS config, registry creation, image push, deployment, database/storage/Service Bus/Key Vault/secret creation. No on-premises changes (SQL Server, database, logins, legacy deployment unchanged).
- Task 7: fresh audit of direct + transitive NuGet after all other work; minimum patched versions; verified no-op if none; never invent CVEs.
- Extra findings are recommendations only — never added as tasks.
- Artifact location: the workflow tool placed artifacts under `.github/upgrades/scenarios/dotnet-version-upgrade/` (tool-determined path); do not use `azure-migrate`, `start_app_mod_migration_session`, or `.github/modernize`.
- A1 (Guided review, Task 01): ship Bootstrap 5.3.3 CSS+JS and jQuery 3.7.1 (plus jquery.validation 1.21.0, unobtrusive 4.0.0, modernizr 2.6.2) as `wwwroot` static files; fix `Site.css`/`site.css` casing.
- A2 (Guided review, Task 01): preserve notification routes/methods/PascalCase property names/shape; `CreatedAt` wire format = whatever keeps `notifications.js` working. Verify the consumer; preserve the legacy format via a converter only if the consumer depends on it. Record the choice.
- Container port: 8080 (aspnet:10.0 default).

## Upgrade Options

### Strategy
- Upgrade Strategy: All-at-Once

### Project Structure
- Project Approach: Web Projects: In-place rewrite

### Compatibility
- Unsupported Packages: Resolve Inline (all incompatible packages have known replacements)
- Unsupported API Handling: Fix Inline
- Windows Native APIs: No Compatibility Pack
- System.Web Adapters: Direct Migration to ASP.NET Core APIs

### Modernization
- Assembly Binding Redirects: Remove Binding Redirects
- Nullable Reference Types: Leave Disabled

## Strategy
**Selected**: All-at-Once (with owner-mandated seven-task chain)
**Rationale**: Single .NET Framework 4.8 project (single-project rule → All-at-Once); owner requirements fix exactly seven chained top-level tasks: 01 .NET 10/ASP.NET Core MVC, then 02 SQL MI, 03 Blob, 04 Service Bus, 05 Key Vault, 06 OpenTelemetry, 07 CVE audit.

### Execution Constraints
- Strict chain 01 → 02 → 03 → 04 → 05 → 06 → 07; each later task operates on the upgraded net10.0 app. Do not add, split out or reorder top-level tasks. Task 01 may be broken into subtasks (SDK-style conversion vs TFM/API port are distinct concerns).
- Task 01 is a single in-place pass: update the project file, update packages, restore, then build and fix all compilation errors in one bounded pass. Then validate.
- Every task: `dotnet build` of `app/ContosoUniversity` plus a `dotnet run` check of the home, Students, Courses, Instructors and Departments pages. If the `DefaultConnection` user secret is missing, mark runtime validation BLOCKED (never LocalDB). Azure-dependent checks are BLOCKED pending Azure sign-in and private-network access. BLOCKED ≠ impossible.
- Do not use the `migrating-webapi-odata` skill or its compatibility gate (owner decision overrides the wire-contract pin). Preserve the notification JSON contract manually.
- Commit Strategy stays Manual (owner setting), overriding the All-at-Once "single commit" recommendation.
