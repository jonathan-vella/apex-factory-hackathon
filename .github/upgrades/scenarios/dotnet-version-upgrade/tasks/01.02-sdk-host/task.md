# 01.02-sdk-host: Convert the project to SDK-style net10.0 and establish a minimal Core host

# 01.02 SDK project conversion and minimal ASP.NET Core host

## Objective
Convert the single classic WAP in place to `Microsoft.NET.Sdk.Web` and `net10.0`, then establish the smallest buildable/runnable ASP.NET Core host before feature migration.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata
- #skill:converting-to-sdk-style
- #skill:managing-target-frameworks
- #skill:building-projects

## Prerequisite
`01.01-wire-contract-baseline` completed with the scoped PASS still valid.

## Scope
- `app/ContosoUniversity/ContosoUniversity.csproj` and solution reference
- `packages.config`, `Global.asax`, `Global.asax.cs`, and a new `Program.cs`
- Package/reference cleanup owned by task 01 only

## Steps
1. Use the sequential SDK-style conversion workflow for `ContosoUniversity.csproj`; preserve a reviewable inventory of all 22 binding redirects, including the six mandatory conflicts and six possible downgrades, before removing legacy binding machinery.
2. Replace the project with `Microsoft.NET.Sdk.Web`, set `TargetFramework` to `net10.0`, migrate required dependencies to `PackageReference`, and remove WebApplication/System.Web imports, explicit framework references, SNI copy targets, `packages.config`, and framework-provided MVC/Razor/WebPages/CodeDom/BCL packages. Remove obsolete Optimization/WebGrease/Antlr dependencies rather than replacing Antlr when its only consumer disappears. Remove unused `Microsoft.Identity.Client`; do not add Entra sign-in.
3. Keep EF/SQL implementation and version-policy work owned by task 02, MSMQ replacement by task 04, telemetry packages by task 06, and the final vulnerability decision by task 07. Do not silently perform those migrations here.
4. Add a minimal `Program.cs` host and `/health` endpoint. Temporarily exclude not-yet-migrated legacy controllers/views/services from target compilation with explicit, reviewable project items; do not delete them.
5. Build, run, and verify `/health` returns 200 before feature work.

## Done when
The IDE loads an SDK-style `Microsoft.NET.Sdk.Web` project targeting `net10.0`; restore/build succeeds for the minimal host and `/health` returns 200. The wire PASS remains linked, and no task 02-07 implementation has been introduced.

## Research and execution reference

### Verified scope and dependencies
- The solution contains one project, `app/ContosoUniversity/ContosoUniversity.csproj`, with no project references or dependants. The project ordering tool returns only this project, so conversion is sequential and atomic.
- The current project is a classic WAP targeting .NET Framework 4.8 with `Microsoft.WebApplication.targets`, explicit compile/content/reference items, `packages.config`, and a custom SQL Client SNI copy target. No `Directory.Build.props`, `Directory.Build.targets`, `.resx`, XAML, T4, or stub markers affect this child.
- The installed SDK is .NET SDK `10.0.401`, with `Microsoft.AspNetCore.App 10.0.12` available. The target framework is defined in the project rather than an imported shared properties file.
- The scoped wire-contract gate is **PASS**, recorded in [the 01.01 progress record](../01.01-wire-contract-baseline/progress-details.md#wire-compatibility). The protected notification JSON actions remain excluded legacy source in this child; their contract is unchanged and will be migrated by `01.11-notifications-controller`.

### Assessment findings owned by this child
- The assessment reports 157 findings for the project: 94 mandatory, 58 potential, and 5 optional. Relevant findings here are SDK conversion, retargeting, removal of framework-provided packages, unsupported System.Web host machinery, and replacement of `Global.asax` startup with a minimal Core entry point.
- `Web.config` contains 22 binding redirects. The six mandatory conflicts are `Newtonsoft.Json`, `System.Threading.Tasks.Extensions`, `System.ComponentModel.Annotations`, `System.Runtime.CompilerServices.Unsafe`, `System.Memory`, and `Microsoft.Data.SqlClient`; the same six are the possible forced downgrades. This inventory is retained here before legacy binding machinery is removed from the build.
- Remove framework-provided or legacy-host-only packages/references: `Microsoft.AspNet.Mvc`, `Microsoft.AspNet.Razor`, `Microsoft.AspNet.WebPages`, `Microsoft.Web.Infrastructure`, `Microsoft.CodeDom.Providers.DotNetCompilerPlatform`, `NETStandard.Library`, BCL compatibility packages, `Microsoft.AspNet.Web.Optimization`, `WebGrease`, and `Antlr`. Remove unused `Microsoft.Identity.Client`; do not add sign-in.
- Preserve EF/SQL, MSMQ, configuration, mutable-file, telemetry, and CVE implementation files on disk but exclude all not-yet-migrated legacy C# and Razor from this minimal host build. Tasks `01.03` through `01.11` will re-include migrated application slices; tasks 02-07 retain their approved technology ownership.
- No test project exists for this solution. This child validates restore/build plus a live HTTP 200 response from `/health`; application page validation remains deferred until the relevant controllers/views are migrated.

### Execution order and validation
1. Run the dedicated SDK conversion tool against the sole project and solution without changing the target framework.
2. Build the converted project on its original framework and confirm `packages.config` is removed.
3. Retarget the converted project to `Microsoft.NET.Sdk.Web` and `net10.0`, reduce package/reference state to the minimal host, explicitly exclude legacy source/views, remove `Global.asax` build artifacts, and add `Program.cs` with `MapGet("/health", () => "ok")`.
4. Run `dotnet restore app/ContosoUniversity/ContosoUniversity.csproj`, `dotnet build app/ContosoUniversity/ContosoUniversity.csproj`, and `dotnet build app/ContosoUniversity/ContosoUniversity.sln`; require 0 errors and 0 warnings.
5. Run the project on an explicit localhost URL and request `/health`; require HTTP 200 and body `ok`.

## Decomposition verdict
- Evaluated `dotnet-version-upgrade/execution.md` and breakdown hints `common.md`, `framework-migration.md`, and `framework-web-migration.md`.
- **Atomic**: this child covers one dependency-free project and one ordered conversion/retarget/minimal-host gate. Controller, configuration, static asset, EF/SQL, MSMQ, authentication, and telemetry concerns are already isolated into sibling or later approved tasks. No stub, multi-project, package-replacement-research, or Windows API hint triggers another split.
