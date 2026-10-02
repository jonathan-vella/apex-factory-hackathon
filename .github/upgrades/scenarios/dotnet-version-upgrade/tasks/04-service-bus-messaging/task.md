# 04-service-bus-messaging: Migrate messaging to Azure Service Bus

**Depends on**: 03-blob-storage-files

Replace the interim in-process notification queue from Task 01 (originally MSMQ `.\Private$\ContosoUniversityNotifications`) with Azure Service Bus using `Azure.Messaging.ServiceBus`, DefaultAzureCredential and configuration `ServiceBus:FullyQualifiedNamespace` / `ServiceBus:QueueName` — no shared access keys, SAS or connection strings. Preserve notification semantics: a JSON-serialized `Notification` is sent on create/edit/delete of Students, Courses, Instructors and Departments (send failures logged, never break the main operation); `GET /Notifications/GetNotifications` reads back up to 10 pending messages per poll (MSMQ receive was destructive with a 1-second timeout — mirror with receive-and-complete and a short max wait) and returns the unchanged JSON shape; `MarkAsRead` stays a no-op returning success.

Register the Service Bus client/sender/receiver as singletons and dispose cleanly. Do not create, configure or deploy the Service Bus resource.

**Done when**: `dotnet build` succeeds; no MSMQ or in-process queue remains on the runtime path; local `dotnet run` against the real namespace (private endpoint) proves **both** send (create/edit/delete an entity) and receive (notification appears via `GetNotifications` and in the notifications.js toast); home, Students, Courses, Instructors, Departments load. Database-backed steps are **BLOCKED** until the user secret is supplied.
