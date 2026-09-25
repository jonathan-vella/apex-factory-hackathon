# Contoso University - .NET 10

Contoso University is an SDK-style ASP.NET Core MVC application targeting
`net10.0`. It retains the existing controllers, Razor views, routes, EF Core
model, and CRUD workflows. Static web assets are served from `wwwroot`.

## Technology

- ASP.NET Core MVC on .NET 10
- Entity Framework Core 10 with SQL Server
- Razor views and Bootstrap

## Project structure

```text
ContosoUniversity/
├── Controllers/            # MVC controllers
├── Data/                   # EF Core context and sample-data initializer
├── Models/                 # Entities and view models
├── Views/                  # Razor views
├── Services/               # Notification service
├── wwwroot/Content/        # CSS
├── wwwroot/Scripts/        # JavaScript
├── wwwroot/Uploads/        # Teaching-material images
├── Program.cs              # ASP.NET Core startup, DI, and routes
├── appsettings.json        # Default application configuration
└── ContosoUniversity.csproj
```

## Configuration

`ConnectionStrings:DefaultConnection` is read from ASP.NET Core configuration.
The checked-in default preserves the original LocalDB development setting;
environment variables and .NET user secrets can override it. For example:

```powershell
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<connection-string>" --project .\ContosoUniversity.csproj
```

The request-body limit (10 MB) and request timeout (one hour) are represented
in `appsettings.json`. The course-image validation remains limited to 5 MB and
the existing supported image extensions.

## Run locally

Install the .NET 10 SDK and a SQL Server instance. On Windows with LocalDB
available, run:

```powershell
dotnet restore
dotnet run
```

The application initializes the database and seeds sample data when
`Database:InitializeOnStartup` is not set to `false`. Set the connection string
through configuration when using a database other than LocalDB.

The project is cross-platform and is suitable for a Linux container host. The
LocalDB default is for local development only; provide the hosted SQL
connection string through App Service configuration or another runtime
configuration provider.

## Features

- Student CRUD with pagination and search
- Course and department management
- Instructor assignments and office locations
- Enrollment statistics
- Course teaching-material image uploads
- Notifications for student, course, instructor, and department changes

The notification transport is temporarily process-local so the upgraded
application remains cross-platform. It is not durable or shared across
instances; the later Service Bus task in the modernization plan replaces it.

## Database initialization

The initializer creates the database when it does not exist and seeds sample
students, instructors, courses, departments, assignments, and enrollments when
the student table is empty. `EnsureCreated` does not apply schema migrations;
database migrations are managed separately.
