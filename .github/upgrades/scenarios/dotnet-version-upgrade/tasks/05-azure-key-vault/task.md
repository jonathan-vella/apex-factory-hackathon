# 05-azure-key-vault: Integrate Azure Key Vault

## Research Findings (2026-09-29)

### Confirmed project state

- Scope is the single SDK-style `net10.0` application `app/ContosoUniversity/ContosoUniversity.csproj`. Direct package versions before this task are `Azure.Identity` 1.21.0, `Azure.Messaging.ServiceBus` 7.21.0, `Azure.Storage.Blobs` 12.29.2, and `Microsoft.EntityFrameworkCore.SqlServer` 10.0.12.
- Supported stable `Azure.Extensions.AspNetCore.Configuration.Secrets` for `net10.0` is 1.5.2. Its package documentation confirms `AddAzureKeyVault(new Uri(vaultUri), new DefaultAzureCredential())`; the provider maps Key Vault `--` secret-name separators to configuration `:` separators.
- `Program.cs` creates the ASP.NET Core builder and then immediately calls `GetConnectionString("DefaultConnection")`, validates the SQL configuration, and registers `SchoolContext`. Key Vault must be added after builder creation but before the connection-string read so the existing SQL policy and EF registration consume the vault value.
- `appsettings.json` contains an empty `ConnectionStrings:DefaultConnection`; `appsettings.Development.json` is empty. No vault URI is in committed app settings.
- A user-secrets key-name-only check found `ConnectionStrings:DefaultConnection`, `Storage:ContainerName`, `Storage:BlobServiceUri`, `ServiceBus:QueueName`, and `ServiceBus:FullyQualifiedNamespace`, but no Key Vault key. Secret values were not printed or inspected. The Development user-secret connection string remains the existing source and must not be rewritten.
- `Program.cs` already rejects SQL credentials and invalid endpoints outside Development. Keep that policy and ensure the Key Vault provider supplies the connection string before it runs.
- No Key Vault provider package or `AddAzureKeyVault` call exists yet. Existing Azure service integrations use `Azure.Identity` with `DefaultAzureCredential`; reuse that approved credential pattern.
- There is no applicable .NET test project. Local development pages can be checked with the existing SQL user secret; Key Vault private DNS, identity access, and secret presence are not configured locally and must not be provisioned for this task.

### Implementation and validation boundary

- Add `Azure.Extensions.AspNetCore.Configuration.Secrets` 1.5.2 and conditionally add the Key Vault provider only outside Development.
- Require `KeyVault:VaultUri` outside Development and validate HTTPS, default port, standard `*.vault.azure.net` host, and absence of IP literals, `privatelink`, path, user info, query, or fragment. Keep the hostname standard so private DNS resolves it to the private endpoint.
- Provider-load failures must abort startup with a clear, non-secret diagnostic. Do not fall back to an environment/appsettings SQL connection string if Key Vault cannot supply the existing secret. Do not log or surface secret values.
- Development must not construct a Key Vault client and must continue resolving `ConnectionStrings:DefaultConnection` from user secrets.
- Do not create a vault/secret, assign roles, alter private DNS/networking, deploy, or modify SQL/on-premises systems. Test negative Production startup validation locally without making a network call; record live vault access as unverified.

Add the existing Azure Key Vault as a mandatory configuration source outside Development, using `KeyVault:VaultUri` and `DefaultAzureCredential`. Ensure the existing secret name `ConnectionStrings--DefaultConnection` maps to `ConnectionStrings:DefaultConnection`, participates in startup early enough for database registration, and does not expose secret values in source, logs, generated artifacts, or client responses. Development continues to use .NET user secrets for the unchanged local SQL-authenticated connection string and does not require Key Vault.

Use the vault's standard private-DNS-resolved hostname and retain private-only access. On Azure, App Service settings hold only `KeyVault:VaultUri` and non-secret endpoints; Key Vault holds `ConnectionStrings--DefaultConnection`. Do not hard-code the vault endpoint or Azure identity identifiers, use a `privatelink` hostname or IP address, open public access, provision/configure the vault, create secrets, assign access/RBAC, or deploy any application/resource change. Outside Development, missing or inaccessible mandatory Key Vault configuration must fail clearly rather than silently falling back to embedded credentials.

**Done when**: Non-Development configuration requires the existing Key Vault and resolves the SQL secret mapping without stored credentials, Development remains user-secrets based, and restore/build succeeds with no errors; record new warnings but don't block on them. Every applicable test passes or is recorded as unavailable, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments in Development; missing local SQL secrets block page validation until supplied, while missing private Key Vault access blocks only the corresponding non-Development integration check and does not authorize Azure changes.
