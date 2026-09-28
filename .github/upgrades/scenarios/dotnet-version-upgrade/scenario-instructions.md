# .NET Version Upgrade

## Preferences
- **Flow Mode**: Guided
- **Target Framework**: net10.0
- **Scope**: app/ContosoUniversity
- **Workflow Boundary**: Tasks 01 through 03 are complete and approved; execute task 04 only, then stop for review before task 05

## Source Control
- **Source Branch**: spike/b06-upgrade-compare
- **Working Branch**: spike/b06-upgrade-compare
- **Commit Strategy**: Manual
- **Branch Sync**: Disabled

## User Preferences

### Technical Preferences
- Use the `dotnet-version-upgrade` scenario; do not use `azure-migrate` or invoke `start_app_mod_migration_session`.
- Target .NET 10 and ASP.NET Core MVC while preserving controllers, Razor views, user-visible behavior, and the EF Core model, relationships, and mappings.
- Use an SDK-style `Microsoft.NET.Sdk.Web` project, `PackageReference`, ASP.NET Core configuration, dependency injection, case-consistent static assets, and .NET SDK container publishing without a Dockerfile or Docker requirement.
- Do not add Microsoft Entra ID application user sign-in.
- Use Azure SQL Managed Instance as the only Azure database target and keep `ConnectionStrings:DefaultConnection`.
- On Azure, SQL uses `Authentication=Active Directory Default`, no credentials, and the private VNet-local standard host name. Never use the public data endpoint.
- In Development only, allow an unchanged SQL-authenticated connection string for the unchanged on-premises SQL Server when supplied through .NET user secrets. Outside Development, refuse startup when the connection contains a user name or password.
- Use Azure Blob Storage only for mutable application-managed files. Authenticate with `DefaultAzureCredential`; configure `Storage:BlobServiceUri` and `Storage:ContainerName`; never expose blob URLs to browsers.
- Use Azure Service Bus as the only messaging target. Authenticate with `DefaultAzureCredential`; configure `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName`; preserve send and receive semantics.
- Add the existing Key Vault as a mandatory configuration source outside Development, using `DefaultAzureCredential` and `KeyVault:VaultUri`. The Azure secret is `ConnectionStrings--DefaultConnection`.
- Replace Trace and Debug usage with `ILogger<T>`. Use only `Azure.Monitor.OpenTelemetry.AspNetCore` and one `UseAzureMonitor()` call, conditionally registered when an Application Insights connection string exists, with `DefaultAzureCredential`.
- Audit direct and transitive NuGet CVEs last; use minimum compatible patched versions and retain the task as a verified no-op when no vulnerability is found.
- All Azure SDK clients use `DefaultAzureCredential`; do not hard-code credential types, client IDs, tenant IDs, object IDs, Azure endpoints, or secrets.
- Backend services and the container registry are private-only and use standard host names resolved by private DNS. Do not use `privatelink` host names, IP addresses, public data endpoints, or public firewall exceptions.
- Target the existing Azure App Service for Linux container host. Do not provision, configure, assign roles, push images, deploy, or change Azure resources.
- Do not change the on-premises SQL Server, database, logins, or legacy application deployment.

### Execution Style
- Preserve exactly seven top-level tasks in the specified order and dependency chain, even when an implementation step is already satisfied; plan verification and record such implementation as a no-op.
- Every task validation must include a successful build and local `dotnet run` verification that Home, Students, Courses, Instructors, and Departments pages load.
- A missing local SQL-authentication secret blocks runtime validation until supplied; it does not make the task impossible and must remain in the plan.
- Allow workflow tooling to generate `tasks.md` for approved task execution; never create it manually.
- Tasks 01 through 03 are complete and approved. Execute approved task 04 only, then stop for review without starting task 05.

## Decisions
- **Task 1 execution approval**: Completed; reviewed and approved before task 02.
- **Task 2 execution approval**: Completed; reviewed and approved before task 03.
- **Task 3 execution approval**: Completed; reviewed and approved before task 04.
- **Task 4 execution approval**: Execute `04-azure-service-bus` only, then stop for review before task 05.
- **Upgrade Strategy**: All-at-Once
- **Project Approach**: In-place rewrite
- **Unsupported Packages**: Resolve Inline
- **Unsupported API Handling**: Fix Inline
- **System.Web Adapters**: Direct Migration to ASP.NET Core APIs
- **Assembly Binding Redirects**: Document and Review Before Removing
- **Test Coverage**: Skip generated coverage; retain required build, available-test, and local page-run validation
- The seven top-level tasks are:
  1. Upgrade to .NET 10 and ASP.NET Core MVC
  2. Migrate the database workload to Azure SQL Managed Instance
  3. Migrate mutable file handling to Azure Blob Storage
  4. Migrate messaging to Azure Service Bus
  5. Integrate Azure Key Vault
  6. Migrate logging and tracing to OpenTelemetry with Azure Monitor
  7. Audit and remediate dependency CVEs
- Dependencies form the exact chain Task 1 -> Task 2 -> Task 3 -> Task 4 -> Task 5 -> Task 6 -> Task 7.
- Every task after Task 1 operates on the upgraded .NET 10 application.

## Upgrade Options

### Strategy
- Upgrade Strategy: All-at-Once

### Project Structure
- Project Approach: In-place rewrite

### Compatibility
- Unsupported Packages: Resolve Inline (2 incompatible packages)
- Unsupported API Handling: Fix Inline
- System.Web Adapters: Direct Migration to ASP.NET Core APIs

### Modernization
- Assembly Binding Redirects: Document and Review Before Removing

### Reliability
- Test Coverage: Skip

## Strategy
**Selected**: All-at-Once
**Rationale**: The assessment contains one isolated, non-SDK ASP.NET Framework 4.8 web project with no project-to-project dependency graph; the confirmed in-place approach and exact seven-task application-modernization sequence require one coordinated project upgrade rather than dependency tiers.

### Execution Constraints
- Treat the project conversion and framework migration as one coordinated upgrade stream while preserving the exact seven approved top-level tasks and their strict linear dependency chain.
- Keep the application buildable and warning-free at every task boundary; validate any available tests and the five required local pages before advancing.
- Resolve incompatible packages and unsupported APIs inside their owning approved task; do not create extra top-level tasks or defer work through compatibility stubs.
- Preserve controllers, Razor views, observable behavior, and EF mappings while moving directly to native ASP.NET Core APIs without System.Web Adapters.
- Do not provision, configure, deploy, assign roles, push images, alter Azure resources, or change the on-premises SQL Server, database, logins, or legacy deployment.

## Build Tool Decisions
- **ContosoUniversity.csproj**: `dotnet build` (SDK-style `Microsoft.NET.Sdk.Web`, `net10.0`, with no desktop/resource/tooling requirements).
