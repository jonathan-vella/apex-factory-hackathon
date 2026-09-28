# Progress details

## 2026-09-28 execution

### Outcome

- Migrated `StudentsController` from System.Web MVC to ASP.NET Core MVC with constructor-injected `SchoolContext` and `INotificationService`.
- Preserved all eight actions, conventional action names/routes, null-ID 400 results, Edit/Delete missing-row 404 helpers, the recorded Details `Single()` missing-row behavior, redirects, validation messages, and notification dispatch calls.
- Preserved the Index sort/search/current-filter/page behavior and ten-row pagination. `PaginatedList<T>` was included in the SDK project without source changes.
- Replaced legacy bind include syntax with the same Core binding allowlists for Create and Edit.
- Migrated all five Students Razor views to Tag Helpers. GET search/sort/pagination query names and values remain intact; POST forms retain their action targets and emit anti-forgery fields. Create/Edit retain client validation through the relocated local scripts.
- Included the Students controller, pagination helper, and feature views in the SDK project. No SQL, EF/package modernization, Service Bus, telemetry, global error middleware, or later top-level implementation was added.

### Files modified

- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.07-students-controller/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.07-students-controller/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Controllers/StudentsController.cs`
- `app/ContosoUniversity/Views/Students/Create.cshtml`
- `app/ContosoUniversity/Views/Students/Delete.cshtml`
- `app/ContosoUniversity/Views/Students/Details.cshtml`
- `app/ContosoUniversity/Views/Students/Edit.cshtml`
- `app/ContosoUniversity/Views/Students/Index.cshtml`

`app/ContosoUniversity/PaginatedList.cs` was inspected and included but not modified.

### Validation

- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore`: succeeded with 0 errors and 4 pre-existing NuGet vulnerability warnings.
- No matching .NET test project exists, so no .NET tests were available to run.
- Development host started successfully at `http://127.0.0.1:5187` and stopped after focused probes.
- Runtime results: `/health` 200; `GET /Students/Create` 200; `GET /Students/Details`, `/Students/Edit`, and `/Students/Delete` without IDs each returned 400.
- The rendered Create HTML used `/Students/Create`, contained `__RequestVerificationToken`, and loaded both local validation scripts. A Create POST without an anti-forgery cookie/token returned 400 before action execution.
- Static acceptance checks found all eight `IActionResult` actions and the unchanged current-sort, name/date sort, search reset/current-filter, first/last-name filtering, and page-size/page-number logic.
- Scoped legacy search found no `System.Web`, `HttpStatusCodeResult`, `HttpNotFound`, `Bind(Include`, `Html.ActionLink`, `Html.BeginForm`, `Scripts.Render`, or `Styles.Render` in the Students controller/views.
- `git diff --check` passed for all scoped source and workflow artifacts; Git emitted only the existing CRLF-to-LF notice for the project file.

### Warnings

- `NU1903`: direct `Microsoft.Data.SqlClient` 2.1.4 has a known high-severity vulnerability.
- `NU1902`: transitive `Microsoft.IdentityModel.JsonWebTokens` 6.8.0 has a known moderate-severity vulnerability.
- `NU1904`: transitive `System.Drawing.Common` 4.7.0 has a known critical-severity vulnerability.
- `NU1902`: transitive `System.IdentityModel.Tokens.Jwt` 6.8.0 has a known moderate-severity vulnerability.
- These warnings predate this child and are assigned to the later approved package/EF/CVE work. They were neither suppressed nor changed here because doing so would execute later top-level concerns.

### Runtime blocker

- `dotnet user-secrets list --project app/ContosoUniversity/ContosoUniversity.csproj` reported `No secrets configured for this application.`
- Database-backed runtime checks for Students Index pagination/search/sort, found/missing-row queries, and successful Create/Edit/Delete operations are blocked until `ConnectionStrings:DefaultConnection` is supplied through Development user secrets. No database or secret was created or changed.

## Wire Compatibility

- **Decision:** PASS, reusing the host baseline in `../01.01-wire-contract-baseline/progress-details.md`.
- This feature has conventional Razor HTML actions only and adds no OData, Atom, JSON/XML response, formatter, serializer, custom header, auth requirement, or externally pinned response shape.

### Decomposition

Atomic after evaluating `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`. The parent already isolated this single controller-owned feature; no additional hint or dependency required a split.