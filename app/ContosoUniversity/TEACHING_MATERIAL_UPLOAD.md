# Teaching Material Image Storage

Course teaching-material images are stored in the existing Azure Blob Storage
container. The application streams each image through the
`Courses/TeachingMaterialImage` endpoint, so the container can remain private
and browsers do not need SAS tokens.

## Features

- Upload images while creating or editing a course.
- Accept JPG, JPEG, PNG, GIF, and BMP files up to 5 MB.
- Generate unique blob names in the
  `course_{CourseID}_{GUID}.{extension}` format.
- Delete the previous blob after a course image is replaced.
- Delete the associated blob when a course is removed.
- Render course-list thumbnails and course details from the application.

## Runtime configuration

Provide both settings at runtime:

| Setting | Purpose |
| --- | --- |
| `Storage:BlobServiceUri` | Absolute URI of the existing Blob Storage service |
| `Storage:ContainerName` | Name of the existing container |

For App Service, use application settings named
`Storage__BlobServiceUri` and `Storage__ContainerName`. For local development,
use .NET user secrets or environment variables. Do not put account keys, SAS
tokens, or storage connection strings in application configuration.

The application authenticates with `DefaultAzureCredential`. Its runtime
identity must already have permission to read, write, and delete blobs in the
configured container. The application does not create the container or assign
roles.

## Implementation details

- New and replaced images store only the blob name in the existing
  `TeachingMaterialImagePath` database field, not a direct Blob Storage URL.
- Views link to the application endpoint, which downloads the blob using the
  application's Azure identity and returns its image content type.
- Upload validation keeps the 5 MB limit and supported extensions.
- The ASP.NET Core request-body limit remains 10 MB.
- Ordinary CSS, JavaScript, and bundled static assets continue to be served
  from `wwwroot`; only mutable teaching-material images use Blob Storage.
- The migration does not add application sign-in or change authorization;
  course and upload actions retain the existing application behavior.

## Existing images

The application does not bulk-copy local uploads. Before rollout, copy any
existing `Uploads/TeachingMaterials` files to the configured container,
preserving their generated filenames. Legacy database paths are resolved by
filename, so they continue to render after the corresponding blobs are copied.

## Troubleshooting

- **Missing configuration**: Verify both runtime settings are present and that
  `Storage:BlobServiceUri` is an absolute URI.
- **403 response from Blob Storage**: Confirm the identity selected by
  `DefaultAzureCredential` already has data-plane access to the configured
  container.
- **404 image response**: Confirm the stored blob name exists in the configured
  container.
- **Rejected upload**: Verify the image is no larger than 5 MB and uses JPG,
  JPEG, PNG, GIF, or BMP.

Back up and retain images using the organization's Azure Storage backup policy;
the application no longer writes teaching-material images to its local
filesystem.
