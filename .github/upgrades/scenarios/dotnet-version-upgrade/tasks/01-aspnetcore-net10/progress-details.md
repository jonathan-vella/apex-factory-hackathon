# Progress: 01-aspnetcore-net10

## Result
- `dotnet build app/ContosoUniversity`: succeeded, 0 warnings, 0 errors. No tests exist in the project.
- Target: net10.0, `Microsoft.NET.Sdk.Web`; EF Core SqlServer pinned to 10.0.12.
- Container publish properties present in csproj (`ContainerBaseImage`, `ContainerRepository`, `ContainerPort` 8080). Publish not run; no Dockerfile.
- No `System.Web`, `System.Messaging`, `ConfigurationManager`, `Scripts.Render`, or `Styles.Render` references remain.

## Files modified
- Project: `ContosoUniversity.csproj` (rewritten SDK-style), `ContosoUniversity.sln` (project type GUID).
- New: `Program.cs`, `appsettings.json`, `appsettings.Development.json`, `Properties/launchSettings.json`, `Views/_ViewImports.cshtml`, `Views/Shared/_ValidationScriptsPartial.cshtml`.
- Rewritten: all six controllers, `BaseController`, `Services/NotificationService.cs` (in-process `ConcurrentQueue`, System.Text.Json).
- Views: `_Layout`, `Error`, `Home/Index`, 8 Create/Edit views (validation scripts now via partial).
- Moved to `wwwroot`: `css/`, `js/notifications.js`, `lib/` (former `Content`/`Scripts`).
- Deleted: `Global.asax(.cs)`, `packages.config`, `App_Start/*`, `Data/SchoolContextFactory.cs`, `Properties/AssemblyInfo.cs`, `Web.config`, `Views/Web.config`.

## Runtime checks
Initially BLOCKED (not failed): the `ConnectionStrings:DefaultConnection` user secret was not set. After the owner set it (2026-10-02), the checks were rerun and passed.

Build: `dotnet build` succeeded, 0 errors, 0 warnings. `dotnet run` (Development) listened on http://localhost:5080 with no startup errors; the process was stopped afterwards.

| URL | Status | Notes |
|---|---|---|
| `/` | 200 | Title "Home Page - Contoso University" |
| `/Students` | 200 | Table renders |
| `/Courses` | 200 | Table renders; 2.37 MB response (cause not investigated) |
| `/Instructors` | 200 | Table renders; 2.03 MB response (cause not investigated) |
| `/Departments` | 200 | Table renders |
| `/Notifications/GetNotifications` | 200 | `{"success":true,"notifications":[],"count":0}`; no items, so PascalCase item properties not verified |
| `/Students/Create`, `/Courses/Create` | 200 | Forms render; Courses form has the file upload field |

Assets referenced by the home page all returned 200 (`/css/site.css`, `/css/notifications.css`, `/js/notifications.js`, `/lib/jquery-3.4.1.min.js`, `/lib/bootstrap.js`, `/lib/modernizr-2.6.2.js`, `/lib/respond.js`); no 404s.

### Styling comparison with legacy (report only, nothing changed)
- Legacy bundled `bootstrap.css` + `site.css`, but `bootstrap.css`/`bootstrap.min.css` were listed in the csproj and missing from the repo, so legacy pages were styled by `site.css` only. The current layout links `site.css` and `notifications.css`; no Bootstrap CSS exists in either version.
- Layout uses Bootstrap 4/5 class names while the bundled JS is Bootstrap 3.4.1.
- `site.css`: 628 lines in both, 14 differing lines; only two reviewed (added emoji icons on navbar brand/links).
- Expected result: essentially identical to legacy. Based on referenced assets and HTTP status; no screenshot tool was used.

## Deviations / notes
- MVC JSON uses `PropertyNamingPolicy = null` (PascalCase) to stay compatible with `notifications.js`.
- Uploads are served from `ContentRoot/Uploads` at `/Uploads`; the 10 MB limits are set via Kestrel and `FormOptions`.
- `Debug.WriteLine`/`Trace.TraceError` left as is (Task 06 owns logging).
- A Bootstrap CSS file is not present on disk (as before), so the layout does not reference one. Recommend adding it.
- `Views/Notifications/Index.cshtml` has a pre-existing unbalanced `</div>`; it compiled without error and was left untouched.
- Decomposition: assessed as atomic. The nested TaskBreaker could not be dispatched (no `agent` tool available).
