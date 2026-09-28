# Service Bus Notification System

The application sends a notification after a Student, Course, Instructor, or Department is created, updated, or deleted. The existing browser client polls the application for messages and displays them as dismissible notifications.

## Configuration

Configure both values in ASP.NET Core configuration:

- `ServiceBus:FullyQualifiedNamespace`: the standard namespace host, such as `your-namespace.servicebus.windows.net`
- `ServiceBus:QueueName`: the existing queue name; the deployment protocol uses `notifications`

For local development, set the values with user secrets:

```powershell
dotnet user-secrets set "ServiceBus:FullyQualifiedNamespace" "your-namespace.servicebus.windows.net" --project app/ContosoUniversity/ContosoUniversity.csproj
dotnet user-secrets set "ServiceBus:QueueName" "notifications" --project app/ContosoUniversity/ContosoUniversity.csproj
```

The application authenticates with `DefaultAzureCredential`. The standard namespace hostname must resolve through private DNS. Do not use a Service Bus connection string, SAS token, shared key, IP address, `privatelink` hostname, public endpoint, or embedded credentials. The application does not create the queue or configure Azure permissions or networking.

## Message behavior

- The JSON body preserves the `Notification` fields and the existing CREATE, UPDATE, and DELETE message text.
- The legacy label is carried in the Service Bus `Subject`; normal priority is retained as application metadata. Service Bus does not provide MSMQ-style per-message priority scheduling.
- Receiving waits up to one second and completes a received message, matching the legacy destructive receive behavior. An empty queue returns no notification.
- `MarkAsRead` remains a no-op; notifications are not persisted to the `Notification` database table by this service.
- `NotificationsController` returns up to ten received notifications. The browser polls every five seconds, shows up to five at once, and removes each after one minute or when dismissed.
- Notification send failures do not undo or fail the underlying entity operation.

## Verify

1. Start the application with the configured Development SQL secret.
2. Confirm Home, Students, Courses, Instructors, and Departments load.
3. With an existing authorized Service Bus namespace and queue configured, create or edit a supported entity and confirm the notification appears in the browser.
4. Confirm the receive endpoint returns no notification when the queue is empty.

If the namespace, queue, credentials, data-plane permissions, private DNS, or network path is unavailable, the live messaging check is blocked externally. The application pages remain available, and no Azure resources or permissions are created by the application.
