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
├── Services/               # Blob Storage and notification services
├── wwwroot/Content/        # CSS
├── wwwroot/Scripts/        # JavaScript
├── Program.cs              # ASP.NET Core startup, DI, and routes
├── appsettings.json        # Default application configuration
└── ContosoUniversity.csproj
```

## Configuration

`ConnectionStrings:DefaultConnection` is read from ASP.NET Core runtime
configuration. No database connection string is checked in. For local
development, provide it through .NET user secrets:

```powershell
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<connection-string>" --project .\ContosoUniversity.csproj
```

Hosted environments should provide `ConnectionStrings__DefaultConnection`
through platform configuration. The application passes the supplied value
unchanged to EF Core and the SQL client. SQL-authentication connection strings
provided through user secrets are not converted to managed identity. The SQL
client uses its default Azure credential chain only when the supplied string
explicitly contains `Authentication=Active Directory Default`.

Key Vault is an optional runtime configuration source. Set
`KeyVault:VaultUri` (or the environment variable `KeyVault__VaultUri`) to the
URI of the existing vault. The application uses `DefaultAzureCredential`, and
the Key Vault secret `ConnectionStrings--DefaultConnection` maps to
`ConnectionStrings:DefaultConnection` and takes precedence over earlier
configuration sources. When `KeyVault:VaultUri` is not set, the existing
configuration providers—including local user secrets—remain unchanged.

The request-body limit (10 MB) and request timeout (one hour) are represented
in `appsettings.json`. The course-image validation remains limited to 5 MB and
the existing supported image extensions.

Teaching-material images are stored in the existing Azure Blob Storage
container. Supply `Storage:BlobServiceUri` and `Storage:ContainerName` through
runtime configuration (for example, environment variables
`Storage__BlobServiceUri` and `Storage__ContainerName`). The application uses
`DefaultAzureCredential`; no storage keys, SAS tokens, or connection strings are
required.

## Run locally

Install the .NET 10 SDK and configure `ConnectionStrings:DefaultConnection`
with a SQL Server endpoint reachable from your development environment:

```powershell
dotnet restore
dotnet run
```

The application initializes the database and seeds sample data when
`Database:InitializeOnStartup` is not set to `false`. Set the connection string
through user secrets or another runtime configuration provider before starting
the application.

The project is cross-platform and is suitable for a Linux container host.
Provide the hosted Managed Instance connection through App Service
configuration or another runtime configuration provider; do not add it to the
checked-in application settings.

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
