---
name: app-service-configuration
description: Check the CoE archetype's App Service settings for Contoso University, its managed identity, and the SQL Managed Instance connection with managed identity, and switch the web app to the modernized image at the end of C7. Use when configuring or troubleshooting the web app, the Key Vault connection secret or the database user for the app identity.
---

# App Service configuration

## When to use

- In C6, to check what the archetype already configured for the app: the identity, the Key Vault and OpenTelemetry settings. Don't switch the web app to your image in C6.
- In C7, after cutover, to write the Key Vault connection secret, create the database user and switch the web app to your image.
- When the web app doesn't start, can't pull its image, or can't reach a backend.

The archetype owns the infrastructure: don't create or change Azure resources, and don't change the app's code to fit the hosting. The modernized app needs its database at startup, so it runs on App Service only once C7 has migrated the database.

## What the archetype provides

| Setting | Value |
|---|---|
| Identity | User-assigned `id-university-<suffix>`; App Service sets `AZURE_CLIENT_ID` to its client ID, so `DefaultAzureCredential` uses it |
| App settings | `Storage__BlobServiceUri`, `Storage__ContainerName`, `ServiceBus__FullyQualifiedNamespace`, `ServiceBus__QueueName`, `KeyVault__VaultUri`, `APPLICATIONINSIGHTS_CONNECTION_STRING`, `AZURE_CLIENT_ID`, `WEBSITES_PORT` `8080` |
| Roles for the identity | AcrPull, Storage Blob Data Contributor, Azure Service Bus Data Sender and Receiver, Key Vault Secrets User, Monitoring Metrics Publisher |
| Database connection | Not an app setting: the Key Vault secret `ConnectionStrings--DefaultConnection`, written in C7 |
| Image pull | With the identity, over the VNet; the registry accepts ARM-audience tokens |

App settings use `__` where the code reads `:`: `ServiceBus__QueueName` is `ServiceBus:QueueName`.

## Steps

### C6: check the configuration

1. List the settings and the identity:

   ```powershell
   az webapp config appsettings list -g rg-university-<suffix> -n app-university-<suffix> --query "[].name" -o tsv
   az webapp identity show -g rg-university-<suffix> -n app-university-<suffix> --query "userAssignedIdentities" -o json
   ```

2. Check that the app reads exactly these keys: `git grep -n -E "Storage:|ServiceBus:|KeyVault:|APPLICATIONINSIGHTS_CONNECTION_STRING|DefaultConnection" -- app/ContosoUniversity/*.cs app/ContosoUniversity/Services`. A key the app reads but the archetype doesn't set is a gap to raise with your coach, not a resource to create.

### C7: connect to the migrated database and go live

After cutover removes the link, the database is writable:

1. **Write the connection secret.** It uses Microsoft Entra authentication and has no password:

   ```powershell
   $mi = az sql mi show -g rg-university-<suffix> -n sqlmi-university-<suffix> --query fullyQualifiedDomainName -o tsv
   az keyvault secret set --vault-name kv-university-<suffix> --name 'ConnectionStrings--DefaultConnection' --value "Server=$mi;Database=ContosoUniversity;Authentication=Active Directory Default;Encrypt=True;" --output none
   ```

   No `User Id=` is needed: `AZURE_CLIENT_ID` selects the identity. Use the instance's standard host name, never a `privatelink` name, an IP address or the public endpoint.

2. **Create the database user** for the identity. Connect to `ContosoUniversity` on the Managed Instance from SSMS on `vm-dev01` with **Microsoft Entra MFA**, as the archetype's deployer, and run:

   ```sql
   CREATE USER [id-university-<suffix>] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_datareader ADD MEMBER [id-university-<suffix>];
   ALTER ROLE db_datawriter ADD MEMBER [id-university-<suffix>];
   ALTER ROLE db_ddladmin ADD MEMBER [id-university-<suffix>];
   ```

   `WITH SID` and `TYPE = E` aren't supported on SQL Managed Instance.

3. **Switch the web app to your image** and restart it:

   ```powershell
   az webapp config container set -g rg-university-<suffix> -n app-university-<suffix> --container-image-name cruniversity<suffix>.azurecr.io/contoso-university:<tag> --container-registry-url https://cruniversity<suffix>.azurecr.io --output none
   az webapp config show -g rg-university-<suffix> -n app-university-<suffix> --query acrUseManagedIdentityCreds   # true: the archetype set the pull identity
   az webapp restart -g rg-university-<suffix> -n app-university-<suffix>
   ```

## Checks

- `az webapp config container show -g rg-university-<suffix> -n app-university-<suffix>` names your image.
- `https://app-university-<suffix>.azurewebsites.net/` loads, and the Students, Courses, Instructors and Departments pages show the migrated data.
- An upload on **Courses** > **Edit** lands in `teaching-materials`, a student edit shows a toast, and requests reach Application Insights.
- `az webapp log tail -g rg-university-<suffix> -n app-university-<suffix>` shows no startup exception.

| Symptom | Cause |
|---|---|
| The app exits at startup before C7 | Expected: the database isn't migrated yet. Don't point the web app at your image before C7 |
| The image pull fails with the identity | `acrUseManagedIdentityCreds` must be `true` and `acrUserManagedIdentityID` the identity's client ID, as the archetype sets them. To set them again: `az webapp config set --acr-use-identity true --acr-identity <identity resource ID>` (this flag takes the resource ID) |
| `ACRTokenRetrievalFailure` | The registry must accept ARM-audience tokens: `az acr config authentication-as-arm show -r cruniversity<suffix>` prints `enabled`. The archetype sets it |
| "KeyVault:VaultUri is not configured" | `KeyVault__VaultUri` is missing, or written with `:` |
| "ConnectionStrings:DefaultConnection is not configured" | The Key Vault secret wasn't written (step 1), or its name uses `:` instead of `--` |
| "Server identity does not have Azure Active Directory Readers permission" | The Managed Instance's primary identity must be the team's `id-sqlmi-directory`. Ask your coach |
| "Login failed for user '<token-identified principal>'" | The database user doesn't exist, or its name isn't the identity's name |

## Example

Before, the legacy app's `Web.config`, with a password in the file:

```xml
<add name="DefaultConnection" connectionString="Server=10.10.1.4;Database=ContosoUniversity;User Id=contosoapp;Password=..." />
```

After, nothing in the repo. On App Service the Key Vault secret `ConnectionStrings--DefaultConnection` holds:

```text
Server=sqlmi-university-<suffix>.<dns-zone>.database.windows.net;Database=ContosoUniversity;Authentication=Active Directory Default;Encrypt=True;
```
