# Progress details

## 2026-09-28 - Courses controller migration

### Outcome
- Migrated all eight `CoursesController` actions from `System.Web.Mvc` to ASP.NET Core MVC.
- Replaced `HttpPostedFileBase`/`SaveAs` with `IFormFile`/`CopyToAsync` while preserving extension validation, the 5 MiB limit, generated `course_{CourseID}_{Guid}{extension}` names, replacement cleanup, deletion cleanup, and non-blocking delete cleanup failures.
- Injected `IWebHostEnvironment` and retained local files under content-root `Uploads/TeachingMaterials` with persisted same-origin paths shaped as `~/Uploads/TeachingMaterials/{fileName}`.
- Added a narrowly scoped `/Uploads` physical static-file mapping. No Azure package, Blob client, storage abstraction, credential, endpoint, or blob URL was added; top-level task 03 remains the owner of Blob Storage.
- Migrated all five course views to ASP.NET Core Tag Helpers. Multipart field name `teachingMaterialImage`, POST anti-forgery behavior, conventional routes, route IDs, validation messages, and visible image rendering were preserved.
- Retained direct `Debug.WriteLine` cleanup logging for task 06 as required.

### Wire compatibility
- Decision: NOT APPLICABLE to serialization for this child.
- Evidence: all eight actions return Razor views, redirects, `BadRequest`, or `NotFound`; the feature has no JSON/XML/OData action, formatter, custom serializer, response header, schema, or external response-shape contract.
- Preserved HTTP surface: conventional `/Courses/{action}/{id?}` routing, POST action names, anti-forgery validation, multipart field names, redirects to `Index`, 400 for missing nullable IDs, and 404 for absent entities.

### Files modified
- `app/ContosoUniversity/Controllers/CoursesController.cs`
- `app/ContosoUniversity/Views/Courses/Create.cshtml`
- `app/ContosoUniversity/Views/Courses/Delete.cshtml`
- `app/ContosoUniversity/Views/Courses/Details.cshtml`
- `app/ContosoUniversity/Views/Courses/Edit.cshtml`
- `app/ContosoUniversity/Views/Courses/Index.cshtml`
- `app/ContosoUniversity/Program.cs`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.10-courses-controller/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.10-courses-controller/progress-details.md`

### Validation
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore`: succeeded, 0 errors, 4 warnings.
- Warnings are pre-existing package vulnerability findings explicitly deferred to top-level task 07: `Microsoft.Data.SqlClient` 2.1.4 (`NU1903`), `Microsoft.IdentityModel.JsonWebTokens` 6.8.0 (`NU1902`), `System.Drawing.Common` 4.7.0 (`NU1904`), and `System.IdentityModel.Tokens.Jwt` 6.8.0 (`NU1902`). They were not suppressed or changed in this task.
- IDE diagnostics: no errors in `CoursesController.cs`, `Program.cs`, or the Courses views.
- Legacy/API residue search: no `System.Web`, `HttpPostedFileBase`, `Server.MapPath`, legacy form/link helpers, bundle calls, Azure references, Blob references, credentials, or blob URLs remain in the migrated slice.
- `git diff --check`: passed; Git emitted only the existing line-ending notice for `ContosoUniversity.csproj`.
- No .NET test project exists for the application.
- Repository `npm test`: not run because `npm` is not installed (`npm` command not recognized).

### Runtime validation and blocker
- `dotnet user-secrets list --project app/ContosoUniversity/ContosoUniversity.csproj`: `No secrets configured for this application.`
- Application startup on `http://127.0.0.1:5087`: succeeded.
- `GET /health`: HTTP 200.
- `GET /Courses`: conventional route resolved to `CoursesController.Index`, then returned HTTP 500 because `ConnectionStrings:DefaultConnection` is empty and EF reported `No database provider has been configured for this DbContext.`
- Course CRUD, upload, replacement, deletion, and rendered image runtime checks remain blocked until the Development SQL-authenticated `DefaultConnection` user secret is supplied. This is the expected scenario prerequisite, not an implementation failure.

### Decomposition
- Evaluated scenario `execution.md` and `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. This is the parent-planned single-controller migration unit; no matching hint requires a further split.

### Deviations
- None from task scope. The final Azure Blob implementation remains wholly deferred to task 03, and no sibling or task 02 work was executed.
