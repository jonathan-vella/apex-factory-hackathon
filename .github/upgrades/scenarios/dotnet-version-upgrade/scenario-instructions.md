# .NET Version Upgrade

## Preferences
- **Flow Mode**: Guided
- **Target Framework**: .NET 10 (`net10.0`)
- **Scope**: `app/ContosoUniversity`
- **Current Request Boundary**: Assessment and planning only; do not start or execute tasks

## Source Control
- **Source Branch**: jonathan-vella-cautious-journey
- **Working Branch**: jonathan-vella-cautious-journey
- **Commit Strategy**: After Each Task
- **Branch Sync**: Auto (Merge)

## Decisions
- **Assessment Review Gate**: Assessment approved; generate `plan.md`, then stop for review before starting any task.
- **Planning Review Gate**: Plan generated; do not call `start_task` or begin implementation until the user explicitly approves execution.
- Use this `dotnet-version-upgrade` scenario as the sole owning scenario; do not use `azure-migrate`, start an app modernization migration session, or create `.github/modernize` artifacts.
- Produce exactly seven top-level tasks in this order and dependency chain: .NET 10 and ASP.NET Core MVC; Azure SQL Managed Instance; Azure Blob Storage; Azure Service Bus; Azure Key Vault; OpenTelemetry with Azure Monitor; dependency CVE audit and remediation.
- Preserve every required task even when its implementation is already satisfied; plan verification and record implementation as a no-op where appropriate.
- Every task validates a successful build and local `dotnet run`, loading Home, Students, Courses, Instructors, and Departments. Record blocked runtime validation separately from an impossible task.
- Do not modify application source files, Azure resources, on-premises resources, or deployments during assessment and planning.

### Task 1 Constraints
- Upgrade to an SDK-style `Microsoft.NET.Sdk.Web` project targeting `net10.0`, using `PackageReference`.
- Preserve controllers, Razor views, user-visible behavior, the EF Core model and mappings, default route, global filters, and CSS/JavaScript static-file behavior.
- Migrate applicable `Web.config`, `Global.asax`, `RouteConfig`, `FilterConfig`, and `BundleConfig` behavior to ASP.NET Core equivalents; ensure Linux-safe filename casing.
- Register services with dependency injection, including the database context and notification service.
- Use .NET SDK container publishing with `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, and the application port in the project file. Do not add a Dockerfile or require Docker.
- Do not add Microsoft Entra ID user sign-in. Windows Authentication and LocalDB Integrated Security are local hosting/database evidence, not application identity requirements.

### Task 2 Constraints
- Azure SQL Managed Instance is the only Azure database target; never propose Azure SQL Database or the managed instance public data endpoint.
- Continue using `ConnectionStrings:DefaultConnection`. On Azure it uses the private VNet-local standard host name with `Authentication=Active Directory Default` and no user name or password.
- In Development only, pass an on-premises SQL-authenticated connection string supplied through .NET user secrets unchanged. Outside Development, refuse startup if the connection contains a user name or password.
- Never automatically convert SQL authentication to managed identity or record secrets in source control/planning artifacts. Preserve the EF Core model and behavior.

### Task 3 Constraints
- Azure Blob Storage is the only target for mutable application-managed files. Use `DefaultAzureCredential`, `Storage:BlobServiceUri`, and `Storage:ContainerName`.
- Do not use Azure Files, mounts, shared keys, SAS, or storage connection strings. Keep ordinary static assets in the application and serve private stored images through the application, not blob URLs.
- Preserve file validation, types, size limits, naming, replacement cleanup, deletion, controllers, and views.

### Task 4 Constraints
- Azure Service Bus is the only messaging target. Replace MSMQ/System.Messaging while preserving create/edit/delete notification sending and reading.
- Use `DefaultAzureCredential`, `ServiceBus:FullyQualifiedNamespace`, and `ServiceBus:QueueName`; prohibit shared keys, SAS, and connection strings. Validate sending and receiving.

### Task 5 Constraints
- Azure Key Vault is mandatory outside Development and is an ASP.NET Core configuration source using `DefaultAzureCredential` and `KeyVault:VaultUri`; refuse startup outside Development when the URI is missing.
- On Azure, `ConnectionStrings--DefaultConnection` holds the Entra-authenticated SQL Managed Instance connection string. App settings hold only `KeyVault:VaultUri` and non-secret endpoints.
- In Development, Key Vault is optional and user secrets remain allowed only for the unchanged on-premises SQL login.

### Task 6 Constraints
- Replace `System.Diagnostics.Trace` and `Debug` with `ILogger<T>`.
- Use only `Azure.Monitor.OpenTelemetry.AspNetCore` with one `UseAzureMonitor()` call and `DefaultAzureCredential`.
- Register Azure Monitor only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value; otherwise use normal built-in ASP.NET Core console logging.
- Validate requests, SQL and HTTP dependencies, and logs reaching Application Insights from a local run.

### Task 7 Constraints
- Run a fresh direct and transitive NuGet vulnerability audit last. Upgrade each finding to the minimum compatible patched version and document major-version/breaking-change risks.
- Do not invent findings. Retain the task as a verified no-op if no known vulnerabilities are found.

## Azure and Hosting Boundaries
- All Azure SDK clients use `DefaultAzureCredential`; do not hard-code credential types, client IDs, tenant IDs, object IDs, endpoints, or secrets.
- SQL Managed Instance, Blob Storage, Service Bus, Key Vault, and the container registry are private-only and reached through private endpoints/VNet using standard configured host names and private DNS. Never use `privatelink` names, IP addresses, public data endpoints, or public firewall rules.
- The existing Azure App Service for Linux container front end and Application Insights ingestion are the only permitted public endpoints.
- All Azure resources already exist. Do not plan provisioning, IaC, role assignments, private endpoint/DNS setup, image push, deployment, database creation, resource creation, or on-premises changes.

## Planning Decisions
- **Upgrade Strategy**: All-at-Once
- **Project Approach**: In-place rewrite
- **Unsupported Packages**: Resolve Inline
- **Unsupported API Handling**: Fix Inline
- **System.Web Adapters**: Direct Migration to ASP.NET Core APIs
- **Assembly Binding Redirects**: Remove Binding Redirects
- **Generated Test Coverage Tasks**: Skip; retain existing tests and require build plus local-run page validation in every task

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

### Reliability
- Test Coverage: Skip

## Strategy
**Selected**: All-at-Once
**Rationale**: The assessment contains one independent .NET Framework web project, so the single-project framework-migration rule applies; the user also requires one fixed, linear seven-task chain for the in-place rewrite.

### Execution Constraints
- Treat the in-place migration as one coordinated upgrade of `app/ContosoUniversity`; do not introduce project tiers, side-by-side hosts, or parallel migration phases.
- Execute the seven plan tasks only in their declared linear order, with each task depending on and preserving the validated state from its predecessor.
- Resolve unsupported packages and APIs inline, migrate directly from System.Web to ASP.NET Core APIs, and remove obsolete assembly binding redirects without deferred stubs.
- Retain existing tests without generating test-baseline tasks; every task must build successfully and pass a local `dotnet run` validation of Home, Students, Courses, Instructors, and Departments before the next task starts.
- Preserve no-provisioning, no-deployment, private-network, authentication, secret-handling, hosting, and no-on-premises-change boundaries throughout execution; unavailable credentials or private connectivity block validation rather than making implementation impossible.
