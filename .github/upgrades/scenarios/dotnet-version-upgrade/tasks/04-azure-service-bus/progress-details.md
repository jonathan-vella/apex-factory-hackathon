# Task 04 progress details

## Outcome

- Added `Azure.Messaging.ServiceBus` 7.21.0, supported for the application's `net10.0` target.
- Replaced the task placeholder with an asynchronous Service Bus implementation using `ServiceBusClient`, `DefaultAzureCredential`, `ServiceBus:FullyQualifiedNamespace`, and `ServiceBus:QueueName`. Client, sender, and receiver resources are created lazily and reused for the application lifetime so absent messaging configuration does not prevent normal pages from loading.
- Validated the configured namespace as a standard `*.servicebus.windows.net` host and reject IP literals, `privatelink`, ports, URL paths, user information, query strings, and fragments. Queue creation is not performed.
- Preserved the legacy notification JSON fields, message text, local timestamp, `System` user fallback, `IsRead=false`, `{entityType} {operation}` label as Service Bus `Subject`, and `Normal` priority as application metadata. Service Bus does not support MSMQ-style per-message priority scheduling.
- Preserved asynchronous best-effort notification sends after all Course, Department, Instructor, and Student create/edit/delete operations. The entity operation remains successful when sending fails.
- Receiving uses PeekLock with a one-second wait and completes a received message before returning its deserialized notification, preserving the legacy destructive receive behavior. Empty queues return no notification; `MarkAsRead` remains a no-op. The Notifications endpoint still returns at most ten notifications with its existing JSON shape.
- Updated the application notification and setup guides to describe Service Bus configuration and remove MSMQ installation/permission steps.
- The active .NET 10 source, project package graph, and built dependency manifest contain no `System.Messaging` runtime dependency. The legacy `bin/net48` artifacts are not part of the net10 dependency manifest.
- No Service Bus namespace, queue, identity, role assignment, network setting, deployment, or on-premises system was created or changed.

## Validation

- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --configuration Release --verbosity minimal`: restore and build succeeded with 0 warnings and 0 errors.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln --configuration Release --verbosity minimal`: restore and build succeeded with 0 warnings and 0 errors.
- Package resolution confirmed `Azure.Messaging.ServiceBus` 7.21.0 and `Azure.Identity` 1.21.0. The built `net10.0` dependency manifest contains no `System.Messaging`.
- Compiler diagnostics found no errors in the modified source files; `git diff --check` found no whitespace errors.
- Source scans found no legacy synchronous notification calls or `System.Messaging` API references. All 12 entity create/edit/delete call sites await the notification service; the send, receive, and settlement SDK calls are present in the compiled implementation.
- Test-project discovery returned `[]`; no applicable .NET test project is present.
- In Development, `/`, `/Students`, `/Courses`, `/Instructors`, `/Departments`, and `/health` returned HTTP 200.
- `/Notifications/GetNotifications` returned HTTP 200 with the existing generic `success=false` error result because Service Bus configuration is absent. The local application remained available.

## External integration blocker

- A key-name-only user-secrets check found no `ServiceBus:FullyQualifiedNamespace` or `ServiceBus:QueueName`; values of existing secrets were not displayed. Consequently, no live Service Bus send or receive was attempted, and queue access, `DefaultAzureCredential` identity resolution, data-plane permissions, private DNS, and network reachability remain unverified.
- The live end-to-end check must exercise both a send and a receive against the existing authorized queue. It remains blocked until the environment owner supplies valid configuration and access; this task made no Azure or network changes.

## Files changed

- `.github/upgrades/scenarios/dotnet-version-upgrade/scenario-instructions.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/04-azure-service-bus/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/04-azure-service-bus/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`
- `app/ContosoUniversity/Services/INotificationService.cs`
- `app/ContosoUniversity/Services/NotificationService.cs`
- `app/ContosoUniversity/Controllers/BaseController.cs`
- `app/ContosoUniversity/Controllers/NotificationsController.cs`
- `app/ContosoUniversity/Controllers/CoursesController.cs`
- `app/ContosoUniversity/Controllers/DepartmentsController.cs`
- `app/ContosoUniversity/Controllers/InstructorsController.cs`
- `app/ContosoUniversity/Controllers/StudentsController.cs`
- `app/ContosoUniversity/README.md`
- `app/ContosoUniversity/NOTIFICATION_SYSTEM_README.md`
- `app/ContosoUniversity/SETUP_TESTING_GUIDE.md`

## Boundary

Task 04 is complete for application code and local validation. Live Service Bus integration remains externally blocked as recorded above. Task 05, Azure Key Vault, remains unstarted for review and separate approval.