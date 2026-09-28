# 04-azure-service-bus: Migrate messaging to Azure Service Bus

## Research Findings (2026-09-28)

### Confirmed project state

- Scope is the single SDK-style `net10.0` application `app/ContosoUniversity/ContosoUniversity.csproj`. Current direct packages are `Azure.Identity` 1.21.0, `Azure.Storage.Blobs` 12.29.2, and `Microsoft.EntityFrameworkCore.SqlServer` 10.0.12; no Service Bus package is referenced.
- The current `Services/NotificationService.cs` is a deliberate task-04 placeholder that throws `NotSupportedException`; the legacy implementation is recoverable from the imported baseline commit and the upgrade assessment. No active `System.Messaging` API or package dependency remains in the `net10.0` source/project.
- `Azure.Messaging.ServiceBus` 7.21.0 is the supported stable package version returned for `net10.0`.
- The application owns `INotificationService` with two send overloads, a receive operation, and `MarkAsRead`. `BaseController` invokes sends after CRUD writes and catches failures to keep the entity operation successful. `NotificationsController.GetNotifications` reads up to ten messages and preserves its PascalCase JSON contract; `wwwroot/js/notifications.js` polls every five seconds.
- The legacy send payload serializes the `Notification` model, sets the label to `{entityType} {operation}`, sets normal priority, records local `DateTime.Now`, defaults `CreatedBy` to `System`, and sets `IsRead` to false. The message text is `New {displayText} has been created`, `{displayText} has been updated`, or `{displayText} has been deleted`, where `displayText` is `{entityType} '{entityDisplayName}'` or `{entityType} (ID: {entityId})`.
- Legacy receive destructively dequeues one message with a one-second timeout; an empty queue returns null. `MarkAsRead` is intentionally a no-op and notifications are not persisted through the `Notification` DbSet by the service. The framework migration retained this service boundary as a placeholder.
- Current DI registers `INotificationService` as scoped. `Program.cs` already uses configuration and dependency injection, and its required SQL configuration is independent from messaging.
- A user-secrets key-name-only check returned `ConnectionStrings:DefaultConnection`, `Storage:ContainerName`, and `Storage:BlobServiceUri`; it returned no Service Bus keys. Secret values were not displayed or inspected. No Service Bus namespace or queue is configured in application JSON.
- Repository test-project discovery previously returned `[]`; no applicable .NET test project is present.

### Implementation boundary

- Use `ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName`, `DefaultAzureCredential`, and `Azure.Messaging.ServiceBus` only. Map the legacy label to Service Bus `Subject` and normal priority to application metadata; Service Bus does not offer MSMQ-style per-message priority scheduling.
- Preserve the one-second receive wait, destructive receive/settlement, notification JSON fields and message text, and non-fatal entity-write behavior. Do not create the queue; normal application pages must remain available when messaging configuration or access is absent.
- Validate that the configured namespace is a standard `*.servicebus.windows.net` hostname, with private DNS expected at runtime. Do not use connection strings, SAS/shared keys, IPs, `privatelink`, public endpoints, or embedded credentials, and do not assign roles or modify Azure/network resources.

Replace `NotificationService` and all unsupported `System.Messaging`/MSMQ dependencies with Azure Service Bus as the only messaging target, preserving notifications when an entity is created, edited, or deleted and preserving the ability to read notifications back. Preserve message content, labels/metadata where behaviorally relevant, priority expectations where supportable, timeout handling, and application error behavior. The assessment attributes 57 compatibility findings to MSMQ, including queue creation, permission grants, formatters, synchronous send/receive, and queue-specific exceptions; resolve these incompatibilities within this task rather than retaining MSMQ, introducing another broker, or deferring stubs.

Configure `ServiceBus:FullyQualifiedNamespace` and `ServiceBus:QueueName`, and authenticate with `DefaultAzureCredential`. SAS authentication is disabled: never use shared access keys, SAS tokens, or Service Bus connection strings. Use only the standard namespace hostname through private DNS; never use a `privatelink` hostname, IP address, public endpoint, embedded credential, or firewall exception. Queue creation, permissions, network changes, identity/RBAC assignments, and Azure configuration are outside scope.

**Done when**: The application has no runtime dependency on MSMQ or `System.Messaging`, Service Bus preserves the required contract through application-owned abstractions, validation proves both sending and receiving rather than sending alone, and restore/build succeeds with no errors; record new warnings but don't block on them. All applicable tests pass or are recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments; unavailable existing Service Bus access is reported as a blocked external integration check without weakening the required local page checks or changing Azure/on-premises systems.
