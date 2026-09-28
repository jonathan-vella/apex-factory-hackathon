# 01.03 configuration and DI boundary progress

## Outcome

- **Status**: ready for orchestrator review and completion
- **Decomposition**: atomic after evaluating `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`
- **Done-when review**: ASP.NET Core configuration is active; built-in DI validates; scoped `SchoolContext` and `INotificationService` both resolve during startup; the project builds and `/health` runs without implementing SQL MI policy, Blob, Service Bus, Key Vault, or telemetry.

## Wire compatibility

- Reused the scoped PASS from `../01.01-wire-contract-baseline/progress-details.md#wire-compatibility`.
- This child changes no route, endpoint, formatter, serializer, HTTP response model, or response shape.
- The notification interface preserves both send overloads, receive, and mark-read operations. The current implementation constructs successfully and throws a deterministic `NotSupportedException` only when one of those operations is invoked; task 04 owns the Service Bus implementation.

## Changes

- Added secret-free `appsettings.json` with an empty `ConnectionStrings:DefaultConnection` key and an empty `appsettings.Development.json`; added `UserSecretsId` metadata without creating or reading a secret value.
- Restored `Microsoft.EntityFrameworkCore.SqlServer` 3.1.32 and `Microsoft.Data.SqlClient` 2.1.4 exactly as the pre-upgrade data stack. Package modernization, SQL policy, and credential validation remain deferred to tasks 02 and 07.
- Included `SchoolContext`, `DbInitializer`, all model classes, and the notification contract/implementation in net10 compilation.
- Registered `SchoolContext` and `INotificationService` as scoped services. When the Development secret is absent, the context is registered without a database provider so the host and container can validate without inventing or copying a connection string.
- Enabled built-in provider validation and resolved both scoped registrations from a startup scope without performing database or messaging operations.
- Removed the `SchoolContextFactory` API and its `ConfigurationManager` access. Physical file deletion was recreated by the workspace twice, so the tracked file now contains only its namespace and no factory type.
- Removed `EnsureCreated` from `DbInitializer` and disambiguated its EF query with `Queryable.SingleOrDefault` for .NET 10 compilation.
- Replaced direct MSMQ/configuration/Debug behavior in `NotificationService` with the compile-safe task-04 boundary. No `System.Messaging`, broker package, cloud setting, telemetry, or `// STUB:` marker was added.

## Files modified

- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.03-configuration-di-boundaries/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.03-configuration-di-boundaries/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`
- `app/ContosoUniversity/appsettings.json`
- `app/ContosoUniversity/appsettings.Development.json`
- `app/ContosoUniversity/Data/DbInitializer.cs`
- `app/ContosoUniversity/Data/SchoolContextFactory.cs`
- `app/ContosoUniversity/Services/INotificationService.cs`
- `app/ContosoUniversity/Services/NotificationService.cs`

## Validation

- `dotnet restore app/ContosoUniversity/ContosoUniversity.csproj` succeeded.
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore` succeeded with 0 errors and 4 package-audit warnings.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln --no-restore` succeeded with 0 errors and the same 4 package-audit warnings.
- Development `dotnet run --no-build --no-launch-profile --urls http://127.0.0.1:5088` started successfully with no user-secrets file present. Startup resolution proved both scoped registrations construct.
- `GET /health` returned HTTP 200 with body `ok`; the host was then stopped.
- Test-project discovery returned an empty list, so no applicable .NET tests were available to run.
- Boundary scan found no `System.Messaging`, `ConfigurationManager`, `EnsureCreated`, `Database.Migrate`, `// STUB:`, Service Bus, Key Vault, OpenTelemetry, or Azure Identity references in the scoped configuration/data/model/service source.
- Configuration validation confirmed the committed `DefaultConnection` key exists and is empty. No configuration or secret value was printed or copied.
- `SchoolContext` still has all nine `DbSet` declarations and its mappings were unchanged.
- VS Code source diagnostics reported no errors. `git diff --check` reported no whitespace errors.

## Warnings and blockers

- NuGet reports four advisories from the deliberately retained EF Core 3.1/SqlClient dependency graph: direct `Microsoft.Data.SqlClient` 2.1.4 plus transitive `Microsoft.IdentityModel.JsonWebTokens` 6.8.0, `System.IdentityModel.Tokens.Jwt` 6.8.0, and `System.Drawing.Common` 4.7.0. They cannot be cleared in this child without violating the explicit task-02/task-07 package boundaries; no warning was suppressed.
- The Development SQL user-secrets file is absent. This does not block `/health` or DI validation, but it remains the expected blocker for later database-backed page validation.
- Home, Students, Courses, Instructors, and Departments remain excluded until their approved sibling migration tasks, so this child correctly validates only the host/container and `/health` boundary.