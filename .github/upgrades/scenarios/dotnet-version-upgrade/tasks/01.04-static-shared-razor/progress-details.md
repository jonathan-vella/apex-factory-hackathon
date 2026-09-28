# Progress details

## 2026-09-28 execution

### Outcome
- Added ASP.NET Core MVC services, conventional routing, and `UseStaticFiles()` while retaining `/health` and leaving all controllers excluded for their existing sibling tasks.
- Added shared Core Razor imports, migrated the layout to Tag Helpers/direct local assets, and migrated the error view from `System.Web.Mvc.HandleErrorInfo` to `ErrorViewModel`.
- Deleted `App_Start/BundleConfig.cs` and `Views/Web.config`; no legacy bundle render calls or old `/Content`/`/Scripts` paths remain in shared Razor scope.
- Moved immutable assets into lowercase `wwwroot/css` and `wwwroot/js`. Preserved `notifications.js` behavior and endpoint/JSON expectations unchanged.
- Restored local Bootstrap 3.4.1 CSS to match the existing Bootstrap 3.4.1 JavaScript. The versioned file SHA-256 is `6D92DFC1700FD38CD130AD818E23BC8AEF697F815B2EA5FACE2B5DFAD22F2E11`.
- No favicon existed in the working tree or repository history; removed the stale project entry rather than fabricating one. Mutable `Uploads/TeachingMaterials` remained outside `wwwroot` and unchanged.
- No Blob, telemetry, controller, endpoint, serializer, or Azure implementation was added.

### Files modified or added
- `.github/upgrades/scenarios/dotnet-version-upgrade/breakdown-context.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.04-static-shared-razor/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/01.04-static-shared-razor/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`
- `app/ContosoUniversity/Views/_ViewImports.cshtml`
- `app/ContosoUniversity/Views/Shared/_Layout.cshtml`
- `app/ContosoUniversity/Views/Shared/Error.cshtml`
- `app/ContosoUniversity/wwwroot/css/bootstrap.min.css`
- `app/ContosoUniversity/wwwroot/css/site.css`
- `app/ContosoUniversity/wwwroot/css/notifications.css`
- `app/ContosoUniversity/wwwroot/js/bootstrap.js`
- `app/ContosoUniversity/wwwroot/js/bootstrap.min.js`
- `app/ContosoUniversity/wwwroot/js/jquery-3.4.1-vsdoc.js`
- `app/ContosoUniversity/wwwroot/js/jquery-3.4.1.js`
- `app/ContosoUniversity/wwwroot/js/jquery-3.4.1.min.js`
- `app/ContosoUniversity/wwwroot/js/jquery-3.4.1.min.map`
- `app/ContosoUniversity/wwwroot/js/jquery-3.4.1.slim.js`
- `app/ContosoUniversity/wwwroot/js/jquery-3.4.1.slim.min.js`
- `app/ContosoUniversity/wwwroot/js/jquery-3.4.1.slim.min.map`
- `app/ContosoUniversity/wwwroot/js/jquery.validate-vsdoc.js`
- `app/ContosoUniversity/wwwroot/js/jquery.validate.js`
- `app/ContosoUniversity/wwwroot/js/jquery.validate.min.js`
- `app/ContosoUniversity/wwwroot/js/jquery.validate.unobtrusive.js`
- `app/ContosoUniversity/wwwroot/js/jquery.validate.unobtrusive.min.js`
- `app/ContosoUniversity/wwwroot/js/modernizr-2.6.2.js`
- `app/ContosoUniversity/wwwroot/js/notifications.js`
- `app/ContosoUniversity/wwwroot/js/respond.js`
- `app/ContosoUniversity/wwwroot/js/respond.min.js`

### Files deleted after relocation or cleanup
- `app/ContosoUniversity/App_Start/BundleConfig.cs`
- `app/ContosoUniversity/Content/Site.css`
- `app/ContosoUniversity/Content/notifications.css`
- `app/ContosoUniversity/Scripts/bootstrap.js`
- `app/ContosoUniversity/Scripts/bootstrap.min.js`
- `app/ContosoUniversity/Scripts/jquery-3.4.1-vsdoc.js`
- `app/ContosoUniversity/Scripts/jquery-3.4.1.js`
- `app/ContosoUniversity/Scripts/jquery-3.4.1.min.js`
- `app/ContosoUniversity/Scripts/jquery-3.4.1.min.map`
- `app/ContosoUniversity/Scripts/jquery-3.4.1.slim.js`
- `app/ContosoUniversity/Scripts/jquery-3.4.1.slim.min.js`
- `app/ContosoUniversity/Scripts/jquery-3.4.1.slim.min.map`
- `app/ContosoUniversity/Scripts/jquery.validate-vsdoc.js`
- `app/ContosoUniversity/Scripts/jquery.validate.js`
- `app/ContosoUniversity/Scripts/jquery.validate.min.js`
- `app/ContosoUniversity/Scripts/jquery.validate.unobtrusive.js`
- `app/ContosoUniversity/Scripts/jquery.validate.unobtrusive.min.js`
- `app/ContosoUniversity/Scripts/modernizr-2.6.2.js`
- `app/ContosoUniversity/Scripts/notifications.js`
- `app/ContosoUniversity/Scripts/respond.js`
- `app/ContosoUniversity/Scripts/respond.min.js`
- `app/ContosoUniversity/Views/Web.config`

## Wire Compatibility
- **Scope:** Shared Razor/static asset infrastructure for the ContosoUniversity MVC host.
- **Decision:** PASS, reusing the parent host record in `breakdown-context.md`.
- **OData/Atom:** Absent; this child adds no OData package, formatter, serializer, or route.
- **Notification contract:** `wwwroot/js/notifications.js` still calls `GET /Notifications/GetNotifications`, reads the `{ success, notifications, count }` envelope, and consumes PascalCase `Operation`, `EntityType`, `Message`, `CreatedBy`, and `CreatedAt` properties. Its contents were relocated without contract changes.
- **Affected endpoints:** None. Controllers and raw JSON actions remain owned by sibling tasks.

### Validation
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --no-restore`: succeeded, 0 errors and 4 pre-existing NuGet vulnerability warnings.
- `dotnet run --no-build --project app/ContosoUniversity/ContosoUniversity.csproj --urls http://127.0.0.1:5184`: host started successfully in Production. The expected `No action descriptors found` informational message remains because controller siblings are intentionally excluded.
- HTTP 200 runtime probes with expected MIME types: `/health`, `/css/bootstrap.min.css`, `/css/site.css`, `/css/notifications.css`, `/js/modernizr-2.6.2.js`, `/js/jquery-3.4.1.min.js`, `/js/bootstrap.min.js`, `/js/respond.min.js`, `/js/notifications.js`, `/js/jquery.validate.min.js`, and `/js/jquery.validate.unobtrusive.min.js`.
- Scoped search for `System.Web.Optimization`, `BundleConfig`, `Scripts.Render`, `Styles.Render`, `~/Content/`, and `~/Scripts/`: zero matches.
- Scoped search for Blob and telemetry implementation signals: zero matches.
- `Content/` and `Scripts/` existence check: both absent.
- `git diff --check` for application and task artifacts: passed; Git emitted only its existing CRLF-to-LF notice for the project file.
- No .NET test project exists for this application, so no .NET tests were available to run.

### Warnings and blockers
- `NU1903`: direct `Microsoft.Data.SqlClient` 2.1.4 has a known high-severity vulnerability.
- `NU1902`: transitive `Microsoft.IdentityModel.JsonWebTokens` 6.8.0 has a known moderate-severity vulnerability.
- `NU1904`: transitive `System.Drawing.Common` 4.7.0 has a known critical-severity vulnerability.
- `NU1902`: transitive `System.IdentityModel.Tokens.Jwt` 6.8.0 has a known moderate-severity vulnerability.
- These warnings predate this child and package/EF/CVE remediation is explicitly assigned to later approved tasks. They were not suppressed or changed here to avoid executing sibling scope.
- Home, Students, Courses, Instructors, and Departments page checks cannot run at this child boundary because their controllers and feature views are intentionally excluded until tasks `01.05` through `01.11`; focused `/health` and static-file runtime checks passed.

### Decomposition
Atomic after evaluating `execution.md`, `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`. The active bundling/static-assets hint is fully contained by this existing child; no further split was needed.