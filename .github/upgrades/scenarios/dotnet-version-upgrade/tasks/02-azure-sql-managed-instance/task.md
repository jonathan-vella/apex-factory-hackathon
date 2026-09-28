# 02-azure-sql-managed-instance: Migrate the database workload to Azure SQL Managed Instance

## Research Findings (2026-09-28)

### Confirmed project state

- Scope is the single upgraded project `app/ContosoUniversity/ContosoUniversity.csproj`, targeting `net10.0`; package versions are declared in the project and no `Directory.Packages.props`/central package management file exists.
- Direct references before this task are `Microsoft.EntityFrameworkCore.SqlServer` 3.1.32 and `Microsoft.Data.SqlClient` 2.1.4. The generated assessment recommends EF Core SQL Server 10.0.12, and the supported-package check returns 10.0.12 for `net10.0`.
- `Program.cs` reads `ConnectionStrings:DefaultConnection`, but currently registers SQL Server only when the value is nonempty. An absent or blank value therefore leaves a DI-resolved `SchoolContext` without a provider instead of failing clearly.
- `appsettings.json` contains an empty `ConnectionStrings:DefaultConnection`; the Development user-secrets key exists. Its value was not read or copied. Pass the configured string unchanged to `UseSqlServer`.
- `SchoolContext.cs` has nine `DbSet`s (`Courses`, `Enrollments`, `Departments`, `OfficeAssignments`, `CourseAssignments`, `People`, `Students`, `Instructors`, `Notifications`), `datetime2` conventions, explicit table mappings, the Person TPH discriminator, CourseAssignment composite key and relationships, and the Instructor/OfficeAssignment one-to-one relationship. This file is not intended to change.
- `DbInitializer.Initialize` exists but is not called from the current ASP.NET Core startup. There is no application migrations directory and no app-side `Migrate`, `EnsureCreated`, or migration initializer.
- No source currently performs direct ADO.NET commands. The SQL client reference is a provider dependency; remove its stale 2.1.4 pin when upgrading the EF SQL Server provider so NuGet can resolve the provider-compatible SQL client. Any connection-string parsing added here must use the SQL provider's connection-string semantics and must pass the original configured string unchanged to EF Core.

### Database/schema safety boundary

| Existing writer/path | Toolchain | Where it runs | Evidence |
| --- | --- | --- | --- |
| Legacy Framework app warm-up creates/seeds the database | Legacy application's `EnsureCreated()` path | Existing legacy deployment on `vm-app01`; deployment status cannot be established from this workspace | `infra/datacenter/scripts/Install-AppLegacySite.ps1:9,150` |

The in-place rewrite and task instructions do not establish whether the legacy host still uses the same database. Treat the database as potentially shared. This task changes only EF provider/configuration code: do not add migrations, call `Migrate()`/`EnsureCreated()`, perform DDL or data writes, change the legacy deployment, or alter SQL Server/logins. Live schema ownership and private endpoint reachability are not validated here.

### Implementation and validation boundary

- Development may accept the existing SQL-authenticated user-secret value and pass it through unchanged. Outside Development, fail startup when SQL username/password values are present; require `Authentication=Active Directory Default` and reject IP-address, `privatelink`, or public port 3342 data sources. No hostname, credential, or endpoint value will be committed.
- Keep `ConnectionStrings:DefaultConnection`; no Azure Key Vault source is added in this task (task 05 owns it).
- After package restore/build, run the five required local pages using Development configuration without displaying the user-secret value. If database connectivity fails, report the exact blocker without altering the database or deployment.
- No applicable .NET test project was recorded during task 01; recheck discovery and record an unavailable-test no-op if still absent.
- Scope excludes Azure provisioning/configuration, RBAC, schema/data changes, SQL Server/logins, and changes to `infra/datacenter/scripts/Install-AppLegacySite.ps1`.

Operate on the upgraded .NET 10 application and move its Azure database configuration boundary to Azure SQL Managed Instance while retaining `ConnectionStrings:DefaultConnection`. Upgrade the EF Core 3.1 data stack to a .NET 10-compatible EF Core release and preserve all nine `DbSet` properties, `datetime2` conventions, explicit table mappings, Person TPH discriminator, composite key, course/instructor relationships, one-to-one office assignment, and existing application behavior. Use ASP.NET Core configuration and DI-provided `DbContextOptions`; do not introduce Microsoft Entra application user sign-in.

The Azure connection string must use the private VNet-local standard Managed Instance hostname, `Authentication=Active Directory Default`, and no embedded credentials, public data endpoint on port 3342, `privatelink` hostname, IP address, or firewall exception. Development alone may pass the unchanged on-premises SQL-authenticated string from .NET user secrets to EF Core without conversion or reinterpretation. Non-Development startup must reject connection strings containing a user name or password; never convert a SQL-authenticated string to managed identity automatically. This task changes application code/configuration only: it must not provision or configure Managed Instance, modify schemas or data, assign RBAC, validate live private endpoints, or change the on-premises SQL Server, database, logins, or deployment.

**Done when**: EF Core and SQL client dependencies are compatible with `net10.0`, the assessed model and mappings remain intact, Azure and Development connection-string policies are enforced, and restore/build succeeds with no errors; record new warnings but don't block on them. Every applicable test passes or is recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments against the Development secret; an absent local SQL secret keeps runtime/page validation blocked until supplied rather than impossible, while unavailable Azure network/RBAC/resource access is documented without infrastructure changes.
