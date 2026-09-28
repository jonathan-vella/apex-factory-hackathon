# 01.12 Cleanup and container validation progress

## Outcome

- **Status**: ready for orchestrator review and completion.
- **Done-when review**: the net10.0 project restores and builds with zero errors; the one-project solution builds; no .NET test project exists; SDK container publishing produced and validated a local archive without Docker, push, registry publication, or deployment; Home, notification routes, and static assets pass live probes; the four database-backed index pages have only the required missing Development SQL secret blocker.
- **Workflow boundary**: no task 02-07 implementation or Azure resource action was started. Existing database, mutable-file, messaging, logging, and package-audit code remains for its approved top-level task.

## Decomposition

- Evaluated `dotnet-version-upgrade/execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: **atomic**. This child integrates and validates one dependency-free project after controller, configuration, and Razor/static work were already isolated into completed siblings. Task 04 still owns messaging replacement; no stub, multi-project, authentication, package-research, or unresolved controller-unit trigger applies.

## Changes

- Removed all temporary `Compile`, `Content`, `None`, and `RazorGenerate` exclusion/re-inclusion machinery. Normal SDK defaults now include the complete application.
- Added SDK container metadata: base image `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, exposed port `8080/tcp`, and `ASPNETCORE_HTTP_PORTS=8080`.
- Added production exception handling through `/Home/Error`, preserving the retired global `HandleErrorAttribute` behavior without exposing exception details.
- Removed the remaining ASP.NET Framework host/build artifacts after documenting all 22 binding redirects in `task.md`.

## Files modified

- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.12-cleanup-container-validation/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.12-cleanup-container-validation/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`

## Files deleted

- `app/ContosoUniversity/App_Start/FilterConfig.cs`
- `app/ContosoUniversity/App_Start/RouteConfig.cs`
- `app/ContosoUniversity/Properties/AssemblyInfo.cs`
- `app/ContosoUniversity/Web.config`

Previously deleted `Global.asax`, `Global.asax.cs`, `App_Start/BundleConfig.cs`, `Views/Web.config`, `packages.config`, root `Content`, and root `Scripts` remain deleted. No Dockerfile or Docker-related file was added.

## Binding redirects

- The complete 22-entry redirect inventory, including old ranges and target versions, is preserved in `task.md` before removal of `Web.config`.
- The six assessment conflicts and possible forced downgrades are explicitly retained there: `Newtonsoft.Json`, `System.Threading.Tasks.Extensions`, `System.ComponentModel.Annotations`, `System.Runtime.CompilerServices.Unsafe`, `System.Memory`, and `Microsoft.Data.SqlClient`.

## Build and test validation

- `dotnet --version`: `10.0.401`.
- `dotnet restore app/ContosoUniversity/ContosoUniversity.csproj --verbosity minimal`: succeeded, 0 errors, 4 unique package advisory warnings.
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --configuration Release --no-restore --verbosity minimal`: succeeded, 0 errors, the same 4 warnings; output `bin/Release/net10.0/ContosoUniversity.dll`.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln --configuration Release --no-restore --verbosity minimal`: succeeded, 0 errors, the same 4 warnings.
- The first two focused Debug build attempts failed with the same 10 errors because two `apply_patch` deletion attempts reported success but left `FilterConfig.cs`, `RouteConfig.cs`, and `AssemblyInfo.cs` physically present. The exact four scoped files were then removed with `Remove-Item`; the repeated focused build succeeded with 0 errors. No production-code workaround or exclusion was added.
- The modernization test discovery tool returned `[]`. Repository scans found no other `.csproj`, test SDK, MSTest, xUnit, NUnit, TUnit, `global.json`, `Directory.Build.props`, or `Directory.Packages.props`; therefore no applicable .NET test command existed and test execution is a recorded no-op.
- VS Code diagnostics report no `Program.cs` errors. Project diagnostics report only the four package advisories below.

## Container validation

- Command: `dotnet publish app/ContosoUniversity/ContosoUniversity.csproj --configuration Release --no-restore /t:PublishContainer -p:ContainerArchiveOutputPath="$env:TEMP\contoso-university-task01.tar.gz" -p:ContainerImageTag=task-01-validation --verbosity minimal`.
- Result: succeeded in 7.9 seconds, 0 errors, the same 4 warnings. The non-empty `ContainerArchiveOutputPath` used the SDK's archive path and skipped local-registry publication; Docker was not invoked.
- Archive size: 101,992,448 bytes. Validated metadata: repository/tag `contoso-university:task-01-validation`, base image `mcr.microsoft.com/dotnet/aspnet:10.0`, exposed port `8080/tcp`, environment `ASPNETCORE_HTTP_PORTS=8080`, entry point `dotnet /app/ContosoUniversity.dll`.
- The application layer contains `ContosoUniversity.dll`, notification/site CSS, notification JavaScript, and their compressed static-web-asset variants.
- The temporary archive was removed after inspection. Nothing was pushed, deployed, or written to an Azure resource.

## Inclusion and contract validation

- Evaluated SDK items contain exactly 7 controller files by name: `BaseController`, `CoursesController`, `DepartmentsController`, `HomeController`, `InstructorsController`, `NotificationsController`, and `StudentsController`.
- Evaluated items contain 28 Razor views and 21 static assets. Notification CSS and JavaScript are included. Normal SDK defaults, not explicit project re-inclusions, provide the items.
- Source checks found 12 `[ValidateAntiForgeryToken]` attributes, 0 `// STUB:` markers, 0 controller references to `SchoolContextFactory`, and 0 legacy `System.Web`/MVC/WebPages/Optimization references outside generated output.
- Package listing contains only `Microsoft.Data.SqlClient` and `Microsoft.EntityFrameworkCore.SqlServer` as direct references. No old MVC, Razor, WebPages, Optimization, WebGrease, or Antlr package remains.
- No OData/Atom, System.Web adapter, Azure Blob, Azure Service Bus, Key Vault, OpenTelemetry/Azure Monitor, or `DefaultAzureCredential` implementation was introduced.
- The default route remains `{controller=Home}/{action=Index}/{id?}`. Production `/Students` failure returned the shared HTML error page with status 500 and did not expose `InvalidOperationException` or provider details, proving exception-handler routing to `Home/Error`.
- `git diff --check` passed. Git emitted only the existing CRLF-to-LF notice for the project file.

## Live HTTP probes

The Release app ran via `dotnet run` on explicit localhost URLs with no launch profile.

| Probe | Result |
| --- | --- |
| `GET /` | 200, HTML |
| `GET /Students` | 500, blocked by missing Development SQL secret/provider |
| `GET /Courses` | 500, blocked by missing Development SQL secret/provider |
| `GET /Instructors` | 500, blocked by missing Development SQL secret/provider |
| `GET /Departments` | 500, blocked by missing Development SQL secret/provider |
| `GET /Notifications` | 200, HTML |
| `GET /Notifications/GetNotifications` | 200, `application/json`, exact body `{"success":false,"message":"Error retrieving notifications"}` |
| `POST /Notifications/MarkAsRead?id=42` | 200, `application/json`, exact body `{"success":false,"message":"Error updating notification"}` |
| `GET /css/site.css` | 200, `text/css` |
| `GET /css/notifications.css` | 200, `text/css` |
| `GET /js/notifications.js` | 200, `text/javascript` |

The notification error envelopes are the expected task-04 deferred-service behavior. Prior deterministic success-contract evidence in `../01.11-notifications-controller/progress-details.md` remains current; no serializer, route, consumer, or response-model setting changed.

## Warnings and blocker

Four unique NuGet advisory warnings remain and were neither suppressed nor remediated because top-level task 07 owns dependency CVE decisions:

- `NU1903`: direct `Microsoft.Data.SqlClient` 2.1.4, high severity, GHSA-98g6-xh36-x2p7.
- `NU1902`: transitive `Microsoft.IdentityModel.JsonWebTokens` 6.8.0, moderate severity, GHSA-59j7-ghrg-fj52.
- `NU1902`: transitive `System.IdentityModel.Tokens.Jwt` 6.8.0, moderate severity, GHSA-59j7-ghrg-fj52.
- `NU1904`: transitive `System.Drawing.Common` 4.7.0, critical severity, GHSA-rxg9-xrhp-64gj.

`dotnet user-secrets list --project app/ContosoUniversity/ContosoUniversity.csproj` returned exactly `No secrets configured for this application.` Because the Development `ConnectionStrings:DefaultConnection` SQL user secret is absent, Students, Courses, Instructors, and Departments runtime/page validation is blocked until that secret is supplied. Their exact runtime result is HTTP 500 with `System.InvalidOperationException: No database provider has been configured for this DbContext.` No connection string was added and no on-premises or Azure system was changed.
