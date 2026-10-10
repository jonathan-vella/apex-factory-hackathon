# Copilot instructions

This repo holds Contoso University, a legacy ASP.NET MVC 5 app on .NET Framework 4.8 in `app/ContosoUniversity`. It's being modernized to .NET 10 and ASP.NET Core MVC, packaged as a container image and run on Azure App Service for Linux.

## Scope

- Change only `app/ContosoUniversity` and the Upgrade agent's artifacts under `.github/upgrades/`. Never edit other files: the rest of the repo is kit material.
- Build, run and test only `app/ContosoUniversity`. Don't run the repo's PowerShell or npm scripts.
- All Azure resources already exist. Never provision, deploy or change Azure resources, and never change the on-premises SQL Server, its database or the legacy app on `vm-app01`.

## Target services

| Need | Service | Configuration keys |
|---|---|---|
| Database | Azure SQL Managed Instance | `ConnectionStrings:DefaultConnection` |
| Uploads | Azure Blob Storage, container `teaching-materials` | `Storage:BlobServiceUri`, `Storage:ContainerName` |
| Notifications | Azure Service Bus, queue `notifications` | `ServiceBus:FullyQualifiedNamespace`, `ServiceBus:QueueName` |
| Secrets | Azure Key Vault | `KeyVault:VaultUri` |
| Telemetry | Application Insights, through the Azure Monitor OpenTelemetry distro | `APPLICATIONINSIGHTS_CONNECTION_STRING` |
| Image | Private Azure Container Registry, repository `contoso-university` | Built with .NET SDK container publishing; no Dockerfile |

Every value comes from configuration. Never hard-code endpoints, keys, connection strings, IDs or secrets.

## Authentication

- **On App Service:** the web app's user-assigned managed identity, through `DefaultAzureCredential`. App Service sets `AZURE_CLIENT_ID`. The database connection uses `Authentication=Active Directory Default` with no user name or password, and comes from the Key Vault secret `ConnectionStrings--DefaultConnection`.
- **On the dev VM (`vm-dev01`):** the member's own identity, through `DefaultAzureCredential` with `AZURE_TOKEN_CREDENTIALS=AzureCliCredential` set, because the VM's own policy-added system-assigned identity has no data roles.
- **SQL authentication** is used only in `Development`, against the unchanged source database on `vm-app01`, with the `contosoapp` login from .NET user secrets. Outside `Development` the app refuses a connection string that contains a user name or password.
- No shared keys, SAS tokens, connection strings with secrets or local authentication for Storage, Service Bus or Application Insights.

Backends are reached only through private endpoints, by their standard host names. Never use `privatelink` host names, IP addresses or the SQL Managed Instance public endpoint.

## How to work

Follow the playbook in [modernization/playbook.md](modernization/playbook.md). The skills in [skills/](skills/) cover what the Upgrade agent's tasks can leave behind. Run the app after every change; a passing build isn't enough.
