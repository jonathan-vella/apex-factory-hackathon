# Projects and dependencies analysis

This document provides a comprehensive overview of the projects and their dependencies in the context of upgrading to .NETCoreApp,Version=v10.0.

Detailed findings live alongside this file in `assessment/`. This page is the index: read it first, then open only the documents you need.

## Table of Contents

- [Executive Summary](#executive-summary)
  - [Highlevel Metrics](#highlevel-metrics)
  - [Projects Compatibility](#projects-compatibility)
  - [Package Compatibility](#package-compatibility)
  - [API Compatibility](#api-compatibility)
  - [Binding Redirect Configuration](#binding-redirect-configuration)
- [Top API Migration Challenges](#top-api-migration-challenges)
  - [Technologies and Features](#technologies-and-features)
  - [Most Frequent API Issues](#most-frequent-api-issues)
- [Detailed Reports](#detailed-reports)
  - [Projects Relationship Graph](assessment/project-graph.md)
  - [Aggregate NuGet packages details](assessment/nuget/aggregate-packages.md)
  - [Most Frequent API Issues (complete list)](assessment/api-issues/most-frequent-api-issues.md)
  - [Project Details](#project-details)

## Executive Summary

### Highlevel Metrics

| Metric | Count | Status |
| :--- | :---: | :--- |
| Total Projects | 1 | All require upgrade |
| Total NuGet Packages | 45 | 26 need upgrade |
| Total Code Files | 56 |  |
| Total Code Files with Incidents | 16 |  |
| Total Lines of Code | 3392 |  |
| Total Number of Issues | 157 |  |
| Proposed Target Framework | net10.0 |  |
| Estimated LOC to modify | 89+ | at least 2.6% of codebase |

### Projects Compatibility

| Project | Target Framework | Difficulty | Test Coverage | Package Issues | API Issues | Binding Issues | Est. LOC Impact | Description |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| [ContosoUniversity.csproj](assessment/projects/ContosoUniversity.md) | net48 | 🔴 High | 🧪 Recommended | 41 | 89 | 12 | 89+ | Wap, Sdk Style = False |

🧪 **Test Coverage** — projects risky enough to add behavior-locking tests before upgrading, to catch regressions the upgrade may introduce. Requires the **dotnet-test** plugin.

### Package Compatibility

| Status | Count | Percentage |
| :--- | :---: | :---: |
| ✅ Compatible | 19 | 42.2% |
| ⚠️ Incompatible | 2 | 4.4% |
| 🔄 Upgrade Recommended | 24 | 53.3% |
| ***Total NuGet Packages*** | ***45*** | ***100%*** |

### API Compatibility

| Category | Count | Impact |
| :--- | :---: | :--- |
| 🔴 Binary Incompatible | 61 | High - Require code changes |
| 🟡 Source Incompatible | 28 | Medium - Needs re-compilation and potential conflicting API error fixing |
| 🔵 Behavioral change | 0 | Low - Behavioral changes that may require testing at runtime |
| ✅ Compatible | 1288 |  |
| ***Total APIs Analyzed*** | ***1377*** |  |

### Binding Redirect Configuration

| Severity | Count | Description |
| :--- | :---: | :--- |
| 🔴Mandatory | 6 | Must be fixed to avoid runtime failures |
| 🟡Potential | 6 | May cause issues in certain scenarios |
| ***Total Binding Issues*** | ***12*** | ***Across 1 project(s)*** |

## Top API Migration Challenges

### Technologies and Features

| Technology | Issues | Percentage | Migration Path |
| :--- | :---: | :---: | :--- |
| MSMQ & Message Queuing | 57 | 64.0% | Microsoft Message Queue (MSMQ) APIs for Windows-based message queuing that are not supported in .NET Core/.NET. MSMQ is a Windows-specific technology. Migrate to RabbitMQ, Azure Service Bus, or other modern message queues. |
| Legacy Configuration System | 16 | 18.0% | Legacy XML-based configuration system (app.config/web.config) that has been replaced by a more flexible configuration model in .NET Core. The old system was rigid and XML-based. Migrate to Microsoft.Extensions.Configuration with JSON/environment variables; use System.Configuration.ConfigurationManager NuGet package as interim bridge if needed. |
| ASP.NET Framework (System.Web) | 16 | 18.0% | Legacy ASP.NET Framework APIs for web applications (System.Web.*) that don't exist in ASP.NET Core due to architectural differences. ASP.NET Core represents a complete redesign of the web framework. Migrate to ASP.NET Core equivalents or consider System.Web.Adapters package for compatibility. |

### Most Frequent API Issues

| API | Count | Percentage | Category |
| :--- | :---: | :---: | :--- |
| T:System.Messaging.MessageQueue | 18 | 20.2% | Binary Incompatible |
| P:System.Web.HttpPostedFileBase.ContentLength | 4 | 4.5% | Source Incompatible |
| T:System.Configuration.ConfigurationManager | 4 | 4.5% | Source Incompatible |
| T:System.Messaging.MessageQueueAccessRights | 4 | 4.5% | Binary Incompatible |
| T:System.Messaging.MessagePriority | 3 | 3.4% | Binary Incompatible |
| T:System.Messaging.MessageQueueErrorCode | 3 | 3.4% | Binary Incompatible |
| F:System.Messaging.MessageQueueAccessRights.FullControl | 2 | 2.2% | Binary Incompatible |
| M:System.Messaging.MessageQueue.#ctor(System.String) | 2 | 2.2% | Binary Incompatible |
| M:System.Messaging.MessageQueue.Create(System.String) | 2 | 2.2% | Binary Incompatible |
| M:System.Messaging.MessageQueue.Exists(System.String) | 2 | 2.2% | Binary Incompatible |

The table above is the top 10. See [the complete list](assessment/api-issues/most-frequent-api-issues.md) for every affected API.

## Detailed Reports

- [Projects Relationship Graph](assessment/project-graph.md)
- [Aggregate NuGet packages details](assessment/nuget/aggregate-packages.md)
- [Most Frequent API Issues (complete list)](assessment/api-issues/most-frequent-api-issues.md)

### Project Details

- [ContosoUniversity.csproj](assessment/projects/ContosoUniversity.md)

## Dedicated Assessor Findings

These findings supplement the generated compatibility report for the explicitly scoped
`ContosoUniversity.csproj`. No application source, infrastructure, deployment, or Azure resources
were changed or exercised.

### Existing application shape

- **Framework and project style:** classic, non-SDK ASP.NET Web Application Project targeting
  .NET Framework 4.8. It imports `Microsoft.WebApplication.targets`, uses `packages.config`,
  explicit file lists and assembly `HintPath` references, and requires conversion to
  `Microsoft.NET.Sdk.Web`, `PackageReference`, and `net10.0`.
- **Startup and dependency injection:** `Global.asax.cs` registers MVC areas, filters, routes, and
  bundles, then manually constructs `DbContextOptions<SchoolContext>`. The project references the
  Microsoft.Extensions.DependencyInjection 3.1 packages but does not use an ASP.NET Core host or
  application service container. Startup must move to `Program.cs` and framework DI.
- **Routes, filters, and bundles:** conventional `{controller}/{action}/{id}` routing is registered
  through `RouteCollection`; `HandleErrorAttribute` is globally registered; and
  `System.Web.Optimization` bundles are rendered by `_Layout.cshtml`. These System.Web mechanisms
  do not carry forward and need ASP.NET Core endpoint routing, exception handling/filter
  equivalents, and direct static asset references or a supported asset pipeline.
- **Controllers and views:** seven MVC controllers and Razor views use `System.Web.Mvc`,
  `ActionResult`, `HttpStatusCodeResult`, `HttpNotFound`, `Html.ActionLink`, and legacy HTML helpers.
  POST actions generally use anti-forgery validation. Controllers and user-visible behavior for
  Home, Students, Courses, Instructors, Departments, and Notifications need behavior-preserving
  ASP.NET Core MVC conversion.
- **Static assets:** CSS, JavaScript, favicon, and uploads are project-root content rather than
  `wwwroot` assets. Case and inclusion need reconciliation: `_Layout.cshtml` references
  `Content/notifications.css` and `Scripts/notifications.js`, but those files are not included in
  the classic project file. The project file also records asset versions that differ from some
  package declarations. Static files therefore require an explicit, case-consistent inventory
  during migration.

### Data, files, messaging, configuration, and observability

- **EF model:** the application already uses EF Core 3.1 with SQL Server. `SchoolContext` contains
  nine `DbSet` properties, `datetime2` conventions, explicit table mappings, Person TPH
  discrimination, a composite key, course/instructor relationships, and a one-to-one office
  assignment. These mappings and relationships must be preserved while moving to EF Core 10 and
  DI-provided `DbContextOptions`.
- **Database configuration:** configuration currently comes from `Web.config` under the
  `DefaultConnection` name. The assessed configuration has legacy `system.web`,
  `system.webServer`, app settings, and 22 binding redirects. Secret values were not copied into
  this report. The target must retain `ConnectionStrings:DefaultConnection`; Azure must use the
  Azure SQL Managed Instance private VNet-local standard hostname with
  `Authentication=Active Directory Default` and no embedded credentials. Development may use the
  unchanged on-premises SQL-authenticated string only from .NET user secrets; non-Development
  startup must reject user-name/password-bearing connection strings.
- **Mutable files:** `CoursesController` accepts image uploads and directly creates, writes, and
  deletes files below `Uploads/TeachingMaterials` through `Server.MapPath`. This is mutable
  application-managed state and must move behind an Azure Blob Storage service using
  `DefaultAzureCredential`, `Storage:BlobServiceUri`, and `Storage:ContainerName`; browser-facing
  blob URLs are outside the approved design.
- **Messaging:** `NotificationService` directly creates and grants permissions on a local MSMQ
  private queue, then performs synchronous send/receive operations. `System.Messaging` is the
  largest compatibility area (57 findings) and is unsupported on modern .NET. Preserve send and
  receive semantics using Azure Service Bus only, configured by
  `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName` with
  `DefaultAzureCredential`.
- **Key Vault:** no Azure Key Vault integration or Azure Identity client usage was found. Outside
  Development, the existing Key Vault must be a mandatory configuration source through
  `KeyVault:VaultUri` and `DefaultAzureCredential`; the expected secret maps from
  `ConnectionStrings--DefaultConnection`.
- **Trace/Debug:** direct `Trace.TraceError` and `Debug.WriteLine` calls occur in controllers and
  notification handling. Replace them with injected `ILogger<T>`. The approved telemetry boundary
  is `Azure.Monitor.OpenTelemetry.AspNetCore` with one conditional `UseAzureMonitor()` registration
  when an Application Insights connection string exists, authenticated with
  `DefaultAzureCredential`.

### Packages and security evidence

- The generated assessment found 45 NuGet packages: 19 compatible, 2 incompatible, and 24 with
  recommended upgrades. ASP.NET MVC/Razor/WebPages and several BCL packages become framework
  functionality; `Microsoft.AspNet.Web.Optimization` is both incompatible and deprecated.
- One concrete vulnerability was identified: **Microsoft.Data.SqlClient 2.1.4 —
  CVE-2024-0056**. The generated assessment recommends replacing it with a patched compatible
  release (currently reported as 7.1.0). Direct and transitive packages still require the requested
  final CVE audit; select minimum compatible patched versions and retain a verified no-op result if
  that later audit finds nothing else.
- Twelve binding issues were identified, including six mandatory conflicts and six potential
  downgrades. SDK-style migration should remove legacy binding redirects rather than reproduce
  them.

### Validation and hosting readiness

- **Tests:** no matching .NET test project or test code for this application was found under the
  repository test area. The generated assessment recommends adding behavior-locking coverage.
  Manual/runtime validation must cover Home, Students, Courses, Instructors, and Departments.
- **Local prerequisites:** the current application depends on Windows/.NET Framework 4.8 tooling,
  Visual Studio Web Application targets, IIS Express, packages.config restore, SQL Server/LocalDB,
  and MSMQ. The target application will instead require the .NET 10 SDK plus access to its SQL,
  blob, messaging, Key Vault, and telemetry configuration as applicable.
- **Blocked runtime validation:** no .NET user-secrets identity or local SQL-authentication secret
  is present in the scoped project. Target-state `dotnet run` database/page validation is therefore
  **blocked until that Development secret is supplied**, not impossible.
- **Container publishing:** the classic WAP cannot yet use .NET SDK container publishing. No
  Azure SDK/container-publish configuration was found. Readiness requires conversion to
  `Microsoft.NET.Sdk.Web`, a successful `dotnet publish`, correct static content inclusion, and
  runtime configuration; the approved destination is the existing private Azure App Service for
  Linux container host, using SDK container publishing without a Dockerfile.

### Boundaries and requirements carried into planning

- Azure SDK clients must use `DefaultAzureCredential`; do not hard-code credential types, IDs,
  endpoints, or secrets.
- Azure SQL Managed Instance is the only Azure database target. Blob Storage is only for mutable
  application-managed files. Azure Service Bus is the only messaging target.
- Backend services and the container registry remain private-only and use standard hostnames
  resolved by private DNS. Do not use `privatelink` hostnames, IP addresses, public data endpoints,
  or public firewall exceptions.
- Assessment did not provision, configure, assign roles, push images, deploy, alter Azure
  resources, or change on-premises SQL Server/database/logins/deployment. Network reachability,
  managed-identity/RBAC assignments, existing resource configuration, and live private-endpoint
  behavior were not validated because they are explicitly outside this stage.

