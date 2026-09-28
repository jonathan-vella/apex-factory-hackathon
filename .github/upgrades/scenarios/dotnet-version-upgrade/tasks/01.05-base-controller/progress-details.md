# Progress Details

## 2026-09-28 execution

### Outcome
- Migrated `BaseController` from `System.Web.Mvc.Controller` to ASP.NET Core MVC `Controller`.
- Replaced `SchoolContextFactory.Create()` and concrete `NotificationService` construction with a protected constructor accepting scoped `SchoolContext` and `INotificationService` dependencies.
- Preserved the protected member names used by all six derived controllers, both notification helper overloads, their argument ordering, the unauthenticated `System` user value, and non-fatal exception handling.
- Removed controller-owned disposal. ASP.NET Core scoped DI now owns both lifetimes.
- Included only `Controllers/BaseController.cs` in target compilation; concrete controllers remain excluded for tasks 01.06 through 01.11.

### Wire compatibility
- Parent gate verdict remains **PASS** for the ContosoUniversity MVC host.
- This abstract base declares no route/action and emits no HTTP response body, header, status, or serialized model. It changes no serializer or response contract.
- The later NotificationsController JSON contract remains pinned by the parent baseline in `breakdown-context.md`; this task preserves the notification service call arguments consumed by that controller family.

### Validation
- `dotnet build .\app\ContosoUniversity\ContosoUniversity.csproj --no-restore`: succeeded with 0 errors and 4 package-vulnerability warnings.
- Editor diagnostics: no errors in `Controllers/BaseController.cs`.
- Forbidden-pattern check: no `System.Web`, `SchoolContextFactory.Create`, `new NotificationService`, or `Dispose(` remains in `BaseController.cs`.
- DI registration check: `Program.cs` retains scoped `SchoolContext` and `INotificationService` registrations with `ValidateOnBuild` and `ValidateScopes` enabled.
- Runtime smoke test: host started at `http://127.0.0.1:5075`; `GET /health` returned HTTP 200 with `ok`. The host was stopped after validation.
- No .NET test project exists for this application. Concrete page validation is deferred until the owning controller tasks compile those controllers; the current host correctly reports no action descriptors at this isolated child boundary.

### Warnings and deferred concerns
- `NU1903`: `Microsoft.Data.SqlClient` 2.1.4, GHSA-98g6-xh36-x2p7 (high).
- `NU1902`: `Microsoft.IdentityModel.JsonWebTokens` 6.8.0, GHSA-59j7-ghrg-fj52 (moderate).
- `NU1904`: `System.Drawing.Common` 4.7.0, GHSA-rxg9-xrhp-64gj (critical).
- `NU1902`: `System.IdentityModel.Tokens.Jwt` 6.8.0, GHSA-59j7-ghrg-fj52 (moderate).
- These warnings predate this child and remain explicitly owned by top-level task 07. No warning was suppressed and no package was changed outside this task's scope.
- Logging migration remains owned by task 06; the existing diagnostic write is intentionally retained.
- Service Bus implementation remains owned by task 04; this task injects the existing compile-safe notification contract only.

### Files modified
- `app/ContosoUniversity/Controllers/BaseController.cs`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.05-base-controller/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.05-base-controller/progress-details.md`

### Blockers
- None for child task 01.05.