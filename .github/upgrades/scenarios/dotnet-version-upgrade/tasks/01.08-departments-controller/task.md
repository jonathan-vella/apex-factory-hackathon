# 01.08-departments-controller: Migrate DepartmentsController and department Razor views

# 01.08 Migrate DepartmentsController

## Objective
Migrate department CRUD, administrator selection, and optimistic-concurrency behavior as one controller-owned unit.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Scope
- `Controllers/DepartmentsController.cs`
- `Views/Departments/*.cshtml`

## Established surface
Eight actions cover Index, Details, Create GET/POST, Edit GET/POST, Delete GET/POST. The edit path handles `RowVersion` concurrency and repopulates administrator choices; POSTs use anti-forgery.

## Steps
1. Re-run controller dependency analysis and verify shared DI/route/filter prerequisites.
2. Migrate MVC results, binding, validation, anti-forgery, select-list construction, and not-found/bad-request behavior.
3. Preserve concurrency exception handling and RowVersion round-tripping without changing the EF model or database policy.
4. Migrate all department views/forms and preserve notification calls through the task-04 boundary.
5. Build and runtime-check when SQL configuration is available, otherwise record the precise blocker.

## Done when
All eight actions and department views compile and preserve CRUD/concurrency behavior; no SQL MI, Service Bus, or telemetry migration is included.

## Research findings

- **Project state**: `ContosoUniversity.csproj` is already SDK-style, targets `net10.0`, and uses the ASP.NET Core host, conventional `{controller=Home}/{action=Index}/{id?}` route, scoped `SchoolContext`, and `INotificationService` registration established by earlier children.
- **Controller unit**: `DepartmentsController` owns eight conventional MVC actions and five Razor views. Its dependency graph resolves through `BaseController` to `SchoolContext`, `Department`, `Instructor`, EF Core concurrency APIs, and the existing notification abstraction. No project references or test dependants exist.
- **Binding and status contract**: nullable GET ids return 400 when absent and 404 when no department exists. Create and Edit POSTs retain explicit property allowlists, anti-forgery validation, invalid-model view responses, and successful redirects to Index. The POST action named `Delete` retains anti-forgery and redirect semantics.
- **Concurrency contract**: Edit posts `DepartmentID` and `RowVersion`, catches `DbUpdateConcurrencyException`, reports database values for changed fields, reports deletion by another user, replaces the posted row version with the current database value, repopulates administrator choices, and renders the same Edit view so a second save can retry.
- **Visible output**: preserve headings, labels, validation messages, administrator selection placeholder, currency/date display metadata, action links, and delete confirmation text. Existing shared `_ViewImports.cshtml` enables ASP.NET Core Tag Helpers; no custom view engine, display mode, explicit master, or view-location override exists.
- **Notification boundary**: successful create, edit, and delete operations continue calling `SendEntityNotification`; broker replacement remains deferred to top-level task 04.
- **Assessment findings**: the generated project assessment reports 157 project-wide issues, including System.Web MVC/Razor incompatibilities and EF Core 3.1-to-10 package recommendations. Earlier children already converted the project/host; this child addresses only the remaining `System.Web.Mvc` controller and legacy Razor helper usage in the Departments feature. Package upgrades, SQL policy, MSMQ replacement, and telemetry are outside this child.
- **Stubs**: no `// STUB:` markers exist in the affected project.
- **Validation constraints**: no matching .NET test project exists. Build is required. Runtime database/page validation remains blocked when the Development `DefaultConnection` user secret is absent; the host health endpoint can still be checked without SQL access.

## Wire Compatibility

- **Verdict**: scoped PASS, reusing the evidence in `../01.01-wire-contract-baseline/progress-details.md`.
- Departments actions return Razor views, redirects, 400, or 404 results only. They expose no OData, Atom, JSON/XML response contract, custom formatter, serializer, response header, authorization rule, or external protocol consumer. Preserve the baseline routes, methods, statuses, and anti-forgery behavior.

## Decomposition verdict

- Evaluated `dotnet-version-upgrade/execution.md` and `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- **Atomic**: the parent already isolated this one controller and its five views. No stub, multi-project ordering, package replacement, authentication, middleware, static-asset, Windows API, or messaging implementation trigger adds an independent concern.
