# 01.07-students-controller: Migrate StudentsController and student Razor views

# 01.07 Migrate StudentsController

## Objective
Migrate student list/search/pagination and CRUD behavior as one controller-owned unit.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Controllers/StudentsController.cs`, `PaginatedList.cs` as required
- `Views/Students/*.cshtml`

## Established surface
Eight actions cover Index, Details, Create GET/POST, Edit GET/POST, Delete GET/POST. POSTs use anti-forgery; Index carries sort/search/current-filter/page state. Direct `Trace.TraceError` remains task 06 ownership.

## Steps
1. Re-run dependency analysis and verify DI, default routing, global error handling, and anti-forgery prerequisites.
2. Migrate MVC result/status/not-found APIs, model binding include behavior, validation, async/query behavior only where required for Core compatibility, and preserve pagination/filter semantics.
3. Migrate all student views and forms, retaining anti-forgery and validation behavior.
4. Preserve notification-send calls through the compile-safe contract; do not implement Service Bus or telemetry.
5. Build and smoke-test routes when the Development SQL secret is available; otherwise record the exact runtime blocker.

## Done when
The Students controller and views compile on net10.0, all eight actions retain their baseline behavior, and build succeeds without task 02/04/06 implementation.

## Research findings

- The project is already an SDK-style `Microsoft.NET.Sdk.Web` host targeting `net10.0`; `Program.cs` registers scoped `SchoolContext`, `INotificationService`, MVC, static files, and the conventional `{controller=Home}/{action=Index}/{id?}` route.
- `StudentsController` is one MVC controller with eight actions and depends on the migrated `BaseController`, `SchoolContext`, `INotificationService`, `Student`, `EntityOperation`, EF Core, and `PaginatedList<Student>`. Roslyn dependency analysis found no project dependency outside `ContosoUniversity.csproj`.
- The five feature views are `Index`, `Details`, `Create`, `Edit`, and `Delete`. Shared `_ViewImports.cshtml` already enables ASP.NET Core Tag Helpers. No custom view engine, mobile display mode, explicit master selection, child action, custom model binder, value provider, attribute route, authorization rule, or custom response header applies.
- `PaginatedList<T>` is framework-neutral and must be included with the feature. Its existing count, skip/take, page index, previous-page, and next-page semantics require no source rewrite.
- No `// STUB:` markers exist in the affected project. The notification calls must continue through `INotificationService`; task 04 remains responsible for replacing its unavailable broker implementation.
- The host currently has no explicit global exception middleware. Final global error handling recheck remains assigned to `01.12-cleanup-container-validation`; this child must not broaden into that top-level cleanup concern.

## Assessment findings

- The generated assessment identifies this project as a high-difficulty ASP.NET Framework WAP migration with 157 findings, including System.Web MVC/Razor APIs, unsupported bundling, legacy configuration, and MSMQ. Prior children already converted the project/host, DI boundary, shared Razor infrastructure, and static assets.
- This child addresses only the remaining Students-owned MVC namespace/result/model-binding and Razor helper findings. It adds no package replacement: EF/package modernization remains outside this child, and security remediation remains task 07 ownership.
- The assessment recommends behavior-locking coverage, but no matching .NET test project exists. Focused build and available route/view smoke checks are the validation surface.

## Behavior baseline

- `GET /Students/Index` returns 200 with ten-row pagination; non-null `searchString` resets `page` to 1, otherwise `currentFilter` is reused. Search remains first/last-name `Contains`; sort values remain default last-name ascending, `name_desc`, `Date`, and `date_desc`.
- `GET /Students/Details/{id}` returns 400 for null and 200 for a found row including enrollments/courses. A missing row currently throws from `Single()` before the coded 404 branch; preserve that recorded baseline rather than silently changing it.
- Create GET returns today's date. Create/Edit POST bind only their existing allowlists, retain SQL datetime-range validation, return 200 with validation/save errors, and redirect to Index with 302 after a valid save.
- Edit/Delete GET return 400 for null, 404 for a missing row, and 200 for a found row. Delete POST retains action name `Delete`, anti-forgery validation, notification dispatch, and 302 redirect on both success and handled failure; failure continues to set `TempData["ErrorMessage"]`.
- All three POST actions remain `[ValidateAntiForgeryToken]`; Core form Tag Helpers generate the hidden anti-forgery field. Routes stay conventional and action names stay unchanged.

## Wire Compatibility

- **Verdict: PASS (current baseline reused).** This feature contains Razor HTML actions only, with no OData, Atom, JSON/XML response, custom formatter/serializer, raw writer, or external response-shape consumer. Evidence is recorded in `../01.01-wire-contract-baseline/progress-details.md`; the controller and view scope does not change that evidence.

## Decomposition verdict

- Evaluated `dotnet-version-upgrade/execution.md` and `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- **Atomic.** The parent already isolated each controller as required by the web-controller hint. This child is one controller-owned feature with its five views and pagination helper; no stubs, package replacement, auth, middleware, static-asset, or messaging implementation trigger adds an independent unit.
