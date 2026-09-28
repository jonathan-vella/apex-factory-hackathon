# .NET Version Upgrade

## Preferences
- **Flow Mode**: Guided
- **Target Framework**: net10.0
- **Scope**: app/ContosoUniversity
- **Workflow Boundary**: Assessment and planning only; do not start or execute planned tasks.

## Source Control
- **Source Branch**: spike/b06-upgrade-compare
- **Working Branch**: spike/b06-upgrade-compare
- **Commit Strategy**: Manual
- **Branch Sync**: Disabled

## User Preferences

### Technical Preferences
- Use the `dotnet-version-upgrade` scenario. Do not use `azure-migrate`.
- Create exactly six dependency-ordered top-level tasks: .NET 10 and ASP.NET Core MVC, Azure SQL Managed Instance, Azure Blob Storage, Azure Service Bus, Azure Key Vault, then dependency CVE audit and remediation.
- Preserve the exact dependency chain from Task 1 through Task 6, even when an implementation step is already satisfied; plan verification and a no-op implementation step where appropriate.
- Do not add Microsoft Entra ID application user sign-in.
- Use Azure SQL Managed Instance as the only database target and continue reading `ConnectionStrings:DefaultConnection`.
- Preserve SQL authentication connection strings unchanged; use managed identity for SQL only when `Authentication=Active Directory Default` is explicitly present.
- Use Azure Blob Storage as the only mutable-file target and Azure Service Bus as the only messaging target.
- Use `DefaultAzureCredential` for Azure SDK clients.
- Read Azure endpoints and names from runtime configuration; prohibit hard-coded secrets, keys, SAS tokens, and Storage or Service Bus connection strings.
- Use the existing Azure Key Vault as an ASP.NET Core configuration source while preserving local user-secrets behavior.
- Target the existing Azure App Service for Linux container host with reproducible container packaging and local validation only.

### Execution Style
- Do not modify application source files.
- Do not provision, change, or deploy Azure resources.
- Do not create infrastructure-as-code, assign Azure roles, create registries, push images, or deploy the application.
- Do not manually create `tasks.md`.
- Stop after `assessment.md` and `plan.md` are ready for review.

## Decisions
- Task 1 must target `net10.0`, use an SDK-style `Microsoft.NET.Sdk.Web` project and `PackageReference`, migrate applicable `Web.config` settings, preserve controllers, Razor views, user-visible behavior, and the EF Core model, and require build/test validation.
- Task 2 must preserve both SQL-authentication and explicitly selected managed-identity connection modes. If the local SQL secret is unavailable, runtime validation is blocked until supplied.
- Task 3 covers only mutable application-managed files and preserves validation, file types, size limits, naming, replacement cleanup, deletion, controllers, and views.
- Task 4 replaces MSMQ or `System.Messaging` behavior with Azure Service Bus while preserving notification semantics.
- Task 5 adds Azure Key Vault configuration without reinterpreting SQL authentication or adding user sign-in.
- Task 6 runs last, audits direct and transitive NuGet dependencies, remediates only detected vulnerabilities, and remains as a verified no-op when none are found.

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
**Rationale**: The assessment found one independent .NET Framework web project with no project dependencies; the user-required plan upgrades that application atomically in Task 1 before applying the workload migrations in a strict chain.

### Execution Constraints
- Treat Task 1 as one atomic application upgrade and require a clean `net10.0` build before Task 2 begins.
- Preserve the exact top-level order and dependency chain; do not split, reorder, or inject additional top-level tasks.
- Resolve package and API compatibility work within the owning task without deferred stubs or extra resolution tasks.
- Validate the full application and all available tests at Task 1 and again after Task 6.
- Do not create commits automatically.
