Use the GitHub Copilot Upgrade Agent’s stateful, dashboard-compatible workflow for this request.

## Workflow Requirements

- Scope the work to `app/ContosoUniversity`.
- Use the `dotnet-version-upgrade` scenario as the owning scenario.
- Initialize or resume the scenario under `.github/upgrades/dotnet-version-upgrade`.
- Do not use the `azure-migrate` scenario.
- Do not invoke `start_app_mod_migration_session`.
- Do not create planning artifacts under `.github/modernize`.
- Use Guided flow mode.
- Perform assessment and planning only.
- Do not start or execute any planned task.
- Do not modify application source files.
- Do not provision, change, or deploy Azure resources.
- Stop after the assessment and plan are ready for review.
- Preserve the task order and dependencies specified below even when the current source already satisfies part of a task. In that case, plan verification and record the implementation step as a no-op where appropriate.

## Goal

Assess `app/ContosoUniversity` and create one dependency-ordered upgrade and Azure migration plan for .NET 10, ASP.NET Core MVC, and the specified existing Azure services.

## Required Tasks

Create exactly these six top-level tasks in this order:

1. Upgrade to .NET 10 and ASP.NET Core MVC
2. Migrate the database workload to Azure SQL Managed Instance
3. Migrate mutable file handling to Azure Blob Storage
4. Migrate messaging to Azure Service Bus
5. Integrate Azure Key Vault
6. Audit and remediate dependency CVEs

Task 1 has no dependencies.

Every subsequent task must depend on the preceding task, producing this exact chain:

`Task 1 -> Task 2 -> Task 3 -> Task 4 -> Task 5 -> Task 6`

All tasks after Task 1 must operate on the upgraded .NET 10 application.

## Task 1: .NET 10 and ASP.NET Core MVC

Plan the upgrade of `app/ContosoUniversity` to .NET 10 and ASP.NET Core MVC.

The task must require:

- Target framework `net10.0`.
- An SDK-style `Microsoft.NET.Sdk.Web` project.
- `PackageReference` instead of `packages.config`.
- Migration of applicable `Web.config` settings to `appsettings.json`, environment-specific configuration, or ASP.NET Core configuration.
- Preservation of existing controllers.
- Preservation of Razor views and user-visible behavior.
- Preservation of the EF Core entity model, relationships, and mappings.
- A reproducible Linux container definition suitable for the existing Azure App Service for Linux container host.
- Build and test validation.

Do not add Microsoft Entra ID user sign-in.

The application has no user sign-in flow. Treat IIS Express Windows Authentication settings and LocalDB `Integrated Security` only as local hosting and database configuration evidence. They are not application identity requirements.

Remove any Microsoft Entra ID user sign-in work from the plan. Stale documentation or view text mentioning Windows Authentication may be corrected within Task 1, but it must not produce an identity migration task.

## Task 2: Azure SQL Managed Instance

Use Azure SQL Managed Instance as the only Azure database target.

Do not propose or plan Azure SQL Database.

Continue reading the database connection from:

`ConnectionStrings:DefaultConnection`

The application must support both of these modes:

- When `DefaultConnection` contains SQL authentication for the on-premises SQL Server and the `contosoapp` login supplied through user secrets, pass the connection string to EF Core unchanged.
- Use managed identity only when `DefaultConnection` explicitly contains `Authentication=Active Directory Default`.

Do not convert a SQL-authenticated connection string to managed identity automatically.

Do not put usernames, passwords, connection strings, or other secrets in source control or planning artifacts.

Preserve the EF Core model and existing application behavior.

If the local SQL-authentication secret is unavailable during assessment, record runtime validation as blocked until the student supplies it. Do not remove this requirement from the plan.

## Task 3: Azure Blob Storage

Use Azure Blob Storage as the only target for mutable application files.

Do not use or propose:

- Azure Files
- Storage mounts
- Storage account shared keys
- SAS tokens
- Storage connection strings

Authenticate with `DefaultAzureCredential`.

Read these values from configuration at execution time:

- `Storage:BlobServiceUri`
- `Storage:ContainerName`

Plan migration only for mutable application-managed files, including teaching-material uploads, replacement, retrieval, and deletion.

Keep ordinary application CSS, JavaScript, images, and bundled static assets in the application unless they are currently mutable user-managed content.

Preserve existing validation, supported file types, size limits, naming behavior, replacement cleanup, deletion behavior, controllers, and views.

## Task 4: Azure Service Bus

Use Azure Service Bus as the only messaging target.

Replace any MSMQ or `System.Messaging` behavior while preserving notification semantics and application behavior.

Service Bus SAS authentication is disabled.

Do not use or propose:

- Shared access keys
- SAS tokens
- Service Bus connection strings

Authenticate with `DefaultAzureCredential`.

Read these values from configuration at execution time:

- `ServiceBus:FullyQualifiedNamespace`
- `ServiceBus:QueueName`

Do not create, configure, provision, or deploy the Service Bus resource.

## Task 5: Azure Key Vault

Use the existing Azure Key Vault as an ASP.NET Core configuration source.

Authenticate with `DefaultAzureCredential`.

Read this value from configuration at execution time:

- `KeyVault:VaultUri`

Preserve local user-secrets behavior.

Do not replace or reinterpret a SQL-authenticated `DefaultConnection`. Managed identity applies to SQL only when the connection string explicitly contains `Authentication=Active Directory Default`.

Do not add Microsoft Entra ID application user sign-in.

Do not provision Key Vault, create identities, assign Azure roles, or deploy resources.

## Task 6: CVE Audit and Remediation

Run this task last.

Plan a fresh audit of direct and transitive NuGet dependencies after all other upgrade and migration work.

For each detected vulnerability:

- Upgrade to the minimum compatible patched version.
- Document major-version changes and breaking-change risks.
- Build the final `net10.0` application.
- Run all available tests.

If no known vulnerabilities are found, retain Task 6 and record it as a verified no-op.

Do not invent CVE findings.

## Azure Authentication and Configuration Rules

Use `DefaultAzureCredential` for all Azure SDK clients.

The plan must prohibit:

- Storage shared keys
- Storage SAS tokens
- Storage connection strings
- Service Bus shared keys
- Service Bus SAS tokens
- Service Bus connection strings
- Hard-coded Azure endpoints
- Hard-coded secrets

The following values must come from configuration at execution time:

- `Storage:BlobServiceUri`
- `Storage:ContainerName`
- `ServiceBus:FullyQualifiedNamespace`
- `ServiceBus:QueueName`
- `KeyVault:VaultUri`
- `ConnectionStrings:DefaultConnection`

## Hosting and Infrastructure Boundaries

The hosting target is an existing Azure App Service for Linux using containers.

All Azure resources already exist.

Do not add tasks for:

- Azure resource provisioning
- Infrastructure-as-code generation
- Azure role assignment
- Container registry creation
- Image push
- Application deployment
- Database creation
- Storage account creation
- Service Bus creation
- Key Vault creation

Container packaging and local container validation may be planned, but deployment must not be performed.

## Required Artifacts

Create the normal stateful Upgrade Agent artifacts under:

`.github/upgrades/dotnet-version-upgrade/`

At minimum, produce:

- `assessment.md`
- `plan.md`
- `scenario-instructions.md`

Use the Upgrade Agent’s workflow state tools so the scenario can be opened in the Upgrade Agent dashboard.

Do not manually create `tasks.md`. Let the Upgrade Agent workflow generate and maintain it when task execution is explicitly approved later.

## Required Review Output

After creating the assessment and plan:

1. Show the full artifact paths.
2. Show the six planned tasks and their dependencies.
3. Show a table with exactly one row for each rule below.

| Rule | Requirement |
|---|---|
| 1 | .NET 10 and ASP.NET Core MVC upgrade is first; preserve controllers, views, and EF Core |
| 2 | No Microsoft Entra ID user sign-in task |
| 3 | Blob Storage and SQL Managed Instance are the only workload targets |
| 4 | Preserve local SQL authentication; managed identity only when explicitly selected |
| 5 | Preserve the required six-task order |
| 6 | Use DefaultAzureCredential and runtime endpoint configuration without keys, SAS, or Azure service connection strings |
| 7 | Target existing Azure App Service for Linux containers without provisioning or deployment |

For each row, explain exactly how the plan complies.

4. List anything that could not be assessed or validated and explain why.
5. Clearly distinguish a blocked validation from an impossible task.
6. Confirm whether any application files, Azure resources, or deployments were changed.

Stop and wait for my review. Do not call `start_task` and do not begin implementation.
