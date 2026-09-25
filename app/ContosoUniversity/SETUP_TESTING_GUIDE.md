# Setup and testing guide

## Prerequisites

- .NET 10 SDK
- A reachable SQL Server instance and a configured
  `ConnectionStrings:DefaultConnection`

On Windows with SQL Server LocalDB available, the checked-in development
connection string can be used. Override it with .NET user secrets or the
`ConnectionStrings__DefaultConnection` environment variable for other
instances.

## Build and run

From this directory:

```powershell
dotnet restore
dotnet build
dotnet run
```

The application creates the database and seeds sample data on startup unless
`Database:InitializeOnStartup` is set to `false`.

## Verify notifications

1. Open the Notifications page.
2. Create, edit, or delete a student, course, instructor, or department.
3. Confirm the notification appears in the top-right corner.
4. Confirm the browser polls `GET /Notifications/GetNotifications` every five
   seconds and each response contains no more than ten messages.

The .NET 10 upgrade uses a temporary process-local queue. It does not persist
messages across restarts or share them between application instances; the
modernization plan's later Service Bus task replaces this transport.

## Troubleshooting

- If the app fails during database initialization, check the active connection
  string and confirm that SQL Server is reachable.
- If static assets do not load, verify they remain under `wwwroot/Content` and
  `wwwroot/Scripts`.
- If notifications do not appear, check the browser console and the
  `GET /Notifications/GetNotifications` response.
