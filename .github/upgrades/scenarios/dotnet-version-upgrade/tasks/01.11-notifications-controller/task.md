# 01.11-notifications-controller: Migrate NotificationsController and preserve its raw JSON contract

# 01.11 Migrate NotificationsController

## Objective
Migrate the dashboard and two raw MVC JSON actions while preserving the wire-gated contract and leaving broker replacement to task 04.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Controllers/NotificationsController.cs`
- `Views/Notifications/Index.cshtml`
- `Scripts/notifications.js` only for compatibility corrections proven necessary

## Wire contract
The scoped gate is PASS. Preserve `GET /Notifications/GetNotifications` and `POST /Notifications/MarkAsRead` as raw MVC JSON, HTTP 200 success/error envelopes, `success/message/notifications/count` field names, the 10-item limit, and PascalCase notification properties consumed by the script. Do not add OData or globally change JSON naming policy in a way that breaks this contract.

## Research findings
- The generated assessment identifies this single project as a high-difficulty ASP.NET Framework MVC migration and flags `System.Web` plus 57 unsupported MSMQ usages. No assessment issue is specific to `NotificationsController`; controller conversion is nevertheless required because it imports `System.Web.Mvc` and uses the removed `JsonRequestBehavior.AllowGet` overload.
- Roslyn dependency analysis resolves the controller through the already-migrated `BaseController`, scoped `SchoolContext`, `INotificationService`, `Notification`, and the existing EF model graph. `Program.cs` already registers the context and notification contract, but the controller needs a constructor that forwards both dependencies to `BaseController`.
- Task 01.03 replaced the unsupported MSMQ implementation with a compile-safe `INotificationService` implementation whose receive and mark-read methods deterministically throw `NotSupportedException`. This controller must retain its handled HTTP 200 error envelopes around that boundary; task 04 exclusively owns the broker implementation.
- `Program.cs` uses the conventional `{controller=Home}/{action=Index}/{id?}` route and `AddControllersWithViews`, matching the legacy default route. `_ViewImports.cshtml`, `_ViewStart.cshtml`, shared layout, static middleware, and the relocated `wwwroot/js/notifications.js` and `wwwroot/css/notifications.css` are already ready.
- The existing view contains legacy `Html.ActionLink` calls, an unmatched closing `div`, Bootstrap 3 panel/label/well classes, and stale claims that MSMQ is currently active. Migrate the links to tag helpers, correct the markup, and describe messaging as unavailable pending task 04 without claiming a replacement implementation.
- The browser consumer still polls `/Notifications/GetNotifications` with `GET`, `credentials: 'same-origin'`, rejects non-2xx responses, and reads lower-camel envelope fields plus PascalCase notification fields. No script correction is required.
- Repository scan found no `// STUB:` markers and no .NET test project. Contract validation therefore needs deterministic controller-level checks plus available runtime requests; live broker success behavior remains deferred.

## Wire compatibility
- Reused the scoped PASS and preservation decision from `../01.01-wire-contract-baseline/progress-details.md#wire-compatibility`; consumers, routes, models, and serializer registrations have not changed since that record.
- `GET /Notifications/GetNotifications` must remain HTTP 200 with either `{ success: false, message: "Error retrieving notifications" }` or `{ success: true, notifications, count }`, stop after 10 received items, and serialize each notification with exactly `Id`, `EntityType`, `EntityId`, `Operation`, `Message`, `CreatedAt`, `CreatedBy`, `IsRead`, and `ReadAt` property names.
- `CreatedAt` and non-null `ReadAt` remain JSON date strings parseable by the browser `Date` constructor; nullable `ReadAt` remains JSON `null`. Envelope names remain lower camel case regardless of application-wide JSON defaults.
- `POST /Notifications/MarkAsRead` must remain conventionally bound from `id` and HTTP 200 with either `{ success: true }` or `{ success: false, message: "Error updating notification" }`.
- Neither action gains `[ApiController]`, authorization, anti-forgery validation, OData, custom headers, or changed status semantics.

## Decomposition verdict
- Evaluated `dotnet-version-upgrade/execution.md` and `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: **atomic**. The parent already isolated each controller, and this child is the single `NotificationsController` feature unit with one view and its pinned raw JSON contract. The mandatory messaging replacement remains isolated in task 04; no stubs, package replacement, authentication, middleware, multi-project ordering, or independent static-asset work is in scope.

## Steps
1. Re-run dependency analysis and re-evaluate the wire gate if consumers, serialization, models, or routes changed. STOP on a new/unknown signal.
2. Migrate `JsonResult` calls and HTTP method attributes to ASP.NET Core MVC while pinning the established field names and behavior explicitly.
3. Migrate the dashboard view and preserve polling URL, same-origin credentials, error behavior, and visual notifications.
4. Consume only the compile-safe notification contract from task 01.03. Do not implement Azure Service Bus, alternate messaging, or telemetry. Keep send and receive method shapes ready for task 04.
5. Build and exercise deterministic JSON-contract checks independent of live MSMQ/Service Bus; record deferred broker integration as task 04 ownership.

## Done when
The dashboard and three actions compile, contract checks prove the gated JSON shape/status behavior, no OData is added, and broker implementation remains task 04.
