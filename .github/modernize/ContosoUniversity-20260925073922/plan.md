# Modernization Plan: ContosoUniversity Azure Service Migration

**Project**: ContosoUniversity

**Assessment report**:
`.github/modernize/assessment/reports/report-20260925073922/report.json`

---

## Technical Framework

- **Language**: C# on .NET Framework 4.8
- **Framework**: ASP.NET MVC 5.2.9 with Entity Framework Core 3.1.32
- **Build Tool**: MSBuild with `packages.config`
- **Database**: SQL Server LocalDB
- **Key Dependencies**: System.Web MVC, EF Core SQL Server, System.Messaging
- **Application Scope**: `app/ContosoUniversity`

---

## Overview

This plan migrates only the assessment categories selected from report
`report-20260925073922`. The application currently uses local file storage,
SQL Server LocalDB with an integrated connection string, Windows
authentication, plaintext configuration, and MSMQ. The migration will:

- move persistent file workloads to the selected Azure Storage service;
- move SQL connectivity to an Azure SQL target using managed identity;
- replace Windows AD authentication with Microsoft Entra ID;
- protect remaining application credentials with managed identity and
  Azure Key Vault; and
- replace MSMQ messaging with Azure Service Bus.

The work starts by freezing a test baseline, applies code transformations
sequentially to avoid file conflicts, and converges in mock-mode integration
verification. Infrastructure provisioning and deployment are outside the
selected scope.

---

## Migration Impact Summary

| Application | Original Service | New Azure Service | Authentication | Comments |
|---|---|---|---|---|
| ContosoUniversity | Local files | Blob or Azure Files | Managed identity | Target unresolved |
| ContosoUniversity | SQL Server | Azure SQL DB or MI | Managed identity | Target unresolved |
| ContosoUniversity | Windows AD | Microsoft Entra ID | Entra ID | Selected |
| ContosoUniversity | Plaintext credentials | Azure Key Vault | Managed identity | Selected |
| ContosoUniversity | MSMQ | Azure Service Bus | Managed identity | Selected |

---

## Selected Assessment Scope

- **Local File** — issue: Static content detected
  - Migrate from local file system to Azure Blob Storage
    [kbId: local-file-to-azure-blob-storage]
  - Migrate from local file system to Azure File Storage
    [kbId: local-file-to-azure-file-storage]
- **SQL Server** — issue: SQL database connection detected
  - Migrate from SQL Server to Managed Identity Based Azure SQL
    [kbId: local-sql-server-to-azure-sql-db]
  - Migrate from SQL Server to Managed Identity Based Azure SQL Managed
    Instance [kbId: local-sql-server-to-azure-sql-mi]
- **Windows Ad** — issue: Windows authentication detected
  - Migrate from Windows AD to Microsoft Entra ID
    [kbId: windows-ad-to-azure-ad]
- **Local Credential** — issue: Connection strings without configuration
  builders detected
  - Migrate from Plaintext Credentials to Secured Credentials protected by
    Managed Identity and Azure KeyVault
    [kbId: plaintext-credential-to-azure-keyvault]
- **File System Management** — issue: Local or network IO operations detected
  - File System Management Migration
    [kbId: file-system-management-prompt]
- **Msmq** — issue: MSMQ usage is detected
  - Migrate from MSMQ to Azure Service Bus
    [kbId: msmq-to-azure-servicebus]

---

## Execution Phases and Dependencies

1. **Baseline** — snapshot `app/ContosoUniversity` and capture the current
   behavior plus the mock/real decision table.
2. **Sequential transformation chain** — authentication, credential
   protection, database, file storage, and messaging migrations run in that
   order. Each transformation depends on the preceding transformation.
3. **Integration verification** — waits for the baseline and every
   transformation, then verifies the migrated Azure service boundaries in
   mock mode.

No infrastructure, runtime/framework upgrade, containerization, deployment,
or unrelated assessment category is included.

---

## Open Questions & Questionnaire

- [x] Q: Should the plan provision infrastructure? → A: No; no provisioning
  was requested, so this plan is code-migration only.
- [x] Q: Should integration verification be included? → A: Yes; use the
  questionnaire default mock mode because no Azure environment was supplied.
- [x] Q: Should deployment or containerization be included? → A: No; the
  selected categories request service migration only.
- [ ] Choose the persistent file target before execution: Azure Blob Storage
  or Azure File Storage. The file-management transformation must apply only
  the chosen alternative.
- [ ] Choose the database target before execution: Azure SQL Database or
  Azure SQL Managed Instance. The database transformation must apply only the
  chosen alternative.

---

## Success Measures

- All five migration transformations complete for the chosen alternatives.
- The application builds and existing unit tests pass after each
  transformation.
- New Azure integration boundaries have mock-based unit coverage where
  applicable.
- Integration verification demonstrates preserved file, database,
  authentication, secret-access, and messaging behavior.
- No plaintext Azure credentials or connection strings are committed.

