# 01.02 SDK host progress

## Outcome

- **Status**: ready for orchestrator completion
- **Wire-contract prerequisite**: scoped PASS reused from `../01.01-wire-contract-baseline/progress-details.md#wire-compatibility`; no endpoint or serializer source was changed by this child
- **Decomposition**: atomic after evaluating `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`

## Changes

- Ran the dedicated SDK conversion tool against the sole project in dependency order.
- Converted `ContosoUniversity.csproj` to `Microsoft.NET.Sdk.Web`, retargeted it from `net48` to `net10.0`, and removed legacy assembly/package references, WebApplication imports, SNI copy targets, and all NuGet package dependencies from the minimal host.
- Added explicit project exclusions for legacy App_Start, controllers, data, models, services, Razor views, `PaginatedList.cs`, `AssemblyInfo.cs`, `Global.asax`, and Web.config files. These application files remain on disk for their approved migration children except the obsolete tracked `Global.asax`, `Global.asax.cs`, and `packages.config`, which were removed.
- Added `Program.cs` with a minimal `WebApplication` and `GET /health` returning `ok`.
- Updated the solution project type GUID for the SDK-style C# project.
- Preserved the 22-redirect inventory in `task.md`, including the six mandatory conflicts and six possible downgrades, before excluding legacy binding configuration from the Core host.
- No EF/SQL, MSMQ/Service Bus, Blob, Key Vault, telemetry, authentication, or CVE-remediation implementation was introduced.

## Conversion checkpoint

- The initial converted net48 build exposed converter omissions: a stale direct `System.Runtime.CompilerServices.Unsafe 4.5.3` downgrade, missing System.Web/Optimization references, incorrect executable output type, and an obsolete packages.config-era SNI copy target.
- Applied minimal format-only repairs and reran `dotnet build app/ContosoUniversity/ContosoUniversity.csproj`; the net48 project compiled successfully. Its only remaining warning was `NU1903` for `Microsoft.Data.SqlClient 2.1.4`, already assigned to the later approved vulnerability work and removed from this package-free minimal host.
- The conversion tool preserved a review exclusion for `Services/LoggingService.cs`; the final host supersedes it with the explicit `Services/**/*.cs` deferred-slice exclusion.

## Final validation

- `dotnet restore app/ContosoUniversity/ContosoUniversity.csproj` — succeeded.
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj` — succeeded with 0 errors and 0 warnings; output is `bin/Debug/net10.0/ContosoUniversity.dll`.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln` — succeeded with 0 errors and 0 warnings.
- `dotnet run --project app/ContosoUniversity/ContosoUniversity.csproj --no-build --urls http://127.0.0.1:5087` — host started in Production and listened on the requested URL.
- `Invoke-WebRequest -Uri 'http://127.0.0.1:5087/health' -UseBasicParsing` — returned `StatusCode=200 Body=ok`; the host log recorded HTTP 200 and was then stopped.
- `dotnet list app/ContosoUniversity/ContosoUniversity.csproj package` — reported no packages for `net10.0`.
- Test-project discovery returned an empty list, so no .NET tests were available to run.
- VS Code diagnostics reported no errors for the project, solution, source, task, or breakdown files.
- `git diff --check` found no whitespace errors; Git emitted only a line-ending notice for the converted project file.

## Warnings and blockers

- **Final warnings**: 0.
- **Blockers**: none for this child.
- The Development SQL secret still blocks database-backed page validation, but this minimal host intentionally exposes only `/health`; page and DI validation belongs to subsequent approved children.