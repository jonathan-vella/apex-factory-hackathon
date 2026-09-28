#nullable enable

using System;
using System.Globalization;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace ContosoUniversity.Services
{
    public interface ITeachingMaterialStorage
    {
        Task UploadAsync(string fileName, Stream content, string contentType, CancellationToken cancellationToken = default);
        Task<TeachingMaterialFile?> DownloadAsync(string fileName, CancellationToken cancellationToken = default);
        Task DeleteAsync(string fileName, CancellationToken cancellationToken = default);
    }

    public sealed record TeachingMaterialFile(Stream Content, string ContentType);

    internal static class TeachingMaterialFileName
    {
        private const string Prefix = "course_";
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };

        internal static bool IsAllowedExtension(string extension)
        {
            return Array.Exists(AllowedExtensions, allowedExtension =>
                string.Equals(allowedExtension, extension, StringComparison.OrdinalIgnoreCase));
        }

        internal static bool IsValid(string fileName)
        {
            if (string.IsNullOrWhiteSpace(fileName) ||
                fileName.Contains('/') ||
                fileName.Contains('\\') ||
                !string.Equals(Path.GetFileName(fileName), fileName, StringComparison.Ordinal) ||
                !fileName.StartsWith(Prefix, StringComparison.Ordinal))
            {
                return false;
            }

            var extension = Path.GetExtension(fileName);
            if (!IsAllowedExtension(extension))
            {
                return false;
            }

            var nameWithoutExtension = Path.GetFileNameWithoutExtension(fileName);
            var separatorIndex = nameWithoutExtension.IndexOf('_', Prefix.Length);
            if (separatorIndex <= Prefix.Length ||
                !int.TryParse(
                    nameWithoutExtension.AsSpan(Prefix.Length, separatorIndex - Prefix.Length),
                    NumberStyles.AllowLeadingSign,
                    CultureInfo.InvariantCulture,
                    out _))
            {
                return false;
            }

            var guid = nameWithoutExtension.AsSpan(separatorIndex + 1);
            return Guid.TryParseExact(guid, "D", out _);
        }
    }
}