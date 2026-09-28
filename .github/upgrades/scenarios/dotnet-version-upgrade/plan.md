# ContosoUniversity .NET 10 and Azure Workload Upgrade Plan

## Scope and boundaries

- Application scope: `app/ContosoUniversity`
- Target framework: `net10.0`
- Hosting target: the existing Azure App Service for Linux container host
- Azure resources already exist; provisioning, infrastructure-as-code, role assignment, registry creation, image push, deployment, and resource creation are excluded.
- No task adds Microsoft Entra ID application user sign-in.
- Every Azure SDK client uses `DefaultAzureCredential`, and all service endpoints and names come from runtime configuration.

## Upgrade Options

| Option | Selected | Why |
|--------|----------|-----|
| Upgrade Strategy | All-at-Once | One independent .NET Framework project must be upgraded atomically before the ordered workload migrations. |
| Project Approach | In-place rewrite | The exact six-task chain requires the existing project to become the ASP.NET Core MVC application within Task 1. |
| Unsupported Packages | Resolve Inline | The two incompatible packages have framework-native or known replacement paths and must not create extra top-level tasks. |
| Unsupported API Handling | Fix Inline | Compatibility work must remain in its owning task; MSMQ replacement is reserved for Task 4. |
| System.Web Adapters | Direct Migration to ASP.NET Core APIs | The required end state is native ASP.NET Core MVC without a compatibility-shim cleanup task. |
| Assembly Binding Redirects | Document and Review Before Removing | Twelve redirects include mandatory conflicts and forced downgrades whose intent must be recorded before removal. |
| Test Coverage | Skip | The plan must contain exactly six top-level tasks; all available existing tests are still run in Tasks 1 and 6. |

### Selected Strategy
**All-At-Once** — The scoped application is upgraded atomically in Task 1 before workload migrations begin.
**Rationale**: The assessment found one independent `net48` web project with no project-to-project dependencies. The subsequent Azure workload changes are intentionally serialized by the user-required dependency chain.

## Task dependencies

| Task | Depends on |
|------|------------|
| 01-upgrade-dotnet-10-mvc | None |
| 02-migrate-sql-managed-instance | 01-upgrade-dotnet-10-mvc |
| 03-migrate-blob-storage | 02-migrate-sql-managed-instance |
| 04-migrate-service-bus | 03-migrate-blob-storage |
| 05-integrate-key-vault | 04-migrate-service-bus |
| 06-audit-dependency-cves | 05-integrate-key-vault |

### 01-upgrade-dotnet-10-mvc: Upgrade to .NET 10 and ASP.NET Core MVC

Upgrade `app/ContosoUniversity/ContosoUniversity.csproj` in place from the assessed `net48` ASP.NET MVC 5 application to `net10.0` ASP.NET Core MVC. The task owns the user-required combined conversion to an SDK-style `Microsoft.NET.Sdk.Web` project and `PackageReference`, replacement of legacy `System.Web` hosting, routing and bundling patterns, migration of applicable `Web.config` values into `appsettings.json`, environment-specific configuration, or ASP.NET Core configuration, and documentation or removal of obsolete binding redirects. Preserve the existing controllers, Razor views, user-visible behavior, and the EF Core entity model, relationships, and mappings while updating compatible packages and resolving the assessed API issues that belong to the application upgrade.

Treat IIS Express Windows Authentication and LocalDB integrated-security settings only as local hosting and database evidence. Do not add Microsoft Entra ID application user sign-in. Correct stale Windows Authentication documentation or view text only as part of this task. Add a reproducible Linux container definition suitable for the existing Azure App Service for Linux container host and validate it locally without pushing or deploying an image. If the source already satisfies an individual requirement at execution time, verify it and record that implementation step as a no-op rather than removing or reordering the task.

**Depends on**: None

**Done when**: The application is an SDK-style `Microsoft.NET.Sdk.Web` project targeting `net10.0` with `PackageReference`; applicable legacy configuration is migrated; controllers, Razor views, user-visible behavior, and EF Core mappings are preserved; no user sign-in migration was added; the Linux container definition is reproducible and locally validated; and the application builds successfully with all available tests passing.

### 02-migrate-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance

Operate only on the upgraded .NET 10 application from Task 1 and use Azure SQL Managed Instance as the sole Azure database target. Preserve the EF Core model and application behavior and continue reading the database setting from `ConnectionStrings:DefaultConnection`. When the configured value contains SQL authentication for the on-premises SQL Server and the `contosoapp` login is supplied through user secrets, pass that connection string to EF Core unchanged. Use managed identity only when the configured value explicitly contains `Authentication=Active Directory Default`; never convert or reinterpret a SQL-authenticated value automatically.

Do not put usernames, passwords, connection strings, or other secrets in source control or workflow artifacts. Do not create or deploy a database or provision infrastructure. If the SQL-authentication secret remains unavailable, record SQL-authenticated runtime validation as blocked until the student supplies it while continuing to treat the implementation task as feasible. If the required support is already present at execution time, verify both modes and record the implementation step as a no-op.

**Depends on**: `01-upgrade-dotnet-10-mvc`

**Done when**: The `net10.0` application targets only Azure SQL Managed Instance, preserves `ConnectionStrings:DefaultConnection` and the EF Core model, passes SQL-authenticated values unchanged, selects managed identity only from the explicit authentication keyword, stores no secrets in source control, and records the result or documented input blocker for each runtime mode.

### 03-migrate-blob-storage: Migrate mutable file handling to Azure Blob Storage

Operate only on the upgraded .NET 10 application after Task 2. Replace mutable application-managed teaching-material file operations with Azure Blob Storage as the sole mutable-file target, authenticating with `DefaultAzureCredential` and reading `Storage:BlobServiceUri` and `Storage:ContainerName` at runtime. Cover upload, replacement, retrieval, and deletion while preserving the existing controllers, views, supported `.jpg`, `.jpeg`, `.png`, `.gif`, and `.bmp` types, the 5 MB application limit, `course_{CourseID}_{Guid}{extension}` naming behavior, replacement cleanup, and course-deletion cleanup behavior.

Keep ordinary CSS, JavaScript, images, and bundled static assets in the application unless repository evidence at execution time proves they are mutable user-managed content. Do not use Azure Files, storage mounts, account shared keys, SAS tokens, or Storage connection strings, and do not provision or configure storage. If Blob-backed handling already satisfies the requirement at execution time, verify the complete lifecycle and record the implementation step as a no-op.

**Depends on**: `02-migrate-sql-managed-instance`

**Done when**: All mutable teaching-material operations use only Azure Blob Storage through `DefaultAzureCredential` and runtime URI/container configuration; existing validation and lifecycle semantics are preserved; static application assets remain local; and no prohibited storage authentication or provisioning work is present.

### 04-migrate-service-bus: Migrate messaging to Azure Service Bus

Operate only on the upgraded .NET 10 application after Task 3. Replace the assessed `System.Messaging` and MSMQ behavior with Azure Service Bus as the sole messaging target while preserving create, update, delete, send, receive, serialization, and notification semantics used by the application. Authenticate with `DefaultAzureCredential` and read `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName` from runtime configuration.

Service Bus SAS authentication is disabled: do not use shared access keys, SAS tokens, or Service Bus connection strings. Remove application attempts to create queues or assign queue permissions, because the resource already exists and resource creation, configuration, provisioning, and deployment are out of scope. If Service Bus behavior already meets these requirements at execution time, verify the semantics and record the implementation step as a no-op.

**Depends on**: `03-migrate-blob-storage`

**Done when**: The application has no MSMQ or `System.Messaging` dependency, preserves notification behavior through the existing Azure Service Bus using `DefaultAzureCredential` and runtime namespace/queue configuration, and performs no resource-management or prohibited credential operation.

### 05-integrate-key-vault: Integrate Azure Key Vault

Operate only on the upgraded .NET 10 application after Task 4. Add the existing Azure Key Vault as an ASP.NET Core configuration source, authenticate with `DefaultAzureCredential`, and read `KeyVault:VaultUri` from runtime configuration while preserving local user-secrets behavior. The configuration design must keep `ConnectionStrings:DefaultConnection` semantics unchanged: a SQL-authenticated value remains SQL-authenticated, and managed identity applies to SQL only when `Authentication=Active Directory Default` is explicitly present.

Do not add Microsoft Entra ID application user sign-in, hard-code endpoints or secrets, provision Key Vault, create identities, assign Azure roles, or deploy resources. If the configuration source already complies at execution time, verify provider ordering, local user-secrets behavior, and SQL connection-string semantics, then record the implementation step as a no-op.

**Depends on**: `04-migrate-service-bus`

**Done when**: The application loads the existing vault through `KeyVault:VaultUri` and `DefaultAzureCredential`, local user secrets continue to work, SQL-authenticated `DefaultConnection` values are not reinterpreted, and no identity, role, provisioning, deployment, or user sign-in work was added.

### 06-audit-dependency-cves: Audit and remediate dependency CVEs

Run this task last against the final application produced by Tasks 1-5. Perform a fresh audit of direct and transitive NuGet dependencies and act only on vulnerabilities actually reported by that audit; do not infer CVE identifiers from the earlier compatibility assessment. For each detected vulnerability, upgrade to the minimum compatible patched version and document any major-version change and breaking-change risk.

Build the final `net10.0` application and run all available tests after remediation. If the fresh audit reports no known vulnerabilities, retain this task and record it as a verified no-op. Do not alter the task order merely because package work was partly completed in an earlier task.

**Depends on**: `05-integrate-key-vault`

**Done when**: Fresh direct and transitive NuGet audit results are recorded without invented findings; every detected vulnerability is remediated to the minimum compatible patched version with major-version risks documented; the final `net10.0` application builds; all available tests pass; or the task is explicitly recorded as a verified no-op when no known vulnerabilities are found.
