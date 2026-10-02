using System;
using System.IO;
using System.Text.RegularExpressions;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Configuration;

namespace ContosoUniversity.Services
{
    public class TeachingMaterialStore
    {
        public const string StoredPathPrefix = "~/Uploads/TeachingMaterials/";

        private static readonly Regex ManagedName = new Regex(
            @"^course_\d+_[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\.(jpg|jpeg|png|gif|bmp)$",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);

        private readonly BlobContainerClient _container;

        public TeachingMaterialStore(IConfiguration configuration)
        {
            var serviceUri = configuration["Storage:BlobServiceUri"];
            var containerName = configuration["Storage:ContainerName"];
            if (string.IsNullOrWhiteSpace(serviceUri) || string.IsNullOrWhiteSpace(containerName))
            {
                throw new InvalidOperationException(
                    "Storage:BlobServiceUri and Storage:ContainerName must be configured (user secrets in Development, environment variables or app settings elsewhere).");
            }

            var service = new BlobServiceClient(new Uri(serviceUri), new DefaultAzureCredential());
            _container = service.GetBlobContainerClient(containerName);
        }

        // Maps a stored value to an app-managed blob name, or null when it is not one.
        public static string ResolveBlobName(string storedPath)
        {
            if (string.IsNullOrEmpty(storedPath))
            {
                return null;
            }

            var name = Path.GetFileName(storedPath.Replace('\\', '/'));
            return !string.IsNullOrEmpty(name) && ManagedName.IsMatch(name) ? name : null;
        }

        public static string ToStoredPath(string blobName) => StoredPathPrefix + blobName;

        public void Upload(string blobName, Stream content, string contentType)
        {
            _container.GetBlobClient(blobName).Upload(content, new BlobUploadOptions
            {
                HttpHeaders = new BlobHttpHeaders { ContentType = contentType }
            });
        }

        public bool Delete(string blobName) => _container.GetBlobClient(blobName).DeleteIfExists().Value;

        public (Stream Content, string ContentType)? Open(string blobName)
        {
            var blob = _container.GetBlobClient(blobName);
            if (!blob.Exists().Value)
            {
                return null;
            }

            var result = blob.DownloadStreaming().Value;
            return (result.Content, result.Details.ContentType);
        }
    }
}
