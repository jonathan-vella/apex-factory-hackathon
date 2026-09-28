# 01.01 Wire-contract baseline progress

## Outcome

- **Status**: baseline recorded; scoped wire gate PASS
- **Project approach**: in-place rewrite
- **Application changes**: none
- **Protected scope**: the ContosoUniversity MVC host, especially `GET /Notifications/GetNotifications` and `POST /Notifications/MarkAsRead`

## Evidence reviewed

- Startup and routing: `Global.asax.cs`, `App_Start/RouteConfig.cs`, `App_Start/FilterConfig.cs`, `App_Start/BundleConfig.cs`, `Web.config`, and `Views/Web.config`
- Controllers: all seven files under `Controllers/`, including the abstract `BaseController`
- Notification contract: `Controllers/NotificationsController.cs`, `Models/Notification.cs`, `Services/NotificationService.cs`, `Scripts/notifications.js`, `Views/Shared/_Layout.cshtml`, `NOTIFICATION_SYSTEM_README.md`, and `SETUP_TESTING_GUIDE.md`
- Views: all 27 Razor files under `Views/`
- Generated assessment index and ContosoUniversity findings
- Route ownership analyzer output for `ContosoUniversity.csproj`
- Repository searches for OData, Atom, serializer/formatter customization, response headers, authorization, HTTP modules/handlers, OWIN, DI containers, session state, TempData, and stub markers

## Route baseline

Route registration order is:

1. Ignore `{resource}.axd/{*pathInfo}`.
2. Register the `Default` conventional route `{controller}/{action}/{id}`, with defaults `controller = Home`, `action = Index`, and optional `id`.

There are no areas, attribute routes, route constraints, Web API routes, OData routes, redirects, or runtime-conditional registrations. The route has no method constraint; action attributes provide the method restrictions listed below. `/` resolves to `Home/Index`.

## Endpoint acceptance baseline

All actions use the conventional route. Unless stated otherwise, an action has no authorization requirement, sets no custom response header, returns a Razor view with HTTP 200, and does not validate an anti-forgery token.

### HomeController

| Method and path | Result and status | View |
| --- | --- | --- |
| `GET /` or `/Home/Index` | `ViewResult`, 200 | `Views/Home/Index.cshtml` |
| `GET /Home/About` | `ViewResult` with enrollment-date groups, 200 | `Views/Home/About.cshtml` |
| `GET /Home/Contact` | `ViewResult`, 200 | `Views/Home/Contact.cshtml` |
| `GET /Home/Error` | `ViewResult`, 200 when view resolution succeeds | `Views/Shared/Error.cshtml` |
| `GET /Home/Unauthorized` | `ViewResult` is requested, but no matching Razor view exists; invocation reaches the global exception path | No `Unauthorized.cshtml` exists |

### StudentsController

| Method and path | Result and status | Anti-forgery | View |
| --- | --- | --- | --- |
| `GET /Students/Index` | Paginated `ViewResult`, 200 | No | `Views/Students/Index.cshtml` |
| `GET /Students/Details/{id}` | Null `id`: 400. Found: `ViewResult`, 200. Missing row currently throws from `Single()` before the coded 404 branch. | No | `Views/Students/Details.cshtml` |
| `GET /Students/Create` | `ViewResult`, 200 | No | `Views/Students/Create.cshtml` |
| `POST /Students/Create` | Valid save: redirect to Index, 302. Validation/save failure: `ViewResult`, 200. | Yes | `Views/Students/Create.cshtml` |
| `GET /Students/Edit/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Students/Edit.cshtml` |
| `POST /Students/Edit` | Valid save: redirect to Index, 302. Validation/save failure: `ViewResult`, 200. | Yes | `Views/Students/Edit.cshtml` |
| `GET /Students/Delete/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Students/Delete.cshtml` |
| `POST /Students/Delete/{id}` | Action name is `Delete`. Success and handled failure both redirect to Index, 302; failure sets `TempData["ErrorMessage"]`. | Yes | None |

### DepartmentsController

| Method and path | Result and status | Anti-forgery | View |
| --- | --- | --- | --- |
| `GET /Departments/Index` | `ViewResult`, 200 | No | `Views/Departments/Index.cshtml` |
| `GET /Departments/Details/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Departments/Details.cshtml` |
| `GET /Departments/Create` | `ViewResult`, 200 | No | `Views/Departments/Create.cshtml` |
| `POST /Departments/Create` | Valid save: redirect to Index, 302. Invalid model: `ViewResult`, 200. | Yes | `Views/Departments/Create.cshtml` |
| `GET /Departments/Edit/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Departments/Edit.cshtml` |
| `POST /Departments/Edit` | Valid save: redirect to Index, 302. Invalid/concurrency result: `ViewResult`, 200. | Yes | `Views/Departments/Edit.cshtml` |
| `GET /Departments/Delete/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Departments/Delete.cshtml` |
| `POST /Departments/Delete/{id}` | Action name is `Delete`; success redirects to Index, 302. | Yes | None |

### InstructorsController

| Method and path | Result and status | Anti-forgery | View |
| --- | --- | --- | --- |
| `GET /Instructors/Index` | `ViewResult`, 200 | No | `Views/Instructors/Index.cshtml` |
| `GET /Instructors/Details/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Instructors/Details.cshtml` |
| `GET /Instructors/Create` | `ViewResult`, 200 | No | `Views/Instructors/Create.cshtml` |
| `POST /Instructors/Create` | Valid save: redirect to Index, 302. Invalid model: `ViewResult`, 200. | Yes | `Views/Instructors/Create.cshtml` |
| `GET /Instructors/Edit/{id}` | Null `id`: 400. Found: `ViewResult`, 200. Missing row currently throws from `Single()` before the coded 404 branch. | No | `Views/Instructors/Edit.cshtml` |
| `POST /Instructors/Edit/{id}` | Null `id`: 400. Valid save: redirect to Index, 302. Invalid/handled save failure: `ViewResult`, 200. A missing row throws from `Single()`. | Yes | `Views/Instructors/Edit.cshtml` |
| `GET /Instructors/Delete/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Instructors/Delete.cshtml` |
| `POST /Instructors/Delete/{id}` | Action name is `Delete`; success redirects to Index, 302. | Yes | None |

### CoursesController

| Method and path | Result and status | Anti-forgery | View |
| --- | --- | --- | --- |
| `GET /Courses/Index` | `ViewResult`, 200 | No | `Views/Courses/Index.cshtml` |
| `GET /Courses/Details/{id}` | Null `id`: 400. Found: `ViewResult`, 200. Missing row currently throws from `Single()` before the coded 404 branch. | No | `Views/Courses/Details.cshtml` |
| `GET /Courses/Create` | `ViewResult`, 200 | No | `Views/Courses/Create.cshtml` |
| `POST /Courses/Create` | Valid save: redirect to Index, 302. Invalid upload/model: `ViewResult`, 200. | Yes | `Views/Courses/Create.cshtml` |
| `GET /Courses/Edit/{id}` | Null `id`: 400. Missing row: 404. Found: `ViewResult`, 200. | No | `Views/Courses/Edit.cshtml` |
| `POST /Courses/Edit` | Valid save: redirect to Index, 302. Invalid upload/model: `ViewResult`, 200. | Yes | `Views/Courses/Edit.cshtml` |
| `GET /Courses/Delete/{id}` | Null `id`: 400. Found: `ViewResult`, 200. Missing row currently throws from `Single()` before the coded 404 branch. | No | `Views/Courses/Delete.cshtml` |
| `POST /Courses/Delete/{id}` | Action name is `Delete`; success redirects to Index, 302. | Yes | None |

### NotificationsController

| Method and path | Result and status | Anti-forgery | View/contract |
| --- | --- | --- | --- |
| `GET /Notifications/GetNotifications` | `JsonResult`, HTTP 200 on success and handled failure | No | Raw JSON contract recorded below |
| `POST /Notifications/MarkAsRead?id={id}` | `JsonResult`, HTTP 200 on success and handled failure | No | Raw JSON contract recorded below |
| `GET /Notifications/Index` | `ViewResult`, 200 | No | `Views/Notifications/Index.cshtml` |

## Pipeline and global behavior

- `Application_Start` registers areas, the global filter, routes, bundles, and synchronous database initialization in that order. There are no other `Global.asax` events.
- The only active global filter is `HandleErrorAttribute`. The commented-out global `AuthorizeAttribute` is not behavior. `Web.config` does not explicitly set `customErrors`, so framework defaults still affect whether an unhandled local request displays detailed errors or the shared error view.
- No host-level custom HTTP module or handler is registered. `Views/Web.config` contains only framework Razor view handlers; these are Razor infrastructure, not application-defined request handlers.
- No custom response headers are set by application code.
- No application authentication/authorization middleware or configuration exists. No action has `[Authorize]`. `BaseController` deliberately uses the literal user name `System`.
- Stale documentation describes admin roles and Windows Authentication, but those claims are not implemented and must not be introduced as part of behavior preservation.

## Migration satellite inventory

- **Global.asax/pipeline**: applicable because startup, route/filter/bundle registration, and database initialization live in `Application_Start`.
- **MVC controllers**: applicable to six concrete controllers plus the shared abstract base controller.
- **MVC filters**: applicable because `HandleErrorAttribute` is globally registered.
- **Razor views**: applicable to 27 Razor files, including legacy HTML helpers and `HttpContext.Current` in `Views/Shared/Error.cshtml`.
- **Bundling/static assets**: applicable because `System.Web.Optimization`, root `Content/` and `Scripts/`, and bundle render helpers are used. The notification CSS and JavaScript are directly referenced by `_Layout.cshtml`.
- **TempData/session satellite**: applicable to the student-delete error path because it writes `TempData["ErrorMessage"]`; no direct `Session` or application-state usage was found.
- **Authentication migration**: no-op unless later evidence contradicts this inventory.
- **OWIN/Katana, third-party DI, custom model binding, attribute routing, HTTP modules/handlers, and OData**: not applicable based on current evidence.

## Wire Compatibility

### Scope and applicability

- **Scope**: ContosoUniversity MVC host
- **Approach**: in-place rewrite
- **Applicability**: applicable because two MVC actions emit raw JSON and one is consumed by coordinated in-repository JavaScript.
- **Consumer evidence**: `Scripts/notifications.js` polls only `GET /Notifications/GetNotifications`. No caller for `MarkAsRead`, external client binding, schema, contract test, or separately owned consumer was found. Documentation mentions the GET polling URL but does not define another consumer.
- **Protocol/media type**: non-OData MVC JSON over HTTP. `GetNotifications` explicitly enables GET JSON; `MarkAsRead` returns MVC JSON. No content negotiation, XML contract, or custom media-type registration is present.
- **Formatter/serializer path**: MVC `JsonResult` with anonymous envelopes and default framework/Newtonsoft behavior. No `JsonSerializerSettings`, naming policy, contract resolver, converter, formatter registration, response-model serialization annotation, or raw response writer was found.

### Mandatory signal results

| Signal | Result | Evidence |
| --- | --- | --- |
| Atom formatter | Absent | No Atom media type, OData formatter, or formatter registration exists. |
| Custom OData serializer | Absent | No OData dependency, route, serializer provider, or `ODataEntityTypeSerializer` subclass exists. |
| Externally pinned non-OData shape | Absent | The only executable consumer is the coordinated in-repository script; no external binding/schema/test was found. |
| Explicit external preservation hint | Absent | Repository requirements preserve behavior, but do not identify an externally owned protocol consumer. |

All consumer, registration, and output paths in this scope are known. The mandatory gate result is **PASS**.

### Contract that must be preserved

`GET /Notifications/GetNotifications`:

- HTTP method and status: GET; HTTP 200 for both handled outcomes.
- Success envelope: `{ success: true, notifications, count }`.
- Failure envelope: `{ success: false, message: "Error retrieving notifications" }`.
- Processing limit: at most 10 notifications per request.
- Envelope names remain lower camel case: `success`, `notifications`, `count`, and `message`.
- Notification objects retain default PascalCase names. The browser directly consumes `Operation`, `EntityType`, `Message`, `CreatedBy`, and `CreatedAt`; the effective model also exposes `Id`, `EntityId`, `IsRead`, and nullable `ReadAt` under default serialization.
- The JavaScript expects `notifications` to be an array, operation/entity/message/creator values to be strings, and `CreatedAt` to be parseable by the browser `Date` constructor.
- No authorization rule, anti-forgery requirement, or custom response header is present.

`POST /Notifications/MarkAsRead`:

- HTTP method and status: POST; HTTP 200 for both handled outcomes.
- Input: MVC-bound integer `id` from the conventional request value sources.
- Success envelope: `{ success: true }`.
- Failure envelope: `{ success: false, message: "Error updating notification" }`.
- No authorization rule, anti-forgery requirement, or custom response header is present.

### Preservation decision

Later migration must implement both actions as raw ASP.NET Core MVC JSON actions. Do not add OData, camel-case the notification object properties, rename envelope fields, change the 10-item cap, add anti-forgery/auth requirements, or replace handled HTTP 200 responses with different status codes unless the owner explicitly approves a contract change. Re-run this gate if endpoint consumers, serializer settings, routes, response models, or ownership evidence changes.

## Decomposition verdict

- Execution guidance evaluated: `dotnet-version-upgrade/execution.md`.
- Breakdown hints evaluated: `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: **atomic**. The parent already isolated this mandatory baseline/gate from SDK conversion, configuration, static assets, controller migrations, and final validation. This child has one coherent output: the pre-edit acceptance record.

## Validation

Validation results are appended below after the repository checks complete.

### 2026-09-28 completion check

- Route ownership analysis enumerated the ignored `.axd` route and the active default conventional route with no unresolved registrations or route conflicts.
- Focused PowerShell assertions verified that task metadata links this evidence record and that both notification endpoints, HTTP 200 behavior, the 10-item cap, PASS verdict, and all five browser-consumed PascalCase fields are recorded.
- VS Code diagnostics reported 0 errors and 0 warnings in `task.md`, `progress-details.md`, and `breakdown-context.md`.
- `git diff --check` completed without whitespace errors. Git emitted only pre-existing CRLF-to-LF notices for `scenario-instructions.md` and `scenario.json`, which this child did not edit.
- `git diff --exit-code -- app/ContosoUniversity` passed with no output, confirming no tracked application source/configuration/assets changed.
- Markdown lint and repository JavaScript tests could not start because `node`, `npm`, and `npx` are unavailable on `PATH`. This is an environment/tooling blocker for those optional repository checks; the focused assertions and editor diagnostics completed successfully.
- Project build, `dotnet run`, page checks, and .NET tests were not rerun: this prerequisite intentionally changes no application files, no matching .NET test project exists, and the execution guidance's no-change short-circuit applies. Full build/runtime validation remains owned by child `01.12-cleanup-container-validation` after the application migration.

## Files modified

- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.01-wire-contract-baseline/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.01-wire-contract-baseline/progress-details.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`

No file under `app/ContosoUniversity/` was modified.