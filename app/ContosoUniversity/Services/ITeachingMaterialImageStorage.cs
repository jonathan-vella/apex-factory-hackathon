using System.IO;

namespace ContosoUniversity.Services
{
    public interface ITeachingMaterialImageStorage
    {
        Task<string> UploadAsync(
            int courseId,
            string fileExtension,
            Stream content,
            CancellationToken cancellationToken);

        Task<TeachingMaterialImageDownload> DownloadAsync(
            string imagePath,
            CancellationToken cancellationToken);

        Task DeleteAsync(
            int courseId,
            string imagePath,
            CancellationToken cancellationToken);
    }

    public sealed record TeachingMaterialImageDownload(Stream Content, string ContentType);
}
