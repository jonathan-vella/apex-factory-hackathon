# Progress: 02-sql-managed-instance

## Changes
- app/ContosoUniversity/Program.cs: added `using Microsoft.Data.SqlClient;` and a startup guard — outside Development, `SqlConnectionStringBuilder` rejects a connection string with a user name or password (message never echoes the value). Development passes the string to EF Core unchanged. No auto-conversion.

## Verified no-ops
- Reading `ConnectionStrings:DefaultConnection` and `UseSqlServer` DI registration (Task 01).
- EF Core model and `EnsureCreated`/seed unchanged. On SQL MI the identity needs create-table rights for first-run EnsureCreated; no code change.
- No package change: Microsoft.Data.SqlClient 6.1.6 (via EF Core SqlServer 10.0.12) with Azure.Identity 1.17.1 supports `Authentication=Active Directory Default`.

## Validation
- `dotnet build`: 0 warnings, 0 errors.
- Production + fake credentialed string: refused to start (passed).
- Production + fake `Active Directory Default` string: guard passed; app proceeded to DB connect and failed on the fake host (expected).
- Development with user secret: /, /Students, /Courses, /Instructors, /Departments all 200; app stopped, port free.

## Notes
- No secrets/connection strings written or printed. No Azure, on-prem DB or legacy changes.
