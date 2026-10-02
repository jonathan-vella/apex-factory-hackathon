# 02-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance

**Depends on**: 01-aspnetcore-net10

Make the EF Core data layer target Azure SQL Managed Instance as the only Azure database (never Azure SQL Database), still reading `ConnectionStrings:DefaultConnection`. On Azure the value uses `Authentication=Active Directory Default` with the MI's private VNet-local host name — no user name/password, never the public data endpoint (port 3342); DefaultAzureCredential (managed identity on Azure, Azure CLI locally) supplies the token through Microsoft.Data.SqlClient. In `Development` only, a SQL-auth connection string for the on-prem SQL Server using the existing `contosoapp` login (from user secrets) is passed to EF Core unchanged; outside `Development` the app must refuse to start if DefaultConnection contains a user name or password. Never auto-convert a SQL-auth string to managed identity.

Preserve the EF Core model and behavior, including `EnsureCreated`/seed on startup (research whether the startup seed is acceptable against SQL MI permissions and keep it behavior-equivalent). Much of the reading path is already satisfied by Task 01 (configuration key and DI registration) — where so, record the implementation step as a no-op with verification. No credentials or connection-string values in source control or planning artifacts; no database, login or on-prem changes.

**Done when**: `dotnet build` succeeds; a startup guard rejects user/password connection strings outside Development (verified by running with `ASPNETCORE_ENVIRONMENT` set to a non-Development value and a credentialed string, then with an `Active Directory Default` string); Microsoft.Data.SqlClient supports `Active Directory Default`; local `dotnet run` (Development, on-prem SQL login via user secret) loads home, Students, Courses, Instructors, Departments — **BLOCKED** until the user secret is supplied.

## Research findings (executor)
- Program.cs already reads ConnectionStrings:DefaultConnection and registers SchoolContext via UseSqlServer (Task 01): verified no-op.
- Resolved Microsoft.Data.SqlClient 6.1.6 (via EF Core SqlServer 10.0.12) with Azure.Identity 1.17.1 transitive; 'Active Directory Default' supported. No package change needed.
- DbInitializer uses EnsureCreated + seed unchanged; behavior-equivalent on MI (requires create-table rights for the managed identity; no code change).
- Change: add a startup guard in Program.cs using SqlConnectionStringBuilder: outside Development reject UserID/Password; Development passes string unchanged. Never log values.
- User secret key ConnectionStrings:DefaultConnection exists (value not read).
