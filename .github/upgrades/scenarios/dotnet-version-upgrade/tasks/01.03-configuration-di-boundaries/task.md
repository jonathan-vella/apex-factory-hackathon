# 01.03-configuration-di-boundaries: Migrate configuration and create compile-safe DI boundaries for deferred services

# 01.03 ASP.NET Core configuration, DI, and deferred-service boundaries

## Objective
Replace legacy startup/configuration access and establish compile-safe application contracts required by controllers without implementing the later Azure migrations.

## Required skills
- #skill:migrating-aspnet-framework-to-core
- #skill:migrating-webapi-odata

## Prerequisite
The minimal net10.0 host from `01.02-sdk-host` builds and runs.

## Scope
- `Program.cs`, `appsettings.json`, Development configuration/user-secrets metadata
- `Data/SchoolContext.cs`, `Data/SchoolContextFactory.cs`, `Data/DbInitializer.cs`
- `Services/NotificationService.cs` and new application-owned notification contract files
- Model classes needed by DI contracts

## Steps
1. Migrate only applicable non-secret Web.config settings to ASP.NET Core configuration. Keep `ConnectionStrings:DefaultConnection` as the key, but do not commit the current/local or future Azure connection string; Development obtains it from user secrets.
2. Register the existing `SchoolContext` through DI and remove controller reliance on `SchoolContextFactory`. Do not upgrade EF Core/SqlClient, alter mappings, call `Database.Migrate`/`EnsureCreated`, add SQL MI validation, or implement credential policy; task 02 owns those changes. Preserve all nine DbSets and mappings.
3. Extract an injectable notification contract preserving send, receive, and mark-read semantics. Isolate the unsupported MSMQ implementation from net10.0 compilation behind a clearly documented task-04 boundary that fails only notification operations deterministically; do not add Service Bus, another broker, cloud settings, or `// STUB:` markers.
4. Register service lifetimes with built-in DI so the container validates. Keep direct Trace/Debug behavior for task 06; do not add telemetry.
5. Build and run `/health`; record the missing Development SQL user secret as the expected page-runtime blocker if absent.

## Done when
Configuration uses ASP.NET Core APIs, the DI container validates, `SchoolContext` and the notification contract resolve, and the host builds/runs without implementing tasks 02, 04, 05, or 06.

## Research findings

### Current implementation
- `01.02-sdk-host` left a package-free `net10.0` minimal host and deliberately excludes `Data/**/*.cs`, `Models/**/*.cs`, and `Services/**/*.cs` until their owning children.
- `Web.config` contains four standard ASP.NET MVC app settings, one MSMQ queue-path setting, and `DefaultConnection`. No custom configuration section, encrypted section, authentication section, or environment transform value applies to this child. Values were inventoried with connection-string values redacted.
- `SchoolContextFactory` is the only data-layer `ConfigurationManager.ConnectionStrings` call. `NotificationService` is the only service-layer `ConfigurationManager.AppSettings` call and directly owns all unsupported MSMQ APIs.
- `SchoolContext` has nine `DbSet` properties and the assessed datetime2, table, TPH, composite-key, many-to-many, and one-to-one mappings. `DbInitializer.Initialize` currently calls `EnsureCreated`; this must be removed and the initializer must not run at startup.
- Controllers still construct `SchoolContext` and `NotificationService`, but controller files remain excluded until their dedicated children. Those children will switch to constructor injection; this child establishes the contracts and registrations they require.
- No `// STUB:` markers, third-party DI container, service locator, `HttpContext.Current`, session/application state, or custom controller factory exists in this child scope.

### Assessment findings to address
- Structured assessment query for `ContosoUniversity.csproj` reports 157 issues: 94 mandatory, 58 potential, and 5 optional. Relevant technologies are Legacy Configuration (16 findings) and MSMQ (57 findings).
- Relevant API breaks are `ConfigurationManager` access and the unsupported `System.Messaging` types used by `NotificationService`.
- EF Core 3.1.32 and `Microsoft.Data.SqlClient` 2.1.4 are intentionally retained at this boundary. Their compatibility/security upgrades belong to tasks 02 and 07 respectively; this child must not apply those upgrades or SQL credential policy.
- The wire-compatibility gate is PASS for this scope and is recorded in `../01.01-wire-contract-baseline/progress-details.md`. This child changes no endpoint, formatter, serializer, response model, or route contract.

### Implementation plan
- Add `appsettings.json` with the `ConnectionStrings:DefaultConnection` key present but empty. Do not copy a connection string or retain the obsolete MSMQ setting. Add `appsettings.Development.json` without secrets and initialize project user-secrets metadata only.
- Include the data/model slices needed by `SchoolContext`, retain EF Core/SqlClient package versions, register `SchoolContext` as scoped through `AddDbContext`, and remove `SchoolContextFactory` plus `EnsureCreated` from `DbInitializer`.
- Add `INotificationService` with both send overloads, receive, and mark-read operations. Replace the MSMQ-bound implementation with a scoped implementation that constructs successfully and throws the same deterministic task-04 boundary exception only when an operation is invoked. Do not add another broker or `// STUB:` marker.
- Enable built-in provider validation and resolve `SchoolContext` plus `INotificationService` from a startup scope so this child proves both registrations without touching the database or queue.
- Keep Trace/Debug migration, SQL policy, Blob, Service Bus, Key Vault, and telemetry entirely deferred to tasks 02-06.

### Validation plan
- Restore and build the project and solution; record the intentionally deferred package warning separately if NuGet re-emits the known SqlClient advisory.
- Confirm no compiled configuration/MSMQ usage remains and no secret value is committed.
- Run the Development host with no SQL user secret and verify `/health` returns HTTP 200 with `ok`; database-backed pages remain blocked until the secret and later controller children are available.
- No matching .NET test project exists, as confirmed by the assessment and prior child; test execution is therefore a recorded no-op.

## Decomposition assessment
- Evaluated scenario `execution.md` plus `breakdown-hints/common.md`, `breakdown-hints/framework-migration.md`, and `breakdown-hints/framework-web-migration.md`.
- Verdict: **atomic**. The parent already separated configuration/DI from controllers, static assets, final validation, and all Azure implementations. The mandatory MSMQ replacement hint is satisfied by top-level task 04; this child creates only its compile-safe application boundary. No stub-resolution, multi-project ordering, third-party container, authentication, controller-migration, or unknown package-replacement trigger applies.
