# Setup and testing guide

## Prerequisites

- .NET 10 SDK
- A reachable SQL Server instance and a configured
  `ConnectionStrings:DefaultConnection`

The repository does not include a database connection string. For local
development, store the appropriate connection string in .NET user secrets:

```powershell
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<connection-string>" --project .\ContosoUniversity.csproj
```

Hosted environments should supply `ConnectionStrings__DefaultConnection`
through platform configuration. The application passes the supplied string
through unchanged: SQL authentication remains SQL authentication, and the SQL
client's default Azure credential chain is used only when the value explicitly
contains `Authentication=Active Directory Default`.

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
