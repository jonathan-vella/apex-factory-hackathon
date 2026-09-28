# Task 01 progress details

## Outcome

- Converted `ContosoUniversity.csproj` in place to `Microsoft.NET.Sdk.Web` targeting `net10.0` with `PackageReference` dependencies.
- Replaced the ASP.NET Framework host with ASP.NET Core startup, dependency injection, conventional routing, exception handling, Razor views, and static-file middleware.
- Migrated all seven controllers and 28 Razor views while preserving anti-forgery behavior, routes, status semantics, notification JSON contracts, and user-visible behavior.
- Moved immutable assets to case-consistent `wwwroot` paths and retained mutable course files behind the local boundary owned by task 03.
- Documented all 22 binding redirects before removing the legacy host and configuration artifacts.
- Added .NET SDK container metadata for `mcr.microsoft.com/dotnet/aspnet:10.0`, repository `contoso-university`, and port `8080` without adding a Dockerfile or using Docker.
- Kept SQL Managed Instance, Blob Storage, Service Bus, Key Vault, Azure Monitor, and final CVE remediation in tasks 02 through 07. None of those tasks was started.

## Validation

- `dotnet restore` succeeded.
- Release project and solution builds succeeded with 0 errors.
- No applicable .NET test project was discovered; test execution is a recorded no-op.
- `dotnet publish /t:PublishContainer` produced and validated a local container archive without a registry push or deployment.
- Live probes passed for Home, Notifications, notification JSON contracts, health, and static assets.
- Students, Courses, Instructors, and Departments reached their migrated routes but database-backed page completion is blocked because no Development `ConnectionStrings:DefaultConnection` user secret is configured.

## Remaining warnings

- Four NuGet advisory warnings remain for task 07: `Microsoft.Data.SqlClient`, `Microsoft.IdentityModel.JsonWebTokens`, `System.IdentityModel.Tokens.Jwt`, and `System.Drawing.Common`.
- The missing Development SQL user secret remains an external runtime-validation blocker and was not bypassed.