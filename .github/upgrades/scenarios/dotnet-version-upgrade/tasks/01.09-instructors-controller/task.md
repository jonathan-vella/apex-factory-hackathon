# 01.09-instructors-controller: Migrate InstructorsController and instructor Razor views

# 01.09 Migrate InstructorsController

## Objective
Migrate instructor CRUD, office assignment, selected-course updates, and master/detail rendering as one controller-owned unit.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Controllers/InstructorsController.cs`
- `Views/Instructors/*.cshtml`
- Existing instructor view models only where Core compatibility requires edits

## Established surface
Eight actions cover Index/master-detail, Details, Create GET/POST, Edit GET/POST, Delete GET/POST. Dependencies include InstructorIndexData, AssignedCourseData, course assignments, and office assignment.

## Steps
1. Re-run dependency analysis and verify shared DI/route/filter prerequisites.
2. Migrate MVC result/status/model-binding APIs while preserving eager-loading, selected course updates, office assignment behavior, and validation.
3. Migrate all instructor views/forms and retain anti-forgery tokens and master/detail links.
4. Preserve notification calls behind the task-04 boundary; do not change EF mappings.
5. Build and runtime-check when SQL configuration is available, otherwise record the exact blocker.

## Done when
All eight actions and instructor views compile and preserve baseline behavior without implementing later SQL/messaging/telemetry work.

## Research findings
- The project is already SDK-style `Microsoft.NET.Sdk.Web` on `net10.0`; `Program.cs` registers `SchoolContext`, `INotificationService`, MVC, static files, and the conventional `{controller=Home}/{action=Index}/{id?}` route required by the existing instructor URLs.
- `InstructorsController` is a conventional MVC controller with eight actions. It returns only Razor views, redirects, `400`, and `404`; it has no OData, raw JSON/XML, custom formatter, custom header, authorization, or external response-shape contract. The scoped wire-compatibility verdict is **NOT APPLICABLE** for serialization and remains covered by the parent host PASS.
- Roslyn dependency analysis found `BaseController`, `SchoolContext`, `Instructor`, `OfficeAssignment`, `CourseAssignment`, `Course`, `Department`, `Enrollment`, `InstructorIndexData`, `AssignedCourseData`, and the deferred notification contract. All are already included by the configuration/DI boundary; notification calls must remain unchanged behind task 04.
- The controller requires constructor injection, `IActionResult`, `BadRequest()`/`NotFound()`, Core `[Bind("...")]`, and `TryUpdateModelAsync` with explicit property expressions. The edit action must preserve selected-course add/remove behavior and treat a blank office location as removal without dereferencing a missing office assignment.
- The five instructor views use legacy form/link/input helpers and `@Scripts.Render`. They must use existing global Tag Helpers, retain POST anti-forgery generation, preserve checkbox names and values (`selectedCourses`), keep master/detail route values, and omit the already-migrated shared validation bundle reference.
- The project currently excludes `Controllers/InstructorsController.cs` and `Views/Instructors/**/*.cshtml`; this task must add a dedicated instructor feature item group without changing sibling feature boundaries.
- The generated assessment reports 157 project-wide findings, including legacy MVC/Razor packages and EF Core 3.1-to-10 recommendations. Package modernization, SQL policy, messaging, telemetry, and final CVE remediation are outside this child; this task uses the already-established compile boundary and does not alter packages or mappings.
- No `// STUB:` markers, custom model binders/value providers, custom Razor view engine, explicit master layout selection, authentication concern, or third-party DI container applies to this slice.

## Validation plan
1. Build `ContosoUniversity.csproj` and require zero errors and zero warnings.
2. Start the app without a SQL secret only far enough to verify the host and `/health`; record database-backed instructor page validation as blocked by the missing Development `ConnectionStrings:DefaultConnection` user secret.
3. Confirm no legacy MVC/Razor helpers remain in the instructor controller or views and run repository whitespace validation for the touched files.

## Decomposition verdict
Atomic. The parent task already split the seven controllers into controller-owned feature units, and this child contains one controller plus its five directly associated views. `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md` were evaluated; no stub, multi-project, package-replacement, authentication, middleware, static-pipeline, or later-service concern requires another split.
