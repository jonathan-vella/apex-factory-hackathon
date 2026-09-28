# 01.12-cleanup-container-validation: Remove legacy host remnants and validate build, pages, and SDK container publishing

# 01.12 Cleanup and end-to-end task-01 validation

## Objective
Finish the in-place migration, remove temporary compile exclusions and legacy web-host remnants, configure SDK container publishing, and run the complete task-01 validation gate.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Prerequisite
All seven controller subtasks and shared Razor/static work are complete.

## Scope
- Entire `app/ContosoUniversity` project for cleanup/verification only
- Project container-publish properties and workflow evidence

## Steps
1. Include all migrated source/views through normal SDK defaults; remove temporary exclusions and obsolete `Global.asax`, App_Start route/filter/bundle code, Views/Web.config, packages.config, legacy transforms/imports, and remaining System.Web references. Preserve the binding-redirect inventory in workflow evidence.
2. Confirm no `// STUB:` markers, System.Web adapters, old MVC/Optimization/WebPages packages, direct `SchoolContextFactory` controller use, or accidental implementations of tasks 02-07 remain. Record new warnings without blocking; require zero build errors.
3. Add .NET SDK container publishing properties for base image `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, and the application listening port. Do not add a Dockerfile, require Docker, push, deploy, or alter Azure resources.
4. Restore and build; discover/run applicable tests and record the absence of a matching .NET test project as a no-op. Run `dotnet publish /t:PublishContainer` in the non-push validation mode supported by the SDK and verify the project properties/readiness.
5. Run the app and verify Home, Students, Courses, Instructors, and Departments pages. If `ConnectionStrings:DefaultConnection` is absent from Development user secrets, record only runtime/page validation as blocked until supplied; do not waive it or change on-premises/Azure systems.
6. Recheck the wire baseline, notification JSON contract, anti-forgery, default route, global error handling, and static assets.
7. Stop after task 01 evidence is complete. Do not start, alter, or execute task 02 or any later top-level task.

## Done when
The in-place net10.0 ASP.NET Core MVC project restores/builds with no errors, all available tests pass or are recorded unavailable, container publish readiness is validated without Docker/push/deployment, required pages pass or have the single explicit missing-secret blocker, and the workflow stops before task 02.

## Research and execution reference

### Verified scope and current state
- The solution contains one SDK-style `Microsoft.NET.Sdk.Web` project targeting `net10.0`, with no project references or dependants. Installed SDK `10.0.401` is the correct build and container-publish tool.
- All seven controller files are present: `BaseController`, `HomeController`, `StudentsController`, `CoursesController`, `InstructorsController`, `DepartmentsController`, and `NotificationsController`. All Home, Students, Courses, Instructors, Departments, Notifications, and Shared Razor files are present, along with `_ViewImports.cshtml` and `_ViewStart.cshtml`.
- `wwwroot` contains the migrated CSS and JavaScript, including `css/bootstrap.min.css`, `css/site.css`, `css/notifications.css`, `js/jquery-3.4.1.min.js`, `js/bootstrap.min.js`, `js/respond.min.js`, `js/modernizr-2.6.2.js`, validation scripts, and `js/notifications.js`. `_Layout.cshtml` references these assets with matching case.
- Temporary project exclusions still remove all controllers, data, models, services, feature views, and legacy host files, then explicitly re-include migrated slices. Cleanup must remove that temporary item machinery so normal SDK defaults include the completed application.
- Legacy source remnants still on disk are `App_Start/FilterConfig.cs`, `App_Start/RouteConfig.cs`, root `Web.config`, and SDK-redundant `Properties/AssemblyInfo.cs`. `Global.asax`, `Global.asax.cs`, `App_Start/BundleConfig.cs`, `Views/Web.config`, `packages.config`, root `Content`, and root `Scripts` are already recorded as deleted by prior children and must remain deleted.
- No `// STUB:` marker, controller use of `SchoolContextFactory`, OData/Atom code, System.Web adapter, Dockerfile, container metadata, Azure SDK implementation, Service Bus, Blob Storage, Key Vault, or OpenTelemetry implementation is present. Existing direct `Trace`/`Debug` calls remain owned by task 06 and are not expanded here.
- `Program.cs` already has static-file middleware, the default `{controller=Home}/{action=Index}/{id?}` route, `/health`, and DI validation. It needs production exception handling equivalent to the retired global `HandleErrorAttribute`.
- The wire-contract PASS remains current in `../01.01-wire-contract-baseline/progress-details.md#wire-compatibility`; the notification contract was revalidated in `../01.11-notifications-controller/progress-details.md#wire-compatibility`. No endpoint consumer, serializer setting, route, or response-model evidence has changed.
- Test-project discovery returned an empty set. There is no `global.json`, `Directory.Build.props`, `Directory.Packages.props`, or .NET test package signal in the repository.
- `dotnet user-secrets list --project app/ContosoUniversity/ContosoUniversity.csproj` returned exactly `No secrets configured for this application.` The Development `ConnectionStrings:DefaultConnection` SQL user secret is therefore absent; database-backed page probes must record this blocker without adding a connection string or changing SQL infrastructure.

### Binding redirects documented before removal
The retired root `Web.config` contains these 22 redirects; SDK-style .NET 10 does not reproduce them:

| Assembly | Old range | New version |
| --- | --- | --- |
| Microsoft.Web.Infrastructure | 0.0.0.0-2.0.1.0 | 2.0.1.0 |
| Antlr3.Runtime | 0.0.0.0-3.4.1.9004 | 3.4.1.9004 |
| Newtonsoft.Json | 0.0.0.0-13.0.0.0 | 13.0.0.0 |
| System.Web.Optimization | 1.0.0.0-1.1.0.0 | 1.1.0.0 |
| WebGrease | 0.0.0.0-1.5.2.14234 | 1.5.2.14234 |
| System.Web.Helpers | 1.0.0.0-3.0.0.0 | 3.0.0.0 |
| System.Web.WebPages | 1.0.0.0-3.0.0.0 | 3.0.0.0 |
| System.Web.Mvc | 1.0.0.0-5.2.9.0 | 5.2.9.0 |
| System.Threading.Tasks.Extensions | 0.0.0.0-4.2.0.1 | 4.2.0.1 |
| Microsoft.Extensions.DependencyInjection.Abstractions | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| Microsoft.Extensions.DependencyInjection | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| Microsoft.EntityFrameworkCore.Abstractions | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| Microsoft.Extensions.Caching.Abstractions | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| Microsoft.Extensions.Configuration.Abstractions | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| Microsoft.Extensions.Logging.Abstractions | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| Microsoft.Extensions.Options | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| Microsoft.Extensions.Primitives | 0.0.0.0-3.1.32.0 | 3.1.32.0 |
| System.ComponentModel.Annotations | 0.0.0.0-4.2.1.0 | 4.2.1.0 |
| System.Runtime.CompilerServices.Unsafe | 0.0.0.0-4.0.6.0 | 4.0.6.0 |
| System.Memory | 0.0.0.0-4.0.1.1 | 4.0.1.1 |
| Microsoft.Data.SqlClient | 0.0.0.0-2.0.20168.4 | 2.0.20168.4 |
| netstandard | 0.0.0.0-2.0.0.0 | 2.0.0.0 |

Assessment conflicts/downgrades are retained explicitly for `Newtonsoft.Json`, `System.Threading.Tasks.Extensions`, `System.ComponentModel.Annotations`, `System.Runtime.CompilerServices.Unsafe`, `System.Memory`, and `Microsoft.Data.SqlClient`.

### Container and validation plan
- Configure `ContainerBaseImage` as `mcr.microsoft.com/dotnet/aspnet:10.0` and `ContainerRepository` as `contoso-university`.
- Configure `ContainerPort` item `8080` and `ContainerEnvironmentVariable` `ASPNETCORE_HTTP_PORTS=8080`, so image metadata and Kestrel listening configuration agree.
- Validate with `dotnet publish ... /t:PublishContainer /p:ContainerArchiveOutputPath=...`; installed SDK targets confirm a non-empty archive path skips local-registry publication, so this creates a local OCI archive without Docker, push, registry publication, or deployment.
- Run explicit restore, project build, solution build, applicable-test discovery, container archive publication, artifact inspection, source/contract scans, and local HTTP probes for Home, Students, Courses, Instructors, and Departments. Also probe notification routes and static assets where database access is not required.
- Existing package advisory warnings are owned by top-level task 07. Record them exactly and do not suppress or remediate them in this child; require zero build errors and no new warnings.

## Decomposition verdict
- Evaluated `dotnet-version-upgrade/execution.md` and breakdown hints `common.md`, `framework-migration.md`, and `framework-web-migration.md`.
- **Atomic**: this is the final integration cleanup/validation of one dependency-free project. Controller units, configuration/DI, Razor/static assets, and wire contracts are completed sibling children; MSMQ replacement remains isolated in task 04. No stub, multi-project, authentication, package-replacement research, or unresolved migration-unit trigger applies.
