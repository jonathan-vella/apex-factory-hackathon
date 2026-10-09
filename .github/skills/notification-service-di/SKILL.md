---
name: notification-service-di
description: Check that the `new NotificationService()` in Contoso University's BaseController became constructor injection, with one Service Bus client for the app's lifetime registered in dependency injection, and guide the fix if not. Use when a controller creates the notification service or a Service Bus client itself, or toasts don't appear.
---

# Notification service through dependency injection

## When to use

After task 04 (Service Bus), if any of these is true:

- `git grep -n -E "new NotificationService|new ServiceBusClient" -- app/ContosoUniversity/Controllers` prints anything.
- A Service Bus client is created per request or per controller, which opens a new connection each time.
- Notifications are sent but toasts never appear, and the controller hides the error.

Scope: `app/ContosoUniversity` only.

## Steps

1. **One client.** A `ServiceBusClient` is thread-safe and meant to live as long as the app. It's created once, from `ServiceBus:FullyQualifiedNamespace` with `DefaultAzureCredential`, and registered in `Program.cs` as a singleton. A singleton `NotificationService` that owns the only client also meets the goal. Never a connection string or shared access key.
2. **The service.** `NotificationService` is a singleton. Its constructor takes the client (or the configuration) and an `ILogger<NotificationService>`, creates one sender and one receiver for `ServiceBus:QueueName`, and fails at startup with a clear message if a setting is missing.
3. **Receive.** `ServiceBusReceiveMode.ReceiveAndDelete` matches MSMQ's destructive read. The maximum wait time must be **positive**, such as `TimeSpan.FromSeconds(1)`: with `TimeSpan.Zero` every receive throws.
4. **Controllers.** `BaseController` takes `SchoolContext` and `NotificationService` in its constructor, and every controller passes them on. The field initializer and the `Dispose` override that disposed the service go: the container owns it now.
5. **Errors.** Failures are logged with `ILogger`, never `Debug.WriteLine`. A failed send doesn't break the save that triggered it.

Ask Copilot for the missing steps only, then run the checks.

## Checks

- `git grep -n -E "new NotificationService|new ServiceBusClient" -- app/ContosoUniversity/Controllers` prints nothing.
- `dotnet run`, then create, edit and delete a student. Each shows a toast at the top right within 5 seconds.
- `/Notifications/GetNotifications` returns `{"success":true,"notifications":[...],"count":N}` with PascalCase property names, the shape `wwwroot/js/notifications.js` expects.
- Stop the app, edit a student in another instance or leave a message queued, then start it: queued messages still arrive.

## Example

Before, in `Controllers/BaseController.cs`:

```csharp
public abstract class BaseController : Controller
{
    protected SchoolContext db;
    protected NotificationService notificationService = new NotificationService();

    public BaseController()
    {
        db = SchoolContextFactory.Create();
    }
}
```

After, in `Program.cs` and `Controllers/BaseController.cs`:

```csharp
builder.Services.AddSingleton(_ => new ServiceBusClient(
    builder.Configuration["ServiceBus:FullyQualifiedNamespace"], new DefaultAzureCredential()));
builder.Services.AddSingleton<NotificationService>();
```

```csharp
public abstract class BaseController : Controller
{
    protected readonly SchoolContext db;
    protected readonly NotificationService notificationService;

    protected BaseController(SchoolContext db, NotificationService notificationService)
    {
        this.db = db;
        this.notificationService = notificationService;
    }
}
```
