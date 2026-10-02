# 04-service-bus-messaging: Migrate messaging to Azure Service Bus

**Depends on**: 03-blob-storage-files

Replace the interim in-process notification queue from Task 01 (originally MSMQ `.\Private$\ContosoUniversityNotifications`) with Azure Service Bus using `Azure.Messaging.ServiceBus`, DefaultAzureCredential and configuration `ServiceBus:FullyQualifiedNamespace` / `ServiceBus:QueueName` — no shared access keys, SAS or connection strings. Preserve notification semantics: a JSON-serialized `Notification` is sent on create/edit/delete of Students, Courses, Instructors and Departments (send failures logged, never break the main operation); `GET /Notifications/GetNotifications` reads back up to 10 pending messages per poll (MSMQ receive was destructive with a 1-second timeout — mirror with receive-and-complete and a short max wait) and returns the unchanged JSON shape; `MarkAsRead` stays a no-op returning success.

Register the Service Bus client/sender/receiver as singletons and dispose cleanly. Do not create, configure or deploy the Service Bus resource.

**Done when**: `dotnet build` succeeds; no MSMQ or in-process queue remains on the runtime path; local `dotnet run` against the real namespace (private endpoint) proves **both** send (create/edit/delete an entity) and receive (notification appears via `GetNotifications` and in the notifications.js toast); home, Students, Courses, Instructors, Departments load. Database-backed steps are **BLOCKED** until the user secret is supplied.

## Research findings (confirmed against repo)
- Interim queue: Services/NotificationService.cs (ConcurrentQueue, singleton, injected via BaseController into all controllers); consumers: BaseController.SendEntityNotification, NotificationsController (GetNotifications loop up to 10, MarkAsRead no-op). notifications.js calls /Notifications/GetNotifications.
- Plan: keep NotificationService type/public API (Send/Receive/MarkAsRead) so controllers are unchanged; back it with ServiceBusClient (DefaultAzureCredential) + sender + receiver (ReceiveAndDelete, 1s max wait); config ServiceBus:FullyQualifiedNamespace / ServiceBus:QueueName, empty in appsettings.json, fail fast at startup; IAsyncDisposable disposal; add Azure.Messaging.ServiceBus package; Azure.Identity already referenced.
- Receive-and-complete implemented as ReceiveAndDelete mode (destructive, mirrors MSMQ); batch receive up to 10 with short max wait.

