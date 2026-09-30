# Task 06 progress details

## Outcome

- Added `Azure.Monitor.OpenTelemetry.AspNetCore` 1.6.0, the only direct telemetry package. Existing `Azure.Identity` 1.21.0 provides `DefaultAzureCredential`.
- `Program.cs` reads `APPLICATIONINSIGHTS_CONNECTION_STRING`, then falls back to `ApplicationInsights:ConnectionString`. It registers exactly one `AddOpenTelemetry().UseAzureMonitor(...)` pipeline only when a non-empty value exists, passing that connection string and `DefaultAzureCredential`.
- When neither setting is configured, the app adds no Azure Monitor/OpenTelemetry registration and retains the built-in ASP.NET Core logging providers.
- Replaced all assessed direct `Trace`/`Debug.WriteLine` calls with structured `ILogger<T>` calls that preserve exception details. Student logs omit names and enrollment dates; the edit/delete messages use only student IDs. `ILogger<BaseController>` is passed through all six derived controller constructors.
- Documented optional telemetry configuration and the no-telemetry startup path in the app README. No Application Insights resource, identity, role, network, or infrastructure was configured.

## Validation

- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --configuration Release --no-restore --verbosity minimal`: succeeded after the logging source changes.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln --configuration Release --verbosity minimal`: restore and build succeeded with 0 warnings and 0 errors.
- `dotnet list app/ContosoUniversity/ContosoUniversity.csproj package --include-transitive`: confirmed direct distro version 1.6.0. The resolved exporter and instrumentation packages are transitive; no separate instrumentation or exporter package was added.
- Source scan found no remaining `Trace`/`Debug.WriteLine` calls and exactly one `UseAzureMonitor` registration. Compiler diagnostics reported no errors in the changed C# files; `git diff --check` reported no whitespace errors (only Git CRLF-to-LF notices for existing modified files).
- With both telemetry connection-string settings absent, launched the application in Development and confirmed `/`, `/Students`, `/Courses`, `/Instructors`, and `/Departments` each returned HTTP 200. The temporary server was stopped after the check.
- Upgrade test-project discovery returned `[]`; no applicable .NET test project exists.
- Checked environment-variable and user-secret key names only; `APPLICATIONINSIGHTS_CONNECTION_STRING` and `ApplicationInsights:ConnectionString` are not configured. The Development SQL connection-string secret key is present; its value was not read or printed.

## External integration boundary

- Azure Monitor ingestion was not attempted because no Application Insights connection string is configured. Live export of requests, SQL/HTTP dependencies, and logs, along with `DefaultAzureCredential` resolution, ingestion authorization, and network access, remains an external environment check.
- No dummy connection string, resource, role, endpoint, or network configuration was added to simulate ingestion.

## Files changed

- `.github/upgrades/scenarios/dotnet-version-upgrade/scenario-instructions.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/06-opentelemetry-azure-monitor/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/06-opentelemetry-azure-monitor/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`
- `app/ContosoUniversity/Controllers/BaseController.cs`
- `app/ContosoUniversity/Controllers/CoursesController.cs`
- `app/ContosoUniversity/Controllers/DepartmentsController.cs`
- `app/ContosoUniversity/Controllers/HomeController.cs`
- `app/ContosoUniversity/Controllers/InstructorsController.cs`
- `app/ContosoUniversity/Controllers/NotificationsController.cs`
- `app/ContosoUniversity/Controllers/StudentsController.cs`
- `app/ContosoUniversity/Services/NotificationService.cs`
- `app/ContosoUniversity/README.md`

## Boundary

Task 06 is complete for application code and local validation. Azure Monitor ingestion remains externally unverified because the connection string and Azure access are unavailable. Task 07 remains unstarted and requires separate user approval.
