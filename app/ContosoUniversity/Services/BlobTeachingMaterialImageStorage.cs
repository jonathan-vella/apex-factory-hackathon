using Azure;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace ContosoUniversity.Services
{
    public sealed class BlobTeachingMaterialImageStorage : ITeachingMaterialImageStorage
    {
        private static readonly IReadOnlyDictionary<string, string> ContentTypes =
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                [".jpg"] = "image/jpeg",
                [".jpeg"] = "image/jpeg",
                [".png"] = "image/png",
                [".gif"] = "image/gif",
                [".bmp"] = "image/bmp"
            };

        private readonly Lazy<BlobContainerClient> _containerClient;

        public BlobTeachingMaterialImageStorage(IConfiguration configuration)
        {
            _containerClient = new Lazy<BlobContainerClient>(() =>
            {
                var blobServiceUri = configuration["Storage:BlobServiceUri"];
                var containerName = configuration["Storage:ContainerName"];

                if (string.IsNullOrWhiteSpace(blobServiceUri))
                {
                    throw new InvalidOperationException("Storage:BlobServiceUri must be configured.");
                }

                if (!Uri.TryCreate(blobServiceUri, UriKind.Absolute, out var serviceUri))
                {
                    throw new InvalidOperationException("Storage:BlobServiceUri must be an absolute URI.");
                }

                if (string.IsNullOrWhiteSpace(containerName))
                {
                    throw new InvalidOperationException("Storage:ContainerName must be configured.");
                }

                var serviceClient = new BlobServiceClient(serviceUri, new DefaultAzureCredential());
                return serviceClient.GetBlobContainerClient(containerName);
            });
        }

        private BlobContainerClient ContainerClient => _containerClient.Value;

        public async Task<string> UploadAsync(
            int courseId,
            string fileExtension,
            Stream content,
            CancellationToken cancellationToken)
        {
            var extension = fileExtension.ToLowerInvariant();
            if (!ContentTypes.TryGetValue(extension, out var contentType))
            {
                throw new ArgumentException("The teaching-material image type is not supported.", nameof(fileExtension));
            }

            var blobName = $"course_{courseId}_{Guid.NewGuid()}{extension}";
            var blobClient = ContainerClient.GetBlobClient(blobName);
            await blobClient.UploadAsync(
                content,
                new BlobUploadOptions
                {
                    HttpHeaders = new BlobHttpHeaders { ContentType = contentType }
                },
                cancellationToken);

            return blobName;
        }

        public async Task<TeachingMaterialImageDownload> DownloadAsync(
            string imagePath,
            CancellationToken cancellationToken)
        {
            var blobName = GetBlobName(imagePath);
            if (blobName == null)
            {
                return null;
            }

            try
            {
                var response = await ContainerClient
                    .GetBlobClient(blobName)
                    .DownloadStreamingAsync(cancellationToken: cancellationToken);

                return new TeachingMaterialImageDownload(
                    response.Value.Content,
                    ContentTypes[Path.GetExtension(blobName)]);
            }
            catch (RequestFailedException ex) when (ex.Status == 404)
            {
                return null;
            }
        }

        public async Task DeleteAsync(
            int courseId,
            string imagePath,
            CancellationToken cancellationToken)
        {
            var blobName = GetBlobName(imagePath, courseId);
            if (blobName == null)
            {
                return;
            }

            await ContainerClient
                .GetBlobClient(blobName)
                .DeleteIfExistsAsync(cancellationToken: cancellationToken);
        }

        private static string GetBlobName(string imagePath, int? expectedCourseId = null)
        {
            if (string.IsNullOrWhiteSpace(imagePath))
            {
                return null;
            }

            var normalizedPath = imagePath.Replace('\\', '/');
            var blobName = normalizedPath[(normalizedPath.LastIndexOf('/') + 1)..];
            var extension = Path.GetExtension(blobName);
            var nameWithoutExtension = Path.GetFileNameWithoutExtension(blobName);
            var nameParts = nameWithoutExtension.Split('_');

            if (nameParts.Length != 3
                || !string.Equals(nameParts[0], "course", StringComparison.OrdinalIgnoreCase)
                || !int.TryParse(nameParts[1], out var blobCourseId)
                || !Guid.TryParse(nameParts[2], out _)
                || !ContentTypes.ContainsKey(extension))
            {
                return null;
            }

            if (expectedCourseId.HasValue && blobCourseId != expectedCourseId.Value)
            {
                return null;
            }

            return blobName;
        }
    }
}
