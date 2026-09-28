# .NET 10 Upgrade Plan

## Scope

Upgrade `app/ContosoUniversity/ContosoUniversity.csproj`, the repository's single classic ASP.NET Web Application Project, from .NET Framework 4.8 to `net10.0` and ASP.NET Core MVC. The assessment covers one non-SDK project with 83 files, 3,392 lines of code, 16 files with incidents, 45 NuGet packages, 61 binary-incompatible APIs, 28 source-incompatible APIs, and 12 binding issues.

Planning and later implementation are restricted to application code and configuration. No task may provision or configure Azure resources, assign identities or roles, change network infrastructure, push images, deploy workloads, change the on-premises SQL Server/database/logins, or alter the legacy application deployment.

### Selected Strategy
**All-at-Once** — All projects upgraded simultaneously in a single operation.
**Rationale**: One isolated project moves from .NET Framework 4.8 to .NET 10 with no project-to-project dependency graph. The approved in-place rewrite is organized into the seven required application-modernization tasks rather than dependency tiers.

## Project Group

- **Web application**: `app/ContosoUniversity/ContosoUniversity.csproj` — classic non-SDK ASP.NET Web Application Project, `packages.config`, `System.Web.Mvc`, EF Core 3.1, SQL Server, local mutable files, and MSMQ.
- **Tests**: no matching .NET test project was found. Existing tests must still be discovered and run at each boundary; an absent applicable test project is a recorded verification no-op, not permission to omit build and runtime checks.

## Upgrade Options

| Option | Selected | Why |
|--------|----------|-----|
| Upgrade Strategy | All-at-Once | The assessment found one project and no dependency graph to manage. |
| Project Approach | In-place rewrite | The approved plan preserves exactly seven top-level tasks and does not inject side-by-side scaffold or migration tasks. |
| Unsupported Packages | Resolve Inline | The assessment identified 2 incompatible packages, suitable for resolution in their owning task. |
| Unsupported API Handling | Fix Inline | The approved task structure requires all incompatible APIs to be resolved without deferred compatibility stubs. |
| System.Web Adapters | Direct Migration to ASP.NET Core APIs | The in-place application moves directly from System.Web to native ASP.NET Core APIs. |
| Assembly Binding Redirects | Document and Review Before Removing | The project has 22 redirects and 12 assessed conflicts or downgrades whose purpose must be recorded before removal. |
| Test Coverage | Skip | Generated coverage is not added; build, available-test, and required local page validation remain mandatory. |

## Dependencies

The dependency chain is exact and linear:

`01-upgrade-dotnet-aspnet-core` → `02-azure-sql-managed-instance` → `03-azure-blob-storage` → `04-azure-service-bus` → `05-azure-key-vault` → `06-opentelemetry-azure-monitor` → `07-dependency-cve-audit`

No task may start before its immediate predecessor completes. Tasks that are already satisfied remain in place and are recorded as implementation no-ops followed by the full required verification.

## Cross-Cutting Constraints and Validation

- All Azure SDK clients use `DefaultAzureCredential`. Do not hard-code credential types, client IDs, tenant IDs, object IDs, secrets, endpoints, or credentials.
- Azure SQL Managed Instance is the only Azure database target; Blob Storage is only for mutable application-managed files; Azure Service Bus is the only messaging target. Do not add Microsoft Entra ID application user sign-in.
- Read `Storage:BlobServiceUri`, `Storage:ContainerName`, `ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName`, `KeyVault:VaultUri`, `ConnectionStrings:DefaultConnection`, and `APPLICATIONINSIGHTS_CONNECTION_STRING` from configuration at execution time. Do not hard-code endpoints or secrets.
- Azure backends and the container registry remain private-only. Use their standard host names through private DNS; never substitute `privatelink` host names, IP addresses, public data endpoints, or public firewall exceptions.
- The hosting target is the existing private Azure App Service for Linux container host using .NET SDK container publishing without a Dockerfile. Readiness may be validated locally, but no task may provision, configure, push, or deploy.
- At every task boundary, successfully restore and build the upgraded project with no errors; record new warnings but don't block on them. Run every applicable local test, start it with `dotnet run`, and verify that Home, Students, Courses, Instructors, and Departments load successfully.
- Local page validation uses the unchanged on-premises SQL-authenticated `ConnectionStrings:DefaultConnection` only in Development and only from .NET user secrets. If that secret is absent, runtime/page validation is **blocked until supplied, not impossible**: retain the validation requirement, report the blocker, and do not change the on-premises server, database, logins, or deployment to work around it.
- Missing private-network reachability, credentials, RBAC, or existing Azure resource configuration is likewise an external validation blocker, not authority to change infrastructure or declare the application migration impossible. Record the exact blocked check and preserve completed local evidence.

### 01-upgrade-dotnet-aspnet-core: Upgrade to .NET 10 and ASP.NET Core MVC

Convert `ContosoUniversity.csproj` from its classic Web Application Project structure to `Microsoft.NET.Sdk.Web`, `PackageReference`, and `net10.0`, and move startup from `Global.asax` to the ASP.NET Core host and built-in dependency injection. Migrate applicable `Web.config` settings to `appsettings.json`, environment-specific configuration, or ASP.NET Core configuration. Preserve the seven controllers, Razor views, default route, global filters, anti-forgery behavior, error handling, CSS and JavaScript static-file behavior, and all user-visible behavior while replacing `System.Web.Mvc`, `RouteCollection`, legacy filters, HTML helpers, and bundle rendering directly with ASP.NET Core MVC equivalents. Register the database context and notification service through dependency injection.

The assessment found 45 packages, including 2 incompatible packages and 24 recommended upgrades, plus 61 binary- and 28 source-incompatible APIs. Resolve package and API compatibility inline, remove framework-provided legacy references, and inventory Antlr replacement, deprecated `Microsoft.AspNet.Web.Optimization`, `Microsoft.Identity.Client`, and direct System.Web/configuration usages without adding adapter shims. Document the 22 binding redirects—including six mandatory conflicts and six potential downgrades—before removing them rather than reproducing them in the SDK project. Reconcile case-consistent static content under ASP.NET Core conventions, including the assessed `Content/notifications.css` and `Scripts/notifications.js` discrepancies. Add .NET SDK container publishing properties to the project for base image `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, and the application's listening port. Validate with `dotnet publish /t:PublishContainer`; do not add a Dockerfile or require Docker. Keep the later SQL, file, messaging, Key Vault, and telemetry migrations owned by Tasks 2–6 while ensuring the upgraded application has compile-safe boundaries for them.

**Done when**: The application is an SDK-style `Microsoft.NET.Sdk.Web` project targeting `net10.0`, restores and builds successfully with no errors; record new warnings but don't block on them. All applicable tests pass (or the absence of a matching test project is recorded as a no-op), direct ASP.NET Core MVC behavior and static content are preserved, `dotnet publish /t:PublishContainer` validates the required base image/repository/port properties without a Dockerfile, Docker, registry push, or deployment, and `dotnet run` successfully serves Home, Students, Courses, Instructors, and Departments; if the Development SQL user secret is missing, only the run/page portion remains explicitly blocked until supplied and is not marked impossible or waived.

### 02-azure-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance

Operate on the upgraded .NET 10 application and move its Azure database configuration boundary to Azure SQL Managed Instance while retaining `ConnectionStrings:DefaultConnection`. Upgrade the EF Core 3.1 data stack to a .NET 10-compatible EF Core release and preserve all nine `DbSet` properties, `datetime2` conventions, explicit table mappings, Person TPH discriminator, composite key, course/instructor relationships, one-to-one office assignment, and existing application behavior. Use ASP.NET Core configuration and DI-provided `DbContextOptions`; do not introduce Microsoft Entra application user sign-in.

The Azure connection string must use the private VNet-local standard Managed Instance hostname, `Authentication=Active Directory Default`, and no embedded credentials, public data endpoint on port 3342, `privatelink` hostname, IP address, or firewall exception. Development alone may pass the unchanged on-premises SQL-authenticated string from .NET user secrets to EF Core without conversion or reinterpretation. Non-Development startup must reject connection strings containing a user name or password; never convert a SQL-authenticated string to managed identity automatically. This task changes application code/configuration only: it must not provision or configure Managed Instance, modify schemas or data, assign RBAC, validate live private endpoints, or change the on-premises SQL Server, database, logins, or deployment.

**Done when**: EF Core and SQL client dependencies are compatible with `net10.0`, the assessed model and mappings remain intact, Azure and Development connection-string policies are enforced, and restore/build succeeds with no errors; record new warnings but don't block on them. Every applicable test passes or is recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments against the Development secret; an absent local SQL secret keeps runtime/page validation blocked until supplied rather than impossible, while unavailable Azure network/RBAC/resource access is documented without infrastructure changes.

### 03-azure-blob-storage: Migrate mutable file handling to Azure Blob Storage

Replace the `CoursesController` dependency on `Server.MapPath` and direct creation, writing, and deletion beneath `Uploads/TeachingMaterials` with an application storage abstraction backed only by Azure Blob Storage for mutable application-managed files. Preserve teaching-material upload, replacement, retrieval, and deletion behavior using ASP.NET Core upload types, including existing validation, supported file types, size limits, naming behavior, replacement cleanup, deletion cleanup, controllers, views, and the assessed `HttpPostedFileBase` compatibility surface. Keep ordinary CSS, JavaScript, images, and bundled immutable assets in the application's static-content pipeline.

The Blob client must use `DefaultAzureCredential`, `Storage:BlobServiceUri`, and `Storage:ContainerName`; do not use shared keys, SAS tokens, or storage connection strings. Browser-facing stored images must flow through application endpoints rather than exposing blob URLs. The service endpoint must be the standard private-DNS-resolved hostname; do not use a `privatelink` hostname, IP address, public endpoint, hard-coded Azure identity data, or public firewall exception. Do not create/configure storage, containers, networking, identities, or roles.

**Done when**: Mutable file operations use the Blob-backed abstraction with preserved application behavior and no browser-visible blob URL, and restore/build succeeds with no errors; record new warnings but don't block on them. All applicable tests pass or their absence is recorded, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments; missing Development SQL secrets or existing Blob reachability/RBAC/configuration are retained as explicit external blockers until supplied and never trigger provisioning, deployment, or on-premises changes.

### 04-azure-service-bus: Migrate messaging to Azure Service Bus

Replace `NotificationService` and all unsupported `System.Messaging`/MSMQ dependencies with Azure Service Bus as the only messaging target, preserving notifications when an entity is created, edited, or deleted and preserving the ability to read notifications back. Preserve message content, labels/metadata where behaviorally relevant, priority expectations where supportable, timeout handling, and application error behavior. The assessment attributes 57 compatibility findings to MSMQ, including queue creation, permission grants, formatters, synchronous send/receive, and queue-specific exceptions; resolve these incompatibilities within this task rather than retaining MSMQ, introducing another broker, or deferring stubs.

Configure `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName`, and authenticate with `DefaultAzureCredential`. SAS authentication is disabled: never use shared access keys, SAS tokens, or Service Bus connection strings. Use only the standard namespace hostname through private DNS; never use a `privatelink` hostname, IP address, public endpoint, embedded credential, or firewall exception. Queue creation, permissions, network changes, identity/RBAC assignments, and Azure configuration are outside scope.

**Done when**: The application has no runtime dependency on MSMQ or `System.Messaging`, Service Bus preserves the required contract through application-owned abstractions, validation proves both sending and receiving rather than sending alone, and restore/build succeeds with no errors; record new warnings but don't block on them. All applicable tests pass or are recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments; unavailable existing Service Bus access is reported as a blocked external integration check without weakening the required local page checks or changing Azure/on-premises systems.

### 05-azure-key-vault: Integrate Azure Key Vault

Add the existing Azure Key Vault as a mandatory configuration source outside Development, using `KeyVault:VaultUri` and `DefaultAzureCredential`. Ensure the existing secret name `ConnectionStrings--DefaultConnection` maps to `ConnectionStrings:DefaultConnection`, participates in startup early enough for database registration, and does not expose secret values in source, logs, generated artifacts, or client responses. Development continues to use .NET user secrets for the unchanged local SQL-authenticated connection string and does not require Key Vault.

Use the vault's standard private-DNS-resolved hostname and retain private-only access. On Azure, App Service settings hold only `KeyVault:VaultUri` and non-secret endpoints; Key Vault holds `ConnectionStrings--DefaultConnection`. Do not hard-code the vault endpoint or Azure identity identifiers, use a `privatelink` hostname or IP address, open public access, provision/configure the vault, create secrets, assign access/RBAC, or deploy any application/resource change. Outside Development, missing or inaccessible mandatory Key Vault configuration must fail clearly rather than silently falling back to embedded credentials.

**Done when**: Non-Development configuration requires the existing Key Vault and resolves the SQL secret mapping without stored credentials, Development remains user-secrets based, and restore/build succeeds with no errors; record new warnings but don't block on them. Every applicable test passes or is recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments in Development; missing local SQL secrets block page validation until supplied, while missing private Key Vault access blocks only the corresponding non-Development integration check and does not authorize Azure changes.

### 06-opentelemetry-azure-monitor: Migrate logging and tracing to OpenTelemetry with Azure Monitor

Replace direct `Trace.TraceError` and `Debug.WriteLine` usage in controllers and notification handling with injected `ILogger<T>`, preserving meaningful severity, context, and exception information without logging secrets. Establish the approved telemetry boundary using only `Azure.Monitor.OpenTelemetry.AspNetCore`, with exactly one conditional `UseAzureMonitor()` registration when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value, and set its credential to `DefaultAzureCredential` for Microsoft Entra-authenticated ingestion.

When neither connection-string setting has a value, register nothing extra; built-in ASP.NET Core console logging applies and the application must start normally. Do not add individual instrumentation packages, custom exporters, alternate telemetry frameworks, or duplicate Azure Monitor registration. Application Insights ingestion is the documented backend-network exception; do not hard-code endpoints or identity values, configure Application Insights, assign roles, or deploy.

**Done when**: Assessed Trace/Debug calls are represented by structured `ILogger<T>` usage, Azure Monitor registration is single and conditional with `DefaultAzureCredential`, and restore/build succeeds with no errors; record new warnings but don't block on them. Every applicable test passes or is recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments without requiring telemetry. With a connection string configured, requests, SQL and HTTP dependencies, and logs from the local run appear in Application Insights within a few minutes; unavailable Azure Monitor access is documented as a blocked external check rather than worked around through infrastructure changes.

### 07-dependency-cve-audit: Audit and remediate dependency CVEs

Perform a fresh final audit of direct and transitive NuGet dependencies only after Tasks 1–6 have established the target dependency graph. The existing assessment supplies one concrete vulnerability finding—`Microsoft.Data.SqlClient` 2.1.4 affected by CVE-2024-0056—and no additional CVE may be asserted without fresh audit evidence. Select the minimum `net10.0`-compatible patched version for each confirmed finding, account for transitive dependency effects, and preserve application behavior.

Retain this task even when the fresh audit finds no remaining vulnerability: record remediation as an implementation no-op plus verified clean evidence. Recheck deprecated, incompatible, framework-provided, and upgraded dependencies without treating deprecation alone as a CVE. Finish with local SDK container-publish readiness for the existing private Azure App Service for Linux host, but do not build/push to a registry, provision/configure resources, assign roles, or deploy.

**Done when**: A fresh direct-and-transitive audit records its evidence, CVE-2024-0056 and every other newly evidenced finding are remediated with minimum compatible patched versions or the remediation is recorded as a verified no-op when already clean, and restore/build and local publish succeed with no errors; record new warnings but don't block on them. All applicable tests pass or are recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments; missing Development SQL configuration remains a blocked validation prerequisite until supplied and does not permit waiving the final runtime checks or altering Azure/on-premises systems.
