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
container readiness for Azure App Service on Linux. This is a proposal for
review: do not implement it, provision/change/delete Azure resources, or deploy.

---

## Migration Impact Summary

| Application | Original | Target | Authentication | Decision |
|---|---|---|---|---|
| ContosoUniversity | .NET Framework MVC | .NET 10 ASP.NET Core MVC | N/A | Upgrade first |
| ContosoUniversity | SQL Server/LocalDB | Azure SQL Managed Instance | SQL auth locally; configured Active Directory Default on Azure | MI only |
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

The Windows AD finding is excluded. The application has no user sign-in or
`[Authorize]`; the finding comes only from `IISExpressWindowsAuthentication`
and `Integrated Security=True` in the old LocalDB connection string. Do not
add a Windows AD-to-Microsoft Entra ID migration task. Azure Files and Azure
SQL Database are excluded: the targets are Blob Storage and SQL Managed
Instance.

---

## Configuration and Authentication Decisions

- Azure SQL Managed Instance is the only Azure database target.
- `ConnectionStrings:DefaultConnection` has two deliberate runtime modes:
  - on the dev VM, a SQL-authentication connection string for `10.10.n.4`
    (where `n` is the member subnet) with login `contosoapp` and its password
    lives only in user secrets; pass it to EF Core/SqlClient unchanged;
  - use managed identity for SQL Managed Instance only when this connection
    string explicitly contains `Authentication=Active Directory Default`.
    Do not overwrite a SQL-authentication connection string or inject a token
    into that path. Verify the selected SqlClient version supports this mode.
- `Storage:BlobServiceUri` is the Blob endpoint (for example,
  `https://stuni<suffix>b06.blob.core.windows.net`);
  `Storage:ContainerName` is `teaching-materials`.
- `ServiceBus:FullyQualifiedNamespace` is the namespace hostname (for
  example, `sbns-uni-<suffix>-b06.servicebus.windows.net`);
  `ServiceBus:QueueName` is `notifications`.
- `KeyVault:VaultUri` is the vault URI (for example,
  `https://kv-uni-<suffix>-b06.vault.azure.net/`). If set, load Key Vault
  after the other configuration providers so `ConnectionStrings--DefaultConnection`
  maps to and overrides `ConnectionStrings:DefaultConnection`. If unset,
  continue using user secrets locally; never commit a password.
- Use `DefaultAzureCredential` for Blob, Service Bus and Key Vault. App Service
  managed identity must have existing Blob data, Service Bus sender/receiver,
  and Key Vault secret read permissions; check access without changing roles.
- Storage shared keys and Service Bus SAS are disabled. Keys, SAS tokens,
  Storage connection strings, and Service Bus connection strings are
  explicitly prohibited.

---

## Implementation Tasks (in order, after approval)

1. **Upgrade to .NET 10 first.** Convert the legacy project to SDK-style
   `Microsoft.NET.Sdk.Web` with `net10.0` and compatible `PackageReference`
   dependencies; remove `packages.config` and obsolete MVC 5/System.Web
   dependencies. Move applicable `Web.config` settings to `appsettings.json`
   (never the LocalDB/SQL password), and port `Global.asax`, routing, filters,
   bundles/static files, DI, validation and request/upload size limits to ASP.NET
   Core startup. Keep the controllers' actions/routes, Razor views, models and
   EF Core relationships; adapt MVC 5 APIs and Razor helpers where required.
   Move to compatible EF Core/SqlClient versions, retaining the existing table
   mappings. Gate: `dotnet build`, MVC page/form smoke checks, and no `System.Web`
   dependencies.
2. **Database.** Wire EF Core through configuration/DI instead of
   `ConfigurationManager` in `SchoolContextFactory` and `Global.asax`.
   Connect to the existing SQL Managed Instance when explicitly configured
   for `Authentication=Active Directory Default`; preserve local SQL auth to
   `10.10.n.4` as described above. Do not run `EnsureCreated` or seed data
   automatically against an existing MI database. Gate: verify both connection
   modes and CRUD against the existing schema without creating/changing
   infrastructure.
3. **Uploads to Blob.** Replace `CoursesController` local `Uploads` write,
   replacement and delete logic with a `BlobServiceClient` built from
   `Storage:BlobServiceUri` and `DefaultAzureCredential`. Keep the extension
   allowlist and 5 MB cap, use unique blob names in `teaching-materials`, and
   retain the course's image reference. Because the account is private, serve
   images through an app endpoint that streams blobs using its identity;
   update the course views accordingly, rather than embedding inaccessible
   Blob URLs or issuing SAS links. On edits, delete the old blob only after a
   successful replacement; test create, view, replace and failure handling.
4. **Messaging to Service Bus.** Replace MSMQ in `NotificationService` with
   namespace/queue clients using `DefaultAzureCredential`, registered in DI.
   Preserve the entity-operation send path in `BaseController` and the
   Notifications page's `GetNotifications` polling/read-back: receive up to
   ten messages per poll, deserialize, complete only after successful read,
   and abandon failed messages. Keep a bounded empty-queue wait and the
   existing non-blocking send failure policy; preserve the current no-op
   `MarkAsRead` behavior unless separately agreed. Remove `System.Messaging`
   and stale MSMQ settings/text. Gate: send, poll and display a notification
   using the existing queue, with no SAS or keys.
5. **Secrets from Key Vault.** When `KeyVault:VaultUri` is configured, add
   Azure Key Vault as a configuration source using `DefaultAzureCredential`,
   with precedence over `appsettings.json`, environment variables and user
   secrets for `ConnectionStrings:DefaultConnection`. The secret name is
   `ConnectionStrings--DefaultConnection`. Without the vault URI, local user
   secrets continue to supply the SQL-authentication connection string.
   Gate: verify override, absent-vault fallback, and no credentials in git.

## Verification and Packaging (after the five tasks)

1. **Baseline preparation** — snapshot `app/ContosoUniversity`; this can run
   independently of implementation work.
2. **Security/CVE remediation** — depends on all upgrade and service
   transformations.
3. **Integration verification** — depends on the baseline, upgrade, all four
   service migrations, and security remediation.
4. **Containerization/readiness** — depends on integration verification and
   prepares an Azure App Service for Linux container artifact without
   provisioning or deployment. Ensure Linux casing/static assets work and
   startup does not rely on IIS, MSMQ or local persistent files.

The authoritative task IDs and dependency arrays are in
`.metadata/tasks.json`.

---

## Open Questions & Questionnaire

- [x] Q: Which storage target should be used? → A: Azure Blob Storage only.
- [x] Q: Which Azure SQL target should be used? → A: Azure SQL Managed
  Instance only.
- [x] Q: Should Windows AD be migrated to Microsoft Entra ID? → A: No; there
  is no user sign-in flow.
- [x] Q: How should integration verification run if live access is unavailable?
  A: Use the baseline infrastructure decision table and mocks, recording
  which checks still require the existing private endpoints from `vm-dev01`.
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
- The private Blob images render on course pages, and a sent Service Bus
  notification is read back by the Notifications page polling path.
- The Key Vault secret overrides `ConnectionStrings:DefaultConnection` only
  when `KeyVault:VaultUri` is configured; no password is committed.
- Azure SDK access uses `DefaultAzureCredential`; prohibited keys, SAS tokens,
  and Storage/Service Bus connection strings are absent.
- Dependency CVEs are remediated before containerization.
- Integration verification confirms behavior against the frozen baseline.
- A Linux container configuration is ready for Azure App Service, without
  infrastructure provisioning or deployment.
