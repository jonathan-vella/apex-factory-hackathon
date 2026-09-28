# Task 02 progress details

## Outcome

- Upgraded the SQL Server EF Core provider from 3.1.32 to 10.0.12, compatible with the application's `net10.0` target.
- Removed the direct `Microsoft.Data.SqlClient` 2.1.4 pin, which had no source consumers; the provider now resolves `Microsoft.Data.SqlClient` 6.1.6 and `Microsoft.Data.SqlClient.SNI.runtime` 6.0.2 transitively.
- Made `ConnectionStrings:DefaultConnection` mandatory at startup and configured EF Core SQL Server using the original configured string.
- Development does not parse, rewrite, or convert the existing SQL-authenticated .NET user-secret value. The user-secret key exists; its value was never printed or copied.
- Outside Development, startup rejects embedded SQL usernames/passwords, integrated security, any authentication mode other than `Active Directory Default`, IP literals, `privatelink` names, public DNS labels, and non-default SQL ports other than 1433.
- No Entra application sign-in, Key Vault configuration, Azure SDK identity, hard-coded endpoint, credential, database migration, DDL, data write, schema change, RBAC assignment, or legacy deployment change was added.

## Model and schema safety

- `Data/SchoolContext.cs` was not modified. Its nine `DbSet`s, `datetime2` conventions, explicit table mappings, Person TPH discriminator, CourseAssignment composite key and relationships, and Instructor/OfficeAssignment one-to-one mapping remain intact.
- The application contains no `Database.Migrate()`, `EnsureCreated()`, or migration-applying initializer. `DbInitializer.Initialize` remains unused by application startup.
- Schema-writer inventory found the existing legacy deployment warm-up path in `infra/datacenter/scripts/Install-AppLegacySite.ps1` (`EnsureCreated()` documented at lines 9 and 150). The legacy host's current deployment status and whether it uses the same database cannot be proven from this workspace. Task 02 therefore made no schema or data changes and did not modify the script.
- Azure private DNS, Managed Instance availability, credentials, RBAC, and live connectivity were not exercised; those are external checks and Azure changes are outside this task.

## Validation

- `dotnet restore app/ContosoUniversity/ContosoUniversity.csproj --verbosity minimal`: succeeded.
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --configuration Release --no-restore --verbosity minimal`: succeeded, 0 errors, 0 warnings.
- `dotnet build app/ContosoUniversity/ContosoUniversity.sln --configuration Release --no-restore --verbosity minimal`: succeeded, 0 errors, 0 warnings.
- Resolved packages confirmed `Microsoft.EntityFrameworkCore.SqlServer` 10.0.12, EF Core 10.0.12 components, SqlClient 6.1.6, and SqlClient SNI runtime 6.0.2.
- Test-project discovery returned `[]`; no applicable .NET test project exists.
- In Development, the application used the existing user-secret configuration and returned HTTP 200 for `/`, `/Students`, `/Courses`, `/Instructors`, and `/Departments`.
- In Production, a synthetic passwordless connection string with `Authentication=Active Directory Default` and a standard MI hostname started successfully; `/health` returned HTTP 200. No SQL connection was attempted.
- Production negative checks passed for missing connection string, embedded credentials, public endpoint/port 3342, `privatelink` hostname, IP endpoint, and integrated authentication.
- No actual Azure SQL endpoint was contacted and no on-premises database or login was modified.

## Files changed

- `.github/upgrades/scenarios/dotnet-version-upgrade/scenario-instructions.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/02-azure-sql-managed-instance/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/02-azure-sql-managed-instance/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`

## Boundary

Task 02 is complete. Task 03 and all later tasks remain unstarted; mutable file handling, Service Bus, Key Vault, telemetry, and the final dependency CVE audit remain in their approved owners.