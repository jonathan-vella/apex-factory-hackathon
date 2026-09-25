# Modernization Plan: Contoso University Azure Services Modernization

**Project**: ContosoUniversity

**Assessment**: `report-20260925090428`

---

## Technical Framework

- **Language**: C# on .NET Framework 4.8
- **Framework**: ASP.NET MVC 5.2.9 with Entity Framework Core 3.1.32
- **Build Tool**: MSBuild with `packages.config`
- **Database**: SQL Server LocalDB
- **Key Dependencies**: System.Messaging, Microsoft.Data.SqlClient,
  Microsoft.EntityFrameworkCore.SqlServer

---

## Overview

This plan addresses only the selected findings in assessment report
`report-20260925090428` and the required dependency security review. The
application currently depends on local static and uploaded files, SQL Server
with Windows-integrated credentials, Windows authentication, plaintext
configuration, local file APIs, and MSMQ.

The modernized application will:

- externalize selected file workloads to an approved Azure Storage target;
- use an approved Azure SQL target with managed identity;
- replace Windows AD authentication with Microsoft Entra ID;
- protect credentials with Azure Key Vault and managed identity;
- make file-system behavior cloud-compatible;
- replace MSMQ with Azure Service Bus; and
- remediate known dependency vulnerabilities.

The work is sequenced to avoid conflicting edits in this legacy ASP.NET
application. No migration task is executed by this plan.

---

## Assessment Verification

All selected findings were confirmed in both the report and current source:

| Finding | Current-project evidence |
|---|---|
| Static content detected | `Content`, `Scripts`, and uploaded image files |
| SQL database connection detected | `Web.config` `DefaultConnection`; EF SQL |
| Windows authentication detected | IIS Express Windows auth is enabled |
| Connection strings without builders | Plaintext `Web.config` connection |
| Local or network IO detected | `CoursesController.cs` file operations |
| MSMQ usage is detected | `NotificationService.cs` uses `System.Messaging` |

The report identifies `Scale.0001`, `Database.0002`, `Identity.0002`,
`Security.0002`, `Local.0003`, and `Queue.0003`. Direct inspection also found
`Server.MapPath`, `Directory`, and `File` usage in course upload workflows,
`Integrated Security=True` in `Web.config`, Windows authentication in the
project file, and MSMQ queue creation/send/receive behavior.

---

## Migration Impact Summary

| Original service | Approved Azure outcome | Authentication |
|---|---|---|
| Local static files | Blob or File Storage | Managed identity |
| SQL Server | Azure SQL DB or SQL MI | Managed identity |
| Windows AD | Microsoft Entra ID | Entra ID |
| Plaintext credentials | Azure Key Vault | Managed identity |
| Local/network file I/O | Cloud-compatible file management | Managed identity |
| MSMQ | Azure Service Bus | Managed identity |

Selected solution markers:

- Migrate from local file system to Azure Blob Storage
  [kbId: local-file-to-azure-blob-storage]
- Migrate from local file system to Azure File Storage
  [kbId: local-file-to-azure-file-storage]
- Migrate from SQL Server to Managed Identity Based Azure SQL
  [kbId: local-sql-server-to-azure-sql-db]
- Migrate from SQL Server to Managed Identity Based Azure SQL Managed Instance
  [kbId: local-sql-server-to-azure-sql-mi]
- Migrate from Windows AD to Microsoft Entra ID
  [kbId: windows-ad-to-azure-ad]
- Migrate from Plaintext Credentials to Secured Credentials protected by
  Managed Identity and Azure KeyVault
  [kbId: plaintext-credential-to-azure-keyvault]
- File System Management Migration
  [kbId: file-system-management-prompt]
- Migrate from MSMQ to Azure Service Bus
  [kbId: msmq-to-azure-servicebus]

---

## Phases and Dependencies

1. **Storage and data transformations** run sequentially to prevent conflicts.
2. **Identity, secret, file-system, and messaging transformations** continue
   the same dependency chain.
3. **Security and CVE remediation** runs after every transformation.

Blob Storage versus Azure File Storage and Azure SQL Database versus Azure SQL
Managed Instance are retained as the selected alternatives. Before a future
execution, one target in each pair must be designated as authoritative. The
non-authoritative alternative must then be skipped rather than applying both
targets to the same workload.

No infrastructure, baseline, integration-test, containerization, or deployment
phase is included.

---

## Assumptions and Decisions

- The application scope is `app\ContosoUniversity`.
- This is a code-migration plan only; Azure resources are not provisioned.
- The two storage and two SQL selections are mutually exclusive alternatives.
- Existing upload validation and course image behavior must be preserved.
- Existing database behavior and notification semantics must be preserved.
- Managed identity is required wherever a selected solution specifies it.
- No runtime/framework upgrade is included because none was requested.
- No deployment target is assumed.

---

## Open Questions & Questionnaire

- [x] Q: Include environment/infrastructure provisioning? → A: No; code
  migration only.
- [x] Q: Include integration testing? → A: No; scope is limited to the selected
  migrations and mandatory security/CVE work.
- [x] Q: Include security/CVE remediation? → A: Yes; mandatory planning task.
- [x] Q: Select a deployment target? → A: No deployment.
- [x] Q: Include containerization? → A: No; no deployment was requested.
- [ ] Before execution, choose Blob Storage or Azure File Storage as the
  authoritative local-file target.
- [ ] Before execution, choose Azure SQL Database or Azure SQL Managed Instance
  as the authoritative SQL target.

