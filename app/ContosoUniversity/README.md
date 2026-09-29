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
  - Existing Azure Service Bus namespace and queue for live notification integration checks

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

## Runtime Connection Configuration

- In Development, configure `ConnectionStrings:DefaultConnection` with .NET user secrets. Key Vault is not required.
- Outside Development, configure only `KeyVault:VaultUri` as a non-secret application setting, using the standard `https://<vault-name>.vault.azure.net/` hostname resolved through private DNS.
- Store the SQL connection string in the existing Key Vault secret named `ConnectionStrings--DefaultConnection`. The application loads it with `DefaultAzureCredential` before registering the database context; a missing vault setting, inaccessible vault, or missing secret prevents startup.
- Do not put the SQL secret in appsettings files, source control, logs, or client-visible responses. Azure vault, identity, permission, and network configuration are managed outside this application.
