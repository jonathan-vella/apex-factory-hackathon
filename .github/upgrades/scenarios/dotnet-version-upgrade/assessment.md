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

## Scoped Workload Assessment

This addendum records repository evidence and execution boundaries needed for the requested six-task .NET and Azure workload plan. It does not provision or validate any Azure resource.

### Application upgrade

- The scope contains one ASP.NET Framework MVC 5 project targeting `net48`. It is a classic, non-SDK-style web project with `packages.config`; the required target is an in-place ASP.NET Core MVC application targeting `net10.0` with `Microsoft.NET.Sdk.Web` and `PackageReference`.
- The project contains existing controllers and Razor views. The assessment reports 89 incompatible APIs, 41 package issues, 12 binding issues, and legacy routing, bundling, `Global.asax`, configuration, and `System.Web` usage.
- The project already uses EF Core 3.1 packages. Upgrade work must preserve the entity model, relationships, mappings, and user-visible behavior while moving to compatible .NET 10 packages and hosting patterns.
- IIS Express Windows Authentication metadata and documentation text were found, but no application user sign-in flow was established. These are local-hosting or stale-documentation signals, not a requirement for Microsoft Entra ID user sign-in.
- No Linux container definition was found in scope. Task 1 must plan reproducible container packaging and local container validation for the existing Azure App Service for Linux container host, without image push or deployment.
- No test project was found in scope. Build validation is required; test execution remains required for any tests available when Tasks 1 and 6 execute.

### Database workload

- The application reads `DefaultConnection` from legacy configuration and passes it to EF Core SQL Server setup. The repository value is local-development evidence only and is not an application identity requirement.
- Azure SQL Managed Instance is the sole planned Azure database target. Runtime behavior must continue reading `ConnectionStrings:DefaultConnection`, pass SQL-authenticated connection strings unchanged, and use managed identity only when the configured value explicitly contains `Authentication=Active Directory Default`.
- The student-provided `contosoapp` SQL-authentication secret was not available during this assessment. SQL-authenticated runtime connectivity validation is blocked until that secret is supplied through user secrets; the migration task itself remains feasible.

### Mutable files

- `CoursesController` manages teaching-material images under `Uploads/TeachingMaterials`: upload and replacement, retrieval through stored paths, and deletion during course deletion.
- Existing behavior includes a 5 MB application limit, the `.jpg`, `.jpeg`, `.png`, `.gif`, and `.bmp` extensions, generated `course_{CourseID}_{Guid}{extension}` names, replacement cleanup, and non-blocking cleanup failure during course deletion.
- Ordinary CSS, JavaScript, images, and bundled static assets are separate from this mutable content and remain application assets. Azure Blob Storage is the sole mutable-file target, using `DefaultAzureCredential` and runtime configuration from `Storage:BlobServiceUri` and `Storage:ContainerName`.

### Messaging

- `NotificationService` uses `System.Messaging` and MSMQ to send and receive JSON notifications for create, update, and delete operations. It also attempts local queue creation and permission changes, behavior that cannot be carried forward to the existing Azure resource.
- Azure Service Bus is the sole messaging target. The migration must preserve notification content and semantics, use `DefaultAzureCredential`, and read `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName` at runtime. Resource creation and configuration are out of scope.

### Key Vault and configuration

- No existing Azure Key Vault configuration source was identified in the scoped application. Task 5 must integrate the existing vault through `KeyVault:VaultUri` and `DefaultAzureCredential` while retaining local user-secrets behavior.
- The plan must not reinterpret SQL-authenticated `DefaultConnection`, add application user sign-in, create identities, assign Azure roles, or provision or deploy resources.
- All Azure endpoints and resource names must come from runtime configuration. Storage keys, SAS tokens, Storage connection strings, Service Bus keys, SAS tokens, Service Bus connection strings, hard-coded endpoints, and hard-coded secrets are prohibited.

### Dependency security

- The generated package assessment flags the current `Microsoft.Data.SqlClient` package as vulnerable but does not provide a CVE identifier. No CVE identifier is asserted by this assessment.
- A fresh direct-and-transitive NuGet vulnerability audit is required only after Tasks 1-5. Task 6 must retain a verified no-op outcome if that fresh audit finds no known vulnerabilities.

### Assessment limitations

- No Azure control-plane calls were made, so resource existence, role assignments, network access, managed identity permissions, and service configuration were not validated.
- The local SQL-authentication secret was unavailable, so SQL-authenticated runtime connectivity is blocked pending student input.
- No application build, test run, container build, database connection, Blob operation, Service Bus operation, or Key Vault operation was performed because this workflow is limited to assessment and planning.

