## Detected Hints

### hint: web-wire-contract-preservation
- **Status**: active
- **Priority**: MUST
- **Evidence**: `ContosoUniversity.csproj` is an in-place ASP.NET Framework MVC host migration. `NotificationsController` exposes `GET /Notifications/GetNotifications` and `POST /Notifications/MarkAsRead` JSON actions, and `Scripts/notifications.js` consumes the GET envelope and PascalCase notification properties.
- **Detected**: 2026-09-28, during task `01-upgrade-dotnet-aspnet-core`

### hint: web-controller-migration-units
- **Status**: active
- **Priority**: MUST
- **Evidence**: Seven controller classes require migration: `BaseController`, `HomeController`, `StudentsController`, `DepartmentsController`, `InstructorsController`, `CoursesController`, and `NotificationsController`. The hint becomes mandatory above five controllers.
- **Detected**: 2026-09-28, during task `01-upgrade-dotnet-aspnet-core`

### hint: web-config-to-appsettings
- **Status**: active
- **Priority**: SHOULD
- **Evidence**: `Web.config` contains `DefaultConnection`, four app settings, request-size settings, and 22 binding redirects; `Global.asax.cs` and `SchoolContextFactory.cs` use legacy configuration.
- **Detected**: 2026-09-28, during task `01-upgrade-dotnet-aspnet-core`

### hint: web-bundling-and-static-assets
- **Status**: active
- **Priority**: SHOULD
- **Evidence**: `Microsoft.AspNet.Web.Optimization`, `App_Start/BundleConfig.cs`, `@Scripts.Render`, `@Styles.Render`, root `Content/` and `Scripts/`, and no `wwwroot` are present. The assessed notification CSS/JavaScript project-inclusion and casing discrepancies also require reconciliation.
- **Detected**: 2026-09-28, during task `01-upgrade-dotnet-aspnet-core`

### hint: system-messaging-replacement
- **Status**: resolved
- **Priority**: MUST
- **Evidence**: `NotificationService` directly uses MSMQ, but the approved plan already isolates the actual broker replacement in top-level task `04-azure-service-bus`. Task 01 may introduce only a compile-safe application contract and must not implement Service Bus or another broker.
- **Detected**: 2026-09-28, during task `01-upgrade-dotnet-aspnet-core`

### hint: web-auth-migration-isolation
- **Status**: resolved
- **Priority**: MUST
- **Evidence**: No `[Authorize]`, application authentication middleware, or `Web.config` authentication/authorization/membership sections exist. Legacy IIS Express flags and stale documentation mention Windows Authentication, while `BaseController` explicitly uses the unauthenticated `System` identity. Task 01 must not introduce Microsoft Entra ID or another application sign-in system.
- **Detected**: 2026-09-28, during task `01-upgrade-dotnet-aspnet-core`

## Wire Compatibility

### scope: ContosoUniversity MVC host
- **Project approach**: In-place rewrite
- **Decision**: PASS
- **OData/Atom signal**: absent; no OData package, routes, formatters, Atom media types, or OData serializers were found.
- **Custom serializer signal**: absent; the host uses MVC `JsonResult` with anonymous envelopes and the default Newtonsoft behavior, with no custom converter or formatter registration.
- **Pinned external non-OData shape signal**: absent; repository search found only the coordinated in-repo `Scripts/notifications.js` consumer and notification documentation, with no external client binding, schema, contract test, or externally owned consumer.
- **Explicit preservation hint signal**: absent for an external protocol. The approved plan requires behavior preservation, so the internal JSON contract remains an acceptance requirement rather than a STOP signal.
- **Contract to preserve**: `GET /Notifications/GetNotifications` returns HTTP 200 JSON with either `{ success: false, message }` or `{ success: true, notifications, count }`, limits results to 10, and emits notification properties with their existing PascalCase names used by the script (`Operation`, `EntityType`, `Message`, `CreatedBy`, `CreatedAt`). `POST /Notifications/MarkAsRead` returns HTTP 200 JSON with `{ success: true }` or `{ success: false, message }`. No action has an authorization attribute or custom response header.
- **Evidence**: `Controllers/NotificationsController.cs`, `Scripts/notifications.js`, `Models/Notification.cs`, `App_Start/RouteConfig.cs`, `NOTIFICATION_SYSTEM_README.md`, `SETUP_TESTING_GUIDE.md`, package/configuration searches, and the generated project assessment.
- **Preservation decision**: Migrate these actions as raw ASP.NET Core MVC JSON actions; do not add OData. Re-run the gate if endpoint consumers, serializer settings, routes, or response models change.

## Breakdown Decisions

### task: 01-upgrade-dotnet-aspnet-core
- Broken into 12 subtasks based on hints: `web-wire-contract-preservation`, `web-controller-migration-units`, `web-config-to-appsettings`, `web-bundling-and-static-assets`, and the core dependency/validation-gate triggers.
- Order the work as baseline/gate, SDK host, configuration and deferred-service boundaries, static/shared Razor infrastructure, one subtask for each of the seven controllers, then cleanup and full validation.
- Keep SQL Managed Instance policy and EF 10 migration in task 02, Blob implementation in task 03, Service Bus implementation in task 04, Key Vault in task 05, telemetry in task 06, and final CVE audit/remediation in task 07.

### task: 01.01-wire-contract-baseline
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. This child is the already-isolated mandatory baseline/wire-gate unit; it records evidence only and leaves SDK conversion, configuration, static assets, controllers, and validation to their existing sibling tasks.
- No stub-resolution, multi-project ordering, package replacement, Windows API isolation, controller migration, authentication migration, or other independent implementation concern is in this child's scope.

### task: 01.02-sdk-host
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The scope is one dependency-free WAP and one ordered gate: dedicated SDK conversion, original-framework build check, approved `net10.0` retarget, minimal ASP.NET Core host, and `/health` validation.
- The parent breakdown already isolates configuration, static assets, each controller, final cleanup, EF/SQL, MSMQ, authentication, and telemetry. No stubs exist, and no multi-project, unknown replacement, or Windows API hint adds an independent unit to this child.

### task: 01.03-configuration-di-boundaries
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. This child is the already-isolated configuration/container gate: ASP.NET Core configuration, scoped `SchoolContext`, and a resolvable notification contract that defers broker operations.
- The parent breakdown already isolates controllers, static assets, final validation, EF/SQL policy, Blob, Service Bus, Key Vault, and telemetry. The mandatory `system-messaging-replacement` hint remains satisfied by top-level task 04; no replacement is attempted here. No stubs, custom config sections, third-party DI container, authentication scope, multi-project ordering, or package-replacement research trigger applies.

### task: 01.04-static-shared-razor
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. This child is the dedicated shared Razor, bundling-removal, and static-asset unit created for the active `web-bundling-and-static-assets` hint.
- The parent breakdown already isolates every controller and feature view, configuration/DI, final validation, Blob, messaging, authentication, and telemetry. No stubs, multi-project ordering, package-replacement research, controller migration, or other independent concern is in scope.

### task: 01.05-base-controller
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent already isolated the shared abstract base from each concrete controller; this child is one coherent MVC namespace, constructor-injection, and DI-lifetime migration with a focused compile gate.
- The parent wire-contract PASS remains current because this abstract base owns no route or response serialization. No stubs, multi-project ordering, unknown package replacement, third-party container, auth/filter conversion, or messaging implementation is in scope; later top-level concerns remain deferred.

### task: 01.06-home-controller
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent already isolated each controller; this child is the single `HomeController` feature unit with its three existing Razor views and a focused build/runtime gate.
- The scoped wire gate remains PASS because all five actions are conventional MVC view actions with no OData, JSON/XML serialization, custom headers, auth, or external response-shape contract. No stubs, multi-project ordering, package replacement, third-party DI, middleware, static-assets, Windows API, or messaging implementation is in scope.

### task: 01.07-students-controller
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent already isolated each controller; this child is the single `StudentsController` feature unit with five Razor views and the framework-neutral pagination helper.
- The scoped wire gate remains PASS because all eight actions return Razor views, redirects, or status results with no OData, JSON/XML serialization, custom headers, auth, or external response-shape contract. No stubs, multi-project ordering, package replacement, third-party DI, middleware, static-assets, Windows API, or messaging implementation is in scope.

### task: 01.08-departments-controller
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent already isolated each controller; this child is the single `DepartmentsController` feature unit with five Razor views and its controller-owned optimistic-concurrency behavior.
- The scoped wire gate remains PASS because all eight actions return Razor views, redirects, or status results with no OData, JSON/XML serialization, custom headers, auth, or external response-shape contract. No stubs, multi-project ordering, package replacement, third-party DI, middleware, static-assets, Windows API, or messaging implementation is in scope.

### task: 01.09-instructors-controller
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent already isolated each controller; this child is the single `InstructorsController` feature unit with five Razor views and its controller-owned office and course-assignment behavior.
- The scoped wire gate is not applicable to serialization because all eight actions return Razor views, redirects, or status results with no OData, JSON/XML serialization, custom headers, auth, or external response-shape contract. No stubs, multi-project ordering, package replacement, third-party DI, middleware, static-assets, Windows API, or messaging implementation is in scope.

### task: 01.10-courses-controller
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. The parent already isolated each controller; this child is the single `CoursesController` feature unit with five Razor views and minimal `IWebHostEnvironment` path plumbing for its existing local upload lifecycle.
- The scoped wire gate is not applicable to serialization because all eight actions return Razor views, redirects, or status results with no OData, JSON/XML serialization, custom headers, auth, or external response-shape contract. No stubs, multi-project ordering, package replacement, third-party DI, middleware, static-pipeline migration, messaging implementation, or Blob implementation is in scope.