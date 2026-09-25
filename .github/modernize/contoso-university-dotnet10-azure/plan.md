# Modernization Plan: Contoso University on .NET 10 and Azure

**Project**: `app/ContosoUniversity`

**Assessment source**:
`.github/modernize/assessment/reports/report-20260925090428/report.json`

---

## Technical Framework

- **Language**: C# on .NET Framework 4.8; target .NET 10 (`net10.0`)
- **Framework**: ASP.NET MVC 5; target ASP.NET Core MVC on .NET 10
- **Build Tool**: legacy MSBuild project; target SDK-style `dotnet` project
- **Database**: SQL Server LocalDB with EF Core 3.1; target Azure SQL
  Managed Instance while retaining supported local SQL authentication
- **Key Dependencies**: ASP.NET MVC 5, EF Core 3.1, Microsoft.Data.SqlClient,
  MSMQ (`System.Messaging`), Newtonsoft.Json, and `packages.config`
- **Hosting target**: existing Azure App Service for Linux using containers

---

## Overview

This plan modernizes Contoso University without provisioning or deploying Azure
resources. It first moves the application to .NET 10 and ASP.NET Core MVC while
preserving its controllers, Razor views, behavior, and EF Core model. It then
migrates the verified database, uploaded-file, message-queue, and configuration
concerns to the single Azure targets selected by the user.

The resulting application will:

- Run as an SDK-style ASP.NET Core MVC application on .NET 10.
- Use Azure SQL Managed Instance, Azure Blob Storage, Azure Service Bus, and
  Azure Key Vault resources that already exist.
- Use `DefaultAzureCredential` for Azure SDK clients, with no Storage shared
  keys, Service Bus SAS tokens, or Azure service connection strings.
- Preserve local SQL authentication when `ConnectionStrings:DefaultConnection`
  contains the on-premises server and `contosoapp` login supplied by user
  secrets; use managed identity only when the connection string contains
  `Authentication=Active Directory Default`.
- Remain suitable for Azure App Service for Linux container hosting without
  adding infrastructure provisioning or deployment execution.

Work is strictly sequential in this order: .NET 10 upgrade, SQL Managed
Instance, Blob/file handling, Service Bus, Key Vault, and CVE remediation.

---

## Validated Assessment Scope

The latest report contains 25 incidents across six findings. Current source was
checked before planning:

- **Confirmed**: the project is a classic .NET Framework 4.8 web project using
  `packages.config`, ASP.NET MVC 5, `Web.config`, and EF Core 3.1.
- **Confirmed**: `DefaultConnection` is consumed by EF Core and currently points
  to SQL Server LocalDB using integrated security.
- **Confirmed**: teaching-material images are created, read, replaced, and
  deleted through local filesystem APIs under `Uploads/TeachingMaterials`.
- **Confirmed**: `NotificationService` directly uses MSMQ through
  `System.Messaging`.
- **Confirmed**: settings and a connection string are held in `Web.config`,
  supporting externalized configuration and Key Vault integration.
- **Narrowed false positive**: the generic static-content finding does not mean
  all CSS, JavaScript, or bundled application assets should move to Blob
  Storage. Only mutable teaching-material uploads are in migration scope.
- **Ignored false positive**: the Windows-authentication finding does not
  represent application user sign-in. The only evidence is IIS Express
  configuration and LocalDB integrated security; no Microsoft Entra ID user
  sign-in task is included.

---

## Migration Impact Summary

| App | Original | Azure target | Authentication |
|---|---|---|---|
| Contoso | .NET Framework MVC | .NET 10 Core MVC | N/A |
| Contoso | SQL LocalDB/on-prem | SQL Managed Instance | SQL/AD Default |
| Contoso | Local uploads | Blob Storage | DefaultAzureCredential |
| Contoso | MSMQ | Service Bus | DefaultAzureCredential |
| Contoso | Web.config secrets | Key Vault | DefaultAzureCredential |

---

## Plan Scope and Sequencing

The executable task definitions are in `.metadata/tasks.json`. The six tasks
form one dependency chain, so every Azure migration and the final security pass
runs on the upgraded .NET 10 application.

1. Upgrade to .NET 10 and ASP.NET Core MVC.
2. Migrate database connectivity to Azure SQL Managed Instance.
3. Migrate mutable teaching-material file handling to Azure Blob Storage.
4. Replace MSMQ notifications with Azure Service Bus.
5. Integrate existing Azure Key Vault configuration.
6. Scan and remediate dependency CVEs.

There are no infrastructure, deployment, Microsoft Entra ID user sign-in,
Azure Files, storage-mount, or Azure SQL Database tasks. No task provisions
resources or deploys the application.

---

## Configuration Contract

The execution phase must obtain environment-specific values at runtime:

- `ConnectionStrings:DefaultConnection`
- `Storage:BlobServiceUri`
- `Storage:ContainerName`
- `ServiceBus:FullyQualifiedNamespace`
- `ServiceBus:QueueName`
- `KeyVault:VaultUri`

No resource IDs, secrets, shared keys, SAS tokens, or Azure service connection
strings are embedded in this plan.

---

## Completion Criteria

- The project targets `net10.0`, uses SDK-style `PackageReference`, and runs as
  ASP.NET Core MVC while retaining controllers, views, and the EF Core model.
- Applicable `Web.config` settings are represented through `appsettings.json`
  and environment-specific configuration.
- Database behavior supports both the specified local SQL-authentication mode
  and the explicitly selected Azure managed-identity mode.
- Mutable teaching-material uploads use Blob Storage; no Azure Files or mounts
  are introduced.
- Notifications use Service Bus without SAS or connection strings.
- Azure clients use `DefaultAzureCredential` and the named configuration keys.
- Known dependency CVEs are remediated, and the final project builds and tests
  successfully.

---

## Explicit Exclusions

- Microsoft Entra ID application user sign-in
- Azure SQL Database
- Azure Files and storage mounts
- Azure resource provisioning or infrastructure-as-code generation
- Deployment execution
- Moving ordinary application CSS, JavaScript, or bundled static assets to Blob
  Storage
- Integration-test generation not requested by the user
