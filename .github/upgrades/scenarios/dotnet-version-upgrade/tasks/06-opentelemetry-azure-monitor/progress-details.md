# Task 06 progress
Files: ContosoUniversity.csproj (Azure.Monitor.OpenTelemetry.AspNetCore 1.6.0), Program.cs, appsettings.json (empty ApplicationInsights:ConnectionString), Controllers/BaseController.cs, NotificationsController.cs, StudentsController.cs.
Courses controller and NotificationService already used ILogger (no change). Student logs: exception + ID only, no names.
Build: 0 warnings, 0 errors. Grep: no Diagnostics Debug/Trace remains.
No connection string (env overridden to empty): home/Students/Courses/Instructors/Departments/notifications poll 200, console logging.
With connection string (user secrets, not recorded): pages 200, startup ok. 'az monitor app-insights' extension not installed; queried via read-only 'az rest' on the App Insights query API: requests (7), SQL dependencies (6, plus Entra token in-proc), traces (4) arrived. Not observed: outbound HTTP dependencies (Blob/Service Bus not exercised); a forced 500 on /Students/Details/999999 was framework-logged.
App stopped after runs.
