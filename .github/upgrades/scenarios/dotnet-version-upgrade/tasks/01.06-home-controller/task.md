# 01.06-home-controller: Migrate HomeController and its Razor views

# 01.06 Migrate HomeController

## Objective
Migrate the simplest concrete controller and its three views as the first MVC feature unit.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Controllers/HomeController.cs`
- `Views/Home/Index.cshtml`, `About.cshtml`, `Contact.cshtml`

## Established surface
Five actions: Index, About, Contact, Error, Unauthorized. No auth attributes; About queries enrollment statistics through the inherited context.

## Steps
1. Re-run controller dependency analysis and confirm implicit route/filter dependencies.
2. Migrate action results and MVC namespace to ASP.NET Core while preserving conventional routes, ViewBag content, response status behavior, and visible output.
3. Migrate associated Razor helpers/models as needed without redesigning the UI.
4. Include this controller/views in target compilation, build, and smoke-test Home endpoints; record SQL-secret blocking separately for database-backed About behavior.

## Done when
All five Home actions and three views compile and match the baseline, Home Index serves successfully, and the scoped wire PASS remains valid.

## Execution research
- `HomeController` is a view-serving MVC controller with five conventional GET actions and no authorization, attribute routing, custom headers, JSON/XML responses, child actions, custom binders, or action filters.
- The effective route is `{controller=Home}/{action=Index}/{id?}` in `Program.cs`, matching the legacy `{controller}/{action}/{id}` default in `App_Start/RouteConfig.cs`. The legacy global filter only added `HandleErrorAttribute`; no controller-specific filter dependency exists.
- Roslyn dependency analysis resolves `BaseController`, `SchoolContext`, `INotificationService`, `EnrollmentDateGroup`, and the EF model graph. The base controller, scoped context, notification contract, model compilation, conventional route, `_ViewImports.cshtml`, `_ViewStart.cshtml`, and shared layout are already included by prior child tasks.
- The concrete controller still imports `System.Web.Mvc`, returns legacy `ActionResult`, and has no constructor to satisfy the migrated base constructor. The SDK project excludes all concrete controllers and all Home Razor views until this child includes them.
- `Index`, `Contact`, `Error`, and `Unauthorized` render views; `Contact` sets `ViewBag.Message` to `Your contact page.` and `Unauthorized` sets `ViewBag.Message` to `You don't have permission to access this resource.` `About` groups students by enrollment date and renders `IEnumerable<EnrollmentDateGroup>`.
- The three scoped views preserve their existing visible text and model. `Index` uses compatible `Url.Action`; `About` uses compatible `DisplayFor`; `Contact` uses only Razor/ViewBag and static HTML. No view-location override, child action, partial, custom helper, or removed Razor API applies.
- The generated project assessment flags the broader `System.Web` MVC surface and incompatible legacy MVC/Razor packages. This child addresses only the controller namespace/action-result surface and Razor compilation; package modernization and unrelated controllers remain in their owning tasks. No `// STUB:` markers exist in the affected project.
- Runtime `About` validation requires `ConnectionStrings:DefaultConnection` from Development user secrets. Missing SQL credentials are a recorded runtime blocker, not a reason to change query behavior.

## Wire Compatibility
- **Decision:** PASS (carried from the host baseline in `breakdown-context.md`; rechecked for this scope).
- Home actions produce Razor HTML only. They expose no OData/Atom, formatter, serializer, pinned external JSON/XML shape, or externally owned protocol contract. Conventional action URLs, HTTP 200 behavior for successful view rendering, ViewBag values, and visible HTML remain the acceptance contract.

## Decomposition assessment
- Evaluated scenario `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`, plus the `migrating-webapi-odata` decomposition rule.
- **Verdict: atomic.** The parent already split each of seven controllers into its own child; this task is exactly one controller plus its three feature views. No stubs, multi-project ordering, package replacement, auth, third-party DI, middleware, static-asset pipeline, Windows API, or messaging implementation is in scope.

## Planned validation
1. Build `ContosoUniversity.csproj` with zero errors and zero warnings.
2. Run the app and verify `/health`, `/`, `/Home/Index`, and `/Home/Contact` return HTTP 200 with preserved visible content.
3. Exercise `/Home/About`; verify output when a Development SQL secret is available, otherwise record the expected SQL-configuration blocker precisely.
4. Verify scoped source and views contain no remaining `System.Web` references and the existing host wire PASS remains valid.
