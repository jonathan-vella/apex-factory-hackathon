# Task 03 progress details

## Outcome

- Added `Azure.Identity` 1.21.0 and `Azure.Storage.Blobs` 12.29.2.
- Added `ITeachingMaterialStorage` and an Azure Blob implementation that authenticates with `DefaultAzureCredential`, reads `Storage:BlobServiceUri` and `Storage:ContainerName`, streams upload/download content, retains content types, maps missing blobs to not-found, and supports idempotent deletion.
- Validated configured service URIs as HTTPS standard `*.blob.core.windows.net` hostnames and reject IP literals, `privatelink`, non-default ports, user information, query strings, and fragments. The application does not create the container.
- Registered the storage service as a singleton, removed local upload-directory creation and physical `/Uploads` static serving, and retained the normal `wwwroot` static asset pipeline.
- Migrated Course upload, replacement, retrieval, and deletion operations to the storage abstraction while preserving the existing extension allowlist, 5 MiB limit, generated `course_{CourseID}_{Guid}{extension}` names, and stored `~/Uploads/TeachingMaterials/{fileName}` path format.
- Added a same-origin download endpoint. It streams the blob without exposing its URL, returns 404 for missing or invalid names, and returns 503 when Blob configuration or service access is unavailable.
- Shared filename validation restricts access to the established course ID/GUID filename shape and allowed image extensions; arbitrary keys and path traversal are rejected.
- No local uploads needed backfill; `Uploads/TeachingMaterials` contained only `.gitkeep`.
- No storage resources, container, identity, role assignment, network setting, deployment, or on-premises system was created or changed.

## Validation

- `dotnet restore app/ContosoUniversity/ContosoUniversity.csproj --verbosity minimal`: succeeded.
- `dotnet build app/ContosoUniversity/ContosoUniversity.csproj --configuration Release --no-restore --verbosity minimal`: succeeded, 0 errors, 0 warnings.
- Resolved package versions confirmed `Azure.Identity` 1.21.0, `Azure.Storage.Blobs` 12.29.2, and `Azure.Core` 1.55.0.
- Compiler diagnostics reported no errors in the modified application files; `git diff --check` reported no whitespace errors.
- Test-project discovery returned `[]`; no applicable .NET test project exists.
- In Development, the application used the existing SQL user-secret configuration and returned HTTP 200 for `/`, `/Students`, `/Courses`, `/Instructors`, and `/Departments`.
- A generated-format image path reached the application storage boundary and returned HTTP 503 with Blob settings absent. Arbitrary and malformed names, a traversal path, and `/Uploads/TeachingMaterials/.gitkeep` returned HTTP 404.
- Source scan found no remaining local upload directory creation, file writes/deletes, or `PhysicalFileProvider` mapping in the application project.

## External dependencies

- `Storage:BlobServiceUri` and `Storage:ContainerName` are not configured in Development. Therefore no Blob request was made and actual upload, replacement, retrieval, or delete against Azure could not be exercised.
- The operator must supply the standard service hostname and container name, and verify that the container exists, `DefaultAzureCredential` resolves to an authorized identity, required Blob data-plane permissions are assigned, and private DNS/network reachability work. Those environment and Azure checks are outside this task.

## Files changed

- `.github/upgrades/scenarios/dotnet-version-upgrade/scenario-instructions.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/03-azure-blob-storage/task.md`
- `.github/upgrades/scenarios/dotnet-version-upgrade/tasks/03-azure-blob-storage/progress-details.md`
- `app/ContosoUniversity/ContosoUniversity.csproj`
- `app/ContosoUniversity/Program.cs`
- `app/ContosoUniversity/Controllers/CoursesController.cs`
- `app/ContosoUniversity/Services/ITeachingMaterialStorage.cs`
- `app/ContosoUniversity/Services/AzureBlobTeachingMaterialStorage.cs`

## Boundary

Task 03 is complete. Task 04, Azure Service Bus, remains unstarted for review and separate approval.