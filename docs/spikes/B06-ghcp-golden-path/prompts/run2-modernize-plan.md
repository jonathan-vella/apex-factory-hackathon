/create-modernization-plan Create the modernization plan for app/ContosoUniversity from the latest assessment report in .github/modernize/assessment/reports, following these rules exactly.

## Workflow Requirements

- Scope the work to `app/ContosoUniversity` on the current branch.
- Perform assessment and planning only.
- Do not start or execute any planned task.
- Do not modify application source files.
- Do not change, provision, or deploy Azure resources.
- Do not change the on-premises environment: the SQL Server on the app VM, its database, its logins, and the legacy deployment of the application stay exactly as they are.
- Stop after the assessment and plan are ready for review.
- Preserve the task order and dependencies specified below even when the current source already satisfies part of a task. In that case, plan verification and record the implementation step as a no-op where appropriate.

## Goal

Assess `app/ContosoUniversity` and create one dependency-ordered upgrade and Azure migration plan for .NET 10, ASP.NET Core MVC, and the specified existing Azure services. The Azure target state uses Microsoft Entra authentication only and private endpoints for every backend service.

## Required Tasks

Create exactly these seven top-level tasks in this order:

1. Upgrade to .NET 10 and ASP.NET Core MVC
2. Migrate the database workload to Azure SQL Managed Instance
3. Migrate mutable file handling to Azure Blob Storage
4. Migrate messaging to Azure Service Bus
5. Integrate Azure Key Vault
6. Migrate logging and tracing to OpenTelemetry with Azure Monitor
7. Audit and remediate dependency CVEs

Task 1 has no dependencies.

Every subsequent task must depend on the preceding task, producing this exact chain:

`Task 1 -> Task 2 -> Task 3 -> Task 4 -> Task 5 -> Task 6 -> Task 7`

All tasks after Task 1 must operate on the upgraded .NET 10 application.

Every task's validation must include a successful build and a local run of the application (`dotnet run`) in which the home, Students, Courses, Instructors, and Departments pages load. A passing build alone is not sufficient.

## Task 1: .NET 10 and ASP.NET Core MVC

Plan the upgrade of `app/ContosoUniversity` to .NET 10 and ASP.NET Core MVC.

The task must require:

- Target framework `net10.0`.
- An SDK-style `Microsoft.NET.Sdk.Web` project.
- `PackageReference` instead of `packages.config`.
- Migration of applicable `Web.config` settings to `appsettings.json`, environment-specific configuration, or ASP.NET Core configuration.
- Nothing lost from `Global.asax`, `RouteConfig`, `FilterConfig`, or `BundleConfig`: the default route, global filters, and CSS and JavaScript served as static files.
- Services registered with dependency injection, including the database context and the notification service.
- Consistent static file names and references, because Linux file names are case-sensitive.
- Preservation of existing controllers.
- Preservation of Razor views and user-visible behavior.
- Preservation of the EF Core entity model, relationships, and mappings.
- Container image support through .NET SDK container publishing (`dotnet publish /t:PublishContainer`) with the container properties in the project file: base image `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, and the port the app listens on. Do not add a Dockerfile, and do not require Docker.
- Build, test, and local-run validation.

Do not add Microsoft Entra ID user sign-in.

The application has no user sign-in flow. Treat IIS Express Windows Authentication settings and LocalDB `Integrated Security` only as local hosting and database configuration evidence. They are not application identity requirements.

Remove any Microsoft Entra ID user sign-in work from the plan. Stale documentation or view text mentioning Windows Authentication may be corrected within Task 1, but it must not produce an identity migration task.

## Task 2: Azure SQL Managed Instance

Use Azure SQL Managed Instance as the only Azure database target.

Do not propose or plan Azure SQL Database.

Continue reading the database connection from:

`ConnectionStrings:DefaultConnection`

On Azure, the database connection uses Microsoft Entra authentication only:

- The connection string contains `Authentication=Active Directory Default` and no user name or password.
- It uses the managed instance's private, VNet-local host name. Never use the public data endpoint (port 3342).

The one exception is local development against the unchanged on-premises source database:

- In the `Development` environment only, when `DefaultConnection` contains SQL authentication for the on-premises SQL Server and the existing `contosoapp` login supplied through .NET user secrets, pass the connection string to EF Core unchanged.
- Outside the `Development` environment, the application must refuse to start if `DefaultConnection` contains a user name or password.

Do not convert a SQL-authenticated connection string to managed identity automatically.

Do not put user names, passwords, connection strings, or other secrets in source control or planning artifacts.

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

Serve stored images through the application. Never link browsers to blob URLs: the storage account has no public access.

Preserve existing validation, supported file types, size limits, naming behavior, replacement cleanup, deletion behavior, controllers, and views.

## Task 4: Azure Service Bus

Use Azure Service Bus as the only messaging target.

Replace any MSMQ or `System.Messaging` behavior while preserving notification semantics and application behavior: sending a notification when an entity is created, edited, or deleted, and reading notifications back.

Service Bus SAS authentication is disabled.

Do not use or propose:

- Shared access keys
- SAS tokens
- Service Bus connection strings

Authenticate with `DefaultAzureCredential`.

Read these values from configuration at execution time:

- `ServiceBus:FullyQualifiedNamespace`
- `ServiceBus:QueueName`

Validation must prove both sending and receiving, not only sending.

Do not create, configure, provision, or deploy the Service Bus resource.

## Task 5: Azure Key Vault

Azure Key Vault is mandatory on Azure.

- Add the existing Key Vault as an ASP.NET Core configuration source, authenticated with `DefaultAzureCredential`, using `KeyVault:VaultUri`.
- Outside the `Development` environment, the application must refuse to start if `KeyVault:VaultUri` is missing.
- On Azure, the secret `ConnectionStrings--DefaultConnection` holds the SQL Managed Instance connection string (Microsoft Entra authentication, no password). App Service application settings hold only `KeyVault:VaultUri` and the non-secret endpoints.
- In the `Development` environment, `KeyVault:VaultUri` is optional, and .NET user secrets remain allowed for the on-premises SQL login only.

Do not replace or reinterpret a SQL-authenticated `DefaultConnection` in the `Development` environment.

Do not add Microsoft Entra ID application user sign-in.

Do not provision Key Vault, create secrets, create identities, assign Azure roles, or deploy resources.

## Task 6: OpenTelemetry and Azure Monitor

Keep this simple:

- Replace `System.Diagnostics.Trace` and `Debug` calls with `ILogger<T>`.
- Add the Azure Monitor OpenTelemetry distro (`Azure.Monitor.OpenTelemetry.AspNetCore`) with a single `UseAzureMonitor()` call. Don't add individual instrumentation packages or custom exporters.
- Register it only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value, and set its credential to `DefaultAzureCredential` so ingestion uses Microsoft Entra authentication (local authentication is disabled on Application Insights).
- When no connection string is configured, register nothing extra: the built-in ASP.NET Core console logging applies, and the application must start and run normally.
- Validation: with a connection string configured, requests, SQL and HTTP dependencies, and logs from a local run appear in Application Insights within a few minutes.

## Task 7: CVE Audit and Remediation

Run this task last.

Plan a fresh audit of direct and transitive NuGet dependencies after all other upgrade and migration work.

For each detected vulnerability:

- Upgrade to the minimum compatible patched version.
- Document major-version changes and breaking-change risks.
- Build the final `net10.0` application.
- Run all available tests.

If no known vulnerabilities are found, retain Task 7 and record it as a verified no-op.

Do not invent CVE findings.

## Azure Authentication Rules

On Azure, every connection uses Microsoft Entra authentication:

- Use `DefaultAzureCredential` for all Azure SDK clients. On Azure it uses the web app's managed identity; locally, the developer's Azure CLI sign-in.
- Do not hard-code credential types, client IDs, tenant IDs, or object IDs.

The plan must prohibit:

- SQL logins, user names, and passwords on Azure
- Storage shared keys, SAS tokens, and connection strings
- Service Bus shared keys, SAS tokens, and connection strings
- Application Insights local (instrumentation-key-only) authentication
- Hard-coded Azure endpoints
- Hard-coded secrets

The following values must come from configuration at execution time:

- `Storage:BlobServiceUri`
- `Storage:ContainerName`
- `ServiceBus:FullyQualifiedNamespace`
- `ServiceBus:QueueName`
- `KeyVault:VaultUri`
- `ConnectionStrings:DefaultConnection`
- `APPLICATIONINSIGHTS_CONNECTION_STRING`

## Network Rules

Every backend service is private: SQL Managed Instance, Blob Storage, Service Bus, Key Vault, and the container registry have public network access disabled and are reached only through private endpoints or the virtual network.

- Use each service's standard host name from configuration. Private DNS resolves it to the private address.
- Never use `privatelink` host names, IP addresses, or the SQL Managed Instance public data endpoint in code or configuration.
- Do not add IP firewall rules or anything that requires public network access to a backend service.

The web front end, the App Service app, may accept public inbound traffic. Apart from Application Insights ingestion, the kit's other documented exception, it's the only public endpoint.

## Hosting and Infrastructure Boundaries

The hosting target is an existing Azure App Service for Linux using containers.

All Azure resources already exist.

Do not add tasks for:

- Azure resource provisioning
- Infrastructure-as-code generation
- Azure role assignment
- Private endpoint or DNS configuration
- Container registry creation
- Image push
- Application deployment
- Database creation
- Storage account creation
- Service Bus creation
- Key Vault creation or secret creation

Container packaging and local container validation may be planned, but deployment must not be performed.

## Required Artifacts

Write the plan as the modernization plan's normal output: `.github/modernize/<plan-folder>/plan.md` and `.metadata/tasks.json`, with the seven tasks above as the tasks in `tasks.json`, in order, with their dependencies.

## Required Review Output

After creating the assessment and plan:

1. Show the full artifact paths.
2. Show the seven planned tasks and their dependencies.
3. Show a table with exactly one row for each rule below.

| Rule | Requirement |
|---|---|
| 1 | .NET 10 and ASP.NET Core MVC upgrade is first; preserve controllers, views, and EF Core; SDK container publishing, no Dockerfile |
| 2 | No Microsoft Entra ID user sign-in task |
| 3 | Blob Storage and SQL Managed Instance are the only workload targets |
| 4 | Microsoft Entra authentication only on Azure; SQL authentication only in Development against the unchanged on-premises source |
| 5 | Key Vault is mandatory outside Development and holds `ConnectionStrings--DefaultConnection` |
| 6 | Backends are private only; the web front end and Application Insights ingestion are the only public endpoints |
| 7 | OpenTelemetry through the Azure Monitor distro with Entra-authenticated ingestion, registered only when a connection string is set |
| 8 | Preserve the required seven-task order, with build and local-run validation for every task |
| 9 | Target existing Azure App Service for Linux containers without provisioning or deployment; no on-premises changes |

For each row, explain exactly how the plan complies.

4. List anything that could not be assessed or validated and explain why.
5. Clearly distinguish a blocked validation from an impossible task.
6. Confirm whether any application files, Azure resources, on-premises resources, or deployments were changed.

Stop and wait for my review. Do not begin implementation.
