# Assessment — ContosoUniversity → .NET 10 (`net10.0`)

> Scenario: `dotnet-version-upgrade` · Scope: `app/ContosoUniversity` only · Flow: Guided · Date: 2026-09-30
> Method: **manual/fallback assessment**. `generate_dotnet_upgrade_assessment` was unavailable, so this is based on direct file inspection. No shell was available. Package vulnerability data was **not** checked with tooling; see §12.
> No application source, project, Azure or on-premises resource was changed. No secret values appear in this document.

**Contents:** [1 Summary](#1-summary) · [2 Projects](#2-project-inventory) · [3 Packages](#3-packages-packagesconfig--net-10-replacements) · [4 Toolchain & secrets](#4-toolchain-and-local-sql-auth-user-secret) · [5 MSMQ](#5-msmq--systemmessaging-and-notification-endpoints) · [6 Files](#6-mutable-file-handling-teaching-material-uploads) · [7 Trace/Debug](#7-systemdiagnosticstrace--debug-usage) · [8 Startup/config](#8-webconfig-globalasax-routeconfig-filterconfig-bundleconfig) · [9 Static casing](#9-static-files-casing-and-missing-files-linux) · [10 WinAuth/LocalDB](#10-windows-authentication--localdb-evidence-only) · [11 Tests](#11-test-projects) · [12 Vulnerabilities](#12-known-vulnerable-packages-report-only) · [13 Data access](#13-data-access-and-di-candidates) · [14 Already satisfied](#14-already-satisfied-by-current-source-no-op-candidates) · [15 API breaking changes](#15-flagged-apis--breaking-changes-for-task-1) · [16 Risks](#16-risks-blockers-and-ambiguities) · [17 Recommendations](#17-recommendations-only-not-tasks)

## 1. Summary

| Metric | Value |
|---|---|
| Projects in scope | 1 (`ContosoUniversity.csproj`, in `ContosoUniversity.sln`; the solution contains only this project) |
| Current | .NET Framework 4.8 (`v4.8`; packages.config says `net482`), ASP.NET MVC 5.2.9, legacy (non-SDK) web project, `packages.config` |
| Target | `net10.0`, SDK-style `Microsoft.NET.Sdk.Web`, `PackageReference`, ASP.NET Core MVC |
| C# files | 30 (7 controllers, 10 models + 3 view models, 3 Data, 3 App_Start, Global.asax.cs, NotificationService, PaginatedList, AssemblyInfo) |
| Razor views | 26 (Students 5, Courses 5, Instructors 5, Departments 5, Home 3, Notifications 1, Shared 2) + `_ViewStart` + `Views/Web.config` |
| packages.config entries | 45: 5 are client-side content packages (they become static files), 1–2 are kept as updated PackageReferences (EF Core SqlServer 10, optional Tools; Newtonsoft.Json optional), and the rest are removed as in-box or ASP.NET Core shared framework |
| Data access | Already **EF Core 3.1.32** (not EF6). Uses `EnsureCreated` and a seed initializer. No migrations |
| Windows-only APIs | `System.Messaging` (MSMQ), `Server.MapPath`/`HttpPostedFileBase`, `System.Web.*` |
| Test projects | None |
| .NET 10 SDK | Present: `10.0.401` (found by directory inspection) |
| User secret `ConnectionStrings:DefaultConnection` | Not available: the project has **no `UserSecretsId`**. **Runtime validation BLOCKED** until one is set |

## 2. Project inventory

| Project | Current state | Proposed target |
|---|---|---|
| `app/ContosoUniversity/ContosoUniversity.csproj` | Legacy ToolsVersion 15 web project (`ProjectTypeGuids` MVC/Web), `OutputType Library`, `TargetFrameworkVersion v4.8`, HintPath references into `packages\`, custom `CopySQLClientNativeBinaries` target (SNI DLL copy), `IISExpressWindowsAuthentication=enabled`, IIS URL `https://localhost:44300/` | `Microsoft.NET.Sdk.Web`, `net10.0`, `PackageReference`, `Program.cs` minimal hosting, `wwwroot` static files, container properties (`ContainerBaseImage=mcr.microsoft.com/dotnet/aspnet:10.0`, `ContainerRepository=contoso-university`, `ContainerPort` = listening port, e.g. 8080, the default for aspnet 8+ images) |

The csproj lists explicit `Compile`/`Content` items. Several files exist on disk but are **not** listed, so a legacy publish would skip them: `Views/Notifications/Index.cshtml`, `Scripts/notifications.js`, `Content/notifications.css`, and the slim/vsdoc jQuery files. SDK globbing fixes this.

## 3. Packages (packages.config) → .NET 10 replacements

| Package(s) | Current | .NET 10 action |
|---|---|---|
| Microsoft.AspNet.Mvc / Razor / WebPages | 5.2.9 / 3.2.9 / 3.2.9 | **Remove**. Use the ASP.NET Core shared framework (`Microsoft.AspNetCore.App`) |
| Microsoft.AspNet.Web.Optimization, WebGrease, Antlr | 1.1.3 / 1.5.2 / 3.4.1.9004 | **Remove**. Serve bundles as static `<link>`/`<script>` files |
| Microsoft.Web.Infrastructure, Microsoft.CodeDom.Providers.DotNetCompilerPlatform | 2.0.1 / 2.0.1 | **Remove** (System.Web-only) |
| Microsoft.EntityFrameworkCore (+Abstractions, Analyzers, Relational, SqlServer) | 3.1.32 | **Microsoft.EntityFrameworkCore.SqlServer 10.0.x** (brings the rest transitively) |
| Microsoft.EntityFrameworkCore.Tools | 3.1.32 | 10.0.x if design-time tooling is needed (optional; there are no migrations) |
| Microsoft.Data.SqlClient / .SNI.runtime | 2.1.4 / 2.1.1 | **Remove direct refs**. EF Core SqlServer 10 brings a current SqlClient (6.x) transitively. Delete the `CopySQLClientNativeBinaries` target |
| Microsoft.Identity.Client | 4.21.1 | **Remove direct ref** (transitive via SqlClient/Azure.Identity if needed) |
| Microsoft.Extensions.* (Caching, Configuration, DI, Logging, Options, Primitives) | 3.1.32 | **Remove**. In the shared framework at 10.0 |
| Newtonsoft.Json | 13.0.3 | Keep 13.0.3 (latest), or switch to System.Text.Json. See the JSON shape risk in §5 |
| System.Buffers, System.Memory, System.Numerics.Vectors, System.Runtime.CompilerServices.Unsafe, System.Threading.Tasks.Extensions, System.Collections.Immutable, System.ComponentModel.Annotations, System.Diagnostics.DiagnosticSource, Microsoft.Bcl.AsyncInterfaces, Microsoft.Bcl.HashCode, NETStandard.Library | various 4.x/1.x/2.0.3 | **Remove** (in-box on .NET 10) |
| bootstrap, jQuery, jQuery.Validation, Microsoft.jQuery.Unobtrusive.Validation, Modernizr | 5.3.3 / 3.7.1 / 1.21.0 / 4.0.0 / 2.6.2 | **Not NuGet on .NET 10**. Ship as static files under `wwwroot`. **Drift:** the files on disk are jQuery **3.4.1** and Bootstrap JS **3.4.1**, and `Content/bootstrap.css` is missing (§9) |
| GAC `System.Messaging` | .NET Framework | **No .NET 10 equivalent**. Task 1: interim in-process queue. Task 4: `Azure.Messaging.ServiceBus` |

Later tasks add these packages (latest stable at execution time): `Azure.Identity`, `Azure.Storage.Blobs` (T3), `Azure.Messaging.ServiceBus` (T4), `Azure.Extensions.AspNetCore.Configuration.Secrets` (T5), `Azure.Monitor.OpenTelemetry.AspNetCore` (T6).

## 4. Toolchain and local SQL-auth user secret

- **.NET SDK:** `C:\Program Files\dotnet\sdk\10.0.401` exists, so the .NET 10 SDK is installed. This was found by directory inspection because no shell was available to run `dotnet --list-sdks`. There is no `global.json` in the repo or `app/`.
- **UserSecretsId:** **absent** from `ContosoUniversity.csproj`, which is expected for a .NET Framework web project. `dotnet user-secrets list` therefore does not apply to the project and was not run. No user-secrets store is associated with this project.
- **`ConnectionStrings:DefaultConnection` user secret:** **NOT available.**
- **Status:** **Runtime validation (the `dotnet run` page checks in every task) is BLOCKED** until two things happen:
  1. Task 1 makes the project SDK-style and adds a `UserSecretsId`.
  2. The student sets `ConnectionStrings:DefaultConnection` (SQL auth, existing `contosoapp` login, on-premises SQL Server) with `dotnet user-secrets set`.
- This is a blocked validation, not an impossible task. Never fall back to LocalDB.
- `Web.config` `DefaultConnection` points to LocalDB with Integrated Security. That is evidence only and must not be carried into appsettings as a fallback.

## 5. MSMQ / System.Messaging and notification endpoints

**Files:** `Services/NotificationService.cs`, `Controllers/BaseController.cs`, `Controllers/NotificationsController.cs`, `Models/Notification.cs`, `Scripts/notifications.js`, `Content/notifications.css`, `Views/Notifications/Index.cshtml`, `Views/Shared/_Layout.cshtml` (includes the js/css), `Web.config` (`NotificationQueuePath`), and `NOTIFICATION_SYSTEM_README.md`.

**`NotificationService`** (concrete class, no interface; has `Dispose()` but does not implement `IDisposable`):
- **Queue:** the path comes from `ConfigurationManager.AppSettings["NotificationQueuePath"]`, default `.\Private$\ContosoUniversityNotifications` (a local private queue). If the queue is missing, the service creates it with `MessageQueue.Create` and grants `Everyone` FullControl. Messages use `XmlMessageFormatter(typeof(string))`.
- **Send:** `SendNotification(entityType, entityId, [displayName], EntityOperation, userName)` builds a `Notification`, serializes it with `JsonConvert.SerializeObject`, and sends it as a `Message` (Label `"{entityType} {operation}"`, Priority Normal). Exceptions are swallowed and go to `Debug.WriteLine`.
- **Receive:** `ReceiveNotification()` does a destructive `Receive(TimeSpan.FromSeconds(1))`. It returns null on IOTimeout and on other errors, which it logs with Debug.
- **Other members:** `MarkAsRead(int)` is a **no-op**. `GenerateMessage` produces "New X has been created" / "X has been updated" / "X has been deleted".

**Semantics to preserve:**
- **Senders:** every successful Create, Edit and Delete in the Students, Courses, Instructors and Departments controllers calls `BaseController.SendEntityNotification`, with `CreatedBy="System"`. Instructors send no display name.
- **Readers:** reads are **destructive** (read once, then removed), at most 10 per poll, with no DB persistence. The `Notification` table exists in the model but is never written.

**Wiring:** `BaseController` creates the service with a field initializer, `new NotificationService()`, so there is one MSMQ handle per controller instance and **no DI**. It is disposed in `BaseController.Dispose`.

**JSON endpoints.** These are conventional routes; the "api/notifications" code comments are misleading.

| Route | Method | Consumer | Response shape |
|---|---|---|---|
| `/Notifications/GetNotifications` | GET (`[HttpGet]`, `JsonRequestBehavior.AllowGet`) | `notifications.js` `fetch(..., {method:'GET', credentials:'same-origin'})` polls every 5 s | Success: `{ success: true, notifications: [Notification...], count: n }`. Error: `{ success: false, message: "Error retrieving notifications" }` |
| `/Notifications/MarkAsRead` | POST (`[HttpPost]`, `id` int from form/query, no antiforgery) | **No consumer** in `notifications.js` | `{ success: true }` or `{ success: false, message: "Error updating notification" }` |
| `/Notifications/Index` | GET | Nav link | Razor view (static text mentions MSMQ and the queue path) |

**`Notification` object fields in the JSON (PascalCase):** `Id`, `EntityType`, `EntityId`, `Operation` ("CREATE"/"UPDATE"/"DELETE"), `Message`, `CreatedAt`, `CreatedBy`, `IsRead`, `ReadAt`. `notifications.js` reads `data.success`, `data.notifications`, `n.Operation`, `n.EntityType`, `n.Message`, `n.CreatedBy` and `n.CreatedAt`.

**Migration risks:**
- **(a) Property-name casing:** ASP.NET Core `Json()` uses System.Text.Json with **camelCase** by default, which would break `notifications.js`. Set `JsonSerializerOptions.PropertyNamingPolicy = null`, or use `AddNewtonsoftJson` with the default resolver, so the PascalCase `Notification` properties survive. The top-level anonymous keys are already lowercase.
- **(b) Date format:** MVC 5 `JsonResult` (JavaScriptSerializer) emits `CreatedAt` as `"\/Date(ms)\/"`, which `new Date(...)` in the JS cannot parse. ASP.NET Core emits ISO-8601, which the JS parses correctly. This is a serialization detail that fixes the "time ago" text; see ambiguity A2.
- **(c) Task 1:** replace MSMQ with an **interim in-process queue** (for example a singleton `Channel`/`ConcurrentQueue` behind an `INotificationService` interface) that keeps the destructive read-once, max-10 semantics.
- **(d) Task 4:** use Service Bus with `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName`, authenticated with `DefaultAzureCredential`.

## 6. Mutable file handling (teaching-material uploads)

- **Location:** `Controllers/CoursesController.cs` (Create, Edit, DeleteConfirmed), `Models/Course.TeachingMaterialImagePath` (`[StringLength(255)]`), `Views/Courses/{Index,Details,Edit,Create}.cshtml`, and `TEACHING_MATERIAL_UPLOAD.md`.
- **Upload (Create/Edit POST):** takes the `HttpPostedFileBase teachingMaterialImage` form field (`enctype=multipart/form-data`, `accept="image/*"`).
  - **Validation:** extension (lower-cased) must be one of `.jpg .jpeg .png .gif .bmp`; size ≤ **5 MB** (`5*1024*1024`). Errors go to `ModelState["teachingMaterialImage"]` with the existing messages. There is no content-type or magic-byte check.
- **Naming and storage:**
  - File name: `course_{CourseID}_{Guid}{ext}`.
  - Storage: `Server.MapPath("~/Uploads/TeachingMaterials/")`; the directory is created if missing.
  - DB value: `~/Uploads/TeachingMaterials/{fileName}`. Existing rows in the on-premises DB will contain this legacy format.
- **Replace (Edit):** before saving the new file, deletes the old file at `Server.MapPath(course.TeachingMaterialImagePath)`. That path comes from a **hidden form field**, `@Html.HiddenFor(TeachingMaterialImagePath)`.
- **Delete (DeleteConfirmed):** deletes the file if it exists. Errors are swallowed with `Debug.WriteLine`, and the course is still deleted.
- **Retrieval/serving:**
  - Views render `<img src="@Url.Content(path)">`, and IIS serves `/Uploads/TeachingMaterials/*` directly as static files. Thumbnails are 50 px on Index, 200 px on Edit, 300 px on Details. The Delete view shows no image.
  - In ASP.NET Core, `Uploads/` is outside `wwwroot`, so Task 1 must keep images reachable (for example an app route or static file provider).
  - Task 3 moves storage to Blob (`Storage:BlobServiceUri`, `Storage:ContainerName`) and **serves the images through an app action, never through blob URLs**. It must map the legacy `~/Uploads/...` values to blob names.
- **Request limits:** see §8. `maxRequestLength` is 10240 KB and `maxAllowedContentLength` is 10485760 bytes (10 MB). Preserve these with Kestrel `MaxRequestBodySize` or `[RequestSizeLimit]` and `FormOptions`. The in-app 5 MB rule stays.
- **Disk state:** `Uploads/TeachingMaterials/` holds only `.gitkeep`, and `.gitignore` excludes uploads. The csproj lists `course_1045_2b7f6522-….jpg`, which is **not on disk**, so course 1045 may render a broken image locally.

## 7. System.Diagnostics.Trace / Debug usage

| File | Calls |
|---|---|
| `Controllers/StudentsController.cs` | `Trace.TraceError` ×3 (Create, Edit, DeleteConfirmed catch blocks). Messages include student names, dates and stack traces |
| `Services/NotificationService.cs` | `Debug.WriteLine` ×2 (send failure, receive failure) |
| `Controllers/NotificationsController.cs` | `Debug.WriteLine` ×2 (GetNotifications, MarkAsRead) |
| `Controllers/BaseController.cs` | `Debug.WriteLine` ×1 (SendEntityNotification) |
| `Controllers/CoursesController.cs` | `Debug.WriteLine` ×1 (file delete failure) |
| **Total** | **Trace 3, Debug 6** in 5 files. No trace listeners are configured in Web.config. The `Microsoft.Extensions.Logging` 3.1.32 package is referenced but unused |

Both APIs still compile on .NET 10, so Task 1 can leave them. Task 6 replaces them with `ILogger<T>`.

## 8. Web.config, Global.asax, RouteConfig, FilterConfig, BundleConfig

- **Web.config `connectionStrings` names:** `DefaultConnection` (the value is not reproduced here; it is LocalDB with Integrated Security, see §10).
- **Web.config `appSettings` keys:**

  | Key | Purpose | .NET 10 action |
  |---|---|---|
  | `webpages:Version`, `webpages:Enabled` | MVC 5 only | Drop |
  | `ClientValidationEnabled`, `UnobtrusiveJavaScriptEnabled` | Client validation | Default on in ASP.NET Core, so drop |
  | `NotificationQueuePath` | MSMQ queue path | Drop in Task 1 (interim queue); replaced by `ServiceBus:*` in Task 4 |

- **Web.config `system.web` / `system.webServer`:**
  - `compilation debug=true targetFramework=4.8` and `httpRuntime maxRequestLength=10240 executionTimeout=3600`.
  - `requestFiltering requestLimits maxAllowedContentLength=10485760`.
  - `validateIntegratedModeConfiguration=false`.
  - Assembly binding redirects: remove all.
  - There is no `<authentication>`/`<authorization>` element and no customErrors.
- **Web.config transforms:** `Web.Debug.config` and `Web.Release.config` are referenced in the csproj but **missing on disk**.
- **Views/Web.config:** Razor namespaces `System.Web.Mvc`, `.Ajax`, `.Html`, `System.Web.Optimization`, `ContosoUniversity`, plus a BlockViewHandler. Replace with `Views/_ViewImports.cshtml` (`@using ContosoUniversity`, `ContosoUniversity.Models`, and `@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers`).
- **Global.asax / Global.asax.cs** (`MvcApplication.Application_Start`):
  - `AreaRegistration.RegisterAllAreas()` (there are no areas).
  - Calls `FilterConfig`, `RouteConfig` and `BundleConfig`.
  - `InitializeDatabase()` reads the connection string with `ConfigurationManager`, runs `DbInitializer.Initialize` (`EnsureCreated` + seed) against `DefaultConnection`. Move this to a startup scope in `Program.cs`.
- **RouteConfig:**
  - `IgnoreRoute("{resource}.axd/{*pathInfo}")` can be dropped.
  - `Default` route `{controller}/{action}/{id}` with defaults `Home/Index/id optional` maps to `MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}")`.
- **FilterConfig:**
  - `filters.Add(new HandleErrorAttribute())` maps to `UseExceptionHandler("/Home/Error")` outside Development, or the equivalent. Preserve the `Error` view.
  - The commented-out `AuthorizeAttribute` is not active.
- **BundleConfig:**

  | Bundle | Includes | Used in |
  |---|---|---|
  | `~/bundles/jquery` | `~/Scripts/jquery-{version}.js` (resolves to jquery-3.4.1.js) | _Layout |
  | `~/bundles/jqueryval` | `~/Scripts/jquery.validate*` (validate, unobtrusive; vsdoc ignored) | Create/Edit views via `@section Scripts` |
  | `~/bundles/modernizr` | `~/Scripts/modernizr-*` | _Layout |
  | `~/bundles/bootstrap` | `~/Scripts/bootstrap.js`, `~/Scripts/respond.js` | _Layout |
  | `~/Content/css` | `~/Content/bootstrap.css` (**missing**), `~/Content/site.css` (**casing: file is `Site.css`**) | _Layout |

  In ASP.NET Core these become explicit `<link>`/`<script>` tags (optionally `asp-append-version`) over `wwwroot`.
- **Razor sections:** `_Layout` also links `~/Content/notifications.css` and `~/Scripts/notifications.js` directly, and calls `RenderSection("scripts", false)` while views define `@section Scripts`. Razor section names are case-insensitive, but verify this after the upgrade.

## 9. Static files: casing and missing files (Linux)

| Reference | Referenced as | On disk | Issue |
|---|---|---|---|
| BundleConfig `~/Content/css` | `~/Content/site.css` | `Content/Site.css` | **Case mismatch**: 404 on Linux |
| BundleConfig `~/Content/css`, csproj | `Content/bootstrap.css`, `bootstrap.min.css`, `.map` files | **missing** | The layout uses Bootstrap 5 markup (`navbar-expand-lg`, `me-auto`, `card`) but no Bootstrap CSS is present. packages.config declares bootstrap 5.3.3 |
| `~/bundles/bootstrap` | `Scripts/bootstrap.js` | present, **Bootstrap v3.4.1** | Version mismatch with Bootstrap 5 markup and package 5.3.3 |
| `~/bundles/jquery` | `jquery-{version}.js` | `jquery-3.4.1.js` | packages.config declares 3.7.1 (drift) |
| csproj | `favicon.ico`, `ROLE_SETUP_GUIDE.md`, `Project_Readme.txt`, `Web.Debug.config`, `Web.Release.config`, `Uploads/…/course_1045_….jpg` | missing | Stale csproj items; they disappear with SDK-style globbing |
| _Layout | `~/Content/notifications.css`, `~/Scripts/notifications.js` | same casing | OK |
| notifications.js | `/Notifications/GetNotifications` | controller `NotificationsController.GetNotifications` | OK (MVC routing is case-insensitive) |

## 10. Windows Authentication / LocalDB (evidence only)

The following are **local hosting and database evidence only, not an identity requirement**. No Entra user sign-in is planned.
- **csproj IIS Express settings:** `IISExpressWindowsAuthentication=enabled`, `IISExpressAnonymousAuthentication=disabled`, `NTLMAuthentication=False`, `IISUrl https://localhost:44300/`.
- **Web.config:** `DefaultConnection` uses `(LocalDb)\MSSQLLocalDB` with `Integrated Security=True`, catalog name `ContosoUniversityNoAuthEFCore`.
- **Code has no identity logic:**
  - No `[Authorize]`, roles or `User.Identity` usage anywhere.
  - `BaseController` hard-codes `userName = "System"` ("No authentication").
  - `HomeController.Unauthorized` exists but has no view.
- **Stale text** that Task 1 may correct:
  - `Views/Home/Index.cshtml` says "Entity Framework 6 … with Windows Authentication".
  - `NOTIFICATION_SYSTEM_README.md` and `TEACHING_MATERIAL_UPLOAD.md` mention admin login and roles.
  - `Views/Notifications/Index.cshtml` mentions MSMQ, admin-only access, and "8 seconds" auto-dismiss, while the JS actually uses 60 s.

## 11. Test projects

- **None** for ContosoUniversity; the solution has one project.
- Repo-level `test/` holds PowerShell/Node checks (`Test-Preflight.Tests.ps1`, `*.test.mjs`). They are out of scope and must not be run, per the owner decision.
- Validation will therefore be build + `dotnet run` page checks (home, Students, Courses, Instructors, Departments), plus manual send/receive checks for notifications.

## 12. Known-vulnerable packages (report only)

**Not tool-verified in this run.** No shell was available, so `dotnet list package --vulnerable` and the NuGet audit could not run. The entries below come from public advisories (GitHub Advisory Database / Microsoft Security Response Center). Task 7 must confirm them with a fresh audit. No other CVEs are claimed.

| Package | Current | Advisory (source) | Fixed in | Disposition |
|---|---|---|---|---|
| Microsoft.Data.SqlClient | 2.1.4 | CVE-2024-0056 / GHSA-98g6-xh36-x2p7, High (GitHub Advisory DB, MSRC Jan 2024) | 2.1.7 (and later lines) | Direct ref removed in Task 1. EF Core 10 brings a patched 6.x |
| Microsoft.Identity.Client | 4.21.1 | CVE-2024-35255 / GHSA-m5vv-6r4h-3vj9, Medium (GitHub Advisory DB) | 4.61.3 | Direct ref removed in Task 1. Task 7 checks the transitive version |
| jQuery (static file, not NuGet) | 3.4.1 on disk | CVE-2020-11022, CVE-2020-11023 (jQuery 3.5.0 security release / GitHub Advisory DB) | 3.5.0 | Static asset outside the NuGet audit. Recommendation only (§17) |

- **Out of support:** EF Core 3.1 and the Microsoft.Extensions 3.1 packages are out of support; they are replaced in Task 1.
- **Supported, but removed on .NET 10:** ASP.NET MVC 5.2.9 is supported only on .NET Framework and is removed by the upgrade.

## 13. Data access and DI candidates

- **Stack:**
  - **EF Core 3.1.32 with SQL Server** (`UseSqlServer`). There is **no EF6** (the `System.Data.Entity` reference is not used for EF6).
  - No migrations folder. The schema comes from `EnsureCreated()` plus `DbInitializer` seeding, which is skipped when any Student exists.
  - Against the unchanged on-premises DB, `EnsureCreated` is a no-op when the database already exists.
- **`Data/SchoolContext`** (ctor takes `DbContextOptions<SchoolContext>`):
  - **DbSets:** Courses, Enrollments, Departments, OfficeAssignments, CourseAssignments, People, Students, Instructors, Notifications.
  - **Mappings:**
    - All `DateTime`/`DateTime?` columns are `datetime2` (reflection loop).
    - Tables: `Course`, `Enrollment`, `Department`, `OfficeAssignment`, `CourseAssignment`, `Notification`, and `Person` (TPH with string `Discriminator`, values `Student`/`Instructor`).
    - `CourseAssignment` has a composite key (CourseID, InstructorID) and FKs to Course and Instructor.
    - `Instructor` 1:1 `OfficeAssignment` (FK/PK `InstructorID`).
  - **Conventions and annotations:**
    - `Department.InstructorID` is an FK to `Administrator` by convention.
    - `Department.RowVersion` is `[Timestamp]` (concurrency is handled in `DepartmentsController.Edit`) and `Budget` is `money`.
    - `Person.FirstMidName` maps to column `FirstName`.
    - `Course.CourseID` is `DatabaseGeneratedOption.None`.
    - `Enrollment.Grade` is a nullable enum.
- **`Data/SchoolContextFactory.Create()`:**
  - Static; reads `ConfigurationManager.ConnectionStrings["DefaultConnection"]`.
  - `BaseController` calls it in its ctor, so each controller gets its own `db`.
  - Replace with `AddDbContext<SchoolContext>(o => o.UseSqlServer(config.GetConnectionString("DefaultConnection")))`.
  - Instructors/Departments `Dispose` also dispose `db`. With DI, controllers must not dispose the injected context.
- **EF Core 3.1 → 10 notes:**
  - Queries use `Include`/`ThenInclude`, `Find`, `.Single()` (throws rather than NotFound; preserve), string `Contains` (LIKE), `GroupBy` + `Count` (About page, translatable), and `DbUpdateConcurrencyException` with `GetDatabaseValues`.
  - The Microsoft.Data.SqlClient 4+ default is **`Encrypt=True`**. A connection to the on-premises SQL Server may need a trusted certificate or `TrustServerCertificate` **inside the student's secret**; code must pass it unchanged (Task 2 rule).
- **DI candidates:**
  - `SchoolContext` (scoped).
  - `INotificationService` (singleton interim in-process queue in Task 1, Service Bus in Task 4).
  - Later: file storage service (Task 3, Blob), `IWebHostEnvironment` (replaces `Server.MapPath`), `ILogger<T>` (Task 6).

## 14. Already satisfied by current source (no-op candidates)

| Task | Already satisfied | Still required |
|---|---|---|
| 1 .NET 10 / ASP.NET Core MVC | ORM is already **EF Core**, so no EF6 → EF Core model rewrite is needed. The entity model, relationships and mappings exist and only need to be preserved. The connection name is already `DefaultConnection`. There is no user sign-in, so nothing to remove | Everything else: SDK-style project, net10.0, PackageReference, Program.cs, DI, static files/casing, MSMQ → interim queue, views/controllers API port, container properties, UserSecretsId |
| 2 SQL Managed Instance | Reads `ConnectionStrings:DefaultConnection` by name. Plain `UseSqlServer` with no credential rewriting | Guard: outside Development, refuse user/password. Entra-only connection on Azure. Development pass-through verification |
| 3 Blob Storage | None (local disk) | Full |
| 4 Service Bus | None (MSMQ) | Full |
| 5 Key Vault | None | Full |
| 6 OpenTelemetry | None (a Logging package is referenced but unused) | Full |
| 7 CVE audit | Unknown until the fresh audit. The two candidate advisories (§12) are expected to disappear through Task 1 package removal | Audit. Record as a verified no-op if the audit is clean |

## 15. Flagged APIs / breaking changes for Task 1

- **Controllers:**
  - `System.Web.Mvc.Controller` → `Microsoft.AspNetCore.Mvc.Controller`.
  - `HttpStatusCodeResult(HttpStatusCode.BadRequest)` → `BadRequest()`; `HttpNotFound()` → `NotFound()`.
  - `[Bind(Include="…")]` → `[Bind("…")]`.
  - `TryUpdateModel(obj, "", string[])` → `await TryUpdateModelAsync(obj, "", i => …)` (InstructorsController.Edit).
  - `Json(obj, JsonRequestBehavior.AllowGet)` → `Json(obj)`.
  - `SelectList` → `Microsoft.AspNetCore.Mvc.Rendering`.
  - `TempData` and `ViewBag` remain.
- **Uploads:** `HttpPostedFileBase` (`ContentLength`, `SaveAs`) → `IFormFile` (`Length`, `CopyToAsync`). `Server.MapPath` → `IWebHostEnvironment`.
- **Views:**
  - `@Styles.Render`/`@Scripts.Render` → tags.
  - `Error.cshtml` uses `System.Web.Mvc.HandleErrorInfo` and `HttpContext.Current.IsDebuggingEnabled`, so rewrite it (for example with `ErrorViewModel`, which already exists).
  - `Html.ActionLink`, `BeginForm`, `EditorFor`, `AntiForgeryToken` and `ValidationMessage` exist in ASP.NET Core.
  - The Razor `@:` raw-text usage in Instructors views is supported.
- **Startup/configuration:**
  - `Global.asax`/`App_Start` → `Program.cs`.
  - `ConfigurationManager` → `IConfiguration`.
  - `Web.config` → `appsettings.json` / `appsettings.Development.json` / user secrets.
- **Messaging:** `System.Messaging` is not available on .NET 10 and must be replaced (interim queue).
- **JSON:** default camelCase must be disabled to keep the PascalCase notification shape (§5).

## 16. Risks, blockers and ambiguities

| # | Item | Severity |
|---|---|---|
| B1 | **Runtime validation BLOCKED**: there is no UserSecretsId or `DefaultConnection` secret yet. It is unblocked after Task 1 adds a UserSecretsId and the student sets the secret. Never use LocalDB | Blocker (validation) |
| R1 | Static assets are broken or inconsistent: Bootstrap CSS missing, `site.css` casing, Bootstrap 3 JS vs Bootstrap 5 markup and package. "Preserve user-visible behavior" cannot be checked against a styled baseline | High |
| R2 | JSON casing and date format change for `notifications.js` (§5) | High |
| R3 | MSMQ removal: the interim queue must keep destructive, max-10 read semantics. Notifications are per-process and are lost on restart until Task 4 | Medium |
| R4 | `Encrypt=True` default in SqlClient 4+ may affect the connection to the on-premises SQL Server; handle it in the secret, not in code | Medium |
| R5 | Upload path value `~/Uploads/...` is stored in DB rows that already exist; Task 3 must map legacy values to blob names | Medium |
| R6 | Request-size limits (10 MB) must be re-applied on Kestrel | Low |
| A1 | Which Bootstrap to ship in `wwwroot`? Recommendation: Bootstrap **5.3.3** CSS+JS (matches packages.config and the layout markup) and jQuery 3.7.1 (matches packages.config); the orchestrator should confirm. Alternative: keep the on-disk 3.4.1 JS and add the matching CSS | Decision |
| A2 | Keep the MVC 5 `"\/Date(ms)\/"` date format, or emit ISO-8601? Recommendation: ISO-8601. The JS already calls `new Date(value)`, and property names and structure stay identical | Decision |
| A3 | No `dotnet --list-sdks`/shell was available. SDK 10.0.401 presence was inferred from `C:\Program Files\dotnet\sdk`. The first Task 1 build confirms it | Info |

## 17. Recommendations only (not tasks)

- **Edit upload path:** Course Edit deletes the file at `Server.MapPath` of a **client-posted hidden field**, which allows tampered path deletion. Constrain deletes to the uploads folder or the blob container, for example as a Task 3 detail.
- **XSS:** `notifications.js` builds HTML with `innerHTML` from entity names, a stored-XSS risk. Consider `textContent`.
- **Unused endpoint:** `MarkAsRead` POST has no antiforgery token and no consumer.
- **Details error handling:** `Details` actions use `.Single()`, which throws a 500 instead of returning 404.
- **Missing view:** `HomeController.Unauthorized` has no view.
- **Static files:** the on-disk jQuery 3.4.1 has published advisories, so update the static files. Remove stale csproj items and stale docs (`README.md`, which mentions IIS Express, LocalDB and MSMQ prerequisites).
- **Stale view text:** the `Notifications/Index` text (MSMQ, 8 s auto-dismiss, admin-only) is stale.
