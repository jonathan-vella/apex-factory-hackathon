# Progress details

## 2026-09-28 - Home controller migration

### Outcome
- Migrated `Controllers/HomeController.cs` from `System.Web.Mvc` to ASP.NET Core MVC.
- Added constructor injection for the existing scoped `SchoolContext` and `INotificationService` dependencies required by `BaseController`.
- Preserved all five conventional action routes and action behavior. The CLR method for the `Unauthorized` action is named `UnauthorizedPage` with `[ActionName("Unauthorized")]` to avoid hiding `ControllerBase.Unauthorized()` while retaining `/Home/Unauthorized`.
- Included `HomeController` and `Views/Home/Index.cshtml`, `About.cshtml`, and `Contact.cshtml` in SDK compilation/Razor generation. The three views required no content changes; their existing visible output and model/helper usage are ASP.NET Core-compatible.
- Scoped wire decision remains PASS: these actions render Razor HTML and introduce no OData, JSON/XML serializer, formatter, custom header, auth, or externally pinned response contract.

### Files modified
- `app/ContosoUniversity/Controllers/HomeController.cs`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.06-home-controller/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.06-home-controller/progress-details.md`

### Validation
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore`: PASS, 0 errors, 4 package-vulnerability warnings, no source/Razor warnings.
- Local `dotnet run --no-build` on `http://127.0.0.1:5186`: application started successfully.
- `GET /health`: 200; expected `ok` text present.
- `GET /`: 200; expected `Contoso University` text present.
- `GET /Home/Index`: 200; expected `Welcome to Contoso University` text present.
- `GET /Home/Contact`: 200; expected `Your contact page.` text present.
- `GET /Home/Error`: 200; existing shared error view text present.
- `GET /Home/Unauthorized`: route resolved to `HomeController.UnauthorizedPage`; response remains 500 because neither the baseline nor current repository contains `Views/Home/Unauthorized.cshtml` or `Views/Shared/Unauthorized.cshtml`. No new view was invented because this child explicitly scopes exactly the three existing Home views.
- `GET /Home/About`: route resolved to `HomeController.About`; response was 500 because `ConnectionStrings:DefaultConnection` is absent, so EF reports that no database provider is configured. This is the scenario-recorded missing Development SQL-secret blocker.
- VS Code diagnostics: 0 errors in `HomeController.cs`; four project diagnostics correspond to the package warnings below.
- `git diff --check` on scoped files: PASS.
- No .NET test project exists for this application, so no focused automated test assembly was available.

### Remaining warnings and blockers
- `NU1903`: `Microsoft.Data.SqlClient` 2.1.4, high severity vulnerability (`GHSA-98g6-xh36-x2p7`).
- `NU1902`: transitive `Microsoft.IdentityModel.JsonWebTokens` 6.8.0, moderate vulnerability (`GHSA-59j7-ghrg-fj52`).
- `NU1904`: transitive `System.Drawing.Common` 4.7.0, critical vulnerability (`GHSA-rxg9-xrhp-64gj`).
- `NU1902`: transitive `System.IdentityModel.Tokens.Jwt` 6.8.0, moderate vulnerability (`GHSA-59j7-ghrg-fj52`).
- Package remediation is intentionally deferred to approved top-level task 07; changing these packages here would execute outside child task 01.06.
- Full `About` page output requires the unchanged Development SQL-authenticated connection string to be supplied through .NET user secrets.

### Decomposition
- Evaluated scenario `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: atomic. This child is already the required one-controller migration unit; no further split trigger matched.