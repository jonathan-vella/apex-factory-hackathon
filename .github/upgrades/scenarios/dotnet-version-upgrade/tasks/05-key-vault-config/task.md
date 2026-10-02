# 05-key-vault-config: Integrate Azure Key Vault

**Depends on**: 04-service-bus-messaging

Add the existing Key Vault as an ASP.NET Core configuration source via `Azure.Extensions.AspNetCore.Configuration.Secrets` with DefaultAzureCredential and `KeyVault:VaultUri`. Outside `Development`, the app refuses to start when `KeyVault:VaultUri` is missing; in `Development` it is optional and user secrets remain allowed for the on-prem SQL login — a SQL-auth DefaultConnection in Development is never replaced or reinterpreted. On Azure, secret `ConnectionStrings--DefaultConnection` holds the SQL MI string (Entra auth, no password) and App Service settings carry only `KeyVault:VaultUri` and non-secret endpoints.

Order the Key Vault source so the Task 02 credential guard still evaluates the final DefaultConnection. Do not provision the vault, create secrets or identities, or assign roles; no Entra user sign-in.

**Done when**: `dotnet build` succeeds; startup guard verified (non-Development without `KeyVault:VaultUri` fails fast with a clear message; Development without it starts); with `KeyVault:VaultUri` set, configuration values resolve from Key Vault through the private endpoint (verified via a non-secret check such as the provider being registered and a known key resolving, without printing values); home, Students, Courses, Instructors, Departments load. Database-backed steps are **BLOCKED** until the user secret is supplied.
