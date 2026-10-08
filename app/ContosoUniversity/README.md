# Contoso University - .NET Framework 4.8.2

This project is a ASP.NET MVC 5 targeting .NET Framework 4.8.2.

## Project Overview

### Framework
- ASP.NET MVC 5 (.NET Framework 4.8.2)

### Database Access: Entity Framework
- Entity Framework Core 3.1.32

### Project Structure
```
ContosoUniversity/
├── App_Start/              # Application startup configuration
├── Controllers/            # MVC Controllers
├── Data/                   # Entity Framework context and initializer
├── Models/                 # Data models and view models
├── Views/                  # Razor views
├── Content/                # CSS and other content
├── Scripts/                # JavaScript files
├── Properties/             # Assembly properties
├── Global.asax             # Application global events
├── Web.config              # Configuration file
└── packages.config         # NuGet packages
```

## Database Configuration

The application uses SQL Server LocalDB with the following connection string in `Web.config`:
```xml
  <connectionStrings>
    <add name="DefaultConnection" connectionString="Data Source=(LocalDb)\MSSQLLocalDB;Initial Catalog=ContosoUniversityNoAuthEFCore;Integrated Security=True;MultipleActiveResultSets=True" />
  </connectionStrings>
```

## Running the Application

1. **Prerequisites**:
   - Visual Studio 2019 or later
   - IIS Express
   - SQL Server LocalDB
   - Microsoft Message Queue (MSMQ) Server enabled

2. **Setup**:
   - Open the project in Visual Studio
   - Restore NuGet packages
   - Build the solution
   - Run using IIS Express

## Features

- **Student Management**: CRUD operations for students with pagination and search
- **Course Management**: Manage courses and their assignments to departments
- **Instructor Management**: Handle instructor assignments and office locations
- **Department Management**: Manage departments and their administrators
- **Statistics**: View enrollment statistics by date

## Database Initialization

The application uses Entity Framework Core Code First with a database initializer that:
- Creates the database if it doesn't exist
- Seeds sample data including students, instructors, courses, and departments
- Handles model changes by recreating the database

## Run on Azure App Service

The modernized app runs as a container on App Service for Linux, in the CoE archetype's resource group `rg-university-<suffix>`. It reads every setting from configuration, and authenticates to every backend with the web app's user-assigned managed identity `id-university-<suffix>` through `DefaultAzureCredential`.

| Setting | Where it comes from |
|---|---|
| `Storage__BlobServiceUri`, `Storage__ContainerName` | App settings, set by the archetype |
| `ServiceBus__FullyQualifiedNamespace`, `ServiceBus__QueueName` | App settings, set by the archetype |
| `KeyVault__VaultUri` | App setting, set by the archetype |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App setting, set by the archetype |
| `AZURE_CLIENT_ID` | App setting: the identity's client ID, which `DefaultAzureCredential` uses |
| `ConnectionStrings:DefaultConnection` | Key Vault secret `ConnectionStrings--DefaultConnection`, written after cutover |

The app reads its database at startup, so it runs on App Service only after the database is migrated to SQL Managed Instance. After cutover:

1. Write the Key Vault secret. It uses Microsoft Entra authentication and has no password:

   ```text
   Server=<managed instance host name>;Database=ContosoUniversity;Authentication=Active Directory Default;Encrypt=True;
   ```

2. Create the database user for the identity, connected to `ContosoUniversity` as a Microsoft Entra admin of the managed instance:

   ```sql
   CREATE USER [id-university-<suffix>] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_datareader ADD MEMBER [id-university-<suffix>];
   ALTER ROLE db_datawriter ADD MEMBER [id-university-<suffix>];
   ALTER ROLE db_ddladmin ADD MEMBER [id-university-<suffix>];
   ```

3. Point the web app at the image in the private registry, pulled with the identity, and restart it.

In Development, on `vm-dev01`, the app keeps using the source database with SQL authentication from .NET user secrets, and the member's Azure CLI sign-in for Blob, Service Bus and Key Vault (`AZURE_TOKEN_CREDENTIALS=AzureCliCredential`).
