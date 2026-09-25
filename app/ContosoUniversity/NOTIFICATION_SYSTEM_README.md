# Notification system

CRUD actions for students, courses, instructors, and departments enqueue a
notification. The browser polls `GET /Notifications/GetNotifications` every
five seconds, and the endpoint returns at most ten queued messages per request.

## Current transport

The .NET 10 upgrade temporarily uses a singleton in-process queue so the
application remains buildable and runnable on Linux without MSMQ. The queue
preserves notification payloads and FIFO delivery within one running
application instance, but messages are not durable and are not shared across
instances. The next Service Bus task in the modernization plan replaces this
temporary transport.

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
2. Start the application with `dotnet run`.
3. Open the Notifications page, then create or update a student, course,
   instructor, or department in the same running instance.
4. The notification should appear in the page's top-right corner.

The browser displays at most five notifications at a time; each is dismissed
after one minute or can be closed manually. The polling endpoint caps each
response at ten messages.
