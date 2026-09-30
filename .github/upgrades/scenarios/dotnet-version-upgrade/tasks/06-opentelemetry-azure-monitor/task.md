# 06-opentelemetry-azure-monitor: Migrate logging and tracing to OpenTelemetry with Azure Monitor

## Research Findings (2026-09-30)

### Confirmed project state

- Scope is the single SDK-style `net10.0` application `app/ContosoUniversity/ContosoUniversity.csproj`. The dependency inspector confirms package versions are declared directly in that project; there are no imported package-version props or central package management files.
- Existing direct packages include `Azure.Identity` 1.21.0, `Azure.Extensions.AspNetCore.Configuration.Secrets` 1.5.2, `Azure.Messaging.ServiceBus` 7.21.0, `Azure.Storage.Blobs` 12.29.2, and `Microsoft.EntityFrameworkCore.SqlServer` 10.0.12. No OpenTelemetry or Azure Monitor package is referenced.
- Supported stable `Azure.Monitor.OpenTelemetry.AspNetCore` for `net10.0` is 1.6.0. Package documentation confirms the distro includes ASP.NET Core request, HttpClient, SQL Client dependency, metrics, and `Microsoft.Extensions.Logging` instrumentation; do not add individual instrumentation packages or another exporter.
- The active `Trace`/`Debug` call sites are `StudentsController` (three `Trace.TraceError` catches), `BaseController` (best-effort notification send failure), `CoursesController` (best-effort teaching-material cleanup failure), and `NotificationService` (notification JSON deserialization error). `Services/LoggingService.cs` exists but is empty. No `ILogger<T>`, `UseAzureMonitor`, `AddOpenTelemetry`, `ActivitySource`, or `Meter` is currently used in application source.
- `Program.cs` creates the WebApplication builder, adds the mandatory non-Development Key Vault provider before reading SQL configuration, then registers EF and application services. It currently relies on default ASP.NET Core logging providers and contains no Azure Monitor registration.
- Injecting an `ILogger<T>` into `BaseController` requires passing it through the constructors of its derived controllers: Home, Courses, Departments, Instructors, Notifications, and Students. The logging calls in Students, Courses, and NotificationService will use their own typed logger.
- The only allowed telemetry package for this task is `Azure.Monitor.OpenTelemetry.AspNetCore` 1.6.0. Its `UseAzureMonitor` options support both an explicit configuration connection string and `DefaultAzureCredential`.
- No Application Insights connection-string value was found in committed application JSON. Existing application settings and environment configuration are the runtime sources; do not inspect or print any secret values.
- Test-project discovery returned `[]`; no applicable .NET test project exists.

### Implementation and validation boundary

- Replace the six active direct Trace/Debug calls with structured `ILogger<T>` calls, preserving exception objects and useful non-secret identifiers while avoiding logging student personal data or configuration values.
- Register exactly one `UseAzureMonitor` call only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` is non-empty. Pass the configured value and `new DefaultAzureCredential()` through Azure Monitor options. When neither setting is present, do not register OpenTelemetry/Azure Monitor and retain built-in console logging.
- Validate both setting paths, the no-registration path, and absence of duplicate registrations by local/static checks. Requests, SQL/HTTP dependencies, and log ingestion to Application Insights require a real connection string and authorized identity and remain external if unavailable; do not add an exporter or change infrastructure to simulate them.

Replace direct `Trace.TraceError` and `Debug.WriteLine` usage in controllers and notification handling with injected `ILogger<T>`, preserving meaningful severity, context, and exception information without logging secrets. Establish the approved telemetry boundary using only `Azure.Monitor.OpenTelemetry.AspNetCore`, with exactly one conditional `UseAzureMonitor()` registration when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value, and set its credential to `DefaultAzureCredential` for Microsoft Entra-authenticated ingestion.

When neither connection-string setting has a value, register nothing extra; built-in ASP.NET Core console logging applies and the application must start normally. Do not add individual instrumentation packages, custom exporters, alternate telemetry frameworks, or duplicate Azure Monitor registration. Application Insights ingestion is the documented backend-network exception; do not hard-code endpoints or identity values, configure Application Insights, assign roles, or deploy.

**Done when**: Assessed Trace/Debug calls are represented by structured `ILogger<T>` usage, Azure Monitor registration is single and conditional with `DefaultAzureCredential`, and restore/build succeeds with no errors; record new warnings but don't block on them. Every applicable test passes or is recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments without requiring telemetry. With a connection string configured, requests, SQL and HTTP dependencies, and logs from the local run appear in Application Insights within a few minutes; unavailable Azure Monitor access is documented as a blocked external check rather than worked around through infrastructure changes.
