# .NET Version Upgrade Plan — ContosoUniversity → .NET 10 + Azure

## Overview

**Target**: `app/ContosoUniversity` (.NET Framework 4.8, ASP.NET MVC 5.2.9, legacy csproj with `packages.config`, EF Core 3.1.32, MSMQ) → `net10.0`, SDK-style `Microsoft.NET.Sdk.Web`, `PackageReference`, ASP.NET Core MVC. Then an Azure migration onto existing services: Azure SQL Managed Instance, Azure Blob Storage, Azure Service Bus, Azure Key Vault, and Application Insights through OpenTelemetry. It is hosted on an existing Azure App Service for Linux (containers). All connections use Microsoft Entra authentication, and all backends are private.
**Scope**: One small web project (the solution contains only this project): 30 C# files (7 controllers), 26 Razor views, 45 `packages.config` entries, and no test projects. See `assessment.md` for details.

### Selected Strategy
**All-At-Once** — the single project is upgraded in place in one pass, followed by six Azure-migration tasks on the upgraded app.
**Rationale**: There is 1 project, and it targets .NET Framework. The single-project rule selects All-at-Once. The owner's requirements fix the plan at exactly seven top-level tasks in a strict chain (01 → 02 → 03 → 04 → 05 → 06 → 07). SDK-style conversion and the TFM retarget are distinct concerns, but both sit inside task 01; the executor may split them into subtasks at execution time.

**Validation baseline (every task)**: `dotnet build` of `app/ContosoUniversity` succeeds. `dotnet run` (Development) serves the home, Students, Courses, Instructors and Departments pages. Validation is limited to `app/ContosoUniversity`; the repo's PowerShell and npm checks are not run.
- **BLOCKED (validation deferred, not dropped):** the local run needs the `ConnectionStrings:DefaultConnection` user secret, which points at the unchanged on-premises SQL Server with the existing SQL login. The project has no `UserSecretsId` today. Task 01 adds one, and then the student sets the secret. Until then, every task's page-load check is BLOCKED. The app never falls back to LocalDB.
- **BLOCKED pending Azure access:** checks against Blob Storage, Service Bus, Key Vault, Application Insights and SQL MI need an Azure CLI sign-in. The private backends also need network line of sight (VNet).
- **No task is IMPOSSIBLE.** No concrete evidence prevents implementing any task.

## Upgrade Options (confirmed from requirements)

| Option | Selected | Why |
|--------|----------|-----|
| Upgrade Strategy | All-at-Once | Single .NET Framework project; the owner fixed exactly seven chained tasks |
| Project Approach — Web Projects | In-place rewrite | Owner requirement: single project, in-place; small web surface (7 controllers) |
| Unsupported Packages | Resolve Inline | Every incompatible package has a known replacement: MVC 5/Optimization → ASP.NET Core shared framework, client packages → `wwwroot` static files, `System.Messaging` → interim in-process queue (Service Bus in task 04) |
| Unsupported API Handling | Fix Inline | The API changes are mechanical MVC 5 → ASP.NET Core ports (assessment §15); no deferred stubs |
| Windows Native APIs | No Compatibility Pack | Target is Linux containers; the only Windows-only API is `System.Messaging`, which is replaced |
| System.Web Adapters | Direct Migration to ASP.NET Core APIs | Small in-place web project, no `HttpContext.Current` in controllers (only in `Error.cshtml`) |
| Assembly Binding Redirects | Remove Binding Redirects | Boilerplate Web.config redirects; not needed on .NET 10 |
| Nullable Reference Types | Leave Disabled | Preserve existing null handling; the migration is already demanding |
| Target framework | `net10.0` | Owner requirement |
| Notification transport before task 04 | Interim in-process queue (singleton) | Owner decision; Service Bus stays in task 04 |
| Web API / OData handling | None; `migrating-webapi-odata` skill and gate not used | Owner decision: no Web API/OData surface; the JSON endpoints are used only by `notifications.js` |
| Container port | 8080 | Default HTTP port of `mcr.microsoft.com/dotnet/aspnet:10.0` (`ASPNETCORE_HTTP_PORTS`) |
| Static client libraries (A1) | Bootstrap 5.3.3 CSS+JS, jQuery 3.7.1 (plus jquery.validation 1.21.0, unobtrusive 4.0.0, modernizr 2.6.2) under `wwwroot` | Matches `packages.config` and the Bootstrap 5 markup in `_Layout`. **Flagged for Guided review** |
| Notification JSON date format (A2) | Default: whatever keeps `notifications.js` working. Verify the consumer first. Use ISO-8601 if the consumer parses it; keep the legacy `"\/Date(ms)\/"` format through a converter only if the consumer depends on it | Owner: preserve routes, methods, property names and shape. **Flagged for Guided review** |
| Commit Strategy | Manual (unchanged) | Owner scenario setting; overrides the All-at-Once default recommendation |

## Tasks

### 01-dotnet10-aspnetcore-mvc: Upgrade to .NET 10 and ASP.NET Core MVC

**Depends on**: none

**Project:** Replace the legacy csproj (ToolsVersion 15, `ProjectTypeGuids`, HintPaths, `CopySQLClientNativeBinaries` target, IIS Express settings, stale Compile/Content items) with an SDK-style `Microsoft.NET.Sdk.Web` project targeting `net10.0`.
- **Packages:** switch from `packages.config` to `PackageReference`.
  - Remove the MVC 5, Razor/WebPages, Web.Optimization, WebGrease, Antlr, CodeDom and Web.Infrastructure packages. Remove the in-box System.*/Bcl packages and the Microsoft.Extensions 3.1 packages.
  - Remove the direct Microsoft.Data.SqlClient/SNI/Microsoft.Identity.Client references; EF Core 10 brings current versions transitively. Remove the binding redirects.
  - Add `Microsoft.EntityFrameworkCore.SqlServer` 10.0.x (and Tools only if needed). Keep or replace Newtonsoft.Json.
- **User secrets:** add a `UserSecretsId`.
- **Container publishing:** add the SDK container properties to the csproj: `ContainerBaseImage` `mcr.microsoft.com/dotnet/aspnet:10.0`, `ContainerRepository` `contoso-university`, `ContainerPort` 8080. No Dockerfile, and Docker is not required.
- **Startup:** replace `Global.asax`/`App_Start` with `Program.cs` minimal hosting and preserve everything:
  - **Route:** the default route `{controller=Home}/{action=Index}/{id?}`.
  - **Error handling:** the `HandleErrorAttribute` global filter becomes `UseExceptionHandler("/Home/Error")` outside Development. Rewrite `Error.cshtml` on `ErrorViewModel`.
  - **Bundles:** BundleConfig bundles become explicit `<link>`/`<script>` tags over `wwwroot` static files.
  - **Database initialization:** move the `EnsureCreated` + `DbInitializer` seeding to a startup scope. This is a no-op against the existing on-premises DB.
  - **Request size:** keep the 10 MB request limit (`maxRequestLength`/`maxAllowedContentLength`) with Kestrel/`FormOptions`.
- **Dependency injection:** register `SchoolContext` with `AddDbContext` + `UseSqlServer(GetConnectionString("DefaultConnection"))`, passing the value unchanged. Register an `INotificationService` singleton backed by an **interim in-process queue** that keeps the destructive read-once, max-10-per-poll semantics (assessment §5). Retire `SchoolContextFactory` and the `new NotificationService()` field initializer. Controllers must not dispose the injected context.
- **Configuration:** move the applicable Web.config settings to `appsettings.json`/`appsettings.Development.json`. Drop `webpages:*`, the client-validation keys and `NotificationQueuePath`. Replace `Views/Web.config` with `Views/_ViewImports.cshtml`.
- **Controllers:** port per assessment §15 (`HttpStatusCodeResult`/`HttpNotFound`, `[Bind]`, `TryUpdateModelAsync`, `Json`, `HttpPostedFileBase` → `IFormFile`, `Server.MapPath` → `IWebHostEnvironment`). Preserve all controllers and actions, all Razor views and user-visible behavior, and the EF Core entity model, relationships and mappings (TPH `Person`, composite `CourseAssignment` key, `datetime2` loop, `RowVersion` concurrency).
- **Teaching-material images:** keep uploads on local disk for now, and keep the existing images reachable at their existing `~/Uploads/TeachingMaterials/...` paths (Uploads sits outside `wwwroot`).

**Already satisfied (verify only, no-op):**
- The ORM is already EF Core; no EF6 → EF Core rewrite.
- The connection name is already `DefaultConnection`.
- There is no user sign-in to remove.

**Items for the user's Guided review:**
- **A1 — static assets:**
  - Fix the `Site.css`/`site.css` casing (Linux is case-sensitive), and make every static file name match its reference.
  - Ship Bootstrap **5.3.3** CSS+JS and jQuery **3.7.1**, consistent with `packages.config` and the Bootstrap 5 page markup. Today the on-disk Bootstrap 3.4.1 JS and jQuery 3.4.1 are out of step, and `bootstrap.css` is missing.
  - These are static files under `wwwroot`, not NuGet.
- **A2 — notification JSON:** preserve the `/Notifications/GetNotifications` (GET), `/Notifications/MarkAsRead` (POST) and `/Notifications/Index` routes and methods, and the response shape.
  - Keep the PascalCase `Notification` property names: turn off the camelCase naming policy, or use Newtonsoft with the default resolver.
  - For `CreatedAt`, check how `notifications.js` actually parses it first. Choose the format that keeps it working. Keep the legacy format with a converter only if the consumer depends on it. Record the choice for review.

Stale view or doc text about Windows Authentication/EF6 (e.g. `Views/Home/Index.cshtml`) may be corrected here.

**Prohibitions:**
- No Microsoft Entra ID user sign-in, `[Authorize]` or identity work. IIS Express Windows Auth and LocalDB `Integrated Security` are only evidence of the local hosting and database setup.
- No LocalDB fallback, and no connection-string value in any committed file.
- No Service Bus (task 04), no Dockerfile, no System.Web adapters, no `migrating-webapi-odata` skill or gate.
- `Trace`/`Debug` calls stay as they are until task 06.

**Config keys read:** `ConnectionStrings:DefaultConnection` (user secrets in Development).

**Research starting points:**
- `Global.asax.cs`, `App_Start/*`, `BaseController`, `NotificationService`, `SchoolContextFactory`, `_Layout.cshtml`, `notifications.js`, `Views/Shared/Error.cshtml`.
- `RenderSection("scripts")` vs `@section Scripts`.
- The `Encrypt=True` default in SqlClient 4+: it is handled inside the student's secret, never in code.

**Done when**:
- `dotnet build` succeeds for `net10.0`, and no `packages.config`, `System.Web` or `System.Messaging` references remain.
- `dotnet run` (Development, user-secret `DefaultConnection`) loads the home, Students, Courses, Instructors and Departments pages with styling.
  - **BLOCKED** until the student sets the secret after the `UserSecretsId` exists.
- Creating, editing or deleting an entity produces a notification that `/Notifications/GetNotifications` returns once, with PascalCase properties.
- A teaching-material upload still validates, saves and displays.
- `dotnet publish /t:PublishContainer` produces an image without a Dockerfile. Use `ContainerArchiveOutputPath` so no Docker daemon is needed; nothing is pushed.
- Tests: none exist, and that is recorded.
- The A1/A2 choices are recorded for review.

---

### 02-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance

**Depends on**: 01-dotnet10-aspnetcore-mvc

Azure SQL Managed Instance is the only Azure database target. Never Azure SQL Database. The app keeps reading `ConnectionStrings:DefaultConnection`.

**Already satisfied (verify only, no-op):**
- Task 01 already reads the connection string by that name.
- Task 01 already passes it unchanged to `UseSqlServer`, with no credential rewriting.

**To implement:** a startup guard.
- **Outside Development:** the app refuses to start when `DefaultConnection` contains a user name or password (`User ID`/`UID`/`Password`/`PWD`, parsed with `SqlConnectionStringBuilder`). The failure message must not echo any value.
- **In Development:** a SQL-authenticated `DefaultConnection` for the on-premises SQL Server (existing login, supplied through user secrets) is passed to EF Core unchanged.
- **No conversion:** the app never converts a SQL-authenticated string to managed identity or Entra.
- **On Azure:** the connection string is supplied by configuration (Key Vault in task 05). It uses `Authentication=Active Directory Default` with no user or password, and the MI's private, VNet-local standard host name.
- **No endpoints in code:** code and appsettings contain no host names.

Preserve the EF Core model and behavior.
- `EnsureCreated` and seeding are no-ops against an existing database. Confirm this; add no migrations and no database creation.
- The provider needs no MI-specific or SQL-Database-specific code.

**Prohibitions:**
- No Azure SQL Database.
- No SQL logins, user names or passwords on Azure.
- No public data endpoint (port 3342), `privatelink` host names, IP addresses or firewall rules.
- No database creation, and no on-premises changes.
- No secrets or connection-string values in source or in artifacts.

**Config keys read:** `ConnectionStrings:DefaultConnection`.

**Done when**:
- `dotnet build` succeeds.
- `dotnet run` (Development, user-secret SQL-auth string passed unchanged) loads the home, Students, Courses, Instructors and Departments pages.
  - **BLOCKED** until the student supplies the secret.
- With a non-Development environment and a placeholder `DefaultConnection` that contains a user or password (dummy, non-secret values), the app refuses to start.
- With an Entra-style placeholder (`Authentication=Active Directory Default`, no password), the guard passes.
  - An actual connection to MI is **BLOCKED pending Azure access** (private VNet endpoint).

---

### 03-blob-storage-files: Migrate mutable file handling to Azure Blob Storage

**Depends on**: 02-sql-managed-instance

Move teaching-material image upload, replacement, retrieval and deletion from local disk to Azure Blob Storage, the only target for mutable files. Blob Storage is accessed through `BlobServiceClient` (`Azure.Storage.Blobs`) authenticated with `DefaultAzureCredential` (`Azure.Identity`), registered in DI behind a small storage abstraction used by `CoursesController`. `Storage:BlobServiceUri` and `Storage:ContainerName` come from configuration.

**Preserve:**
- Validation: `.jpg .jpeg .png .gif .bmp`, 5 MB, the existing `ModelState` messages.
- Naming: `course_{CourseID}_{Guid}{ext}`.
- Replacement cleanup: the old file is deleted on Edit.
- Delete behavior: errors are swallowed and the course is still deleted.
- The controllers, views and the stored `TeachingMaterialImagePath` format. Legacy `~/Uploads/TeachingMaterials/{file}` values map to blob names.

**Rules:**
- **Serve images through the app:** stored images are served through an application action or route that streams the blob with the right content type. Views never link browsers to blob URLs; the account has no public access.
- **Blob names:** derive them from the file name only, so deletes stay inside the container.
- **Local storage:** remove task 01's interim local-disk `Uploads` serving.
- **Static assets:** ordinary CSS, JavaScript and images stay in the app.
- **Page loads:** the pages must still load when Blob is unreachable, because only the image action touches storage. There is no local-disk fallback.

**Prohibitions:**
- No Azure Files, storage mounts, shared keys, SAS tokens or storage connection strings.
- No public blob URLs, and no hard-coded endpoints, `privatelink` names or IPs.
- No container or account creation (`CreateIfNotExists`); the resources already exist.
- No copying of files from the on-premises server.

**Config keys read:** `Storage:BlobServiceUri`, `Storage:ContainerName`.

**Done when**:
- `dotnet build` succeeds.
- `dotnet run` loads the home, Students, Courses, Instructors and Departments pages.
  - **BLOCKED** on the SQL user secret.
- With Azure CLI sign-in and private-network access, Course Create uploads a blob, and the image renders through the app route.
- Edit replaces the blob and removes the old one.
- Delete removes the blob, and invalid type or size is rejected with the existing messages.
- The Azure checks are **BLOCKED pending Azure access**.

---

### 04-service-bus-messaging: Migrate messaging to Azure Service Bus

**Depends on**: 03-blob-storage-files

Replace task 01's interim in-process queue (the MSMQ successor) with an `INotificationService` implementation on `Azure.Messaging.ServiceBus`. It uses a singleton `ServiceBusClient` built from `ServiceBus:FullyQualifiedNamespace` and `DefaultAzureCredential`, targeting `ServiceBus:QueueName`.

**Preserve the notification semantics:**
- **Send:** every successful Create, Edit or Delete in Students, Courses, Instructors and Departments sends a notification.
- **Body and label:** the body keeps the same JSON serialization, and the label becomes `"{entityType} {operation}"` as the message subject.
- **Read:** reads stay destructive (read once, then removed), at most 10 per poll, with a short wait.
- **Endpoint:** `/Notifications/GetNotifications` keeps its route, method and JSON shape.
- **Failures:** send and receive failures are swallowed as before, so pages keep working.
- **MarkAsRead:** remains a no-op.

**Prohibitions:**
- No shared access keys, SAS tokens or Service Bus connection strings.
- No namespace or queue creation (no administration-client calls), provisioning or deployment.
- No hard-coded namespace, `privatelink` names or IPs.

**Config keys read:** `ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName`.

**Done when**:
- `dotnet build` succeeds, and no interim queue or MSMQ code remains.
- `dotnet run` loads the home, Students, Courses, Instructors and Departments pages.
  - **BLOCKED** on the SQL user secret.
- Validation proves **both send and receive**: with Azure sign-in and private-network access, an entity create, edit or delete sends a message to the queue.
- `/Notifications/GetNotifications` then receives it (the notification appears in the UI), and a second poll no longer returns it.
- The Azure checks are **BLOCKED pending Azure access**.

---

### 05-key-vault-config: Integrate Azure Key Vault

**Depends on**: 04-service-bus-messaging

Add the existing Key Vault as an ASP.NET Core configuration source (`Azure.Extensions.AspNetCore.Configuration.Secrets`) through `KeyVault:VaultUri` and `DefaultAzureCredential`.

**Startup rules:**
- **Order:** register the source early, so that `ConnectionStrings--DefaultConnection` becomes `ConnectionStrings:DefaultConnection` before `AddDbContext` and before task 02's guard reads it.
- **Outside Development:** the app refuses to start when `KeyVault:VaultUri` is missing.
- **On Azure:**
  - The vault secret `ConnectionStrings--DefaultConnection` holds the MI connection string (Entra auth, no password).
  - App Service settings carry only `KeyVault:VaultUri` and the non-secret endpoints (`Storage:*`, `ServiceBus:*`, `APPLICATIONINSIGHTS_CONNECTION_STRING`).
- **In Development:**
  - `KeyVault:VaultUri` is optional, and user secrets remain allowed for the on-premises SQL login only.
  - Source ordering must never let Key Vault replace or reinterpret a SQL-authenticated user-secret `DefaultConnection`.

**Prohibitions:**
- No Key Vault provisioning, secret creation, identity creation, role assignment or deployment.
- No hard-coded vault URI, `privatelink` names or IPs.
- No Entra ID user sign-in.
- No secrets in source.

**Config keys read:** `KeyVault:VaultUri`, `ConnectionStrings:DefaultConnection`.

**Done when**:
- `dotnet build` succeeds.
- `dotnet run` (Development, no `KeyVault:VaultUri`) loads the home, Students, Courses, Instructors and Departments pages.
  - **BLOCKED** on the SQL user secret.
- A non-Development run without `KeyVault:VaultUri` refuses to start.
- With a vault URI, Azure sign-in and private-network access, the configuration source loads and `DefaultConnection` resolves from the vault secret. These checks are **BLOCKED pending Azure access**.

---

### 06-opentelemetry-azure-monitor: Migrate logging and tracing to OpenTelemetry with Azure Monitor

**Depends on**: 05-key-vault-config

**Logging:** replace the 3 `Trace.TraceError` and 6 `Debug.WriteLine` calls with injected `ILogger<T>`, using structured messages that pass the exception. The calls are in `StudentsController`, `CoursesController`, `BaseController`, `NotificationsController` and the notification service (assessment §7).

**Azure Monitor:**
- **Package and call:** add `Azure.Monitor.OpenTelemetry.AspNetCore` with a single `UseAzureMonitor()` call.
- **Registration:** register it only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value.
- **Credential:** set `Credential = new DefaultAzureCredential()` so ingestion uses Entra auth; local auth is disabled.
- **No connection string:** register nothing extra. The built-in console logging applies, and the app starts and runs normally.

**Prohibitions:**
- No individual instrumentation packages or custom exporters.
- No instrumentation-key-only or local authentication.
- No hard-coded connection string.

**Config keys read:** `APPLICATIONINSIGHTS_CONNECTION_STRING`, `ApplicationInsights:ConnectionString`.

**Done when**:
- `dotnet build` succeeds, and no `System.Diagnostics.Trace`/`Debug` calls remain.
- Without a connection string, `dotnet run` loads the home, Students, Courses, Instructors and Departments pages with console logging.
  - **BLOCKED** on the SQL user secret.
- With a connection string configured and Azure sign-in, requests, SQL and HTTP dependencies, and logs from a local run appear in Application Insights within a few minutes. This check is **BLOCKED pending Azure access**.

---

### 07-cve-audit: Audit and remediate dependency CVEs

**Depends on**: 06-opentelemetry-azure-monitor

After all other work, run a fresh audit of the direct and transitive NuGet dependencies of `app/ContosoUniversity`: `dotnet list package --vulnerable --include-transitive` plus the NuGet audit on restore.

**For each vulnerability found:**
- Upgrade to the minimum compatible patched version.
- Document any major-version changes and breaking-change risks.

**Candidate advisories from the assessment (not tool-verified):** Microsoft.Data.SqlClient 2.1.4 and Microsoft.Identity.Client 4.21.1. Both direct references are removed in task 01; confirm the transitive versions are patched.

**If the audit finds nothing:** keep this task and record it as a verified no-op.

**Rules:**
- Never invent CVE findings.
- Static jQuery files are outside the NuGet audit (see Recommendations).

**Done when**:
- The audit results are recorded, and every finding is remediated or it is documented that none exist.
- The final `net10.0` app builds.
- All available tests are run. No test projects exist, and that is recorded; repo PowerShell/npm checks are out of scope.
- `dotnet run` loads the home, Students, Courses, Instructors and Departments pages.
  - **BLOCKED** on the SQL user secret.

---

## Requirements Compliance

| Rule | Requirement | How the plan complies |
|---|---|---|
| 1 | .NET 10/ASP.NET Core MVC first; preserve controllers, views, EF Core; SDK container publishing, no Dockerfile | **Task 01** is first and has no dependencies. It preserves controllers, views and the EF Core model. It adds `ContainerBaseImage`/`ContainerRepository`/`ContainerPort` to the csproj and validates with `dotnet publish /t:PublishContainer` (archive output, no Docker, no Dockerfile) |
| 2 | No Microsoft Entra ID user sign-in task | No task adds sign-in. Tasks 01 and 05 prohibit it explicitly. Windows Auth and LocalDB are treated as evidence only, and stale text is corrected within task 01 |
| 3 | Blob Storage and SQL Managed Instance are the only workload targets | **Task 02** targets SQL MI only and prohibits Azure SQL Database. **Task 03** targets Blob only and prohibits Azure Files and mounts |
| 4 | Entra auth only on Azure; SQL auth only in Development against the unchanged on-premises source | Task 02: guard refuses user/password outside Development; Development passes the user-secret string unchanged; no auto-conversion. Tasks 03–06: `DefaultAzureCredential` only; no keys, SAS or connection strings |
| 5 | Key Vault mandatory outside Development; holds `ConnectionStrings--DefaultConnection` | **Task 05**: refuses to start outside Development without `KeyVault:VaultUri`; the vault secret supplies `DefaultConnection`; App Service settings hold only `KeyVault:VaultUri` and non-secret endpoints |
| 6 | Backends private only; web front end and App Insights ingestion are the only public endpoints | Tasks 02–06 read standard host names from configuration only and prohibit `privatelink` names, IPs, port 3342, firewall rules and public blob URLs (images are served through the app). Only the web app and App Insights ingestion are public |
| 7 | OpenTelemetry through the Azure Monitor distro with Entra ingestion, registered only when a connection string is set | **Task 06**: single `UseAzureMonitor()` with `DefaultAzureCredential`, conditional on `APPLICATIONINSIGHTS_CONNECTION_STRING`/`ApplicationInsights:ConnectionString`; `Trace`/`Debug` move to `ILogger<T>`; no extra instrumentation or exporters |
| 8 | Seven-task order with build and local-run validation for every task | Exactly tasks 01 → 07 in a strict chain. Every **Done when** includes `dotnet build` and a `dotnet run` check of the five pages. Blocked checks are recorded as BLOCKED, not dropped |
| 9 | Existing App Service for Linux containers; no provisioning or deployment; no on-premises changes | No task covers provisioning, IaC, role assignment, private endpoint or DNS setup, registry creation, image push, deployment, or database/storage/Service Bus/Key Vault/secret creation. The on-premises SQL Server, database, logins and legacy deployment stay unchanged |

## Recommendations

These are recommendations only, not tasks:
- **jQuery advisories:** the on-disk jQuery 3.4.1 has published advisories (CVE-2020-11022/11023). They are resolved if A1 (ship 3.7.1) is accepted in task 01; otherwise update the static file.
- **XSS in `notifications.js`:** it builds HTML with `innerHTML` from entity names, a stored-XSS risk. Consider `textContent`.
- **`MarkAsRead` endpoint:** the POST has no antiforgery token and no consumer.
- **Details actions:** they use `.Single()`, which returns a 500 instead of a 404 for missing IDs.
- **Missing view:** `HomeController.Unauthorized` has no view.
- **Stale docs and view text:** `README.md`, `NOTIFICATION_SYSTEM_README.md`, `TEACHING_MATERIAL_UPLOAD.md`, and `Views/Notifications/Index.cshtml` (MSMQ, admin-only access, "8 seconds" auto-dismiss) still describe the old setup.
- **Upload validation:** add content-type or magic-byte checks for uploads.
- **Existing uploads:** copying existing uploads from the legacy server into Blob is an operational step. It is outside this plan and must not change the on-premises environment.
- **Personal data in logs:** avoid logging student names and dates in error messages.
- **Retries:** consider EF Core `EnableRetryOnFailure` for SQL MI transient faults.
