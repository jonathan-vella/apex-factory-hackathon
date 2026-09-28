# 01.05-base-controller: Migrate BaseController to ASP.NET Core MVC and constructor injection

# 01.05 Migrate BaseController

## Objective
Migrate the shared controller base before all concrete controllers, replacing manual resource construction with ASP.NET Core MVC and DI.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Controllers/BaseController.cs` only, plus minimal DI registration corrections exposed by this controller

## Established dependencies
`BaseController` owns `SchoolContext`, notification sending, disposal, and the unauthenticated `System` user value. All six concrete controllers inherit it. No authorization attributes exist.

## Research findings
- The project is already SDK-style `Microsoft.NET.Sdk.Web` on `net10.0`. `Program.cs` registers `SchoolContext` and `INotificationService` as scoped services, enables service-provider scope/build validation, and verifies both registrations at startup.
- Code-dependency analysis confirms this controller directly depends on `SchoolContext`, `EntityOperation`, and the concrete `NotificationService`; model dependencies are reached through `SchoolContext`. Six concrete MVC controllers inherit this base and use its protected `db`, `notificationService`, and `SendEntityNotification` members.
- The current base uses `System.Web.Mvc.Controller`, calls `SchoolContextFactory.Create()`, constructs `NotificationService`, and disposes both resources. ASP.NET Core built-in DI should instead constructor-inject `SchoolContext` and `INotificationService`; scoped DI owns both lifetimes.
- Preserve the existing notification overload arguments, the unauthenticated `System` user value, and the catch-all non-fatal notification behavior. Logging remains deferred to task 06, so this child retains the existing diagnostic write rather than introducing `ILogger` or Azure Monitor.
- No custom controller factory, service locator, property injection, third-party DI container, authentication/authorization attribute, controller filter, OData surface, or `// STUB:` marker applies to this file. Global `HandleErrorAttribute` migration remains outside this base-controller child.
- The generated assessment reports 16 ASP.NET Framework/System.Web issues at project scope and removal of the legacy MVC package in favor of framework-provided ASP.NET Core MVC. No generated issue is specific to `BaseController`; the source inventory above identifies this child's concrete API changes.
- Package upgrades, EF Core 10/SQL policy, Blob Storage, Service Bus implementation, Key Vault, telemetry/logging, derived-controller actions/views, and final host cleanup remain owned by their later tasks.

## Wire compatibility
- **Verdict:** PASS carried from the parent host baseline in `breakdown-context.md`. This abstract base emits no response payload, changes no route/model/serializer, and preserves notification helper arguments. The detailed child record will be written to `progress-details.md#wire-compatibility`.

## Decomposition assessment
- Evaluated `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- **Verdict:** atomic. The parent already split each controller into its own child; this child changes one abstract base and one compile include. No stub, multi-project, package-replacement, auth, filter, or messaging-implementation trigger adds an independent unit.

## Steps
1. Reconfirm dependencies with code-dependency analysis and the baseline record.
2. Change to ASP.NET Core MVC APIs and inject `SchoolContext` plus the application notification contract through the constructor.
3. Remove `SchoolContextFactory.Create`, `new NotificationService()`, and controller-owned disposal; scoped DI owns lifetimes.
4. Preserve notification call arguments and non-fatal error behavior. Keep logging migration owned by task 06; do not introduce Azure Monitor here.
5. Include the migrated base in target compilation and build.

## Done when
`BaseController` compiles on net10.0, resolves through DI for derived controllers, manually constructs/disposes neither dependency, and has no `System.Web` reference.
