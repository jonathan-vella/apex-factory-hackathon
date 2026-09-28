#nullable enable

using System.Threading;
using System.Threading.Tasks;
using ContosoUniversity.Models;

namespace ContosoUniversity.Services
{
    public interface INotificationService
    {
        Task SendNotificationAsync(
            string entityType,
            string entityId,
            EntityOperation operation,
            string? userName = null,
            CancellationToken cancellationToken = default);

        Task SendNotificationAsync(
            string entityType,
            string entityId,
            string? entityDisplayName,
            EntityOperation operation,
            string? userName = null,
            CancellationToken cancellationToken = default);

        Task<Notification?> ReceiveNotificationAsync(CancellationToken cancellationToken = default);

        void MarkAsRead(int notificationId);
    }
}