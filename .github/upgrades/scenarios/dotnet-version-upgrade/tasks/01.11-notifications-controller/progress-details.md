# 01.11 NotificationsController progress

## Outcome

- **Status**: ready for orchestrator review and completion
- **Done-when review**: the dashboard and all three actions compile; both raw JSON routes preserve their HTTP 200 envelopes and field casing; deterministic checks prove the success shape, 10-item limit, and date serialization; no OData or broker implementation was added.
- **Decomposition**: atomic after evaluating `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`. The parent already isolated this single controller; task 04 remains the separate mandatory messaging replacement.

## Wire Compatibility

- Reused the scoped PASS from `../01.01-wire-contract-baseline/progress-details.md#wire-compatibility`. Consumers, conventional routing, response model, and serializer registrations had not changed.
- `GET /Notifications/GetNotifications` remains raw MVC JSON and HTTP 200 for handled outcomes. Live runtime verification returned `{"success":false,"message":"Error retrieving notifications"}` while the task-04 messaging boundary is unavailable.
- A disposable .NET controller harness injected a deterministic fake `INotificationService` and proved the success response is exactly `{ success, notifications, count }`, returns exactly 10 of more than 10 available items, and does not perform an eleventh receive.
- The harness proved each notification serializes exactly `Id`, `EntityType`, `EntityId`, `Operation`, `Message`, `CreatedAt`, `CreatedBy`, `IsRead`, and `ReadAt`; `CreatedAt` serialized as browser-parseable ISO JSON (`2026-09-28T12:34:56Z`) and nullable `ReadAt` remained `null`.
- `POST /Notifications/MarkAsRead?id=42` remains raw MVC JSON and HTTP 200. Live runtime verification returned `{"success":false,"message":"Error updating notification"}` at the deferred messaging boundary; the fake-service check proved the success response is exactly `{"success":true}` and forwards id `42`.
- Both HTTP method attributes remain present. No `[ApiController]`, authorization, anti-forgery requirement, custom header, OData, global JSON naming change, or non-200 handled result was introduced.

## Changes

- Migrated `NotificationsController` from `System.Web.Mvc` to ASP.NET Core MVC and added constructor injection for the existing scoped context and compile-safe notification contract.
- Removed `JsonRequestBehavior.AllowGet` and pinned `PropertyNamingPolicy = null` on these JSON results only, preserving lower-camel anonymous envelope names and PascalCase model properties without changing global serialization.
- Preserved the receive loop, 10-item cap, exact success/error messages, conventional parameter binding, and task-04 failure handling. Removed legacy `Debug.WriteLine` calls without adding task-06 telemetry.
- Included the notification controller and view in SDK compilation/Razor generation.
- Migrated the dashboard's legacy action links to tag helpers, corrected malformed card markup, and replaced claims that MSMQ is active with an accurate deferred-messaging notice. The polling URL, same-origin credentials, error behavior, static assets, and visual notification script were not changed.

## Files modified

- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.11-notifications-controller/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.11-notifications-controller/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Controllers/NotificationsController.cs`
- `app/ContosoUniversity/Views/Notifications/Index.cshtml`

## Validation

- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore`: succeeded, 0 errors, 4 known package-audit warnings.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln --no-restore`: succeeded, 0 errors, the same 4 warnings.
- Live ASP.NET Core runtime: `/Notifications/Index` returned 200 and rendered the dashboard heading; both JSON endpoints returned 200, `application/json; charset=utf-8`, and the exact deferred-service error envelopes.
- Disposable controller contract harness: passed success-envelope, exact-property, 10-item-cap, ISO-date, nullable-date, method-attribute, and mark-read forwarding assertions. The harness was removed after execution and did not change the repository.
- Test-project discovery returned an empty list, so no repository .NET tests were available.
- Scenario page smoke attempt: Home returned 200. Students, Courses, Instructors, and Departments returned 500 because no Development SQL connection secret/provider is configured; this is the pre-recorded runtime blocker and is unrelated to the notification migration.
- VS Code diagnostics found no controller or Razor errors. Boundary scans found no `System.Web`, `JsonRequestBehavior`, `System.Messaging`, Service Bus, OData, `Debug.WriteLine`, legacy Razor link helpers, or bundle helpers in the scoped files.
- `git diff --check` passed; Git emitted only the existing line-ending notice for the project file.

## Warnings and blockers

- Four package advisories remain: direct `Microsoft.Data.SqlClient` 2.1.4 (`NU1903`) and transitive `Microsoft.IdentityModel.JsonWebTokens` 6.8.0 (`NU1902`), `System.IdentityModel.Tokens.Jwt` 6.8.0 (`NU1902`), and `System.Drawing.Common` 4.7.0 (`NU1904`). Scenario instructions explicitly reserve dependency CVE remediation for task 07; none was suppressed or changed here.
- Broker-backed success behavior cannot be exercised through the live host until task 04 implements Azure Service Bus. Both success contracts were instead validated deterministically with the fake service; no Service Bus package, configuration, client, or implementation was added.
- Database-backed page smoke validation remains blocked until the Development SQL user secret is supplied. Notification dashboard and endpoint runtime validation completed without database access.
