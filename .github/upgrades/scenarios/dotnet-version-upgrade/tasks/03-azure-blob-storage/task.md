# 03-azure-blob-storage: Migrate mutable file handling to Azure Blob Storage

## Research Findings (2026-09-28)

### Confirmed project state

- Scope is the single `net10.0` ASP.NET Core project `app/ContosoUniversity/ContosoUniversity.csproj`; package versions are declared in the project file and there is no central package management file.
- `CoursesController` currently injects `IWebHostEnvironment`, writes uploads directly to `<content-root>/Uploads/TeachingMaterials`, and deletes old files from disk. It validates `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, enforces a 5 MiB maximum, and names uploads `course_{CourseID}_{Guid}{extension}`.
- Create stores `~/Uploads/TeachingMaterials/{fileName}` in `Course.TeachingMaterialImagePath`. Edit deletes the old file before uploading the replacement. Course deletion ignores file-cleanup failures and still deletes the course. Preserve these observable behaviors.
- The Course Index, Details, and Edit views use `Url.Content` on `TeachingMaterialImagePath`, so the existing browser path can remain `/Uploads/TeachingMaterials/{fileName}` if the local physical static-file mapping is replaced with an application endpoint.
- `Program.cs` currently creates the local upload directory and exposes the entire `Uploads` tree with `PhysicalFileProvider`; this mapping must be removed so mutable files are no longer served from local disk.
- `Uploads/TeachingMaterials` contains only `.gitkeep`; there are no existing local teaching-material files to backfill or migrate.
- The `Services` folder is the existing home for application abstractions. Direct package dependencies before this task include only EF Core SQL Server 10.0.12; no Azure Blob SDK or storage service is defined in source.
- Supported stable package versions for `net10.0` are `Azure.Storage.Blobs` 12.29.2 and `Azure.Identity` 1.21.0. Blob SDK guidance confirms `BlobServiceClient(Uri, DefaultAzureCredential)` and thread-safe reusable clients.
- The configured .NET user-secrets list currently contains `ConnectionStrings:DefaultConnection` only; no `Storage:BlobServiceUri` or `Storage:ContainerName` key is configured. Secret values were not inspected or copied.
- Test-project discovery returned no matching .NET test project.

### Implementation and validation boundary

- Add a storage abstraction with an Azure Blob implementation using `DefaultAzureCredential`, `Storage:BlobServiceUri`, and `Storage:ContainerName`. Do not use connection strings, account keys, SAS, blob URLs in `Course.TeachingMaterialImagePath`, or client IDs/tenant IDs.
- Validate any configured service URI as HTTPS on the standard `*.blob.core.windows.net` hostname; reject IP literals, `privatelink`, nonstandard ports, user info, and URL query/fragment data. Private DNS must resolve the standard hostname privately at runtime; this task does not probe or change DNS/networking.
- Do not create the container or storage resources. When local Storage settings are absent, keep normal page requests available and report file operations as an explicit external configuration blocker.
- Stream browser downloads through an application route at the existing `/Uploads/TeachingMaterials/{fileName}` path. Validate file names/extensions and never return or redirect to a Blob URL.
- Modify only the application project/configuration and task artifacts. Do not execute Service Bus task 04, provision/configure resources, assign roles, deploy, or change on-premises systems.

Replace the `CoursesController` dependency on `Server.MapPath` and direct creation, writing, and deletion beneath `Uploads/TeachingMaterials` with an application storage abstraction backed only by Azure Blob Storage for mutable application-managed files. Preserve teaching-material upload, replacement, retrieval, and deletion behavior using ASP.NET Core upload types, including existing validation, supported file types, size limits, naming behavior, replacement cleanup, deletion cleanup, controllers, views, and the assessed `HttpPostedFileBase` compatibility surface. Keep ordinary CSS, JavaScript, images, and bundled immutable assets in the application's static-content pipeline.

The Blob client must use `DefaultAzureCredential`, `Storage:BlobServiceUri`, and `Storage:ContainerName`; do not use shared keys, SAS tokens, or storage connection strings. Browser-facing stored images must flow through application endpoints rather than exposing blob URLs. The service endpoint must be the standard private-DNS-resolved hostname; do not use a `privatelink` hostname, IP address, public endpoint, hard-coded Azure identity data, or public firewall exception. Do not create/configure storage, containers, networking, identities, or roles.

**Done when**: Mutable file operations use the Blob-backed abstraction with preserved application behavior and no browser-visible blob URL, and restore/build succeeds with no errors; record new warnings but don't block on them. All applicable tests pass or their absence is recorded, and `dotnet run` serves Home, Students, Courses, Instructors, and Departments; missing Development SQL secrets or existing Blob reachability/RBAC/configuration are retained as explicit external blockers until supplied and never trigger provisioning, deployment, or on-premises changes.
