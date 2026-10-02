# Progress: 03-blob-storage-files

## Files changed (app/ContosoUniversity)
- Services/TeachingMaterialStore.cs (new): Azure.Storage.Blobs + DefaultAzureCredential, config `Storage:BlobServiceUri` / `Storage:ContainerName`; blob-name regex `course_{id}_{guid}.{ext}` constrains deletes/reads.
- Controllers/CoursesController.cs: Create/Edit/Delete use the store; new `TeachingMaterial/{id}` action streams the blob with content type; delete failures are logged, not fatal; Edit only deletes the old blob if it is app-managed and belongs to the same course.
- Program.cs: removed `/Uploads` static files and directory creation; registered store; fail-fast at startup when Storage settings are missing.
- Views/Courses Index/Details/Edit: image src uses the app URL.
- appsettings.json: `Storage` keys with empty values. csproj: Azure.Storage.Blobs, Azure.Identity.

## Design
Stored DB value format stays `~/Uploads/TeachingMaterials/{file}`; blob name = file name, so old and new rows resolve identically.

## Validation
- `dotnet build`: 0 warnings, 0 errors.
- Storage values came from project user secrets (not written to source or artifacts); Azure CLI sign-in worked.
- Passed (Development, real SQL secret): home, Students, Courses, Instructors, Departments return 200; invalid type and >5 MB rejected with existing messages; upload on Create (302); image served via `/Courses/TeachingMaterial/{id}` as image/png in Index/Details/Edit with no blob host in HTML; replace on Edit changed the name and the old blob was gone (read-only listing showed only the new blob); course Delete removed the blob (listing empty). Test course removed; app stopped.
- Not exercised: delete-failure logging path; legacy-row rendering beyond name mapping.
