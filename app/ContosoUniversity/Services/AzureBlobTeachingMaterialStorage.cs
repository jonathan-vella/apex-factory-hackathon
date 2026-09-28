#nullable enable

using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using Azure;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.Extensions.Configuration;

namespace ContosoUniversity.Services
{
    public sealed class AzureBlobTeachingMaterialStorage : ITeachingMaterialStorage
    {
        private const string BlobServiceUriKey = "Storage:BlobServiceUri";
        private const string ContainerNameKey = "Storage:ContainerName";
        private readonly BlobContainerClient? containerClient;
        private readonly FileExtensionContentTypeProvider contentTypeProvider = new();

        public AzureBlobTeachingMaterialStorage(IConfiguration configuration)
        {
            var blobServiceUri = configuration[BlobServiceUriKey];
            var containerName = configuration[ContainerNameKey];
            if (string.IsNullOrWhiteSpace(blobServiceUri) && string.IsNullOrWhiteSpace(containerName))
            {
                return;
            }

            if (string.IsNullOrWhiteSpace(blobServiceUri) || string.IsNullOrWhiteSpace(containerName))
            {
                throw new InvalidOperationException("Both Storage:BlobServiceUri and Storage:ContainerName must be configured together.");
            }

            if (!Uri.TryCreate(blobServiceUri, UriKind.Absolute, out var serviceUri) ||
                !string.Equals(serviceUri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase) ||
                !serviceUri.IsDefaultPort ||
                !string.Equals(serviceUri.AbsolutePath, "/", StringComparison.Ordinal) ||
                !string.IsNullOrEmpty(serviceUri.UserInfo) ||
                !string.IsNullOrEmpty(serviceUri.Query) ||
                !string.IsNullOrEmpty(serviceUri.Fragment) ||
                serviceUri.Host.Contains("privatelink", StringComparison.OrdinalIgnoreCase) ||
                IPAddress.TryParse(serviceUri.Host, out _) ||
                !serviceUri.Host.EndsWith(".blob.core.windows.net", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Storage:BlobServiceUri must be an HTTPS standard Azure Blob service hostname resolved through private DNS.");
            }

            var client = new BlobServiceClient(serviceUri, new DefaultAzureCredential());
            containerClient = client.GetBlobContainerClient(containerName);
        }

        public async Task UploadAsync(string fileName, Stream content, string contentType, CancellationToken cancellationToken = default)
        {
            var blobClient = GetContainerClient().GetBlobClient(ValidateFileName(fileName));
            await blobClient.UploadAsync(
                content,
                new BlobUploadOptions
                {
                    HttpHeaders = new BlobHttpHeaders { ContentType = contentType }
                },
                cancellationToken);
        }

        public async Task<TeachingMaterialFile?> DownloadAsync(string fileName, CancellationToken cancellationToken = default)
        {
            var blobClient = GetContainerClient().GetBlobClient(ValidateFileName(fileName));
            try
            {
                var response = await blobClient.DownloadStreamingAsync(cancellationToken: cancellationToken);
                var contentType = response.Value.Details.ContentType;
                if (string.IsNullOrWhiteSpace(contentType) && !contentTypeProvider.TryGetContentType(fileName, out contentType))
                {
                    contentType = "application/octet-stream";
                }

                return new TeachingMaterialFile(response.Value.Content, contentType);
            }
            catch (RequestFailedException exception) when (exception.Status == 404)
            {
                return null;
            }
        }

        public async Task DeleteAsync(string fileName, CancellationToken cancellationToken = default)
        {
            var blobClient = GetContainerClient().GetBlobClient(ValidateFileName(fileName));
            await blobClient.DeleteIfExistsAsync(cancellationToken: cancellationToken);
        }

        private BlobContainerClient GetContainerClient()
        {
            return containerClient ?? throw new InvalidOperationException(
                "Storage:BlobServiceUri and Storage:ContainerName are required for teaching material operations.");
        }

        private static string ValidateFileName(string fileName)
        {
            if (!TeachingMaterialFileName.IsValid(fileName))
            {
                throw new ArgumentException("A generated course teaching material file name is required.", nameof(fileName));
            }

            return fileName;
        }
    }
}