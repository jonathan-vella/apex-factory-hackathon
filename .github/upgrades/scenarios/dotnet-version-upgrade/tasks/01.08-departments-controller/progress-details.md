# 01.08 Departments controller progress

## Outcome

- **Status**: implementation complete; build succeeds
- **Scope**: `DepartmentsController`, five department Razor views, and the project feature include only
- **Wire gate**: scoped PASS reused from `01.01-wire-contract-baseline`; no OData or serialized response surface is affected

## Changes

- Migrated `DepartmentsController` from `System.Web.Mvc` to ASP.NET Core MVC, added constructor injection for `SchoolContext` and `INotificationService`, and retained all eight conventional actions.
- Preserved null-id 400 responses, missing-row 404 responses, successful redirects, invalid-model view responses, POST action naming, and anti-forgery validation.
- Retained explicit Create/Edit binding allowlists and notification calls through the existing `INotificationService` boundary.
- Preserved optimistic concurrency diagnostics and administrator-list repopulation. After a conflict, the current database `RowVersion` now replaces the stale model-state value so the hidden field posts the refreshed token on a retry.
- Converted all five department views to ASP.NET Core Tag Helpers while preserving visible labels, values, links, validation output, administrator placeholder text, and delete confirmation output.
- Added the Departments controller and Razor views to the SDK project feature includes. No SQL MI, Service Bus, telemetry, package-version, model, or database-policy change was made.

## Validation

- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore`: **succeeded**, 0 compile errors, 0 C#/Razor warnings, and 4 pre-existing NuGet audit warnings.
- NuGet warnings: `NU1903` for `Microsoft.Data.SqlClient` 2.1.4; `NU1902` for `Microsoft.IdentityModel.JsonWebTokens` 6.8.0; `NU1904` for `System.Drawing.Common` 4.7.0; and `NU1902` for `System.IdentityModel.Tokens.Jwt` 6.8.0.
- These advisories are intentionally not suppressed or remediated in this child because package CVE remediation is explicitly owned by later top-level task 07.
- VS Code diagnostics: 0 errors in `DepartmentsController`; project diagnostics contain only the four NuGet advisories above.
- Legacy API scan: no `System.Web`, `HttpStatusCodeResult`, `HttpNotFound`, `Bind(Include`, `Scripts.Render`, `Html.BeginForm`, or `Html.ActionLink` remains in the Departments slice.
- Contract scan confirmed three POST actions with anti-forgery validation, the `Delete` action alias, administrator select binding in Create/Edit, and `RowVersion` hidden fields plus model-state refresh.
- `git diff --check` passed; Git emitted only a line-ending notice for the existing project file.
- No .NET test project exists in the repository, so no automated .NET tests were available.

## Runtime

- The Development user-secret check reported that `ConnectionStrings:DefaultConnection` is absent.
- `dotnet run --no-build` started successfully at `http://127.0.0.1:5098`; `GET /health` returned **200** with `ok`.
- `GET /Departments/Index` matched and invoked `DepartmentsController.Index`, then returned **500** because EF Core reported: `No database provider has been configured for this DbContext.` This is the expected precise blocker while the required Development SQL secret is missing.
- Database-backed page rendering, CRUD, administrator selection, anti-forgery submission, and live concurrency-conflict behavior could not be exercised without that secret. The temporary host was stopped after validation.

## Decomposition

- Evaluated `dotnet-version-upgrade/execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md` before source edits.
- Verdict: **atomic**. The parent already isolated one controller and its five views, and no additional decomposition trigger matched.

## Files modified

- `app/ContosoUniversity/Controllers/DepartmentsController.cs`
- `app/ContosoUniversity/Views/Departments/Create.cshtml`
- `app/ContosoUniversity/Views/Departments/Delete.cshtml`
- `app/ContosoUniversity/Views/Departments/Details.cshtml`
- `app/ContosoUniversity/Views/Departments/Edit.cshtml`
- `app/ContosoUniversity/Views/Departments/Index.cshtml`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.08-departments-controller/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.08-departments-controller/progress-details.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`