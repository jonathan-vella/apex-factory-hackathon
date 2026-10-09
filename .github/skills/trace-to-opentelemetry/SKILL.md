---
name: trace-to-opentelemetry
description: Check that System.Diagnostics.Trace and Debug in Contoso University became ILogger, exported to Application Insights through the Azure Monitor OpenTelemetry distro with Microsoft Entra authentication, and guide the fix if not. Use when Trace or Debug calls are left, or telemetry doesn't reach Application Insights.
---

# Trace to OpenTelemetry

## When to use

After task 06 (OpenTelemetry), if any of these is true:

- `git grep -n -E "Trace\.|Debug\.Write" -- app/ContosoUniversity` prints anything.
- The app crashes at startup when no Application Insights connection string is set.
- Nothing from a local run shows in Application Insights after 5 minutes.

Scope: `app/ContosoUniversity` only.

## Steps

1. **Logging.** Each class that logs takes an `ILogger<T>`. Every `Trace.TraceError`, `Trace.TraceWarning`, `Trace.WriteLine` and `Debug.WriteLine` becomes `LogError`, `LogWarning` or `LogInformation`, with the exception as the first argument and a message template, not string interpolation. No names or other personal data in log messages.
2. **The distro.** One package, `Azure.Monitor.OpenTelemetry.AspNetCore`, and one `UseAzureMonitor()` call. No separate instrumentation packages or exporters.
3. **Only when configured.** `UseAzureMonitor()` is registered only when `APPLICATIONINSIGHTS_CONNECTION_STRING` or `ApplicationInsights:ConnectionString` has a value. Without one the app starts and runs normally with console logging.
4. **Entra authentication.** Application Insights has local authentication off, so the distro's credential is `DefaultAzureCredential`. On App Service the web app's identity has **Monitoring Metrics Publisher**. On `vm-dev01` your own sign-in needs the same role (playbook, task 06).

Ask Copilot for the missing steps only, then run the checks.

## Checks

- `git grep -n -E "Trace\.|Debug\.Write" -- app/ContosoUniversity` prints nothing.
- With no connection string, `dotnet run` starts and the pages load.
- With the connection string in user secrets, open the five pages and edit a student. Within 5 minutes this returns `request`, `dependency` and `trace` rows:

  ```powershell
  az monitor app-insights query -g rg-university-<suffix> -a appi-university-<suffix> --analytics-query "union requests, dependencies, traces | where timestamp > ago(30m) | summarize count() by itemType" --query "tables[0].rows" -o tsv
  ```

Expected: Service Bus doesn't show as a dependency with the distro's defaults (prove messaging with a send and receive instead), and a `TaskCanceledException` (499) when you leave a page during a notification poll is harmless. A connection string that's set but invalid stops the app at startup: it must start with `InstrumentationKey=`.

## Example

Before, in `Controllers/StudentsController.cs`:

```csharp
catch (Exception ex)
{
    Trace.TraceError($"Error creating student: {ex.Message} | Stack: {ex.StackTrace}");
}
```

After, in `Controllers/StudentsController.cs` and `Program.cs`:

```csharp
catch (Exception ex)
{
    logger.LogError(ex, "Error creating student");
}
```

```csharp
if (!string.IsNullOrWhiteSpace(builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor(o => o.Credential = new DefaultAzureCredential());
}
```
