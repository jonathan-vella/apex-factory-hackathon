# .NET Version Upgrade Plan

## Overview

**Target**: Upgrade `app/ContosoUniversity` in place from .NET Framework 4.8 to `net10.0` and ASP.NET Core MVC, then integrate the existing Azure SQL Managed Instance, Blob Storage, Service Bus, Key Vault, and Application Insights services.
**Scope**: One classic ASP.NET web project with 56 assessed code files, 45 NuGet packages, 89 incompatible API usages, and no project-to-project dependencies.

### Selected Strategy
**All-At-Once** — The single project is rewritten in place, with no side-by-side host or tiered project rollout.
**Rationale**: The single-project .NET Framework rule permits All-at-Once, while the required seven-task chain provides explicit validation checkpoints for the application and service integrations.

All tasks are constrained to application changes in `app/ContosoUniversity`. Azure resources and the on-premises SQL Server, database, logins, and legacy deployment remain unchanged. The plan includes no provisioning, infrastructure as code, role assignments, private endpoint or DNS work, firewall rules, image push, deployment, database/resource/secret creation, or Dockerfile. Existing Azure App Service for Linux container hosting is the target, but only SDK container packaging is in scope.

All Azure SDK integrations use `DefaultAzureCredential`, with no hard-coded credential type, client ID, tenant ID, object ID, endpoint, or secret. Backend services and the container registry remain private-only and are addressed through configured standard host names resolved by private DNS—never `privatelink` names, IP addresses, public firewall access, or the SQL Managed Instance public data endpoint. Only the existing web front end and Application Insights ingestion may be public. Microsoft Entra authentication applies to Azure service access only; no Microsoft Entra user sign-in is added.

## Upgrade Options

| Option | Selected | Why |
|--------|----------|-----|
| Upgrade Strategy | All-at-Once | The assessment contains one independent project, and the user requires a coordinated in-place migration. |
| Project Approach | In-place rewrite | The existing ASP.NET Framework web project must become the .NET 10 application without a side-by-side host. |
| Unsupported Packages | Resolve Inline | Incompatible package functionality must be removed or replaced as part of the task that encounters it, with no deferred stubs. |
| Unsupported API Handling | Fix Inline | All 89 assessed binary/source-incompatible API usages must be resolved in the owning task. |
| System.Web Adapters | Direct Migration to ASP.NET Core APIs | The target must use native ASP.NET Core APIs rather than a System.Web compatibility bridge. |
| Assembly Binding Redirects | Remove Binding Redirects | .NET 10 does not use the 12 assessed .NET Framework binding redirects. |
| Test Coverage | Skip | Existing tests are retained; each task instead requires build, existing-test, and local page validation without generated test-baseline work. |

## Tasks

### 01-upgrade-dotnet-aspnet-core: Upgrade to .NET 10 and ASP.NET Core MVC

Convert `app/ContosoUniversity` in place to an SDK-style `Microsoft.NET.Sdk.Web` project targeting `net10.0`, move from `packages.config` to `PackageReference`, and resolve package and API incompatibilities inline. Directly migrate applicable `Web.config`, `Global.asax`, `RouteConfig`, `FilterConfig`, and `BundleConfig` behavior to ASP.NET Core configuration and middleware, removing obsolete assembly binding redirects and System.Web dependencies. Preserve the default route, global filters, controllers, Razor views, user-visible behavior, EF Core entities/relationships/mappings, and CSS/JavaScript behavior; check static-file names and references for Linux-safe casing. Register the database context and notification service through dependency injection. Apply the HTTP compatibility gate from `#skill:migrating-webapi-odata` before changing host behavior, preserving wire contracts and treating any STOP result as preservation work rather than an automatic OData conversion.

Keep ordinary static assets in the application and configure .NET SDK container publishing in the project file for base image `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, and the application listening port. Validate `dotnet publish /t:PublishContainer` without adding a Dockerfile or requiring Docker. Do not add Microsoft Entra user sign-in; treat IIS Express Windows Authentication and LocalDB Integrated Security only as local hosting/database evidence. Correct stale identity-related documentation or view text only when necessary to preserve accurate user-visible behavior.

**Done when**: The SDK-style `net10.0` ASP.NET Core MVC application restores and builds successfully; existing tests pass; SDK container publishing is configured and validated without Docker; and a local `dotnet run` proves Home, Students, Courses, Instructors, and Departments load with preserved behavior and static assets.

---

### 02-migrate-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance

Depends on `01-upgrade-dotnet-aspnet-core`. Make Azure SQL Managed Instance the only Azure database target while preserving the EF Core model and application behavior. Continue to read `ConnectionStrings:DefaultConnection`. The Azure value must use the managed instance's standard private VNet-local host name, include `Authentication=Active Directory Default`, and contain no user name or password; never target Azure SQL Database, a `privatelink` name, an IP address, or the managed instance public data endpoint on port 3342.

Preserve the sole exception for Development: an on-premises SQL-authenticated connection string for the unchanged SQL Server and existing `contosoapp` login may be supplied through .NET user secrets and must be passed to EF Core unchanged. Never infer or convert that connection to managed identity. Outside Development, refuse startup when `DefaultConnection` contains a user name or password. Do not place connection strings, credentials, or other secrets in source, logs, or planning artifacts, and do not create or migrate databases, alter the on-premises environment, provision networking, or deploy anything. If connectivity is already implemented, verify it and record the implementation portion as a no-op.

**Done when**: Configuration and startup enforcement satisfy both the Azure Entra-only path and unchanged Development SQL-authentication exception; the application builds successfully and existing tests pass; and a local `dotnet run` using an authorized configuration proves Home, Students, Courses, Instructors, and Departments load. A missing Development user secret, Azure CLI identity, or private-network path is recorded as blocked runtime validation and does not waive the validation requirement.

---

### 03-migrate-blob-storage: Migrate mutable file handling to Azure Blob Storage

Depends on `02-migrate-sql-managed-instance`. Use only the existing Azure Blob Storage service for mutable application-managed files such as teaching-material uploads, replacement, retrieval, and deletion. Authenticate with `DefaultAzureCredential` and obtain `Storage:BlobServiceUri` and `Storage:ContainerName` from runtime configuration. Preserve existing file validation, supported types, size limits, naming, replacement cleanup, deletion behavior, controllers, views, and user-visible behavior. Serve private stored images through the application rather than exposing blob URLs.

Keep ordinary CSS, JavaScript, images, and bundled static assets in the application. Do not introduce Azure Files, mounts, shared keys, SAS, storage connection strings, hard-coded endpoints, public blob access, public firewall access, provisioning, role changes, or deployment. Use the standard configured Blob service host name over the existing private endpoint/VNet path. If compliant Blob handling already exists, verify it and record the implementation portion as a no-op.

**Done when**: Upload, retrieval through the application, replacement cleanup, and deletion retain their prior semantics against the configured private Blob service; the application builds successfully and existing tests pass; and a local `dotnet run` proves Home, Students, Courses, Instructors, and Departments load. Unavailable Azure identity or private connectivity is recorded as blocked integration validation, not as an impossible task.

---

### 04-migrate-service-bus: Migrate messaging to Azure Service Bus

Depends on `03-migrate-blob-storage`. Replace MSMQ and all `System.Messaging` usage—the assessment's largest incompatible API area—with the existing Azure Service Bus queue while preserving notification semantics for entity create, edit, and delete operations and preserving notification reads. Authenticate with `DefaultAzureCredential`; read `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName` from runtime configuration; and register the notification service through the established dependency-injection design.

Do not use shared access keys, SAS tokens, Service Bus connection strings, hard-coded endpoints, `privatelink` names, public access, or firewall exceptions. Do not create, configure, provision, or deploy the queue or namespace. Use its standard configured host name through private DNS and the existing private network. If the replacement is already compliant, verify sending and receiving and record the implementation portion as a no-op.

**Done when**: Local integration validation proves both notification sending and receiving for create/edit/delete behavior; the application builds successfully and existing tests pass; and a local `dotnet run` proves Home, Students, Courses, Instructors, and Departments load. Missing Azure identity, queue authorization, or private connectivity is recorded as blocked send/receive validation rather than success or task impossibility.

---

### 05-integrate-key-vault: Integrate Azure Key Vault

Depends on `04-migrate-service-bus`. Add the existing Azure Key Vault as an ASP.NET Core configuration source using `DefaultAzureCredential` and the runtime-configured `KeyVault:VaultUri`. Outside Development, make Key Vault mandatory and refuse startup when the URI is missing. On Azure, resolve `ConnectionStrings--DefaultConnection` from Key Vault as the Entra-authenticated SQL Managed Instance connection string; App Service settings contain only `KeyVault:VaultUri` and non-secret endpoints.

Keep Key Vault optional in Development and retain .NET user secrets solely for the unchanged on-premises SQL login. Do not replace, reinterpret, log, or persist that Development SQL-authenticated `DefaultConnection`, add application user sign-in, hard-code vault or identity details, create secrets or identities, assign roles, provision networking/resources, change on-premises systems, or deploy. Access the standard configured vault host through the existing private endpoint and private DNS. If configuration is already compliant, verify it and record the implementation portion as a no-op.

**Done when**: Startup behavior enforces mandatory Key Vault configuration outside Development and preserves the Development exception without exposing secrets; the application builds successfully and existing tests pass; and a local `dotnet run` proves Home, Students, Courses, Instructors, and Departments load. Missing vault authorization, Azure CLI identity, secret content, or private connectivity is recorded as blocked runtime validation, not as an impossible task.

---

### 06-integrate-azure-monitor: Migrate logging and tracing to OpenTelemetry with Azure Monitor

Depends on `05-integrate-key-vault`. Replace `System.Diagnostics.Trace` and `Debug` calls with injected `ILogger<T>`. Use only `Azure.Monitor.OpenTelemetry.AspNetCore`, with exactly one `UseAzureMonitor()` call and `DefaultAzureCredential`; do not add individual instrumentation packages, custom exporters, instrumentation-key-only authentication, or hard-coded telemetry endpoints.

Register Azure Monitor only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value. When neither is configured, register nothing extra and keep normal built-in ASP.NET Core console logging so the application starts and runs locally. With an authorized configured connection, validate requests, SQL and HTTP dependencies, and logs reaching the existing Application Insights resource; do not provision, reconfigure, or deploy Azure resources. If the implementation is already compliant, verify it and record the implementation portion as a no-op.

**Done when**: Both conditional paths work, Azure Monitor uses Entra-authenticated ingestion, and requests, SQL/HTTP dependencies, and logs from an authorized local run appear in Application Insights; the application builds successfully and existing tests pass; and a local `dotnet run` proves Home, Students, Courses, Instructors, and Departments load. Missing connection configuration, Azure authorization, ingestion access, or observation time is recorded as blocked telemetry validation rather than task impossibility.

---

### 07-audit-remediate-cves: Audit and remediate dependency CVEs

Depends on `06-integrate-azure-monitor`. Run a fresh audit of direct and transitive NuGet dependencies only after all upgrade and service-integration work is complete. For each actual vulnerability, use the minimum compatible patched version, resolve resulting package/API changes inline, and document major-version changes and breaking-change risks without inventing findings. Preserve the prior tasks' authentication, private-network, secret, hosting, no-provisioning, no-deployment, and no-on-premises-change constraints.

Retain this task even when the fresh audit finds no known vulnerabilities, recording remediation as a verified no-op in that case. Do not generate new test-coverage tasks; run all existing tests and preserve the final `net10.0` behavior.

**Done when**: A fresh direct/transitive NuGet audit is recorded with every real finding remediated to the minimum compatible patched version—or a verified no-op when none exist—and any major/breaking risks are documented; the final application builds successfully and all existing tests pass; and a local `dotnet run` proves Home, Students, Courses, Instructors, and Departments load. NuGet feed authentication or unavailable runtime credentials/private connectivity is recorded as blocked validation and does not permit a false clean result.
