---
name: modernize-plan
description: 'B06: plan the Contoso University modernization (.NET 10 first, then database, Blob, Service Bus, Key Vault)'
agent: modernize
model: ["GPT-6 Sol (copilot)"]
reasoning-effort: medium
---

# Plan the Contoso University modernization

Assess and plan the modernization of `app/ContosoUniversity`. Plan only: write the plan and wait for my review before you change any code.

Plan these tasks, in this order:

1. **Upgrade to .NET 10 and ASP.NET Core MVC first.** Convert the project to SDK-style, replace `packages.config` with `PackageReference`, move the `Web.config` settings to `appsettings.json`, and keep the existing controllers, views and EF Core model.
2. **Database:** Azure SQL Managed Instance with managed identity. Keep SQL authentication to `10.10.n.4` working locally (the `contosoapp` login, from user secrets). Use managed identity only when the connection string is configured for it (`Authentication=Active Directory Default`).
3. **Uploads:** move the teaching-material uploads in `CoursesController` from the local `Uploads` folder to Azure Blob Storage, not Azure Files.
4. **Messaging:** move `NotificationService` from MSMQ to Azure Service Bus, keeping both the send path and the read-back on the Notifications page. Remove every reference to `System.Messaging`.
5. **Secrets:** Azure Key Vault as a configuration source when `KeyVault:VaultUri` is set, so the secret `ConnectionStrings--DefaultConnection` overrides `ConnectionStrings:DefaultConnection`.

Constraints:

- **No Windows AD to Microsoft Entra ID task.** The app has no user sign-in and no `[Authorize]`. The assessment's "Windows authentication" finding comes only from `IISExpressWindowsAuthentication` in the project file and `Integrated Security=True` in the old LocalDB connection string.
- Use `DefaultAzureCredential` for Blob, Service Bus and Key Vault. Shared key access and Service Bus local (SAS) auth are off, so use no keys, no SAS and no connection strings with secrets.
- Never put a password in a committed file: user secrets locally, Key Vault on Azure.
- The target is Azure App Service for Linux (containers).
- Don't provision, change or delete any Azure resources: they already exist.
- Use these configuration keys:

  | Key | Purpose |
  |---|---|
  | `ConnectionStrings:DefaultConnection` | SQL authentication to `10.10.n.4` locally, from user secrets or Key Vault only |
  | `Storage:BlobServiceUri` | Blob endpoint, for example `https://stuni<suffix>b06.blob.core.windows.net` |
  | `Storage:ContainerName` | `teaching-materials` |
  | `ServiceBus:FullyQualifiedNamespace` | For example `sbns-uni-<suffix>-b06.servicebus.windows.net` |
  | `ServiceBus:QueueName` | `notifications` |
  | `KeyVault:VaultUri` | For example `https://kv-uni-<suffix>-b06.vault.azure.net/` |

Show me the plan and wait for my review.
