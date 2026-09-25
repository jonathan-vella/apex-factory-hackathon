# Modernization Plan: ContosoUniversity .NET 10 and Azure Migration

**Project**: ContosoUniversity

**Assessment report**:
`.github/modernize/assessment/reports/report-20260925073922/report.json`

---

## Technical Framework

- **Current language/runtime**: C# on .NET Framework 4.8
- **Target language/runtime**: C# on .NET 10 (`net10.0`)
- **Current framework**: ASP.NET MVC 5.2.9
- **Target framework**: ASP.NET Core MVC on .NET 10
- **Current build/configuration**: MSBuild, `packages.config`, and `Web.config`
- **Target build/configuration**: SDK-style project, `PackageReference`, and
  `appsettings.json`
- **Data access**: Preserve and migrate the existing data model with EF Core
- **Application scope**: `app/ContosoUniversity`
- **Hosting readiness target**: Azure App Service for Linux using containers

---

## Overview

This plan first upgrades ContosoUniversity to .NET 10 and ASP.NET Core MVC,
while preserving its controllers, views, and data model. All Azure service
migrations then operate on that upgraded application and run sequentially in
the required order: Azure SQL Managed Instance, Azure Blob Storage, Azure
Service Bus, and Azure Key Vault.

The plan also retains a local SQL-authentication path, establishes integration
verification against the frozen baseline, remediates dependency CVEs, and adds
containerization/readiness work for Azure App Service on Linux. It does not
provision infrastructure, deploy the application, or execute any task.

---

## Migration Impact Summary

| Application | Original | Target | Authentication | Decision |
|---|---|---|---|---|
| ContosoUniversity | .NET Framework MVC | .NET 10 ASP.NET Core MVC | N/A | Upgrade first |
| ContosoUniversity | SQL Server/LocalDB | Azure SQL Managed Instance | DefaultAzureCredential or local SQL auth | MI only |
| ContosoUniversity | Local files | Azure Blob Storage | DefaultAzureCredential | Blob only |
| ContosoUniversity | MSMQ | Azure Service Bus | DefaultAzureCredential | No SAS/connection string |
| ContosoUniversity | Plaintext credentials | Azure Key Vault | DefaultAzureCredential | MI access |
| ContosoUniversity | IIS-hosted app | App Service Linux container | Runtime managed identity | Readiness only |

---

## Selected Assessment Scope

- **SQL Server** — issue: SQL database connection detected
  - Migrate from SQL Server to Managed Identity Based Azure SQL Managed
    Instance [kbId: local-sql-server-to-azure-sql-mi]
- **Local File** — issue: Static content detected
  - Migrate from local file system to Azure Blob Storage
    [kbId: local-file-to-azure-blob-storage]
- **File System Management** — issue: Local or network IO operations detected
  - File System Management Migration
    [kbId: file-system-management-prompt]
- **Msmq** — issue: MSMQ usage is detected
  - Migrate from MSMQ to Azure Service Bus
    [kbId: msmq-to-azure-servicebus]
- **Local Credential** — issue: Connection strings without configuration
  builders detected
  - Migrate from Plaintext Credentials to Secured Credentials protected by
    Managed Identity and Azure KeyVault
    [kbId: plaintext-credential-to-azure-keyvault]

The Windows AD finding is excluded. The application has no user sign-in; the
finding comes only from `IISExpressWindowsAuthentication` and the Integrated
Security LocalDB connection string. The Azure Files and Azure SQL Database
alternatives are also excluded because Blob Storage and Azure SQL Managed
Instance were selected.

---

## Configuration and Authentication Decisions

- Azure SQL Managed Instance is the only Azure database target.
- `ConnectionStrings:DefaultConnection` has two deliberate runtime modes:
  - when it specifies SQL authentication for `10.10.1.4` with login
    `contosoapp`, the password is supplied through user secrets and the
    connection string is used as-is;
  - managed identity is used only when the connection string contains
    `Authentication=Active Directory Default`, using
    `DefaultAzureCredential`.
- Blob Storage uses `Storage:BlobServiceUri` and `Storage:ContainerName`.
- Service Bus uses `ServiceBus:FullyQualifiedNamespace` and
  `ServiceBus:QueueName`.
- Key Vault uses `KeyVault:VaultUri`; the connection-string secret name is
  `ConnectionStrings--DefaultConnection`.
- `DefaultAzureCredential` is mandatory for Azure SQL managed-identity mode,
  Blob Storage, Service Bus, and Key Vault.
- Storage shared keys and Service Bus SAS are disabled. Keys, SAS tokens,
  Storage connection strings, and Service Bus connection strings are
  explicitly prohibited.

---

## Execution Phases and Dependencies

1. **Baseline preparation** — snapshot `app/ContosoUniversity`; this can run
   independently of implementation work.
2. **Upgrade** — migrate to .NET 10 and ASP.NET Core MVC. This is the first
   implementation task.
3. **Database** — depends on the upgrade.
4. **Blob Storage** — depends on the database migration and therefore on the
   upgrade.
5. **Service Bus** — depends on Blob Storage and therefore on the upgrade.
6. **Key Vault** — depends on Service Bus and therefore on the upgrade.
7. **Security/CVE remediation** — depends on all upgrade and service
   transformations.
8. **Integration verification** — depends on the baseline, upgrade, all four
   service migrations, and security remediation.
9. **Containerization/readiness** — depends on integration verification and
   prepares an Azure App Service for Linux container artifact without
   provisioning or deployment.

The authoritative task IDs and dependency arrays are in
`.metadata/tasks.json`.

---

## Open Questions & Questionnaire

- [x] Q: Which storage target should be used? → A: Azure Blob Storage only.
- [x] Q: Which Azure SQL target should be used? → A: Azure SQL Managed
  Instance only.
- [x] Q: Should Windows AD be migrated to Microsoft Entra ID? → A: No; there
  is no user sign-in flow.
- [x] Q: How should integration verification run without supplied Azure
  resources? → A: Use the baseline infrastructure decision table and mock
  external dependencies where live resources are unavailable.
- [x] Q: What is the hosting target? → A: Azure App Service for Linux using
  containers; include readiness work only.
- [x] Q: Should infrastructure be provisioned or the app deployed? → A: No.

---

## Success Measures

- The application targets .NET 10 with an SDK-style project,
  `PackageReference`, ASP.NET Core MVC, and `appsettings.json`.
- Existing controllers, views, observable behavior, and the EF Core data model
  are preserved through the upgrade.
- Database, Blob Storage, Service Bus, and Key Vault migrations complete in
  the required sequence and only after the upgrade.
- The local SQL-authentication path and the Azure SQL managed-identity path
  behave exactly as specified.
- Azure SDK access uses `DefaultAzureCredential`; prohibited keys, SAS tokens,
  and Storage/Service Bus connection strings are absent.
- Dependency CVEs are remediated before containerization.
- Integration verification confirms behavior against the frozen baseline.
- A Linux container configuration is ready for Azure App Service, without
  infrastructure provisioning or deployment.
