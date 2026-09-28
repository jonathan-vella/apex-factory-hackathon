# Progress details

## 2026-09-28 execution

### Outcome
- Migrated all eight `InstructorsController` actions to ASP.NET Core MVC with constructor injection, `IActionResult`, Core status helpers, Core binding syntax, and `TryUpdateModelAsync`.
- Preserved instructor eager loading, course assignment add/remove behavior, blank office assignment removal, department administrator clearing on delete, conventional routes, notification calls, redirects, and `400`/`404` semantics.
- Migrated all five instructor Razor views to Tag Helpers while preserving visible labels/tables/actions, `selectedCourses` checkbox names and values, master/detail route values, POST anti-forgery generation, and validation scripts.
- Added only the instructor controller and views to the SDK project feature boundary. No SQL, EF mapping, messaging, telemetry, authentication, deployment, or later top-level concern was implemented.

### Wire compatibility
- Decision: **NOT APPLICABLE** for serialized wire contracts; this slice contains conventional MVC HTML views, redirects, and status results only.
- No OData, Atom, raw JSON/XML, custom formatter/serializer, custom response header, authorization rule, or externally pinned response shape is present.
- The parent host wire-compatibility PASS remains unchanged.

### Files modified
- `app/ContosoUniversity/Controllers/InstructorsController.cs`
- `app/ContosoUniversity/Views/Instructors/Create.cshtml`
- `app/ContosoUniversity/Views/Instructors/Delete.cshtml`
- `app/ContosoUniversity/Views/Instructors/Details.cshtml`
- `app/ContosoUniversity/Views/Instructors/Edit.cshtml`
- `app/ContosoUniversity/Views/Instructors/Index.cshtml`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.09-instructors-controller/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.09-instructors-controller/progress-details.md`

### Validation
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore`: succeeded with 0 errors and 4 pre-existing NuGet vulnerability warnings.
- Runtime host: started successfully at `http://127.0.0.1:5189` and `GET /health` returned `200 ok`.
- `GET /Instructors`: conventional routing selected `InstructorsController.Index`, then returned `500` because `SchoolContext` has no configured database provider without the missing `ConnectionStrings:DefaultConnection` secret. Exact exception: `System.InvalidOperationException: No database provider has been configured for this DbContext.`
- Database-backed instructor CRUD, course/office persistence, rendered page output, and POST anti-forgery behavior could not be exercised without the Development SQL-authentication user secret.
- No matching .NET test project exists for this application in the repository assessment, so no affected-unit automated tests were available.
- Legacy-pattern scan found no `System.Web`, legacy status helpers, legacy `[Bind(Include=...)]`, synchronous `TryUpdateModel`, legacy form/link/input helpers, or `Scripts.Render` in the migrated instructor slice.
- VS Code diagnostics found no errors in `InstructorsController.cs`; `git diff --check` passed.

### Warnings and deferred work
- `NU1903`: `Microsoft.Data.SqlClient` 2.1.4, high severity vulnerability (`GHSA-98g6-xh36-x2p7`).
- `NU1902`: `Microsoft.IdentityModel.JsonWebTokens` 6.8.0, moderate severity vulnerability (`GHSA-59j7-ghrg-fj52`).
- `NU1904`: `System.Drawing.Common` 4.7.0, critical severity vulnerability (`GHSA-rxg9-xrhp-64gj`).
- `NU1902`: `System.IdentityModel.Tokens.Jwt` 6.8.0, moderate severity vulnerability (`GHSA-59j7-ghrg-fj52`).
- These warnings predate this child and are intentionally deferred to approved top-level task 07; changing package versions here would violate the requested task boundary.

### Decomposition
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent already isolated this single controller and its five directly associated views; no further trigger applied.
