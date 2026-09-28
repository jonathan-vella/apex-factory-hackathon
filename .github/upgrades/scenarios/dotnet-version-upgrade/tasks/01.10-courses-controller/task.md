# 01.10-courses-controller: Migrate CoursesController while preserving the later Blob boundary

# 01.10 Migrate CoursesController

## Objective
Migrate course CRUD and upload-facing MVC APIs while preserving current local behavior and leaving the actual Blob migration entirely to task 03.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Controllers/CoursesController.cs`
- `Views/Courses/*.cshtml`
- Minimal host-environment/path plumbing required to preserve current local files

## Established surface
Eight actions cover Index, Details, Create GET/POST, Edit GET/POST, Delete GET/POST. The POST actions use `HttpPostedFileBase`, `Server.MapPath`, a 5 MB limit, image extension checks, generated names, replacement cleanup, and deletion cleanup.

## Steps
1. Re-run dependency analysis and verify shared DI/route/filter prerequisites.
2. Migrate MVC result/status/binding APIs and `HttpPostedFileBase` to `IFormFile`, preserving validation, limits, naming, replacement, and deletion semantics.
3. Replace only the removed `Server.MapPath` mechanism with Core host-environment/path APIs sufficient for current local `Uploads/TeachingMaterials` behavior. Do not add Blob SDK packages, credentials, endpoints, browser-visible blob URLs, or the final storage abstraction owned by task 03.
4. Migrate all course views/forms, multipart encoding, anti-forgery, and image rendering. Keep direct Debug logging for task 06.
5. Build and runtime-check when SQL configuration is available, otherwise record the exact blocker.

## Done when
All eight actions and course views compile on net10.0 and preserve current upload/CRUD behavior, with the Blob migration still wholly owned by task 03.

## Research findings
- `CoursesController` is a conventional MVC controller with eight actions and five Razor views. Its dependency graph is confined to the already-migrated `BaseController`, `SchoolContext`, `Course`/`Department`, notification contract, EF Core, and the project itself; the migration adds only `IWebHostEnvironment` for physical upload paths.
- The generated project assessment reports 157 project-wide findings. The issues directly owned here are the `System.Web.Mvc` surface and two `HttpPostedFileBase` parameters, including incompatible `ContentLength`, `FileName`, and `SaveAs` members. SDK conversion, host routing, shared Razor/static assets, EF/package upgrades, MSMQ, and CVE work are owned by existing sibling or later top-level tasks.
- The project is already SDK-style `Microsoft.NET.Sdk.Web` targeting `net10.0`; `Program.cs` provides conventional `{controller=Home}/{action=Index}/{id?}` routing, DI for `SchoolContext` and `INotificationService`, and static-file middleware. `_ViewImports.cshtml` already enables ASP.NET Core MVC Tag Helpers.
- Current upload behavior accepts `.jpg`, `.jpeg`, `.png`, `.gif`, and `.bmp` by extension, rejects files larger than 5 MiB, names files `course_{CourseID}_{Guid}{extension}`, stores browser-facing paths as `~/Uploads/TeachingMaterials/{fileName}`, removes the prior image on replacement, and attempts image cleanup before course deletion without blocking database deletion when cleanup fails.
- The compile-safe task-01 boundary keeps files under the application content root at `Uploads/TeachingMaterials`, preserves the existing virtual path value and same-origin image rendering, and uses `IFormFile.CopyToAsync`. It does not add Blob packages, configuration, services, credentials, or URLs; task 03 retains the complete Blob migration.
- Model binding remains form-based MVC binding with explicit `[Bind("CourseID,Title,Credits,DepartmentID,TeachingMaterialImagePath")]`. Multipart forms keep the `teachingMaterialImage` field name, POST actions retain anti-forgery validation, and status behavior remains `BadRequest` for missing IDs and `NotFound` for absent entities.
- No `// STUB:` markers, custom view engine, explicit master layout, OData/Atom formatter, custom serializer, authentication, third-party DI container, or package replacement is in this child scope.

## Wire compatibility
- **Decision:** NOT APPLICABLE to serialization for this child. All eight actions return Razor views, redirects, or status results; there are no JSON/XML/OData actions, custom headers, or externally pinned response shapes in the course feature.
- HTML route, status, form field, anti-forgery, and visible rendering behavior remain explicit acceptance requirements. The detailed gate evidence will be recorded in `progress-details.md`.

## Decomposition assessment
- Evaluated scenario `execution.md` and breakdown hints `common.md`, `framework-migration.md`, and `framework-web-migration.md`.
- **Verdict:** atomic. The parent already split migration by controller, and this child is the prescribed single `CoursesController` plus its five views and minimal path plumbing. No stub-resolution, multi-project, auth, package, static-pipeline, messaging, or independent storage-implementation trigger applies.

## Validation plan
1. Build `ContosoUniversity.csproj` and require zero errors and zero warnings.
2. Search the migrated slice for remaining `System.Web`, `HttpPostedFileBase`, `Server.MapPath`, legacy Razor helpers, and bundle calls.
3. Run available repository tests relevant to content/invariants; no .NET test project exists for this application.
4. Start the application and verify `/health`; attempt Courses page validation only when the Development `DefaultConnection` user secret is available, otherwise record that exact SQL-secret blocker.
