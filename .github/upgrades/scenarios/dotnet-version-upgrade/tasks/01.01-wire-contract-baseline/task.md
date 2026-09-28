# 01.01-wire-contract-baseline: Record the MVC endpoint baseline and mandatory wire-contract gate

# 01.01 Wire-contract gate and migration baseline

## Objective
Before any application-source change, formalize the ASP.NET Framework host baseline and the mandatory wire-contract decision for the in-place migration.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- This task's `task.md` and `progress-details.md`
- Read-only inspection of `app/ContosoUniversity/Global.asax.cs`, `App_Start/RouteConfig.cs`, `App_Start/FilterConfig.cs`, all seven controllers, `Models/Notification.cs`, `Scripts/notifications.js`, and notification documentation

## Established findings
- Project approach is in-place rewrite.
- The scoped wire decision is PASS: no OData/Atom/custom serializer exists and no external pinned consumer was found.
- Preserve the coordinated internal JSON contract for `GET /Notifications/GetNotifications` and `POST /Notifications/MarkAsRead`, including HTTP 200 behavior, envelope fields, the 10-item limit, and PascalCase notification properties consumed by `notifications.js`.
- No application authorization attributes, custom response headers, custom HTTP modules, or custom handlers were found.

## Verified execution research
- The runnable host is the single classic ASP.NET Framework 4.8 Web Application Project at `app/ContosoUniversity/ContosoUniversity.csproj`; this child is a prerequisite/baseline task and does not modify the project.
- Route analysis found one ignored route, `{resource}.axd/{*pathInfo}`, followed by one active conventional route, `{controller}/{action}/{id}`, defaulting to `Home/Index` with optional `id`. No areas or attribute routes are registered.
- `Global.asax.cs` has only `Application_Start`; it registers areas, `HandleErrorAttribute`, the conventional route, bundles, and database initialization. No application `IHttpModule`, `IHttpHandler`, `IHttpAsyncHandler`, OWIN/Katana middleware, third-party DI container, or custom response-header code was found.
- The seven inspected controller files are `BaseController`, `HomeController`, `StudentsController`, `DepartmentsController`, `InstructorsController`, `CoursesController`, and `NotificationsController`. The six concrete controllers expose 40 public actions: 26 implicit GET actions, 12 anti-forgery-protected form POST actions, and the two notification JSON actions.
- Executable configuration contains no authentication, authorization, membership, or role-manager sections, and no controller/action has `[Authorize]`. Comments and notification documentation that describe role restrictions or Windows Authentication are not enforced by the current application and are treated as stale documentation, not baseline behavior.
- The cheap wire-gate check found JSON output and an in-repository consumer, so the gate applies. It found no OData package/route/formatter, Atom media type, custom OData serializer, custom MVC JSON settings, JSON naming policy, response DTO annotations, contract tests, schemas, or external client bindings.
- `GET /Notifications/GetNotifications` is consumed by `Scripts/notifications.js`. It returns HTTP 200 with `{ success: false, message: "Error retrieving notifications" }` on its handled failure path, or `{ success: true, notifications, count }` on success; processing stops after 10 items. The script reads `Operation`, `EntityType`, `Message`, `CreatedBy`, and `CreatedAt` with PascalCase.
- `POST /Notifications/MarkAsRead` accepts form/query-bound integer `id`, has no anti-forgery attribute, and returns HTTP 200 with `{ success: true }` or `{ success: false, message: "Error updating notification" }`. No current in-repository caller was found.
- No `// STUB:` markers were found in the scoped application. Assessment querying is not required by the execution guidance because this child is a prerequisite that changes no project.
- Applicable migration satellites recorded for later children are Global.asax/pipeline, MVC controllers, global filters, Razor views, bundling/static assets, `HttpContext.Current` in the shared error view, and TempData in student deletion. Authentication migration is a no-op unless later evidence changes the inventory.

## Decomposition assessment
- Evaluated `execution.md` and `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent was already decomposed using the mandatory wire-contract and controller-unit hints; this child owns only the pre-edit evidence record and has no independent implementation concerns to split.

## Validation approach
- Preserve the application tree byte-for-byte for this child and verify that no application diff is introduced.
- Validate the recorded route/action inventory against source searches and the route-ownership analyzer.
- Run repository documentation/content checks applicable to workflow Markdown; do not build or run the unchanged application because this no-source-change prerequisite uses the execution guidance's no-change short-circuit.

## Wire Compatibility
- **Decision**: PASS for the ContosoUniversity MVC host.
- **Preservation choice**: migrate both notification actions later as raw ASP.NET Core MVC JSON actions without adding OData or changing their HTTP 200/envelope/casing behavior.
- **Evidence record**: [progress-details.md#wire-compatibility](progress-details.md#wire-compatibility)

## Steps
1. Re-read the recorded evidence and rerun the cheap wire-gate applicability check before source changes.
2. Copy the scoped inventory, signal results, PASS verdict, and preservation choice into `progress-details.md`; link it from this task metadata.
3. Record all conventional `{controller}/{action}/{id}` routes, methods, expected result type/status, anti-forgery use, global error handling, and applicable views as the acceptance baseline.
4. Record applicable migration satellites: Global.asax/pipeline, MVC controllers/filters, Razor views, and static assets. Record that auth migration is a no-op unless new evidence contradicts the current inventory.
5. STOP and report a blocker instead of retargeting if consumers or any wire signal become unknown or a STOP signal appears.

## Done when
The managed workflow contains a complete baseline and an evidence-backed scoped PASS linked from task metadata. No application source has changed.
