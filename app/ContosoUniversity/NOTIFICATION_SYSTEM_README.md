# Notification system

CRUD actions for students, courses, instructors, and departments enqueue a
notification. The browser polls `GET /Notifications/GetNotifications` every
five seconds, and the endpoint returns at most ten queued messages per request.

## Current transport

Notifications are sent to the existing Azure Service Bus queue. Configure the
following runtime settings; do not put namespace values, keys, or connection
strings in checked-in files:

- `ServiceBus__FullyQualifiedNamespace` — the Service Bus namespace hostname.
- `ServiceBus__QueueName` — the existing queue name.

The application authenticates with `DefaultAzureCredential` (a developer
identity locally and the hosting identity in Azure). Those identities need
Service Bus Data Sender and Data Receiver access to the existing queue. The
application does not create or configure the Azure resource. Send failures are
logged without failing the successful entity operation.

No application user sign-in is configured. Notifications use `System` as the
creator unless a caller supplies another name.

## Components

- `NotificationService` creates and receives notification payloads.
- `BaseController` emits notifications after successful entity operations.
- `NotificationsController` exposes the polling and mark-read actions.
- `wwwroot/Scripts/notifications.js` polls and displays notifications.
- `wwwroot/Content/notifications.css` styles the notification UI.

## Run and verify

1. Configure `ConnectionStrings:DefaultConnection` for a reachable SQL Server.
2. Configure `ServiceBus__FullyQualifiedNamespace` and `ServiceBus__QueueName`
   for the existing queue, and ensure the active `DefaultAzureCredential`
   identity can send and receive messages.
3. Start the application with `dotnet run`.
4. Open the Notifications page, then create or update a student, course,
   instructor, or department in the same running instance.
5. The notification should appear in the page's top-right corner after polling.

The browser displays at most five notifications at a time; each is dismissed
after one minute or can be closed manually. The polling endpoint caps each
response at ten messages.
