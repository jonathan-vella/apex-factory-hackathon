# Service Bus Setup and Testing

## Prerequisites

- .NET 10 SDK.
- The existing Development SQL user secret for `ConnectionStrings:DefaultConnection`.
- For live notification checks, an existing Service Bus namespace and queue plus a `DefaultAzureCredential` identity authorized to send and receive messages.

## Configure local Service Bus settings

Use the standard namespace hostname; private DNS must resolve it to the private endpoint. Set both values in user secrets:

```powershell
dotnet user-secrets set "ServiceBus:FullyQualifiedNamespace" "your-namespace.servicebus.windows.net" --project app/ContosoUniversity/ContosoUniversity.csproj
dotnet user-secrets set "ServiceBus:QueueName" "notifications" --project app/ContosoUniversity/ContosoUniversity.csproj
```

Do not configure a connection string, shared access key, or SAS token. Do not create queues, assign roles, or change Azure/network resources as part of local application testing.

## Run local checks

```powershell
dotnet build app/ContosoUniversity/ContosoUniversity.csproj --configuration Release
dotnet run --project app/ContosoUniversity/ContosoUniversity.csproj
```

Confirm Home, Students, Courses, Instructors, and Departments load. With authorized Service Bus access, create or edit a Student, Course, Instructor, or Department and confirm the notification is displayed. The notification client polls every five seconds, displays up to five notifications, and auto-dismisses each after one minute.

`NotificationsController` receives and completes queue messages, waiting up to one second when the queue is empty. The endpoint returns at most ten notifications per poll. `MarkAsRead` is intentionally a no-op because receipt consumes the message and the service does not persist notifications in SQL.

## Troubleshooting

- Missing `ServiceBus:FullyQualifiedNamespace` or `ServiceBus:QueueName` prevents the messaging operation; it does not prevent the normal MVC pages from loading.
- A send failure is logged and does not fail the saved entity operation. A receive failure is returned by the notification endpoint as an error result.
- Check the browser network panel for `/Notifications/GetNotifications` and the browser console for client-side errors.
- If configuration is correct but Service Bus is unavailable, verify the existing namespace, queue, `DefaultAzureCredential` identity, data-plane permissions, private DNS, and network path with the environment owner. Do not weaken authentication or use public endpoints.
