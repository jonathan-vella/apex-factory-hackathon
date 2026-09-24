# Contoso University: the legacy app

`ContosoUniversity/` is the modernization starting state. It's an ASP.NET MVC 5 app on .NET Framework 4.8, with EF Core 3.1, SQL Server, MSMQ and local file uploads. It's kept exactly as upstream publishes it, including what a modernization assessment should find: LocalDB in `Web.config`, `debug="true"`, the MSMQ queue, local uploads and `Trace` logging.

## Source

| Field | Value |
|---|---|
| Repo and folder | [Azure-Samples/dotnet-migration-copilot-samples, `ContosoUniversity`](https://github.com/Azure-Samples/dotnet-migration-copilot-samples/tree/7c1bf47b7e2627fe5a1c764716638815d35e0282/ContosoUniversity) |
| Commit | `7c1bf47b7e2627fe5a1c764716638815d35e0282` |
| Changes | None |

## Legacy dependencies

| Dependency | Where | Target |
|---|---|---|
| SQL Server (LocalDB in the sample, SQL Server 2022 in the datacenter) | `Web.config`, `DefaultConnection` | Azure SQL Managed Instance with managed identity |
| Local file uploads | `Uploads/TeachingMaterials/`, `CoursesController` | Azure Blob Storage |
| MSMQ private queue | `Web.config`, `NotificationQueuePath`; `Services/NotificationService.cs` | Azure Service Bus |
| .NET Framework 4.8, `Global.asax`, bundling | The whole project | .NET 10 and ASP.NET Core |

## Package

The [Build legacy app](../.github/workflows/build-legacy.yml) workflow builds the app on Windows whenever `app/` changes. It packages the web app without its source as `ContosoUniversity-legacy.zip`, checks the package and uploads it as a workflow artifact. On `main`, it publishes the zip to the [`legacy-v1`](https://github.com/jonathan-vella/apex-factory-hackathon/releases/tag/legacy-v1) release, and the datacenter kit (B04) deploys it to `vm-app01`.

Upstream doesn't include the Bootstrap CSS that `BundleConfig.cs` and the project reference. The workflow adds `bootstrap.css` and `bootstrap.min.css` from the restored `bootstrap` 5.3.3 NuGet package to the package only. The source here stays unchanged.
