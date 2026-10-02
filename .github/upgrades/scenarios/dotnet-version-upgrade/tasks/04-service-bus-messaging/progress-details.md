# Progress: 04-service-bus-messaging

## Files changed (app/ContosoUniversity)
- Services/NotificationService.cs: ConcurrentQueue replaced by Azure.Messaging.ServiceBus (`DefaultAzureCredential`); singleton client/sender/receiver, `IAsyncDisposable`. Config `ServiceBus:FullyQualifiedNamespace` / `ServiceBus:QueueName`, fails fast when missing. Send logs failures (never throws). `ReceiveNotifications()` = ReceiveAndDelete, up to 10, 1 s max wait. `MarkAsRead` stays a no-op. Public Send API unchanged, so other controllers are untouched.
- Controllers/NotificationsController.cs: uses `ReceiveNotifications()`, logs via `ILogger`; same routes and JSON shape.
- Program.cs: startup resolves `NotificationService` (fail-fast). appsettings.json: empty `ServiceBus` keys. csproj: `Azure.Messaging.ServiceBus`.

## Validation
- `dotnet build`: 0 warnings, 0 errors.
- Config came from project user secrets (not written to source or artifacts). Queue was empty (0 active, 0 dead-letter) before testing, read-only `az` check.
- Development run with real SQL secret: home, Students, Courses, Instructors, Departments returned 200.
- SEND and RECEIVE passed: Student create, edit, delete each produced a message, read back via `GET /Notifications/GetNotifications` with shape `{success, notifications[], count}` and PascalCase items (Id, EntityType, EntityId, Operation, Message, CreatedAt, CreatedBy, IsRead, ReadAt). A second poll returned empty (destructive receive).
- notifications.js polls `/Notifications/GetNotifications` (setInterval fetch). Browser toast rendering not exercised.
- Cleanup: all test students (ids 300002-300004, name ZzSbTest) deleted via the app; queue drained; app stopped.

## Notes
- No MSMQ or in-process queue remains. Not exercised: send-failure logging path, MarkAsRead call, Courses/Instructors/Departments notifications (same code path via BaseController).
