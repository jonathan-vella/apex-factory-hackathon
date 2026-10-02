# .NET Version Upgrade Plan

## Overview

**Target**: app/ContosoUniversity (ContosoUniversity.csproj) — ASP.NET MVC 5 on .NET Framework 4.8 to ASP.NET Core MVC on .NET 10 (net10.0), then Azure-ready backends (SQL Managed Instance, Blob Storage, Service Bus, Key Vault, Azure Monitor) for an existing App Service for Linux (containers).
**Scope**: 1 project (old-style WAP csproj, packages.config), ~3.4k LOC, 45 packages (26 need upgrade, 2 incompatible), 89 API issues dominated by MSMQ, System.Web and legacy configuration. No test projects exist.

### Selected Strategy
**All-At-Once** — the single project is upgraded in one atomic in-place rewrite (Task 01); Tasks 02–07 then modernize the upgraded net10.0 app in a strict chain.
**Rationale**: 1 project on net48 with no project references; framework migration rules mandate All-at-Once for a single project.

### Validation baseline (applies to every task)
- `dotnet build` of app/ContosoUniversity succeeds.
- Local `dotnet run` on vm-dev01: home, Students, Courses, Instructors and Departments pages load.
- Database-backed runtime checks use the `ConnectionStrings:DefaultConnection` user secret (on-prem SQL login, Development only). Never fall back to LocalDB.
- **BLOCKED (current state)**: the legacy csproj has no `UserSecretsId`, so no user secret can exist for this project yet. Runtime page-load validation for every task is blocked until Task 01 adds `UserSecretsId` and the owner sets `ConnectionStrings:DefaultConnection` via `dotnet user-secrets`. This is blocked, not impossible — build validation is unaffected.
- Blob, Service Bus and Key Vault checks run from vm-dev01 inside the spike VNet via private DNS and DefaultAzureCredential (owner's Azure CLI sign-in); they are expected to run, not be blocked.

## Upgrade Options

| Option | Selected | Why |
|--------|----------|-----|
| Upgrade Strategy | All-at-Once | Single .NET Framework project, no project references |
| Project Approach (Web) | In-place rewrite | Small web surface (7 controllers); user-confirmed |
| Unsupported Packages | Resolve Inline | Only 2 incompatible packages (Web.Optimization, plus MVC 5 stack folded into the framework) |
| Unsupported API Handling | Fix Inline | MSMQ/System.Web/ConfigurationManager fixed in place; no stubs |
| System.Web Adapters | Direct Migration to ASP.NET Core APIs | In-place rewrite; no adapters |
| Assembly Binding Redirects | Remove Binding Redirects | 12 redirect issues (6 mandatory); not used on .NET 10 |
| Nullable Reference Types | Leave Disabled | Avoid noise during migration |
| Test Coverage | Skip | User-confirmed; no existing tests |

## Tasks

### 01-aspnetcore-net10: Upgrade to .NET 10 and ASP.NET Core MVC

**Depends on**: none

Rewrite ContosoUniversity in place as an SDK-style `Microsoft.NET.Sdk.Web` project targeting net10.0 with PackageReference (packages.config removed), deleting the MVC 5 / WebPages / Web.Optimization / CodeDom / WebGrease / Antlr / Microsoft.Web.Infrastructure references, the facade packages now in the framework, the SNI copy target and all binding redirects. EF Core 3.1.32 and Microsoft.Extensions 3.1.32 move to their net10.0-compatible versions; preserve the EF Core entity model, relationships and mappings (`SchoolContext`, `DbInitializer.EnsureCreated` seeding). Replace Global.asax/App_Start with `Program.cs`: default route `{controller=Home}/{action=Index}/{id?}`, `HandleErrorAttribute` equivalent (exception handler + `Error` view; `Views/Shared/Error.cshtml` uses `HttpContext.Current.IsDebuggingEnabled`), static files for CSS/JS, and DI registration of `SchoolContext` (replacing `SchoolContextFactory`/`ConfigurationManager` and the per-controller `new`) and of the notification service. Controllers move from `System.Web.Mvc` (`HttpStatusCodeResult`, `HttpNotFound`, `[Bind(Include=…)]`, `HttpPostedFileBase`, `Server.MapPath`, `JsonRequestBehavior`) to ASP.NET Core equivalents; Razor views move off `Styles.Render`/`Scripts.Render` bundles to explicit `<link>`/`<script>` tags; TempData use in StudentsController must keep working. Add `UserSecretsId` so the Development connection string can come from user secrets.

Configuration: migrate Web.config into appsettings.json / appsettings.Development.json — `ConnectionStrings:DefaultConnection` key name kept but **no value committed** (the LocalDB/Integrated Security value is not carried over), upload limits (`maxRequestLength` 10240 KB / `maxAllowedContentLength` 10 MB → Kestrel/form limits), drop MVC 5-only keys (`webpages:*`, `ClientValidationEnabled`, `UnobtrusiveJavaScriptEnabled` are defaults in Core). `NotificationQueuePath` (MSMQ) is replaced by an interim in-process notification queue registered as a singleton — MSMQ/System.Messaging is removed here but Service Bus is **not** introduced until Task 04. Notification JSON endpoints used only by Scripts/notifications.js must keep routes, methods and JSON shape: `GET /Notifications/GetNotifications` → `{ success, notifications: [ { Id, EntityType, EntityId, Operation, Message, CreatedAt, CreatedBy, IsRead, ReadAt } ], count }` (PascalCase item properties — Core's default camelCase would break `notification.Operation` etc.), error `{ success:false, message }`; `POST /Notifications/MarkAsRead` (`id`) → `{ success }`; plus the `Notifications/Index` view. No Web API/OData surface — do not apply the `migrating-webapi-odata` skill.

Static assets and casing (Linux): BundleConfig references `~/Content/site.css` but the file is `Content/Site.css`; csproj lists `Content/bootstrap.css`, `bootstrap.min.css` (+maps), `favicon.ico`, `Web.Debug.config`, `Web.Release.config`, `ROLE_SETUP_GUIDE.md`, `Project_Readme.txt` and an `Uploads/TeachingMaterials/course_1045_….jpg` that are not on disk; `notifications.js`, `notifications.css`, `Views/Notifications/Index.cshtml` and an empty `Services/LoggingService.cs` exist but are not in the csproj (SDK globbing will pick them up). Make file names and references consistent; keep the existing user-visible look. Teaching-material images must still be served from `Uploads/TeachingMaterials` (stored DB values are `~/Uploads/TeachingMaterials/{file}`) with the same validation until Task 03. Windows Authentication (`IISExpressWindowsAuthentication` enabled, anonymous disabled, IIS Express URL in ProjectExtensions) is local hosting evidence only and is dropped with the WAP settings; stale text in `Views/Home/Index.cshtml` ("Entity Framework 6 … MVC 5 … Windows Authentication") and SETUP_TESTING_GUIDE.md may be corrected — no identity/sign-in work. Add SDK container publishing properties (`ContainerBaseImage` `mcr.microsoft.com/dotnet/aspnet:10.0`, `ContainerRepository` `contoso-university`, `ContainerPort` matching the app's listening port, 8080 by default on .NET 10); no Dockerfile, Docker not required.

**Done when**: project is SDK-style net10.0 with PackageReference, no System.Web/System.Messaging/ConfigurationManager/binding redirects remain; `dotnet build` succeeds; `dotnet publish /t:PublishContainer` configuration is present in the csproj; `UserSecretsId` is set and no connection-string value is committed; local `dotnet run` loads home, Students, Courses, Instructors, Departments and the notifications poll returns the preserved JSON shape (runtime checks **BLOCKED** until the owner sets the `ConnectionStrings:DefaultConnection` user secret).

---

### 02-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance

**Depends on**: 01-aspnetcore-net10

Make the EF Core data layer target Azure SQL Managed Instance as the only Azure database (never Azure SQL Database), still reading `ConnectionStrings:DefaultConnection`. On Azure the value uses `Authentication=Active Directory Default` with the MI's private VNet-local host name — no user name/password, never the public data endpoint (port 3342); DefaultAzureCredential (managed identity on Azure, Azure CLI locally) supplies the token through Microsoft.Data.SqlClient. In `Development` only, a SQL-auth connection string for the on-prem SQL Server using the existing `contosoapp` login (from user secrets) is passed to EF Core unchanged; outside `Development` the app must refuse to start if DefaultConnection contains a user name or password. Never auto-convert a SQL-auth string to managed identity.

Preserve the EF Core model and behavior, including `EnsureCreated`/seed on startup (research whether the startup seed is acceptable against SQL MI permissions and keep it behavior-equivalent). Much of the reading path is already satisfied by Task 01 (configuration key and DI registration) — where so, record the implementation step as a no-op with verification. No credentials or connection-string values in source control or planning artifacts; no database, login or on-prem changes.

**Done when**: `dotnet build` succeeds; a startup guard rejects user/password connection strings outside Development (verified by running with `ASPNETCORE_ENVIRONMENT` set to a non-Development value and a credentialed string, then with an `Active Directory Default` string); Microsoft.Data.SqlClient supports `Active Directory Default`; local `dotnet run` (Development, on-prem SQL login via user secret) loads home, Students, Courses, Instructors, Departments — **BLOCKED** until the user secret is supplied.

---

### 03-blob-storage-files: Migrate mutable file handling to Azure Blob Storage

**Depends on**: 02-sql-managed-instance

Move teaching-material image handling in CoursesController (Create, Edit, DeleteConfirmed) from the local `Uploads/TeachingMaterials` folder to Azure Blob Storage using `Azure.Storage.Blobs` with DefaultAzureCredential and configuration `Storage:BlobServiceUri` / `Storage:ContainerName` — no Azure Files, mounts, shared keys, SAS or connection strings. Preserve current behavior exactly: allowed extensions `.jpg .jpeg .png .gif .bmp` (case-insensitive), 5 MB file limit (and the 10 MB request cap), naming `course_{CourseID}_{Guid}{ext}`, replacement deletes the previous file on Edit, Delete removes the file and logs (not fails) on error, field/validation messages and views unchanged.

Images must be served through the app (e.g. a controller action streaming the blob with the right content type); browsers never receive blob URLs and the container has no public access. Courses Index/Details/Edit views currently render `Url.Content(TeachingMaterialImagePath)`; decide how existing stored values (`~/Uploads/TeachingMaterials/{file}`, max 255 chars) map to blob names so old and new rows both work. The Edit form posts `TeachingMaterialImagePath` from a hidden field and the current code deletes whatever path it names — constrain deletes to app-managed blob names. Ordinary CSS/JS/images stay in the app.

**Done when**: `dotnet build` succeeds; no local filesystem writes remain for uploads; local `dotnet run` against the real storage account (via private endpoint) proves upload on Create, replace on Edit (old blob removed), retrieval of the image through the app URL in Index/Details/Edit, and blob deletion on course Delete; invalid type and >5 MB uploads are rejected with the existing messages; home, Students, Courses, Instructors, Departments load. Database-backed steps are **BLOCKED** until the user secret is supplied.

---

### 04-service-bus-messaging: Migrate messaging to Azure Service Bus

**Depends on**: 03-blob-storage-files

Replace the interim in-process notification queue from Task 01 (originally MSMQ `.\Private$\ContosoUniversityNotifications`) with Azure Service Bus using `Azure.Messaging.ServiceBus`, DefaultAzureCredential and configuration `ServiceBus:FullyQualifiedNamespace` / `ServiceBus:QueueName` — no shared access keys, SAS or connection strings. Preserve notification semantics: a JSON-serialized `Notification` is sent on create/edit/delete of Students, Courses, Instructors and Departments (send failures logged, never break the main operation); `GET /Notifications/GetNotifications` reads back up to 10 pending messages per poll (MSMQ receive was destructive with a 1-second timeout — mirror with receive-and-complete and a short max wait) and returns the unchanged JSON shape; `MarkAsRead` stays a no-op returning success.

Register the Service Bus client/sender/receiver as singletons and dispose cleanly. Do not create, configure or deploy the Service Bus resource.

**Done when**: `dotnet build` succeeds; no MSMQ or in-process queue remains on the runtime path; local `dotnet run` against the real namespace (private endpoint) proves **both** send (create/edit/delete an entity) and receive (notification appears via `GetNotifications` and in the notifications.js toast); home, Students, Courses, Instructors, Departments load. Database-backed steps are **BLOCKED** until the user secret is supplied.

---

### 05-key-vault-config: Integrate Azure Key Vault

**Depends on**: 04-service-bus-messaging

Add the existing Key Vault as an ASP.NET Core configuration source via `Azure.Extensions.AspNetCore.Configuration.Secrets` with DefaultAzureCredential and `KeyVault:VaultUri`. Outside `Development`, the app refuses to start when `KeyVault:VaultUri` is missing; in `Development` it is optional and user secrets remain allowed for the on-prem SQL login — a SQL-auth DefaultConnection in Development is never replaced or reinterpreted. On Azure, secret `ConnectionStrings--DefaultConnection` holds the SQL MI string (Entra auth, no password) and App Service settings carry only `KeyVault:VaultUri` and non-secret endpoints.

Order the Key Vault source so the Task 02 credential guard still evaluates the final DefaultConnection. Do not provision the vault, create secrets or identities, or assign roles; no Entra user sign-in.

**Done when**: `dotnet build` succeeds; startup guard verified (non-Development without `KeyVault:VaultUri` fails fast with a clear message; Development without it starts); with `KeyVault:VaultUri` set, configuration values resolve from Key Vault through the private endpoint (verified via a non-secret check such as the provider being registered and a known key resolving, without printing values); home, Students, Courses, Instructors, Departments load. Database-backed steps are **BLOCKED** until the user secret is supplied.

---

### 06-opentelemetry-azure-monitor: Migrate logging and tracing to OpenTelemetry with Azure Monitor

**Depends on**: 05-key-vault-config

Replace all `System.Diagnostics.Trace`/`Debug` calls with `ILogger<T>`: `Debug.WriteLine` in BaseController (send failure), CoursesController (file-delete error), NotificationsController (2 places), NotificationService (send/receive — superseded by Task 04 code, verify none remain), and `Trace.TraceError` in StudentsController create/edit/delete (these currently include student names and stack traces — log the exception object and IDs, not PII). Add `Azure.Monitor.OpenTelemetry.AspNetCore` with a single `UseAzureMonitor()` call — no individual instrumentation packages or custom exporters — registered only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value, with the credential set to DefaultAzureCredential (local auth disabled). With no connection string nothing extra is registered and built-in console logging is used.

**Done when**: `dotnet build` succeeds; no `System.Diagnostics.Trace`/`Debug` usage remains; app starts and serves home, Students, Courses, Instructors, Departments with no connection string; with a connection string, requests, SQL and HTTP dependencies, and logs from a local run appear in Application Insights within a few minutes. Database-backed steps are **BLOCKED** until the user secret is supplied.

---

### 07-dependency-cve-audit: Audit and remediate dependency CVEs

**Depends on**: 06-opentelemetry-azure-monitor

Run a fresh audit of direct and transitive NuGet dependencies of the final net10.0 app (e.g. `dotnet list package --vulnerable --include-transitive`). For each real advisory, upgrade to the minimum compatible patched version and document any major-version change and breaking-change risk. The assessment flagged Microsoft.Data.SqlClient 2.1.4 as vulnerable without CVE IDs (and Microsoft.Identity.Client 4.21.1 as deprecated); both are expected to be replaced by Tasks 01–02 — re-verify against the fresh audit rather than assuming. Never invent CVE findings; if the audit is clean, this task is a verified no-op.

**Done when**: fresh audit output is recorded with zero unresolved vulnerabilities (or documented no-op); `dotnet build` succeeds; all available tests run (none exist — recorded as such); local `dotnet run` loads home, Students, Courses, Instructors, Departments (**BLOCKED** until the user secret is supplied).

---

## Recommendations

Findings outside the seven tasks — recorded only, not planned work:

- **XSS in notifications.js**: toasts are built with `innerHTML` from `Message`/`CreatedBy`, which include user-entered entity names; consider text-node rendering.
- **Path traversal on Edit**: the posted hidden `TeachingMaterialImagePath` drives file deletion; Task 03 constrains blob deletes, but input validation on that field is worth tightening generally.
- **Missing static assets**: Bootstrap CSS and favicon are referenced but absent, and `_Layout` uses Bootstrap 5 class names; confirm the intended Bootstrap version/source.
- **Error detail leakage**: upload errors surface `ex.Message` to users.
- **Notifications design**: one shared queue is drained by whichever browser polls first (worse with multiple App Service instances); `Notifications` DbSet is unused and `MarkAsRead` is a no-op.
- **`.Single()` on Details/Delete** throws (500) instead of returning 404 for unknown IDs.
- **Stale docs**: README.md (LocalDB connection string), NOTIFICATION_SYSTEM_README.md (MSMQ), TEACHING_MATERIAL_UPLOAD.md and SETUP_TESTING_GUIDE.md should be refreshed after execution.
- **JSON dates**: MVC 5 emitted `/Date(…)/`, which notifications.js could not parse; ISO 8601 from Core fixes the "time ago" display.
- **No test project**: consider adding behavior tests after the upgrade.
