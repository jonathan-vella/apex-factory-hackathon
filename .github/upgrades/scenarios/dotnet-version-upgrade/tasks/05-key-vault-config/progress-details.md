# Task 05-key-vault-config - progress

## Changes
- ContosoUniversity.csproj: added Azure.Extensions.AspNetCore.Configuration.Secrets 1.5.2 (Azure.Identity 1.21.0 already present).
- appsettings.json: empty `KeyVault:VaultUri`.
- Program.cs: Key Vault added as the last configuration source (DefaultAzureCredential) before DefaultConnection is read and the Task 02 guard runs, so the guard evaluates the final value. Missing `KeyVault:VaultUri` outside Development throws a clear message; in Development it is optional.
- Services/LocalFirstSecretManager.cs: in Development, when a DefaultConnection already exists (user secret/env), the vault's `ConnectionStrings--DefaultConnection` is not loaded, so the on-prem SQL-auth value is never replaced. Other secrets still load.

## Precedence
Order: appsettings, user secrets (Dev), env, then Key Vault (last, wins). Exception: Development with an existing DefaultConnection keeps the local value. Non-Development: vault value wins.

## Build
`dotnet build`: 0 warnings, 0 errors.

## Validation (vm-dev01, Azure CLI sign-in, vault discovered read-only; URI supplied via env var only, not stored)
- (a) Production without VaultUri: PASSED - fails fast with "KeyVault:VaultUri is not configured..." message.
- (b) Development without VaultUri, real SQL user secret: PASSED - home, Students, Courses, Instructors, Departments all 200.
- (c) Development with VaultUri: PASSED - provider loaded (DefaultAzureCredential auth through private endpoint succeeded, no error), all five pages 200. Vault contains secret name `ConnectionStrings--DefaultConnection` (listed by name only). Source that won for DefaultConnection in Development: the local user secret (vault secret skipped by design); the app ran against the on-prem DB.
- (d) Production with VaultUri + fake credentialed env string: PASSED - guard refused ("must not contain a user name or password"). Note: the live vault secret itself is SQL-auth (user id/password present, no Active Directory auth; checked via boolean pattern tests only, no value printed), so in non-Development with that vault the app would refuse; the owner must update the vault secret to the SQL MI Entra string before deploying (out of scope here).
- App stopped afterwards; no secrets created/modified.

## Issues
- Live vault secret is not Entra-style (see above); not changed per rules.
